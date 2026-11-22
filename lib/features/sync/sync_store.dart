import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../services/app_database.dart';
import '../media/media_store.dart';
import 'sync_clock.dart';
import 'sync_field_groups.dart';
import 'sync_models.dart';

/// Reads the local replica for a peer and applies a peer's pages into it.
///
/// The LAN server and the pull engine call this store; they never touch Drift
/// directly. Applying is a field-level LWW merge: a group of columns moves
/// together only when its incoming HLC is newer than the local one.
class SyncStore {
  SyncStore(this._db);

  final AppDatabase _db;

  static const defaultSnapshotLimit = 500;
  static const defaultChangesLimit = 200;

  // ---------------------------------------------------------------------------
  // Snapshot and change feed

  /// Builds one dependency-ordered snapshot page.
  ///
  /// A row is sent as a tombstone only when its tombstone is newer than every
  /// field version; otherwise the live row wins. [SyncSnapshotPage.nextSince]
  /// is captured on the first page and carried in the cursor so later pages
  /// keep the same replay point.
  Future<SyncSnapshotPage> snapshotPage({String? cursor, int limit = defaultSnapshotLimit}) async {
    final state = await _db.syncDeviceState();
    final cap = limit.clamp(1, 2000).toInt();
    final position = cursor == null ? null : _decodeCursor(cursor);
    final nextSince = position?.since ?? await _maxChangeSeq();

    final specs = [..._db.syncEntities]
      ..sort((a, b) {
        final byRank = a.rank.compareTo(b.rank);
        return byRank != 0 ? byRank : a.name.compareTo(b.name);
      });

    final rows = <SyncRowPayload>[];
    for (final spec in specs) {
      final liveRows = await _db.readSyncRows(spec);
      final live = {for (final row in liveRows) spec.rowKey(row): row};
      final versions = await _loadVersions(spec.name);
      final tombstones = await _loadTombstones(spec.name);
      final keys = {...live.keys, ...tombstones.keys}.toList()..sort();
      for (final key in keys) {
        if (position != null && !position.precedes(spec.rank, spec.name, key)) continue;
        final payload = _snapshotPayload(spec, key, live[key], versions[key] ?? const {}, tombstones[key]);
        if (payload == null) continue;
        rows.add(payload);
      }
    }

    final hasMore = rows.length > cap;
    final pageRows = hasMore ? rows.sublist(0, cap) : rows;
    final nextCursor = hasMore ? _encodeCursor(pageRows.last, nextSince) : null;

    return SyncSnapshotPage(
      datasetId: state.datasetId,
      epoch: state.epoch,
      nodeId: state.nodeId,
      deviceId: await _localDeviceId(state.nodeId),
      generatedAt: DateTime.now().toUtc(),
      serverHlc: SyncHlc(millis: state.hlcMillis, counter: state.hlcCounter, nodeId: state.nodeId).encode(),
      nextSince: nextSince,
      cursor: nextCursor,
      done: !hasMore,
      knownDevices: await knownDevices(),
      rows: pageRows,
    );
  }

  /// Returns local changes after [since], in sequence order.
  Future<SyncChangesPage> changesPage({required int since, int limit = defaultChangesLimit}) async {
    final state = await _db.syncDeviceState();
    final cap = limit.clamp(1, 1000).toInt();
    final start = since < 0 ? 0 : since;
    final rows =
        await (_db.select(_db.syncChangeRecords)
              ..where((row) => row.seq.isBiggerThanValue(start))
              ..orderBy([(row) => OrderingTerm.asc(row.seq)])
              ..limit(cap + 1))
            .get();
    final hasMore = rows.length > cap;
    final pageRows = hasMore ? rows.sublist(0, cap) : rows;
    final nextSince = pageRows.isEmpty ? start : pageRows.last.seq;

    return SyncChangesPage(
      datasetId: state.datasetId,
      epoch: state.epoch,
      nodeId: state.nodeId,
      nextSince: nextSince,
      hasMore: hasMore,
      knownDevices: await knownDevices(),
      changes: [for (final row in pageRows) _changePayload(row)],
    );
  }

  /// Public device list shared with peers. It never contains a shared key.
  Future<List<SyncKnownDevice>> knownDevices() async {
    final rows = await _db.select(_db.pairedDeviceRecords).get();
    rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [
      for (final row in rows)
        SyncKnownDevice(deviceId: row.id, name: row.name, certificateFingerprint: row.certificateFingerprint),
    ];
  }

  // ---------------------------------------------------------------------------
  // Peer state

  /// The local sync identity: node id, dataset id, epoch and HLC.
  Future<SyncDeviceStateRow> deviceState() => _db.syncDeviceState();

  Future<SyncPeerStateRow?> readPeerState(String peerDeviceId) async {
    return (_db.select(
      _db.syncPeerStateRecords,
    )..where((row) => row.peerDeviceId.equals(peerDeviceId))).getSingleOrNull();
  }

  Future<List<SyncPeerStateRow>> readPeerStates() => _db.select(_db.syncPeerStateRecords).get();

  Future<void> recordPeerSuccess({
    required String peerDeviceId,
    required String datasetId,
    required String peerEpoch,
    required int lastPulledSeq,
    String? lastError,
  }) async {
    await _db
        .into(_db.syncPeerStateRecords)
        .insertOnConflictUpdate(
          SyncPeerStateRecordsCompanion(
            peerDeviceId: Value(peerDeviceId),
            datasetId: Value(datasetId),
            peerEpoch: Value(peerEpoch),
            lastPulledSeq: Value(lastPulledSeq),
            lastSyncedAt: Value(DateTime.now().toUtc()),
            lastError: Value(lastError),
          ),
        );
  }

  Future<void> recordPeerError({required String peerDeviceId, required String error}) async {
    final existing = await readPeerState(peerDeviceId);
    await _db
        .into(_db.syncPeerStateRecords)
        .insertOnConflictUpdate(
          SyncPeerStateRecordsCompanion(
            peerDeviceId: Value(peerDeviceId),
            datasetId: Value(existing?.datasetId ?? ''),
            peerEpoch: Value(existing?.peerEpoch ?? ''),
            lastPulledSeq: Value(existing?.lastPulledSeq ?? 0),
            lastSyncedAt: Value(existing?.lastSyncedAt),
            lastError: Value(error),
          ),
        );
  }

  /// Records that this peer serves a different plan. It is not an error, but
  /// the cursor is reset and the Devices page asks the user for a source.
  Future<void> recordPeerMismatch({required String peerDeviceId, required String datasetId}) async {
    final existing = await readPeerState(peerDeviceId);
    await _db
        .into(_db.syncPeerStateRecords)
        .insertOnConflictUpdate(
          SyncPeerStateRecordsCompanion(
            peerDeviceId: Value(peerDeviceId),
            datasetId: Value(datasetId),
            peerEpoch: const Value(''),
            lastPulledSeq: const Value(0),
            lastSyncedAt: Value(existing?.lastSyncedAt),
            lastError: const Value(null),
          ),
        );
  }

  Future<void> clearPeerState(String peerDeviceId) async {
    await (_db.delete(_db.syncPeerStateRecords)..where((row) => row.peerDeviceId.equals(peerDeviceId))).go();
  }

  // ---------------------------------------------------------------------------
  // Media

  /// Image ids this device still needs to fetch.
  Future<Set<String>> pendingMediaIds() => _db.pendingMediaIds();

  Future<bool> hasCachedMedia(String mediaId) => _db.hasCachedMedia(mediaId);

  /// Verifies and stores an image received from a peer.
  Future<bool> installMedia(String mediaId, Uint8List bytes) => _db.installMedia(mediaId, bytes);

  /// Reads a verified image for the signed media endpoint.
  Future<MediaBlob?> readMedia(String mediaId) => _db.readMedia(mediaId);

  /// Gives rows whose image arrived after the row a local display path.
  Future<int> linkMediaPaths(Iterable<String> mediaIds) => _db.linkMediaPaths(mediaIds);

  // ---------------------------------------------------------------------------
  // Applying pages

  /// Applies one snapshot page. The page is rejected as a whole when the peer
  /// belongs to a different plan; the caller has to offer a source choice.
  Future<SyncApplyResult> applySnapshotPage(SyncSnapshotPage page, {required String peerDeviceId}) async {
    final state = await _db.syncDeviceState();
    if (page.datasetId != state.datasetId) {
      throw SyncDatasetMismatchException(localDatasetId: state.datasetId, remoteDatasetId: page.datasetId);
    }
    return _applyRows(
      _sortByDependency(page.rows),
      peerDeviceId: peerDeviceId,
      peerDatasetId: page.datasetId,
      peerEpoch: page.epoch,
      commitCursor: page.done ? page.nextSince : null,
    );
  }

  /// Applies one delta page. A changed peer epoch means the cursor belongs to a
  /// previous log incarnation, so the caller has to start a fresh snapshot.
  Future<SyncApplyResult> applyChangesPage(SyncChangesPage page, {required String peerDeviceId}) async {
    final state = await _db.syncDeviceState();
    if (page.datasetId != state.datasetId) {
      throw SyncDatasetMismatchException(localDatasetId: state.datasetId, remoteDatasetId: page.datasetId);
    }
    final peerState = await readPeerState(peerDeviceId);
    if (peerState != null && peerState.peerEpoch != page.epoch) {
      throw SyncEpochChangedException(peerDeviceId: peerDeviceId, peerEpoch: page.epoch);
    }
    return _applyRows(
      [for (final change in page.changes) change.payload],
      peerDeviceId: peerDeviceId,
      peerDatasetId: page.datasetId,
      peerEpoch: page.epoch,
      commitCursor: page.nextSince,
    );
  }

  /// Replaces the local plan with a fully staged source snapshot.
  ///
  /// The whole clear-and-apply runs in one transaction, so a malformed source
  /// leaves the target untouched. Identity, pairing records, device-local
  /// settings and media stay in place; only syncable rows and sync bookkeeping
  /// are replaced. The caller must have taken a backup first when this device
  /// has user data.
  Future<SyncApplyResult> applyReplacement(SyncStagedSnapshot staged, {required String peerDeviceId}) async {
    final sourceHlc = SyncHlc.tryParse(staged.serverHlc);
    if (sourceHlc == null) {
      throw const SyncProtocolException('The source clock is invalid');
    }

    final result = await _db.transaction(() async {
      final specs = [..._db.syncEntities]..sort((a, b) => b.rank.compareTo(a.rank));
      for (final spec in specs) {
        if (spec.name == 'setting') {
          await (_db.delete(_db.settingRecords)..where((row) => row.key.equals('weekStart'))).go();
        } else {
          await _db.delete(spec.table).go();
        }
      }
      await _db.delete(_db.remoteSnapshotRecords).go();
      await _db.delete(_db.syncChangeRecords).go();
      await _db.delete(_db.syncFieldVersionRecords).go();
      await _db.delete(_db.syncTombstoneRecords).go();
      await _db.delete(_db.syncPeerStateRecords).go();
      await _db.delete(_db.syncDeviceStateRecords).go();

      final now = DateTime.now().toUtc();
      final hlcMillis = math.max(now.millisecondsSinceEpoch, sourceHlc.millis + 1);
      final nodeId = const Uuid().v4();
      final epoch = const Uuid().v4();
      await _db
          .into(_db.syncDeviceStateRecords)
          .insert(
            SyncDeviceStateRecordsCompanion.insert(
              id: 'local',
              nodeId: nodeId,
              datasetId: staged.datasetId,
              epoch: epoch,
              hlcMillis: hlcMillis,
              hlcCounter: 0,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // The source plan may deliberately have no tags or reference rows. Mark
      // the seeds as done so the next start does not add local defaults back.
      for (final key in const ['defaultCategoriesSeeded', 'homeReferenceSeeded']) {
        await _db.customInsert(
          'INSERT OR REPLACE INTO setting_records (key, value) VALUES (?, ?)',
          variables: [Variable.withString(key), Variable.withString('true')],
        );
      }

      final context = _ApplyContext.empty();
      final applied = SyncApplyResult();
      for (final payload in _sortByDependency(staged.rows)) {
        final accepted = await _applyRow(context, payload);
        if (!accepted) continue;
        if (payload.isDeleted) {
          applied.deleted++;
        } else {
          applied.applied++;
        }
        applied.changedEntities.add(payload.entity);
        if (!payload.isDeleted) await _collectMissingMedia(applied, payload);
      }

      await _db.linkAllMediaPaths();

      await _db
          .into(_db.syncPeerStateRecords)
          .insertOnConflictUpdate(
            SyncPeerStateRecordsCompanion(
              peerDeviceId: Value(peerDeviceId),
              datasetId: Value(staged.datasetId),
              peerEpoch: Value(staged.epoch),
              lastPulledSeq: Value(staged.nextSince),
              lastSyncedAt: Value(now),
              lastError: const Value(null),
            ),
          );
      return applied;
    });

    _db.resetSyncClockCache();
    return result;
  }

  Future<SyncApplyResult> _applyRows(
    List<SyncRowPayload> rows, {
    required String peerDeviceId,
    required String peerDatasetId,
    required String peerEpoch,
    required int? commitCursor,
  }) async {
    if (rows.isEmpty) {
      if (commitCursor != null) {
        await recordPeerSuccess(
          peerDeviceId: peerDeviceId,
          datasetId: peerDatasetId,
          peerEpoch: peerEpoch,
          lastPulledSeq: commitCursor,
        );
      }
      return SyncApplyResult();
    }

    return _db.transaction(() async {
      final context = await _ApplyContext.load(_db, rows);
      final result = SyncApplyResult();
      final observed = <SyncHlc>[];

      for (final payload in rows) {
        observed.addAll(_incomingVersions(payload));
        final applied = await _applyRow(context, payload);
        if (!applied) {
          result.skipped++;
          continue;
        }
        if (payload.isDeleted) {
          result.deleted++;
        } else {
          result.applied++;
        }
        result.changedEntities.add(payload.entity);
        if (!payload.isDeleted) await _collectMissingMedia(result, payload);
      }

      await _db.observeSyncVersions(observed);
      if (commitCursor != null) {
        await _db
            .into(_db.syncPeerStateRecords)
            .insertOnConflictUpdate(
              SyncPeerStateRecordsCompanion(
                peerDeviceId: Value(peerDeviceId),
                datasetId: Value(peerDatasetId),
                peerEpoch: Value(peerEpoch),
                lastPulledSeq: Value(commitCursor),
                lastSyncedAt: Value(DateTime.now().toUtc()),
                lastError: const Value(null),
              ),
            );
      }
      return result;
    });
  }

  /// Snapshot pages are already built in dependency order. Sorting again keeps
  /// a hand-built or reordered page safe with foreign keys enabled.
  List<SyncRowPayload> _sortByDependency(List<SyncRowPayload> rows) {
    final specs = <String, SyncEntitySpec>{};
    for (final row in rows) {
      try {
        specs[row.entity] = _db.syncEntity(row.entity);
      } on ArgumentError {
        throw SyncProtocolException('Unknown sync entity "${row.entity}"');
      }
    }
    return [...rows]..sort((a, b) {
      final first = specs[a.entity]!;
      final second = specs[b.entity]!;
      final byRank = first.rank.compareTo(second.rank);
      if (byRank != 0) return byRank;
      final byEntity = first.name.compareTo(second.name);
      return byEntity != 0 ? byEntity : a.key.compareTo(b.key);
    });
  }

  Future<bool> _applyRow(_ApplyContext context, SyncRowPayload payload) async {
    final SyncEntitySpec spec;
    try {
      spec = _db.syncEntity(payload.entity);
    } on ArgumentError {
      throw SyncProtocolException('Unknown sync entity "${payload.entity}"');
    }

    _validatePayload(spec, payload);
    final localRow = await _db.readSyncRow(spec, payload.key);
    final localVersions = context.versionsFor(spec.name, payload.key);
    final localTombstone = context.tombstoneFor(spec.name, payload.key);

    if (payload.isDeleted) {
      return _applyDelete(
        context,
        spec,
        payload,
        localRow: localRow,
        localVersions: localVersions,
        localTombstone: localTombstone,
      );
    }
    return _applyUpsert(
      context,
      spec,
      payload,
      localRow: localRow,
      localVersions: localVersions,
      localTombstone: localTombstone,
    );
  }

  Future<bool> _applyDelete(
    _ApplyContext context,
    SyncEntitySpec spec,
    SyncRowPayload payload, {
    required Map<String, Object?>? localRow,
    required Map<String, String> localVersions,
    required String? localTombstone,
  }) async {
    final deleted = SyncHlc.parse(payload.deleted!);
    if (localTombstone != null && deleted.compareTo(SyncHlc.parse(localTombstone)) <= 0) {
      return false;
    }
    for (final version in localVersions.values) {
      if (deleted.compareTo(SyncHlc.parse(version)) <= 0) return false;
    }

    final timestamp = DateTime.fromMillisecondsSinceEpoch(deleted.millis, isUtc: true);
    await _db
        .into(_db.syncTombstoneRecords)
        .insertOnConflictUpdate(
          SyncTombstoneRecordsCompanion(
            entity: Value(spec.name),
            rowKey: Value(payload.key),
            version: Value(deleted.encode()),
            rowJson: Value(jsonEncode(_tombstoneRow(spec, payload.key, payload.row))),
            updatedAt: Value(timestamp),
          ),
        );
    context.setTombstone(spec.name, payload.key, deleted.encode());

    if (localRow != null) {
      if (spec.softDelete) {
        final merged = Map<String, Object?>.of(localRow)
          ..['deleted_at'] = deleted.millis
          ..['updated_at'] = _maxMillis([localRow['updated_at'], deleted.millis]);
        await _writeRow(spec, payload.key, merged, exists: true);
      } else {
        await _deleteRow(spec, payload.key);
      }
    }
    return true;
  }

  Future<bool> _applyUpsert(
    _ApplyContext context,
    SyncEntitySpec spec,
    SyncRowPayload payload, {
    required Map<String, Object?>? localRow,
    required Map<String, String> localVersions,
    required String? localTombstone,
  }) async {
    final accepted = <String, SyncHlc>{};
    for (final entry in payload.versions.entries) {
      SyncFieldGroup? group;
      for (final candidate in spec.fields) {
        if (candidate.name == entry.key) {
          group = candidate;
          break;
        }
      }
      if (group == null) {
        throw SyncProtocolException('Unknown merge field "${entry.key}" on ${spec.name}');
      }
      final incoming = SyncHlc.parse(entry.value);
      final local = localVersions[group.name];
      if (local == null || incoming.compareTo(SyncHlc.parse(local)) > 0) {
        accepted[group.name] = incoming;
      }
    }
    if (accepted.isEmpty) return false;

    final tombstone = localTombstone == null ? null : SyncHlc.parse(localTombstone);
    final resurrects =
        tombstone != null && accepted.values.any((version) => version.compareTo(tombstone) > 0);
    if (tombstone != null && !resurrects) return false;

    final merged = <String, Object?>{};
    if (localRow == null) {
      for (final column in spec.payloadColumns) {
        if (!payload.row.containsKey(column)) {
          throw SyncProtocolException('Incomplete ${spec.name} row for ${payload.key}');
        }
      }
      merged.addAll(payload.row);
    } else {
      merged.addAll(localRow);
      for (final groupName in accepted.keys) {
        final group = spec.fields.firstWhere((field) => field.name == groupName);
        for (final column in group.columns) {
          if (payload.row.containsKey(column)) merged[column] = payload.row[column];
        }
      }
      // The key is part of a membership row's only field; make sure a merge
      // cannot move the row to a different key.
      for (final column in spec.keyColumns) {
        merged[column] = payload.row[column] ?? localRow[column];
      }
      if (resurrects) merged['deleted_at'] = null;
    }

    if (merged.containsKey('updated_at')) {
      merged['updated_at'] = _maxMillis([
        merged['updated_at'],
        for (final version in accepted.values) version.millis,
      ]);
    }

    await _writeRow(spec, payload.key, merged, exists: localRow != null);
    if (accepted.containsKey('image') && (spec.name == 'context' || spec.name == 'project')) {
      final mediaId = merged['image_media_id'];
      await _db.linkRowImagePath(spec.name, payload.key, mediaId is String ? mediaId : null);
    }
    for (final entry in accepted.entries) {
      await _db
          .into(_db.syncFieldVersionRecords)
          .insertOnConflictUpdate(
            SyncFieldVersionRecordsCompanion(
              entity: Value(spec.name),
              rowKey: Value(payload.key),
              field: Value(entry.key),
              version: Value(entry.value.encode()),
              updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(entry.value.millis, isUtc: true)),
            ),
          );
      context.setVersion(spec.name, payload.key, entry.key, entry.value.encode());
    }

    if (resurrects) {
      await (_db.delete(
        _db.syncTombstoneRecords,
      )..where((row) => row.entity.equals(spec.name) & row.rowKey.equals(payload.key))).go();
      context.setTombstone(spec.name, payload.key, null);
    }
    return true;
  }

  /// Records the merged image id as pending when its bytes are not cached yet.
  /// The row sync itself is never failed by a missing image.
  Future<void> _collectMissingMedia(SyncApplyResult result, SyncRowPayload payload) async {
    if (payload.entity != 'context' && payload.entity != 'project') return;
    final spec = _db.syncEntity(payload.entity);
    final row = await _db.readSyncRow(spec, payload.key);
    final mediaId = row?['image_media_id'];
    if (mediaId is! String || !isMediaId(mediaId)) return;
    if (!await _db.hasCachedMedia(mediaId)) result.missingMediaIds.add(mediaId);
  }

  void _validatePayload(SyncEntitySpec spec, SyncRowPayload payload) {
    if (payload.entity.isEmpty) throw const SyncProtocolException('Missing entity');
    for (final column in spec.keyColumns) {
      if (!payload.row.containsKey(column)) {
        throw SyncProtocolException('Missing key column "$column" on ${spec.name}');
      }
    }
    final key = spec.rowKey(payload.row);
    if (key != payload.key) {
      throw SyncProtocolException('Row key does not match its key columns on ${spec.name}');
    }
    if (payload.isDeleted) {
      SyncHlc.parse(payload.deleted!);
    } else if (payload.versions.isEmpty) {
      throw SyncProtocolException('Missing field versions on ${spec.name} ${payload.key}');
    }
    if (!payload.isDeleted && (spec.name == 'context' || spec.name == 'project')) {
      final mediaId = payload.row['image_media_id'];
      if (mediaId != null && (mediaId is! String || !isMediaId(mediaId))) {
        throw SyncProtocolException('Invalid media id on ${spec.name} ${payload.key}');
      }
    }
  }

  Future<void> _writeRow(
    SyncEntitySpec spec,
    String key,
    Map<String, Object?> row, {
    required bool exists,
  }) async {
    final columns = <String>[];
    final values = <Variable>[];
    for (final column in spec.payloadColumns) {
      if (!row.containsKey(column)) continue;
      final generated = spec.columns[column];
      if (generated == null) throw SyncProtocolException('Unknown column "$column" on ${spec.name}');
      columns.add(column);
      values.add(_variable(generated, row[column]));
    }

    final table = spec.table.actualTableName;
    if (exists) {
      final keyValues = spec.keyValues(key);
      final where = <String>[];
      for (var index = 0; index < spec.keyColumns.length; index++) {
        where.add('${spec.keyColumns[index]} = ?');
        final generated = spec.columns[spec.keyColumns[index]];
        if (generated == null) {
          throw SyncProtocolException('Unknown key column on ${spec.name}');
        }
        values.add(_variable(generated, keyValues[index]));
      }
      await _db.customUpdate(
        'UPDATE $table SET ${columns.map((column) => '$column = ?').join(', ')} '
        'WHERE ${where.join(' AND ')}',
        variables: values,
        updates: {spec.table},
      );
    } else {
      final placeholders = List.filled(columns.length, '?').join(', ');
      await _db.customInsert(
        'INSERT INTO $table (${columns.join(', ')}) VALUES ($placeholders)',
        variables: values,
        updates: {spec.table},
      );
    }
  }

  Future<void> _deleteRow(SyncEntitySpec spec, String key) async {
    await (_db.delete(spec.table)..where((_) => spec.keyPredicate(key))).go();
  }

  Variable _variable(GeneratedColumn column, Object? value) {
    final type = column.type;
    if (type is! DriftSqlType) {
      throw SyncProtocolException('Unsupported column type for ${column.$name}');
    }
    if (value == null) {
      return switch (type) {
        DriftSqlType.bool => const Variable<bool>(null),
        DriftSqlType.string => const Variable<String>(null),
        DriftSqlType.bigInt => const Variable<BigInt>(null),
        DriftSqlType.int => const Variable<int>(null),
        DriftSqlType.dateTime => const Variable<DateTime>(null),
        DriftSqlType.blob => const Variable<Uint8List>(null),
        DriftSqlType.double => const Variable<double>(null),
        DriftSqlType.any => const Variable<Object>(null),
      };
    }
    final decoded = decodeValue(column, value);
    return switch (type) {
      DriftSqlType.bool => Variable.withBool(decoded as bool),
      DriftSqlType.string => Variable.withString(decoded as String),
      DriftSqlType.bigInt => Variable.withBigInt(decoded as BigInt),
      DriftSqlType.int => Variable.withInt(decoded as int),
      DriftSqlType.dateTime => Variable.withDateTime(decoded as DateTime),
      DriftSqlType.blob => Variable.withBlob(decoded as Uint8List),
      DriftSqlType.double => Variable.withReal(decoded as double),
      DriftSqlType.any => Variable<Object>(decoded as Object),
    };
  }

  // ---------------------------------------------------------------------------
  // Snapshot helpers

  SyncRowPayload? _snapshotPayload(
    SyncEntitySpec spec,
    String key,
    Map<String, Object?>? live,
    Map<String, String> versions,
    SyncTombstoneRow? tombstone,
  ) {
    var activeTombstone = tombstone;
    if (activeTombstone == null && live != null && live['deleted_at'] != null) {
      // Every delete writes a tombstone. A row without one is a repair case;
      // fall back to its deleted time so it still propagates.
      final deletedMillis = live['deleted_at'] is num ? (live['deleted_at']! as num).toInt() : 0;
      activeTombstone = SyncTombstoneRow(
        entity: spec.name,
        rowKey: key,
        version: SyncHlc(millis: deletedMillis, counter: 0, nodeId: 'repair').encode(),
        rowJson: jsonEncode(live),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(deletedMillis, isUtc: true),
      );
    }

    if (activeTombstone != null && _tombstoneBeatsFields(activeTombstone.version, versions)) {
      final row = _tombstoneRow(spec, key, _decodeRow(activeTombstone.rowJson));
      if (!spec.includes(row)) return null;
      return SyncRowPayload(
        entity: spec.name,
        key: key,
        row: row,
        versions: versions,
        deleted: activeTombstone.version,
      );
    }
    if (live == null) return null;
    if (!spec.includes(live)) return null;
    return SyncRowPayload(entity: spec.name, key: key, row: live, versions: versions);
  }

  bool _tombstoneBeatsFields(String tombstone, Map<String, String> versions) {
    final parsed = SyncHlc.parse(tombstone);
    for (final version in versions.values) {
      if (parsed.compareTo(SyncHlc.parse(version)) <= 0) return false;
    }
    return true;
  }

  Map<String, Object?> _tombstoneRow(SyncEntitySpec spec, String key, Map<String, Object?> row) {
    final result = Map<String, Object?>.of(row);
    final values = spec.keyValues(key);
    for (var index = 0; index < spec.keyColumns.length; index++) {
      result[spec.keyColumns[index]] = values[index];
    }
    return result;
  }

  Map<String, Object?> _decodeRow(String raw) {
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final entry in decoded.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  Future<Map<String, Map<String, String>>> _loadVersions(String entity) async {
    final rows = await (_db.select(
      _db.syncFieldVersionRecords,
    )..where((row) => row.entity.equals(entity))).get();
    final result = <String, Map<String, String>>{};
    for (final row in rows) {
      (result[row.rowKey] ??= <String, String>{})[row.field] = row.version;
    }
    return result;
  }

  Future<Map<String, SyncTombstoneRow>> _loadTombstones(String entity) async {
    final rows = await (_db.select(
      _db.syncTombstoneRecords,
    )..where((row) => row.entity.equals(entity))).get();
    return {for (final row in rows) row.rowKey: row};
  }

  Future<int> _maxChangeSeq() async {
    final row = await _db
        .customSelect('SELECT COALESCE(MAX(seq), 0) AS value FROM sync_change_records')
        .getSingle();
    return row.read<int>('value');
  }

  Future<String> _localDeviceId(String fallback) async {
    final identity = await _db.readIdentity();
    return identity?.deviceId ?? fallback;
  }

  String _encodeCursor(SyncRowPayload row, int since) {
    final spec = _db.syncEntity(row.entity);
    return base64Url.encode(
      utf8.encode(jsonEncode({'rank': spec.rank, 'entity': spec.name, 'key': row.key, 'since': since})),
    );
  }

  _SnapshotPosition _decodeCursor(String cursor) {
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(cursor)));
      if (decoded is! Map) throw const FormatException();
      return _SnapshotPosition(
        rank: (decoded['rank'] as num).toInt(),
        entity: decoded['entity'] as String,
        key: decoded['key'] as String,
        since: (decoded['since'] as num).toInt(),
      );
    } catch (_) {
      throw const SyncProtocolException('Invalid snapshot cursor');
    }
  }

  SyncChange _changePayload(SyncChangeRow row) {
    final versions = _decodeVersions(row.versionsJson);
    return SyncChange(
      changeId: row.changeId,
      originNodeId: row.originNodeId,
      originEpoch: row.originEpoch,
      originSeq: row.originSeq,
      op: row.op,
      payload: SyncRowPayload(
        entity: row.entity,
        key: row.rowKey,
        row: _decodeRow(row.rowJson),
        versions: {
          for (final entry in versions.entries)
            if (entry.key != '__deleted') entry.key: entry.value,
        },
        deleted: versions['__deleted'],
      ),
      createdAt: row.createdAt,
    );
  }

  Map<String, String> _decodeVersions(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final entry in decoded.entries)
        if (entry.value != null) '${entry.key}': '${entry.value}',
    };
  }

  Iterable<SyncHlc> _incomingVersions(SyncRowPayload payload) sync* {
    for (final version in payload.versions.values) {
      final parsed = SyncHlc.tryParse(version);
      if (parsed != null) yield parsed;
    }
    if (payload.deleted != null) {
      final parsed = SyncHlc.tryParse(payload.deleted!);
      if (parsed != null) yield parsed;
    }
  }
}

class _SnapshotPosition {
  const _SnapshotPosition({required this.rank, required this.entity, required this.key, required this.since});

  final int rank;
  final String entity;
  final String key;
  final int since;

  /// True when the row comes after this cursor position.
  bool precedes(int rowRank, String rowEntity, String rowKey) {
    if (rowRank != rank) return rowRank > rank;
    final byEntity = rowEntity.compareTo(entity);
    if (byEntity != 0) return byEntity > 0;
    return rowKey.compareTo(key) > 0;
  }
}

class _ApplyContext {
  _ApplyContext(this._versions, this._tombstones);

  factory _ApplyContext.empty() => _ApplyContext({}, {});

  final Map<String, Map<String, Map<String, String>>> _versions;
  final Map<String, Map<String, String>> _tombstones;

  static Future<_ApplyContext> load(AppDatabase db, Iterable<SyncRowPayload> rows) async {
    final entities = {for (final row in rows) row.entity};
    final versions = <String, Map<String, Map<String, String>>>{};
    final tombstones = <String, Map<String, String>>{};
    for (final entity in entities) {
      final versionRows = await (db.select(
        db.syncFieldVersionRecords,
      )..where((row) => row.entity.equals(entity))).get();
      for (final row in versionRows) {
        ((versions[entity] ??= {})[row.rowKey] ??= {})[row.field] = row.version;
      }
      final tombstoneRows = await (db.select(
        db.syncTombstoneRecords,
      )..where((row) => row.entity.equals(entity))).get();
      tombstones[entity] = {for (final row in tombstoneRows) row.rowKey: row.version};
    }
    return _ApplyContext(versions, tombstones);
  }

  Map<String, String> versionsFor(String entity, String key) =>
      _versions[entity]?[key] ?? const <String, String>{};

  String? tombstoneFor(String entity, String key) => _tombstones[entity]?[key];

  void setVersion(String entity, String key, String field, String version) {
    ((_versions[entity] ??= {})[key] ??= {})[field] = version;
  }

  void setTombstone(String entity, String key, String? version) {
    final rows = _tombstones[entity] ??= {};
    if (version == null) {
      rows.remove(key);
    } else {
      rows[key] = version;
    }
  }
}

int _maxMillis(Iterable<Object?> values) {
  var result = 0;
  for (final value in values) {
    final millis = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    result = math.max(result, millis);
  }
  return result;
}
