part of 'app_database.dart';

/// Synced entities, in dependency order. Upserts apply parent-first and deletes
/// apply child-first.
abstract final class SyncRank {
  static const space = 0;
  static const tag = 1;
  static const context = 2;
  static const project = 3;
  static const habit = 4;
  static const habitCompletion = 5;
  static const shiftPattern = 6;
  static const shiftChild = 7;
  static const shiftChecklistCompletion = 8;
  static const entry = 9;
  static const entryChild = 10;
  static const homeReference = 11;
  static const homeItem = 12;
  static const homeItemLocation = 13;
  static const shoppingItem = 14;
  static const homeLog = 15;
  static const setting = 16;
}

extension SyncDatabase on AppDatabase {
  List<SyncEntitySpec> get syncEntities {
    final cached = _syncEntityCache;
    if (cached != null) return cached;
    final entities = _buildSyncEntities();
    _syncEntityCache = entities;
    _syncEntityByName = {for (final entity in entities) entity.name: entity};
    return entities;
  }

  SyncEntitySpec syncEntity(String name) {
    final found = (_syncEntityByName ??= {for (final entity in syncEntities) entity.name: entity})[name];
    if (found == null) throw ArgumentError.value(name, 'name', 'Unknown sync entity');
    return found;
  }

  List<SyncEntitySpec> _buildSyncEntities() => [
    SyncEntitySpec(
      name: 'space',
      table: spaceRecords,
      keyColumns: const ['id'],
      rank: SyncRank.space,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('appearance', ['color']),
        SyncFieldGroup('placement', ['position']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'tag',
      table: tagRecords,
      keyColumns: const ['id'],
      rank: SyncRank.tag,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('appearance', ['color', 'icon']),
        SyncFieldGroup('placement', ['space_id', 'position']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'context',
      table: contextRecords,
      keyColumns: const ['id'],
      rank: SyncRank.context,
      softDelete: true,
      stripColumns: const {'image_path'},
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('content', ['description']),
        SyncFieldGroup('appearance', ['color', 'icon']),
        SyncFieldGroup('image', ['image_media_id']),
        SyncFieldGroup('placement', ['space_id', 'position']),
      ],
      immutableColumns: const {'image_path', 'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'project',
      table: projectRecords,
      keyColumns: const ['id'],
      rank: SyncRank.project,
      softDelete: true,
      stripColumns: const {'image_path'},
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('content', ['description']),
        SyncFieldGroup('appearance', ['color', 'icon']),
        SyncFieldGroup('image', ['image_media_id']),
        SyncFieldGroup('placement', ['space_id', 'context_id', 'position']),
      ],
      immutableColumns: const {'image_path', 'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'habit',
      table: habitRecords,
      keyColumns: const ['id'],
      rank: SyncRank.habit,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('content', ['description', 'color', 'icon']),
        SyncFieldGroup('schedule', ['target_per_week', 'target_period', 'weekdays']),
        SyncFieldGroup('placement', ['space_id', 'context_id', 'position']),
        SyncFieldGroup('archived', ['archived']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'habitCompletion',
      table: habitCompletionRecords,
      keyColumns: const ['habit_id', 'date_key'],
      rank: SyncRank.habitCompletion,
      softDelete: false,
      fields: const [
        SyncFieldGroup(presentField, ['habit_id', 'date_key']),
        SyncFieldGroup('count', ['check_in_count']),
      ],
      immutableColumns: const {'created_at'},
    ),
    SyncEntitySpec(
      name: 'shiftPattern',
      table: shiftPatternRecords,
      keyColumns: const ['id'],
      rank: SyncRank.shiftPattern,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('placement', ['space_id', 'context_id']),
        SyncFieldGroup('timezone', ['time_zone']),
        SyncFieldGroup('cycle', ['cycle_days', 'anchor_date_key']),
        SyncFieldGroup('sleep', ['commute_minutes', 'wind_down_minutes']),
        SyncFieldGroup('enabled', ['enabled']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'shiftSlot',
      table: shiftSlotRecords,
      keyColumns: const ['sync_id'],
      rank: SyncRank.shiftChild,
      softDelete: false,
      autoIncrementColumn: 'id',
      fields: const [
        SyncFieldGroup('slot', ['pattern_id', 'day_index', 'label', 'start_minute', 'end_minute']),
      ],
    ),
    SyncEntitySpec(
      name: 'shiftException',
      table: shiftExceptionRecords,
      keyColumns: const ['sync_id'],
      rank: SyncRank.shiftChild,
      softDelete: false,
      autoIncrementColumn: 'id',
      fields: const [
        SyncFieldGroup('exception', ['pattern_id', 'date_key', 'type', 'start_minute', 'end_minute', 'note']),
      ],
    ),
    SyncEntitySpec(
      name: 'shiftPatternTag',
      table: shiftPatternTagRecords,
      keyColumns: const ['pattern_id', 'tag_id'],
      rank: SyncRank.shiftChild,
      softDelete: false,
      fields: const [
        SyncFieldGroup(presentField, ['pattern_id', 'tag_id']),
      ],
    ),
    SyncEntitySpec(
      name: 'shiftChecklistItem',
      table: shiftChecklistItemRecords,
      keyColumns: const ['id'],
      rank: SyncRank.shiftChild,
      softDelete: false,
      fields: const [
        SyncFieldGroup('content', ['pattern_id', 'label', 'day_index', 'position']),
      ],
    ),
    SyncEntitySpec(
      name: 'shiftChecklistCompletion',
      table: shiftChecklistCompletionRecords,
      keyColumns: const ['item_id', 'date_key', 'slot_key'],
      rank: SyncRank.shiftChecklistCompletion,
      softDelete: false,
      fields: const [
        SyncFieldGroup(presentField, ['item_id', 'date_key', 'slot_key']),
      ],
      immutableColumns: const {'created_at'},
    ),
    SyncEntitySpec(
      name: 'entry',
      table: entryRecords,
      keyColumns: const ['id'],
      rank: SyncRank.entry,
      softDelete: true,
      fields: const [
        SyncFieldGroup('title', ['title']),
        SyncFieldGroup('notes', ['notes']),
        SyncFieldGroup('classification', ['space_id', 'context_id', 'project_id', 'kind']),
        SyncFieldGroup('presentation', ['priority', 'icon']),
        SyncFieldGroup('timing', [
          'date_key',
          'end_date_key',
          'start_minute',
          'end_minute',
          'time_zone',
          'start_at',
          'end_at',
          'all_day',
        ]),
        SyncFieldGroup('recurrence', ['recurrence_json']),
        SyncFieldGroup('status', ['status', 'completed_at']),
        SyncFieldGroup('maintenance', ['last_completed_at', 'repeat_after_completion_days']),
        SyncFieldGroup('source', ['source', 'external_id', 'read_only']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'reminder',
      table: reminderRecords,
      keyColumns: const ['id'],
      rank: SyncRank.entryChild,
      softDelete: false,
      fields: const [
        SyncFieldGroup('schedule', ['offset_minutes', 'time_minute', 'enabled']),
      ],
      immutableColumns: const {'entry_id'},
    ),
    SyncEntitySpec(
      name: 'completion',
      table: completionRecords,
      keyColumns: const ['entry_id', 'date_key'],
      rank: SyncRank.entryChild,
      softDelete: false,
      fields: const [
        SyncFieldGroup(presentField, ['entry_id', 'date_key']),
      ],
      immutableColumns: const {'created_at'},
    ),
    SyncEntitySpec(
      name: 'entryTag',
      table: entryTagRecords,
      keyColumns: const ['entry_id', 'tag_id'],
      rank: SyncRank.entryChild,
      softDelete: false,
      fields: const [
        SyncFieldGroup(presentField, ['entry_id', 'tag_id']),
      ],
    ),
    SyncEntitySpec(
      name: 'timeEntry',
      table: timeEntryRecords,
      keyColumns: const ['id'],
      rank: SyncRank.entryChild,
      softDelete: false,
      fields: const [
        SyncFieldGroup('session', ['entry_id', 'occurrence_date_key', 'started_at', 'ended_at', 'note']),
      ],
      immutableColumns: const {'created_at'},
    ),
    SyncEntitySpec(
      name: 'homeCategory',
      table: homeCategoryRecords,
      keyColumns: const ['id'],
      rank: SyncRank.homeReference,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('appearance', ['icon', 'color']),
        SyncFieldGroup('position', ['position']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'homeLocation',
      table: homeLocationRecords,
      keyColumns: const ['id'],
      rank: SyncRank.homeReference,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('appearance', ['icon', 'color']),
        SyncFieldGroup('position', ['position']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'homeUnit',
      table: homeUnitRecords,
      keyColumns: const ['id'],
      rank: SyncRank.homeReference,
      softDelete: true,
      fields: const [
        SyncFieldGroup('name', ['name']),
        SyncFieldGroup('unit', ['symbol', 'kind']),
        SyncFieldGroup('position', ['position']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'homeItem',
      table: homeItemRecords,
      keyColumns: const ['id'],
      rank: SyncRank.homeItem,
      softDelete: true,
      fields: const [
        SyncFieldGroup('identity', [
          'context_id',
          'group_id',
          'name',
          'description',
          'icon',
          'color',
          'catalog_id',
        ]),
        SyncFieldGroup('classification', ['category', 'category_id', 'location']),
        SyncFieldGroup('stock', [
          'quantity',
          'min_quantity',
          'reorder_level',
          'unit',
          'unit_id',
          'pack_size',
          'expires_date_key',
        ]),
        SyncFieldGroup('notes', ['notes']),
        SyncFieldGroup('lastPurchasedAt', ['last_purchased_at']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'homeItemLocation',
      table: homeItemLocationRecords,
      keyColumns: const ['home_item_id', 'location_id'],
      rank: SyncRank.homeItemLocation,
      softDelete: false,
      fields: const [
        SyncFieldGroup(presentField, ['home_item_id', 'location_id']),
      ],
    ),
    SyncEntitySpec(
      name: 'shoppingItem',
      table: shoppingItemRecords,
      keyColumns: const ['id'],
      rank: SyncRank.shoppingItem,
      softDelete: true,
      fields: const [
        SyncFieldGroup('content', [
          'name',
          'quantity',
          'unit',
          'pack_size',
          'note',
          'home_item_id',
          'catalog_id',
          'category',
          'category_id',
          'icon',
          'color',
          'context_id',
        ]),
        SyncFieldGroup('checked', ['checked']),
        SyncFieldGroup('position', ['position']),
      ],
      immutableColumns: const {'created_at', 'updated_at', 'deleted_at'},
    ),
    SyncEntitySpec(
      name: 'homePurchase',
      table: homePurchaseRecords,
      keyColumns: const ['id'],
      rank: SyncRank.homeLog,
      softDelete: false,
      fields: const [
        SyncFieldGroup('purchase', ['home_item_id', 'shopping_item_id', 'quantity', 'note', 'purchased_at']),
      ],
    ),
    SyncEntitySpec(
      name: 'maintenanceLog',
      table: maintenanceLogRecords,
      keyColumns: const ['id'],
      rank: SyncRank.homeLog,
      softDelete: false,
      fields: const [
        SyncFieldGroup('service', [
          'entry_id',
          'performed_date_key',
          'next_due_date_key',
          'note',
          'duration_minutes',
        ]),
      ],
      immutableColumns: const {'created_at'},
    ),
    SyncEntitySpec(
      name: 'setting',
      table: settingRecords,
      keyColumns: const ['key'],
      rank: SyncRank.setting,
      softDelete: false,
      fields: const [
        SyncFieldGroup('value', ['value']),
      ],
      includeRow: (row) => row['key'] == 'weekStart',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Membership rows

  /// Adds and removes entry tags without discarding tags another device added.
  /// A null [removedIds] keeps the old replace-all behavior.
  Future<void> saveEntryTags(String entryId, Set<String> tagIds, {Set<String>? removedIds}) async {
    final spec = syncEntity('entryTag');
    final existing = await (select(entryTagRecords)..where((row) => row.entryId.equals(entryId))).get();
    final existingIds = {for (final row in existing) row.tagId};
    final toDelete = [
      for (final row in existing)
        if (!tagIds.contains(row.tagId) && (removedIds == null || removedIds.contains(row.tagId))) row,
    ];
    for (final row in toDelete) {
      final key = spec.rowKey({'entry_id': entryId, 'tag_id': row.tagId});
      final before = spec.serialize(row);
      await (delete(
        entryTagRecords,
      )..where((item) => item.entryId.equals(entryId) & item.tagId.equals(row.tagId))).go();
      await recordSyncDelete(spec, key, lastRow: before);
    }
    for (final tagId in tagIds) {
      if (existingIds.contains(tagId)) continue;
      await into(entryTagRecords).insert(
        EntryTagRecordsCompanion.insert(entryId: entryId, tagId: tagId),
        mode: InsertMode.insertOrIgnore,
      );
      final key = spec.rowKey({'entry_id': entryId, 'tag_id': tagId});
      final after = await readSyncRow(spec, key);
      if (after != null) await recordSyncUpsert(spec, key, after: after);
    }
  }

  // ---------------------------------------------------------------------------
  // Per-row shift children

  Future<void> saveShiftSlots(String patternId, List<ShiftSlot> slots, {Set<String>? previousIds}) async {
    final spec = syncEntity('shiftSlot');
    final existing = await (select(shiftSlotRecords)..where((row) => row.patternId.equals(patternId))).get();
    final bySyncId = {
      for (final row in existing)
        if (row.syncId.isNotEmpty) row.syncId: row,
    };
    final incoming = [
      for (final slot in slots) slot.syncId.isEmpty ? slot.copyWith(syncId: const Uuid().v4()) : slot,
    ];
    final incomingIds = {for (final slot in incoming) slot.syncId};
    if (incomingIds.length != incoming.length) {
      throw ArgumentError('Two shift slots share a sync id');
    }
    final toDelete = [
      for (final row in existing)
        if (!incomingIds.contains(row.syncId) && (previousIds == null || previousIds.contains(row.syncId)))
          row,
    ];

    for (final slot in incoming) {
      final existingRow = bySyncId[slot.syncId];
      final before = existingRow == null ? null : spec.serialize(existingRow);
      if (existingRow == null) {
        await into(shiftSlotRecords).insert(
          ShiftSlotRecordsCompanion.insert(
            syncId: Value(slot.syncId),
            patternId: patternId,
            dayIndex: slot.dayIndex,
            label: Value(slot.label),
            startMinute: slot.startMinute,
            endMinute: slot.endMinute,
          ),
        );
      } else {
        await (update(shiftSlotRecords)..where((row) => row.id.equals(existingRow.id))).write(
          ShiftSlotRecordsCompanion(
            patternId: Value(patternId),
            dayIndex: Value(slot.dayIndex),
            label: Value(slot.label),
            startMinute: Value(slot.startMinute),
            endMinute: Value(slot.endMinute),
          ),
        );
      }
      final after = await readSyncRow(spec, slot.syncId);
      if (after != null) {
        await recordSyncUpsert(spec, slot.syncId, before: before, after: after);
      }
    }

    for (final row in toDelete) {
      final before = spec.serialize(row);
      await (delete(shiftSlotRecords)..where((item) => item.id.equals(row.id))).go();
      await recordSyncDelete(spec, row.syncId, lastRow: before);
    }
  }

  Future<void> saveShiftExceptions(
    String patternId,
    List<ShiftException> exceptions, {
    Set<String>? previousIds,
  }) async {
    final spec = syncEntity('shiftException');
    final existing = await (select(
      shiftExceptionRecords,
    )..where((row) => row.patternId.equals(patternId))).get();
    final bySyncId = {
      for (final row in existing)
        if (row.syncId.isNotEmpty) row.syncId: row,
    };
    final incoming = [
      for (final exception in exceptions)
        exception.syncId.isEmpty ? exception.copyWith(syncId: const Uuid().v4()) : exception,
    ];
    final incomingIds = {for (final exception in incoming) exception.syncId};
    if (incomingIds.length != incoming.length) {
      throw ArgumentError('Two shift exceptions share a sync id');
    }
    final toDelete = [
      for (final row in existing)
        if (!incomingIds.contains(row.syncId) && (previousIds == null || previousIds.contains(row.syncId)))
          row,
    ];

    for (final exception in incoming) {
      final existingRow = bySyncId[exception.syncId];
      final before = existingRow == null ? null : spec.serialize(existingRow);
      if (existingRow == null) {
        await into(shiftExceptionRecords).insert(
          ShiftExceptionRecordsCompanion.insert(
            syncId: Value(exception.syncId),
            patternId: patternId,
            dateKey: exception.date.key,
            type: exception.type.name,
            startMinute: Value(exception.startMinute),
            endMinute: Value(exception.endMinute),
            note: Value(exception.note),
          ),
        );
      } else {
        await (update(shiftExceptionRecords)..where((row) => row.id.equals(existingRow.id))).write(
          ShiftExceptionRecordsCompanion(
            patternId: Value(patternId),
            dateKey: Value(exception.date.key),
            type: Value(exception.type.name),
            startMinute: Value(exception.startMinute),
            endMinute: Value(exception.endMinute),
            note: Value(exception.note),
          ),
        );
      }
      final after = await readSyncRow(spec, exception.syncId);
      if (after != null) {
        await recordSyncUpsert(spec, exception.syncId, before: before, after: after);
      }
    }

    for (final row in toDelete) {
      final before = spec.serialize(row);
      await (delete(shiftExceptionRecords)..where((item) => item.id.equals(row.id))).go();
      await recordSyncDelete(spec, row.syncId, lastRow: before);
    }
  }

  Future<void> saveShiftPatternTags(String patternId, Set<String> tagIds, {Set<String>? previousIds}) async {
    final spec = syncEntity('shiftPatternTag');
    final existing = await (select(
      shiftPatternTagRecords,
    )..where((row) => row.patternId.equals(patternId))).get();
    final existingIds = {for (final row in existing) row.tagId};
    final toDelete = [
      for (final row in existing)
        if (!tagIds.contains(row.tagId) && (previousIds == null || previousIds.contains(row.tagId))) row,
    ];

    for (final tagId in tagIds) {
      if (existingIds.contains(tagId)) continue;
      await into(shiftPatternTagRecords).insert(
        ShiftPatternTagRecordsCompanion.insert(patternId: patternId, tagId: tagId),
        mode: InsertMode.insertOrIgnore,
      );
      final key = spec.rowKey({'pattern_id': patternId, 'tag_id': tagId});
      final after = await readSyncRow(spec, key);
      if (after != null) await recordSyncUpsert(spec, key, after: after);
    }

    for (final row in toDelete) {
      final key = spec.rowKey({'pattern_id': row.patternId, 'tag_id': row.tagId});
      final before = spec.serialize(row);
      await (delete(
        shiftPatternTagRecords,
      )..where((item) => item.patternId.equals(row.patternId) & item.tagId.equals(row.tagId))).go();
      await recordSyncDelete(spec, key, lastRow: before);
    }
  }

  // ---------------------------------------------------------------------------
  // Device state and hybrid logical clock

  Future<Set<String>> _syncTables() async => (await customSelect(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  ).get()).map((row) => row.read<String>('name')).toSet();

  Future<Set<String>> _syncColumns(String table) async =>
      (await customSelect('PRAGMA table_info($table)').get()).map((row) => row.read<String>('name')).toSet();

  /// A partial or hand-made database may lack a table or some of its columns.
  /// Seeding skips such a table instead of failing the whole upgrade.
  Future<bool> _specIsComplete(SyncEntitySpec spec) async {
    final tables = await _syncTables();
    if (!tables.contains(spec.table.actualTableName)) return false;
    final columns = await _syncColumns(spec.table.actualTableName);
    return spec.payloadColumns.every(columns.contains) && spec.keyColumns.every(columns.contains);
  }

  Future<SyncDeviceStateRow> syncDeviceState() async {
    final existing = await (select(
      syncDeviceStateRecords,
    )..where((row) => row.id.equals('local'))).getSingleOrNull();
    if (existing != null) return existing;
    return _createSyncDeviceState();
  }

  Future<SyncDeviceStateRow> _createSyncDeviceState({String? datasetId}) async {
    final now = DateTime.now().toUtc();
    final tables = await _syncTables();
    final legacyDataset = tables.contains('setting_records')
        ? await (select(
            settingRecords,
          )..where((row) => row.key.equals(AppDatabase.syncDatasetSettingKey))).getSingleOrNull()
        : null;
    final state = SyncDeviceStateRecordsCompanion.insert(
      id: 'local',
      nodeId: const Uuid().v4(),
      datasetId:
          datasetId ?? (legacyDataset?.value.isNotEmpty == true ? legacyDataset!.value : const Uuid().v4()),
      epoch: const Uuid().v4(),
      hlcMillis: now.millisecondsSinceEpoch,
      hlcCounter: 0,
      createdAt: now,
      updatedAt: now,
    );
    await into(syncDeviceStateRecords).insert(state, mode: InsertMode.insertOrIgnore);
    final row = await (select(syncDeviceStateRecords)..where((row) => row.id.equals('local'))).getSingle();
    if (legacyDataset != null) {
      await (delete(settingRecords)..where((row) => row.key.equals(AppDatabase.syncDatasetSettingKey))).go();
    }
    return row;
  }

  Future<SyncHlcClock> _syncClock() async {
    final state = await syncDeviceState();
    final cached = _syncHlcClock;
    if (cached != null && cached.nodeId == state.nodeId) return cached;
    final clock = SyncHlcClock(nodeId: state.nodeId, millis: state.hlcMillis, counter: state.hlcCounter);
    _syncHlcClock = clock;
    return clock;
  }

  Future<SyncHlc> _nextSyncVersion() async {
    final clock = await _syncClock();
    final version = clock.next(DateTime.now());
    await _persistSyncClock(clock);
    return version;
  }

  Future<void> _persistSyncClock(SyncHlcClock clock) async {
    await (update(syncDeviceStateRecords)..where((row) => row.id.equals('local'))).write(
      SyncDeviceStateRecordsCompanion(
        hlcMillis: Value(clock.millis),
        hlcCounter: Value(clock.counter),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> observeSyncVersions(Iterable<SyncHlc> versions, {DateTime? now}) async {
    final clock = await _syncClock();
    final moment = now ?? DateTime.now();
    var changed = false;
    for (final version in versions) {
      clock.observe(version, moment);
      changed = true;
    }
    if (changed) await _persistSyncClock(clock);
  }

  // ---------------------------------------------------------------------------
  // Row reads and payloads

  Future<Map<String, Object?>?> readSyncRow(SyncEntitySpec spec, String rowKey) async {
    final query = select(spec.table)..where((_) => spec.keyPredicate(rowKey));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return spec.serialize(row);
  }

  Future<List<Map<String, Object?>>> readSyncRows(SyncEntitySpec spec) async {
    if (!await _specIsComplete(spec)) return const [];
    final rows = await select(spec.table).get();
    final result = <Map<String, Object?>>[];
    for (final row in rows) {
      final serialized = spec.serialize(row);
      if (spec.includes(serialized)) result.add(serialized);
    }
    return result;
  }

  Future<Map<String, Object?>?> readSyncBefore(SyncEntitySpec spec, String rowKey) =>
      readSyncRow(spec, rowKey);

  // ---------------------------------------------------------------------------
  // Local change recording

  Future<void> recordSyncUpsert(
    SyncEntitySpec spec,
    String rowKey, {
    Map<String, Object?>? before,
    required Map<String, Object?> after,
  }) async {
    if (!_syncRecording) return;
    if (spec.fields.isEmpty) return;
    final versions = spec.changedFields(before, after);
    final changed = {
      ...versions,
      if (before != null && before['deleted_at'] != null && after['deleted_at'] == null)
        ...spec.fields.map((field) => field.name),
    };
    if (changed.isEmpty) return;

    final version = await _nextSyncVersion();
    final encoded = version.encode();
    await _writeSyncFieldVersions(spec, rowKey, changed, encoded);
    await _writeSyncChange(spec, rowKey, 'upsert', after, {for (final field in changed) field: encoded});
    await _clearSyncTombstone(spec, rowKey, version);
  }

  Future<void> recordSyncDelete(SyncEntitySpec spec, String rowKey, {Map<String, Object?>? lastRow}) async {
    if (!_syncRecording) return;
    final version = await _nextSyncVersion();
    final encoded = version.encode();
    final row = lastRow ?? const <String, Object?>{};
    await into(syncTombstoneRecords).insertOnConflictUpdate(
      SyncTombstoneRecordsCompanion(
        entity: Value(spec.name),
        rowKey: Value(rowKey),
        version: Value(encoded),
        rowJson: Value(jsonEncode(row)),
        updatedAt: Value(DateTime.fromMillisecondsSinceEpoch(version.millis, isUtc: true)),
      ),
    );
    await _writeSyncChange(spec, rowKey, 'delete', row, {'__deleted': encoded});
  }

  /// Reads the row after a mutation and records an upsert or a hard delete.
  Future<void> recordSyncAfter(SyncEntitySpec spec, String rowKey, {Map<String, Object?>? before}) async {
    if (!_syncRecording) return;
    final after = await readSyncRow(spec, rowKey);
    if (after == null) {
      if (before != null) await recordSyncDelete(spec, rowKey, lastRow: before);
      return;
    }
    await recordSyncUpsert(spec, rowKey, before: before, after: after);
  }

  Future<void> _writeSyncFieldVersions(
    SyncEntitySpec spec,
    String rowKey,
    Iterable<String> fields,
    String encoded,
  ) async {
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(SyncHlc.parse(encoded).millis, isUtc: true);
    await batch((batch) {
      for (final field in fields) {
        batch.insert(
          syncFieldVersionRecords,
          SyncFieldVersionRecordsCompanion.insert(
            entity: spec.name,
            rowKey: rowKey,
            field: field,
            version: encoded,
            updatedAt: updatedAt,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _writeSyncChange(
    SyncEntitySpec spec,
    String rowKey,
    String op,
    Map<String, Object?> row,
    Map<String, String> versions,
  ) async {
    final state = await syncDeviceState();
    final placeholder = const Uuid().v4();
    final seq = await into(syncChangeRecords).insert(
      SyncChangeRecordsCompanion.insert(
        changeId: placeholder,
        originNodeId: state.nodeId,
        originEpoch: state.epoch,
        originSeq: 0,
        entity: spec.name,
        rowKey: rowKey,
        op: op,
        rowJson: jsonEncode(row),
        versionsJson: jsonEncode(versions),
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await (update(syncChangeRecords)..where((row) => row.seq.equals(seq))).write(
      SyncChangeRecordsCompanion(changeId: Value('${state.epoch}:$seq'), originSeq: Value(seq)),
    );
  }

  Future<void> _clearSyncTombstone(SyncEntitySpec spec, String rowKey, SyncHlc version) async {
    final tombstone = await (select(
      syncTombstoneRecords,
    )..where((row) => row.entity.equals(spec.name) & row.rowKey.equals(rowKey))).getSingleOrNull();
    if (tombstone == null) return;
    if (version.compareTo(SyncHlc.parse(tombstone.version)) > 0) {
      await (delete(
        syncTombstoneRecords,
      )..where((row) => row.entity.equals(spec.name) & row.rowKey.equals(rowKey))).go();
    }
  }

  /// Seeds only the entities whose rows may have been inserted by the default
  /// seed. Called at startup; it is a no-op when versions already exist.
  Future<void> seedSyncVersionsForEntities(Iterable<String> names) async {
    final state = await syncDeviceState();
    final base = SyncHlc(millis: state.hlcMillis, counter: 0, nodeId: state.nodeId).encode();
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(state.hlcMillis, isUtc: true);
    for (final name in names) {
      final spec = syncEntity(name);
      final rows = await readSyncRows(spec);
      if (rows.isEmpty) continue;
      await batch((batch) {
        for (final row in rows) {
          final key = spec.rowKey(row);
          for (final field in spec.fields) {
            batch.insert(
              syncFieldVersionRecords,
              SyncFieldVersionRecordsCompanion.insert(
                entity: spec.name,
                rowKey: key,
                field: field.name,
                version: base,
                updatedAt: updatedAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        }
      });
    }
  }

  /// Seeds a base version for every existing row and every merge field. Runs
  /// after the v14 migration, after a fresh default seed, and after a backup
  /// import. Missing versions are not overwritten.
  Future<void> seedSyncFieldVersionsForAll({bool seedTombstones = true}) async {
    final state = await syncDeviceState();
    final base = SyncHlc(millis: state.hlcMillis, counter: 0, nodeId: state.nodeId).encode();
    final tombstoneVersion = SyncHlc(millis: state.hlcMillis, counter: 1, nodeId: state.nodeId).encode();
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(state.hlcMillis, isUtc: true);

    for (final spec in syncEntities) {
      final rows = await readSyncRows(spec);
      if (rows.isEmpty) continue;
      await batch((batch) {
        for (final row in rows) {
          final key = spec.rowKey(row);
          for (final field in spec.fields) {
            batch.insert(
              syncFieldVersionRecords,
              SyncFieldVersionRecordsCompanion.insert(
                entity: spec.name,
                rowKey: key,
                field: field.name,
                version: base,
                updatedAt: updatedAt,
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
          if (seedTombstones && spec.softDelete && row['deleted_at'] != null) {
            batch.insert(
              syncTombstoneRecords,
              SyncTombstoneRecordsCompanion.insert(
                entity: spec.name,
                rowKey: key,
                version: tombstoneVersion,
                rowJson: jsonEncode(row),
                updatedAt: updatedAt,
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        }
      });
    }
  }

  /// Clears all sync bookkeeping. A backup import uses this to stop stale
  /// cursors from skipping restored data. [newDataset] starts a new logical
  /// plan; otherwise the existing dataset id is kept.
  Future<void> resetSyncState({bool newDataset = true}) {
    return transaction(() async {
      final state = await (select(
        syncDeviceStateRecords,
      )..where((row) => row.id.equals('local'))).getSingleOrNull();
      await delete(syncChangeRecords).go();
      await delete(syncFieldVersionRecords).go();
      await delete(syncTombstoneRecords).go();
      await delete(syncPeerStateRecords).go();
      await delete(syncDeviceStateRecords).go();
      _syncHlcClock = null;
      final now = DateTime.now().toUtc();
      await into(syncDeviceStateRecords).insert(
        SyncDeviceStateRecordsCompanion.insert(
          id: 'local',
          nodeId: const Uuid().v4(),
          datasetId: newDataset || state == null ? const Uuid().v4() : state.datasetId,
          epoch: const Uuid().v4(),
          hlcMillis: now.millisecondsSinceEpoch,
          hlcCounter: 0,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }
}
