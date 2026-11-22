import 'dart:convert';
import 'dart:typed_data';

/// A public device description shared with peers. It never contains the shared
/// key, a certificate, a PIN or any other secret.
class SyncKnownDevice {
  const SyncKnownDevice({required this.deviceId, required this.name, required this.certificateFingerprint});

  final String deviceId;
  final String name;
  final String certificateFingerprint;

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'certificateFingerprint': certificateFingerprint,
  };

  factory SyncKnownDevice.fromJson(Map<String, Object?> json) => SyncKnownDevice(
    deviceId: _string(json, 'deviceId'),
    name: _string(json, 'name'),
    certificateFingerprint: _string(json, 'certificateFingerprint'),
  );
}

/// One image returned by `POST /sundial/v1/sync/media`.
class SyncMediaItem {
  const SyncMediaItem({required this.id, required this.mime, required this.byteSize, required this.bytes});

  final String id;
  final String mime;
  final int byteSize;
  final Uint8List bytes;

  Map<String, Object?> toJson() => {
    'id': id,
    'mime': mime,
    'byteSize': byteSize,
    'data': base64Encode(bytes),
  };

  factory SyncMediaItem.fromJson(Map<String, Object?> json) {
    final id = _string(json, 'id');
    final mime = _string(json, 'mime');
    final byteSize = _integer(json, 'byteSize');
    final data = _string(json, 'data');
    final Uint8List bytes;
    try {
      bytes = base64Decode(data);
    } on FormatException {
      throw const SyncProtocolException('Invalid media payload');
    }
    return SyncMediaItem(id: id, mime: mime, byteSize: byteSize, bytes: bytes);
  }
}

/// Response of the content-addressed media endpoint. Ids the peer does not
/// have are reported as missing instead of failing the whole batch.
class SyncMediaResponse {
  const SyncMediaResponse({this.media = const [], this.missing = const []});

  final List<SyncMediaItem> media;
  final List<String> missing;

  Map<String, Object?> toJson() => {
    'media': [for (final item in media) item.toJson()],
    'missing': missing,
  };

  factory SyncMediaResponse.fromJson(Map<String, Object?> json) => SyncMediaResponse(
    media: _list(json['media'], SyncMediaItem.fromJson),
    missing: [
      for (final value in json['missing'] is List ? json['missing'] as List : const [])
        if (value is String) value,
    ],
  );
}

/// One row in a snapshot page or in a delta.
///
/// [row] uses the same JSON-safe values as the field mapping module: dates are
/// epoch milliseconds, blobs are base64 and the rest are primitives. [versions]
/// maps a merge-field name to its encoded HLC. [deleted] carries the tombstone
/// version when the row is deleted.
class SyncRowPayload {
  const SyncRowPayload({
    required this.entity,
    required this.key,
    required this.row,
    this.versions = const {},
    this.deleted,
  });

  final String entity;
  final String key;
  final Map<String, Object?> row;
  final Map<String, String> versions;
  final String? deleted;

  bool get isDeleted => deleted != null;

  Map<String, Object?> toJson() => {
    'entity': entity,
    'key': key,
    'row': row,
    'versions': versions,
    if (deleted != null) 'deleted': deleted,
  };

  factory SyncRowPayload.fromJson(Map<String, Object?> json) => SyncRowPayload(
    entity: _string(json, 'entity'),
    key: _string(json, 'key'),
    row: _map(json['row']),
    versions: _versions(json['versions']),
    deleted: json['deleted'] == null ? null : '${json['deleted']}',
  );
}

/// One entry from the local change feed. The payload is identical to a snapshot
/// row, so the apply path is shared.
class SyncChange {
  const SyncChange({
    required this.changeId,
    required this.originNodeId,
    required this.originEpoch,
    required this.originSeq,
    required this.op,
    required this.payload,
    this.createdAt,
  });

  final String changeId;
  final String originNodeId;
  final String originEpoch;
  final int originSeq;

  /// `upsert` or `delete`.
  final String op;
  final SyncRowPayload payload;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => {
    'changeId': changeId,
    'originNodeId': originNodeId,
    'originEpoch': originEpoch,
    'originSeq': originSeq,
    'op': op,
    ...payload.toJson(),
    if (createdAt != null) 'createdAt': createdAt!.toUtc().millisecondsSinceEpoch,
  };

  factory SyncChange.fromJson(Map<String, Object?> json) => SyncChange(
    changeId: _string(json, 'changeId'),
    originNodeId: _string(json, 'originNodeId'),
    originEpoch: _string(json, 'originEpoch'),
    originSeq: _integer(json, 'originSeq'),
    op: _string(json, 'op'),
    payload: SyncRowPayload.fromJson(json),
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(_integer(json, 'createdAt'), isUtc: true),
  );
}

/// Response of `POST /sundial/v1/sync/snapshot`.
class SyncSnapshotPage {
  const SyncSnapshotPage({
    required this.datasetId,
    required this.epoch,
    required this.nodeId,
    required this.deviceId,
    required this.generatedAt,
    required this.serverHlc,
    required this.nextSince,
    required this.cursor,
    required this.done,
    required this.knownDevices,
    required this.rows,
  });

  final String datasetId;
  final String epoch;
  final String nodeId;
  final String deviceId;
  final DateTime generatedAt;
  final String serverHlc;

  /// Local sequence captured when the snapshot started. Deltas from this point
  /// replay changes that landed while the snapshot was being pulled.
  final int nextSince;

  /// Opaque next-page cursor, or null on the last page.
  final String? cursor;
  final bool done;
  final List<SyncKnownDevice> knownDevices;
  final List<SyncRowPayload> rows;

  Map<String, Object?> toJson() => {
    'datasetId': datasetId,
    'epoch': epoch,
    'nodeId': nodeId,
    'deviceId': deviceId,
    'generatedAt': generatedAt.toUtc().millisecondsSinceEpoch,
    'serverHlc': serverHlc,
    'nextSince': nextSince,
    'cursor': cursor,
    'done': done,
    'knownDevices': [for (final device in knownDevices) device.toJson()],
    'rows': [for (final row in rows) row.toJson()],
  };

  factory SyncSnapshotPage.fromJson(Map<String, Object?> json) => SyncSnapshotPage(
    datasetId: _string(json, 'datasetId'),
    epoch: _string(json, 'epoch'),
    nodeId: _string(json, 'nodeId'),
    deviceId: _string(json, 'deviceId'),
    generatedAt: DateTime.fromMillisecondsSinceEpoch(_integer(json, 'generatedAt'), isUtc: true),
    serverHlc: _string(json, 'serverHlc'),
    nextSince: _integer(json, 'nextSince'),
    cursor: json['cursor'] == null ? null : '${json['cursor']}',
    done: json['done'] == true,
    knownDevices: _list(json['knownDevices'], SyncKnownDevice.fromJson),
    rows: _list(json['rows'], SyncRowPayload.fromJson),
  );
}

/// Response of `POST /sundial/v1/sync/changes`.
class SyncChangesPage {
  const SyncChangesPage({
    required this.datasetId,
    required this.epoch,
    required this.nodeId,
    required this.nextSince,
    required this.hasMore,
    required this.knownDevices,
    required this.changes,
  });

  final String datasetId;
  final String epoch;
  final String nodeId;
  final int nextSince;
  final bool hasMore;
  final List<SyncKnownDevice> knownDevices;
  final List<SyncChange> changes;

  Map<String, Object?> toJson() => {
    'datasetId': datasetId,
    'epoch': epoch,
    'nodeId': nodeId,
    'nextSince': nextSince,
    'hasMore': hasMore,
    'knownDevices': [for (final device in knownDevices) device.toJson()],
    'changes': [for (final change in changes) change.toJson()],
  };

  factory SyncChangesPage.fromJson(Map<String, Object?> json) => SyncChangesPage(
    datasetId: _string(json, 'datasetId'),
    epoch: _string(json, 'epoch'),
    nodeId: _string(json, 'nodeId'),
    nextSince: _integer(json, 'nextSince'),
    hasMore: json['hasMore'] == true,
    knownDevices: _list(json['knownDevices'], SyncKnownDevice.fromJson),
    changes: _list(json['changes'], SyncChange.fromJson),
  );
}

/// A complete peer snapshot held in memory before a source replacement.
/// Nothing is written until the caller has validated the whole stage and the
/// target's backup has succeeded.
class SyncStagedSnapshot {
  const SyncStagedSnapshot({
    required this.datasetId,
    required this.epoch,
    required this.nodeId,
    required this.deviceId,
    required this.serverHlc,
    required this.nextSince,
    required this.knownDevices,
    required this.rows,
  });

  final String datasetId;
  final String epoch;
  final String nodeId;
  final String deviceId;
  final String serverHlc;
  final int nextSince;
  final List<SyncKnownDevice> knownDevices;
  final List<SyncRowPayload> rows;
}

/// Summary of one applied page. [changedEntities] drives batched side effects
/// such as the reminder queue and the home widget. [missingMediaIds] holds
/// images accepted by a merge but not yet present in the local cache.
class SyncApplyResult {
  SyncApplyResult({
    this.applied = 0,
    this.skipped = 0,
    this.deleted = 0,
    Set<String>? changedEntities,
    Set<String>? missingMediaIds,
  }) : changedEntities = changedEntities ?? <String>{},
       missingMediaIds = missingMediaIds ?? <String>{};

  int applied;
  int skipped;
  int deleted;
  final Set<String> changedEntities;
  final Set<String> missingMediaIds;

  void merge(SyncApplyResult other) {
    applied += other.applied;
    skipped += other.skipped;
    deleted += other.deleted;
    changedEntities.addAll(other.changedEntities);
    missingMediaIds.addAll(other.missingMediaIds);
  }

  @override
  String toString() => 'SyncApplyResult(applied: $applied, skipped: $skipped, deleted: $deleted)';
}

/// The local plan and the peer plan are not the same dataset, so the caller has
/// to show a source choice. Nothing was written.
class SyncDatasetMismatchException implements Exception {
  const SyncDatasetMismatchException({required this.localDatasetId, required this.remoteDatasetId});

  final String localDatasetId;
  final String remoteDatasetId;

  @override
  String toString() => 'SyncDatasetMismatchException(local: $localDatasetId, remote: $remoteDatasetId)';
}

/// A peer restarted its local change log (replacement, restore or reset). The
/// stored cursor is stale and the caller has to start a fresh snapshot.
class SyncEpochChangedException implements Exception {
  const SyncEpochChangedException({required this.peerDeviceId, required this.peerEpoch});

  final String peerDeviceId;
  final String peerEpoch;

  @override
  String toString() => 'SyncEpochChangedException($peerDeviceId, $peerEpoch)';
}

/// A page was malformed or named an entity this build does not know. The page
/// is rejected as a whole.
class SyncProtocolException implements Exception {
  const SyncProtocolException(this.message);

  final String message;

  @override
  String toString() => 'SyncProtocolException: $message';
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw SyncProtocolException('Missing string field "$key"');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is num) return value.toInt();
  throw SyncProtocolException('Missing integer field "$key"');
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw SyncProtocolException('Expected a JSON object');
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

Map<String, String> _versions(Object? value) {
  if (value == null) return const {};
  final map = _map(value);
  return {
    for (final entry in map.entries)
      if (entry.value != null) entry.key: '${entry.value}',
  };
}

List<T> _list<T>(Object? value, T Function(Map<String, Object?> json) decode) {
  if (value == null) return const [];
  if (value is! List) throw SyncProtocolException('Expected a JSON array');
  return [
    for (final item in value)
      if (item is Map)
        decode({
          for (final entry in item.entries)
            if (entry.key is String) entry.key as String: entry.value,
        })
      else
        throw SyncProtocolException('Expected a JSON object in an array'),
  ];
}

/// Encodes a value for a protocol payload. Kept here so callers do not import
/// `dart:convert` just to build a response.
String encodeSyncJson(Object? value) => jsonEncode(value);
