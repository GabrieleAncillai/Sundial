import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/home_reference_defaults.dart';
import '../features/media/media_store.dart';
import '../features/sync/sync_clock.dart';
import '../features/sync/sync_field_groups.dart';
import '../models/home_item.dart';
import '../models/home_purchase.dart';
import '../models/home_reference.dart';
import '../models/local_identity.dart';
import '../models/maintenance_log.dart';
import '../models/paired_device.dart';
import '../models/remote_snapshot.dart';
import '../models/reminder.dart';
import '../models/search_results.dart';
import '../models/shift_checklist.dart';
import '../models/shopping_item.dart';
import '../models/time_entry.dart';

part 'app_database.g.dart';
part 'app_database_sync.dart';

@DataClassName('SpaceRow')
class SpaceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ContextRow')
class ContextRecords extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().references(SpaceRecords, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get color => integer()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  TextColumn get imagePath => text().nullable()();
  TextColumn get imageMediaId => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ProjectRow')
class ProjectRecords extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().references(SpaceRecords, #id)();
  TextColumn get contextId => text().nullable().references(ContextRecords, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get color => integer()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  TextColumn get imagePath => text().nullable()();
  TextColumn get imageMediaId => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitRow')
class HabitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().references(SpaceRecords, #id)();
  TextColumn get contextId => text().nullable().references(ContextRecords, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get color => integer()();
  TextColumn get icon => text().withDefault(const Constant('star'))();
  IntColumn get targetPerWeek => integer().withDefault(const Constant(7))();

  /// Scheduled weekdays, 1 = Monday through 7 = Sunday, comma separated.
  TextColumn get weekdays => text().withDefault(const Constant('1,2,3,4,5,6,7'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HabitCompletionRow')
class HabitCompletionRecords extends Table {
  TextColumn get habitId => text().references(HabitRecords, #id)();
  IntColumn get dateKey => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {habitId, dateKey};
}

/// A clock-in/clock-out session against an entry occurrence.
@DataClassName('TimeEntryRow')
class TimeEntryRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(EntryRecords, #id)();

  /// Occurrence date in the entry's stored timezone. Null for one-off tasks.
  IntColumn get occurrenceDateKey => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TagRow')
class TagRecords extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().nullable().references(SpaceRecords, #id)();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntryTagRow')
class EntryTagRecords extends Table {
  TextColumn get entryId => text().references(EntryRecords, #id)();
  TextColumn get tagId => text().references(TagRecords, #id)();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}

@DataClassName('ShiftChecklistItemRow')
class ShiftChecklistItemRecords extends Table {
  TextColumn get id => text()();
  TextColumn get patternId => text().references(ShiftPatternRecords, #id)();
  TextColumn get label => text()();

  /// Cycle day this checklist item belongs to. Null applies to every day of
  /// the pattern.
  IntColumn get dayIndex => integer().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShiftChecklistCompletionRow')
class ShiftChecklistCompletionRecords extends Table {
  TextColumn get itemId => text().references(ShiftChecklistItemRecords, #id)();
  IntColumn get dateKey => integer()();

  /// Identity of the shift slot inside the pattern. An empty value is the
  /// legacy single-slot key and is backfilled during the v5 to v6 migration.
  TextColumn get slotKey => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, dateKey, slotKey};
}

@DataClassName('HomeCategoryRow')
class HomeCategoryRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  IntColumn get color => integer()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HomeLocationRow')
class HomeLocationRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('place'))();
  IntColumn get color => integer()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HomeUnitRow')
class HomeUnitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get symbol => text().withDefault(const Constant(''))();

  /// One of [HomeUnitKind], stored as text.
  TextColumn get kind => text().withDefault(const Constant('count'))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HomeItemRow')
class HomeItemRecords extends Table {
  TextColumn get id => text()();

  /// Home this inventory item belongs to.
  TextColumn get contextId => text().nullable().references(ContextRecords, #id)();

  /// Product identity shared by every size/variant of the same product.
  TextColumn get groupId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant('inventory'))();
  IntColumn get color => integer().nullable()();
  TextColumn get catalogId => text().nullable()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable().references(HomeCategoryRecords, #id)();
  TextColumn get location => text().withDefault(const Constant(''))();
  RealColumn get quantity => real().withDefault(const Constant(0))();

  /// Minimum stock at or below which the item is low. Null means no alert.
  RealColumn get minQuantity => real().nullable()();

  /// Legacy reorder threshold kept for older backups and CSV imports.
  RealColumn get reorderLevel => real().nullable()();
  TextColumn get unit => text().withDefault(const Constant(''))();
  TextColumn get unitId => text().nullable().references(HomeUnitRecords, #id)();
  TextColumn get packSize => text().withDefault(const Constant(''))();

  /// Date-only expiry, stored as `YYYYMMDD`.
  IntColumn get expiresDateKey => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get lastPurchasedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('HomeItemLocationRow')
class HomeItemLocationRecords extends Table {
  TextColumn get homeItemId => text().references(HomeItemRecords, #id)();
  TextColumn get locationId => text().references(HomeLocationRecords, #id)();

  @override
  Set<Column<Object>> get primaryKey => {homeItemId, locationId};
}

@DataClassName('ShoppingItemRow')
class ShoppingItemRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant(''))();
  TextColumn get packSize => text().withDefault(const Constant(''))();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get homeItemId => text().nullable().references(HomeItemRecords, #id)();
  TextColumn get catalogId => text().nullable()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable().references(HomeCategoryRecords, #id)();
  TextColumn get icon => text().withDefault(const Constant('shopping_basket'))();
  IntColumn get color => integer().nullable()();

  /// Home this shopping line belongs to.
  TextColumn get contextId => text().nullable().references(ContextRecords, #id)();

  /// Manual order inside the list. Lower values come first.
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Stock that entered the household inventory, from a shopping line or a
/// manual quantity adjustment. Kept deliberately small.
@DataClassName('HomePurchaseRow')
class HomePurchaseRecords extends Table {
  TextColumn get id => text()();
  TextColumn get homeItemId => text().references(HomeItemRecords, #id)();
  TextColumn get shoppingItemId => text().nullable().references(ShoppingItemRecords, #id)();
  RealColumn get quantity => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get purchasedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One completed service for a home gadget.
@DataClassName('MaintenanceLogRow')
class MaintenanceLogRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(EntryRecords, #id)();
  IntColumn get performedDateKey => integer()();
  IntColumn get nextDueDateKey => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get durationMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// This device's pairing identity. One row, id = 1.
@DataClassName('IdentityRow')
class IdentityRecords extends Table {
  IntColumn get id => integer()();
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  TextColumn get username => text()();
  TextColumn get pinSalt => text()();
  TextColumn get pinHash => text()();
  TextColumn get certificatePem => text()();
  TextColumn get privateKeyPem => text()();
  TextColumn get mcpToken => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Devices paired with this one. Excluded from JSON backups on purpose.
@DataClassName('PairedDeviceRow')
class PairedDeviceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get username => text()();
  TextColumn get certificateFingerprint => text()();
  TextColumn get sharedKey => text()();
  TextColumn get host => text().withDefault(const Constant(''))();
  IntColumn get port => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSeenAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EntryRow')
class EntryRecords extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().references(SpaceRecords, #id)();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// One of [EntryKind]. Stored as text so the database stays readable.
  TextColumn get kind => text()();

  /// Anchor date as `YYYYMMDD`, in [timeZone] for timed entries.
  IntColumn get dateKey => integer().nullable()();

  /// End date for multi-day all-day entries.
  IntColumn get endDateKey => integer().nullable()();

  /// Local minutes from midnight, null for all-day entries. An end of 1440 or
  /// more means the entry crosses midnight.
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();

  /// IANA timezone for the wall-clock fields, null for all-day entries.
  TextColumn get timeZone => text().nullable()();

  /// Job, home or person/group inside [spaceId].
  TextColumn get contextId => text().nullable().references(ContextRecords, #id)();
  TextColumn get projectId => text().nullable().references(ProjectRecords, #id)();

  /// Optional icon name for home gadgets.
  TextColumn get icon => text().withDefault(const Constant(''))();

  /// One of [EntryPriority].
  TextColumn get priority => text().withDefault(const Constant('none'))();

  /// Resolved anchor instants in UTC, null for all-day entries.
  DateTimeColumn get startAt => dateTime().nullable()();
  DateTimeColumn get endAt => dateTime().nullable()();

  BoolColumn get allDay => boolean().withDefault(const Constant(false))();

  /// One of [EntryStatus].
  TextColumn get status => text()();

  /// Serialized [RecurrenceRule], null for one-off entries.
  TextColumn get recurrenceJson => text().nullable()();

  /// Import source such as `ics`, null for user entries.
  TextColumn get source => text().nullable()();
  TextColumn get externalId => text().nullable()();
  BoolColumn get readOnly => boolean().withDefault(const Constant(false))();

  DateTimeColumn get lastCompletedAt => dateTime().nullable()();
  IntColumn get repeatAfterCompletionDays => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ReminderRow')
class ReminderRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(EntryRecords, #id)();
  IntColumn get offsetMinutes => integer()();

  /// A local time of day instead of an offset. Null uses [offsetMinutes].
  IntColumn get timeMinute => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShiftPatternRow')
class ShiftPatternRecords extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().references(SpaceRecords, #id)();
  TextColumn get name => text()();

  /// Job this shift pattern belongs to.
  TextColumn get contextId => text().nullable().references(ContextRecords, #id)();

  /// IANA timezone the slot times are defined in.
  TextColumn get timeZone => text().withDefault(const Constant('UTC'))();

  IntColumn get cycleDays => integer()();
  IntColumn get anchorDateKey => integer()();

  /// Per-pattern sleep overrides in minutes. Null uses the global buffer.
  IntColumn get commuteMinutes => integer().nullable()();
  IntColumn get windDownMinutes => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ShiftSlotRow')
class ShiftSlotRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable identity across devices. The local [id] stays device-local.
  TextColumn get syncId => text().withDefault(const Constant(''))();
  TextColumn get patternId => text().references(ShiftPatternRecords, #id)();
  IntColumn get dayIndex => integer()();
  TextColumn get label => text().withDefault(const Constant(''))();
  IntColumn get startMinute => integer()();
  IntColumn get endMinute => integer()();
}

@DataClassName('ShiftPatternTagRow')
class ShiftPatternTagRecords extends Table {
  TextColumn get patternId => text().references(ShiftPatternRecords, #id)();
  TextColumn get tagId => text().references(TagRecords, #id)();

  @override
  Set<Column<Object>> get primaryKey => {patternId, tagId};
}

@DataClassName('ShiftExceptionRow')
class ShiftExceptionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable identity across devices. The local [id] stays device-local.
  TextColumn get syncId => text().withDefault(const Constant(''))();
  TextColumn get patternId => text().references(ShiftPatternRecords, #id)();
  IntColumn get dateKey => integer()();

  /// One of [ShiftExceptionType].
  TextColumn get type => text()();
  IntColumn get startMinute => integer().nullable()();
  IntColumn get endMinute => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// Read-only snapshots from paired devices. Display data only; never merged.
@DataClassName('RemoteSnapshotRow')
class RemoteSnapshotRecords extends Table {
  TextColumn get deviceId => text()();
  TextColumn get deviceName => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {deviceId};
}

@DataClassName('CompletionRow')
class CompletionRecords extends Table {
  TextColumn get entryId => text().references(EntryRecords, #id)();
  IntColumn get dateKey => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entryId, dateKey};
}

@DataClassName('SettingRow')
class SettingRecords extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Device-local index of content-addressed images. It is not a synced entity
/// and never appears in a backup; every device rebuilds it from its own cache.
@DataClassName('MediaCacheRow')
class MediaCacheRecords extends Table {
  /// Lowercase SHA-256 hex of the PNG bytes.
  TextColumn get mediaId => text()();
  TextColumn get path => text()();
  TextColumn get mime => text()();
  IntColumn get byteSize => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {mediaId};
}

/// One row for this device's sync identity and clock. The dataset id is the
/// logical plan shared by paired devices; the node id and epoch are local.
@DataClassName('SyncDeviceStateRow')
class SyncDeviceStateRecords extends Table {
  TextColumn get id => text()();
  TextColumn get nodeId => text()();
  TextColumn get datasetId => text()();
  TextColumn get epoch => text()();
  IntColumn get hlcMillis => integer()();
  IntColumn get hlcCounter => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Append-only feed of local edits. Remote applies never append here, which is
/// what prevents echo loops between paired devices.
@DataClassName('SyncChangeRow')
class SyncChangeRecords extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get changeId => text().unique()();
  TextColumn get originNodeId => text()();
  TextColumn get originEpoch => text()();
  IntColumn get originSeq => integer()();
  TextColumn get entity => text()();
  TextColumn get rowKey => text()();

  /// `upsert` or `delete`.
  TextColumn get op => text()();
  TextColumn get rowJson => text()();
  TextColumn get versionsJson => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('SyncFieldVersionRow')
class SyncFieldVersionRecords extends Table {
  TextColumn get entity => text()();
  TextColumn get rowKey => text()();
  TextColumn get field => text()();
  TextColumn get version => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entity, rowKey, field};
}

@DataClassName('SyncTombstoneRow')
class SyncTombstoneRecords extends Table {
  TextColumn get entity => text()();
  TextColumn get rowKey => text()();
  TextColumn get version => text()();
  TextColumn get rowJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entity, rowKey};
}

@DataClassName('SyncPeerStateRow')
class SyncPeerStateRecords extends Table {
  TextColumn get peerDeviceId => text()();
  TextColumn get datasetId => text()();
  TextColumn get peerEpoch => text()();
  IntColumn get lastPulledSeq => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {peerDeviceId};
}

@DriftDatabase(
  tables: [
    SpaceRecords,
    ContextRecords,
    ProjectRecords,
    HabitRecords,
    HabitCompletionRecords,
    TimeEntryRecords,
    EntryRecords,
    TagRecords,
    EntryTagRecords,
    CompletionRecords,
    ReminderRecords,
    ShiftPatternRecords,
    ShiftSlotRecords,
    ShiftPatternTagRecords,
    ShiftExceptionRecords,
    ShiftChecklistItemRecords,
    ShiftChecklistCompletionRecords,
    HomeCategoryRecords,
    HomeLocationRecords,
    HomeUnitRecords,
    HomeItemRecords,
    HomeItemLocationRecords,
    ShoppingItemRecords,
    IdentityRecords,
    PairedDeviceRecords,
    SettingRecords,
    MediaCacheRecords,
    HomePurchaseRecords,
    MaintenanceLogRecords,
    RemoteSnapshotRecords,
    SyncDeviceStateRecords,
    SyncChangeRecords,
    SyncFieldVersionRecords,
    SyncTombstoneRecords,
    SyncPeerStateRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e, {this.defaultTimeZone = 'UTC', MediaStore? mediaStore})
    : mediaStore = mediaStore ?? MediaStore();

  AppDatabase.open({this.defaultTimeZone = 'UTC', MediaStore? mediaStore})
    : mediaStore = mediaStore ?? MediaStore(),
      super(_openConnection());

  /// Used to interpret legacy wall-clock rows during the v1 to v2 migration.
  final String defaultTimeZone;

  /// Device-local content-addressed image cache. Injected in tests so every
  /// database instance uses its own temp directory.
  final MediaStore mediaStore;

  SyncHlcClock? _syncHlcClock;
  int _syncRecordingSuppression = 0;
  List<SyncEntitySpec>? _syncEntityCache;
  Map<String, SyncEntitySpec>? _syncEntityByName;

  bool get _syncRecording => _syncRecordingSuppression == 0;

  /// Drops the in-memory HLC after the sync tables were replaced.
  void resetSyncClockCache() => _syncHlcClock = null;

  /// Runs a seed or import without writing sync changes.
  Future<T> withoutSyncRecording<T>(Future<T> Function() action) async {
    _syncRecordingSuppression++;
    try {
      return await action();
    } finally {
      _syncRecordingSuppression--;
    }
  }

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _ensureShiftSyncIndexes();
    },
    onUpgrade: (m, from, to) async {
      // Row mappers used by older migrations expect every current column, so
      // the v14 shift sync ids must exist before the v6 slot backfill reads
      // them. The v14 step still creates the sync tables and backfills values.
      if (from < 14) await _addV14ColumnsEarly(m);
      // The v2 backfill reads entries with the current mapper, so all current
      // columns have to exist before it runs. The late v12 call below restores
      // this column if a v10 table rebuild drops it.
      if (from < 12) await _migrateToV12(m);
      // The v2 backfill reads entries with the current mapper, so all current
      // columns have to exist before it runs.
      if (from < 9) await _migrateToV9(m);
      // Add the v4 entry columns first so the v1/v2 backfill can read rows with
      // the current generated entry mapper.
      if (from < 4) await _addV4EntryColumns(m);
      if (from < 2) await _migrateToV2(m);
      if (from < 3) await _migrateToV3(m);
      if (from < 4) await _migrateToV4(m);
      if (from < 5) await _migrateToV5(m);
      if (from < 6) await _migrateToV6(m);
      if (from < 7) await _migrateToV7(m);
      if (from < 8) await _migrateToV8(m);
      if (from < 9) await _migrateToV9(m);
      // A v1.2 build already reported v10 while leaving the draft columns and
      // gadgets behind, so the repair must also run for v10 and v11 files.
      if (from < 12) await _migrateToV10(m);
      if (from < 11) await _migrateToV11(m);
      if (from < 12) await _migrateToV12(m);
      if (from < 13) await _migrateToV13(m);
      if (from < 14) await _migrateToV14(m);
      if (from < 15) await _migrateToV15(m);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Personal, Work and Home exist on first launch. No sample life data is
  /// inserted. Missing defaults are added individually so a partially seeded
  /// database still ends up complete.
  Future<void> seedDefaults() async {
    final existing = await select(spaceRecords).get();
    final ids = existing.map((row) => row.id).toSet();
    final missing = _defaultSpaces.where((space) => !ids.contains(space.id)).toList();
    final now = DateTime.now();
    if (missing.isNotEmpty) {
      await batch((batch) {
        batch.insertAll(spaceRecords, [
          for (final space in missing)
            SpaceRecordsCompanion.insert(
              id: space.id,
              name: space.name,
              color: space.colorValue,
              position: Value(space.position),
              createdAt: now,
              updatedAt: now,
            ),
        ]);
      });
    }

    final tags = await select(tagRecords).get();
    final seeded = await (select(
      settingRecords,
    )..where((row) => row.key.equals('defaultCategoriesSeeded'))).getSingleOrNull();
    if (tags.isEmpty && seeded == null) {
      await batch((batch) {
        batch.insertAll(tagRecords, [
          for (final category in _defaultCategories)
            TagRecordsCompanion.insert(
              id: category.id,
              name: category.name,
              color: category.colorValue,
              icon: Value(category.icon),
              position: Value(category.position),
              createdAt: now,
              updatedAt: now,
            ),
        ]);
        batch.insert(
          settingRecords,
          SettingRecordsCompanion.insert(key: 'defaultCategoriesSeeded', value: 'true'),
        );
      });
    }

    await _seedHomeReferenceDefaults();
    await seedSyncVersionsForEntities(const ['space', 'tag', 'homeCategory', 'homeLocation', 'homeUnit']);
  }

  Stream<List<Space>> watchSpaces() {
    final query = select(spaceRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().map((rows) {
      final spaces = rows.map(_spaceFromRow).toList()..sort((a, b) => a.position.compareTo(b.position));
      return spaces;
    });
  }

  Stream<List<PlannerContext>> watchContexts({String? spaceId}) {
    final query = select(contextRecords)..where((row) => row.deletedAt.isNull());
    if (spaceId != null) query.where((row) => row.spaceId.equals(spaceId));
    return query.watch().map((rows) {
      final contexts = rows.map(_contextFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          if (byPosition != 0) return byPosition;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return contexts;
    });
  }

  Future<void> saveContext(PlannerContext context) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('context');
      final existing = await (select(
        contextRecords,
      )..where((row) => row.id.equals(context.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      final imageMediaId = await _cacheImagePath(context.imagePath);
      await into(contextRecords).insertOnConflictUpdate(
        ContextRecordsCompanion(
          id: Value(context.id),
          spaceId: Value(context.spaceId),
          name: Value(context.name),
          description: Value(context.description),
          color: Value(context.colorValue),
          icon: Value(context.icon),
          imagePath: Value(context.imagePath),
          imageMediaId: Value(imageMediaId),
          position: Value(context.position),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
          deletedAt: Value(context.deletedAt),
        ),
      );
      await recordSyncAfter(spec, context.id, before: before);
    });
  }

  Future<void> softDeleteContext(String id) {
    return transaction(() async {
      final now = DateTime.now();
      final contextSpec = syncEntity('context');
      final projectSpec = syncEntity('project');
      final entrySpec = syncEntity('entry');
      final shiftSpec = syncEntity('shiftPattern');
      final habitSpec = syncEntity('habit');
      final homeSpec = syncEntity('homeItem');
      final shoppingSpec = syncEntity('shoppingItem');

      final contextBefore = await readSyncRow(contextSpec, id);
      final projects = await (select(projectRecords)..where((row) => row.contextId.equals(id))).get();
      final projectIds = {for (final project in projects) project.id};
      final patterns = await (select(shiftPatternRecords)..where((row) => row.contextId.equals(id))).get();
      final habits = await (select(habitRecords)..where((row) => row.contextId.equals(id))).get();
      final homeItems = await (select(homeItemRecords)..where((row) => row.contextId.equals(id))).get();
      final shopping = await (select(shoppingItemRecords)..where((row) => row.contextId.equals(id))).get();
      final contextEntries = await (select(
        entryRecords,
      )..where((row) => row.contextId.equals(id) & row.readOnly.equals(false))).get();
      final projectEntries = projectIds.isEmpty
          ? const <EntryRow>[]
          : await (select(
              entryRecords,
            )..where((row) => row.projectId.isIn(projectIds) & row.readOnly.equals(false))).get();
      final entryBefores = <String, Map<String, Object?>>{};
      for (final row in [...contextEntries, ...projectEntries]) {
        entryBefores[row.id] = entrySpec.serialize(row);
      }

      // Tasks survive with their space; only the grouping is removed.
      await (update(entryRecords)..where((row) => row.contextId.equals(id) & row.readOnly.equals(false)))
          .write(EntryRecordsCompanion(contextId: Value(null), updatedAt: Value(now)));
      if (projectIds.isNotEmpty) {
        await (update(entryRecords)
              ..where((row) => row.projectId.isIn(projectIds) & row.readOnly.equals(false)))
            .write(EntryRecordsCompanion(projectId: Value(null), updatedAt: Value(now)));
        await (update(projectRecords)..where((row) => row.id.isIn(projectIds))).write(
          ProjectRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
      }

      await (update(shiftPatternRecords)..where((row) => row.contextId.equals(id))).write(
        ShiftPatternRecordsCompanion(contextId: Value(null), deletedAt: Value(now), updatedAt: Value(now)),
      );
      await (update(habitRecords)..where((row) => row.contextId.equals(id))).write(
        HabitRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await (update(homeItemRecords)..where((row) => row.contextId.equals(id))).write(
        HomeItemRecordsCompanion(contextId: Value(null), updatedAt: Value(now)),
      );
      await (update(shoppingItemRecords)..where((row) => row.contextId.equals(id))).write(
        ShoppingItemRecordsCompanion(contextId: Value(null), updatedAt: Value(now)),
      );
      await (update(contextRecords)..where((row) => row.id.equals(id))).write(
        ContextRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

      for (final entry in entryBefores.entries) {
        await recordSyncAfter(entrySpec, entry.key, before: entry.value);
      }
      for (final row in projects) {
        await recordSyncDelete(projectSpec, row.id, lastRow: projectSpec.serialize(row));
      }
      for (final row in patterns) {
        await recordSyncDelete(shiftSpec, row.id, lastRow: shiftSpec.serialize(row));
      }
      for (final row in habits) {
        await recordSyncDelete(habitSpec, row.id, lastRow: habitSpec.serialize(row));
      }
      for (final row in homeItems) {
        await recordSyncAfter(homeSpec, row.id, before: homeSpec.serialize(row));
      }
      for (final row in shopping) {
        await recordSyncAfter(shoppingSpec, row.id, before: shoppingSpec.serialize(row));
      }
      await recordSyncDelete(contextSpec, id, lastRow: contextBefore);
    });
  }

  // ---------------------------------------------------------------------------
  // Content-addressed media

  /// Reads a local display file, validates it and ensures its cache entry. A
  /// missing or unreadable image leaves the row saved without a media id; it
  /// never fails the save.
  Future<String?> _cacheImagePath(String? path) async {
    if (path == null || path.trim().isEmpty) return null;
    try {
      final entry = await mediaStore.cacheFromFile(path);
      if (entry == null) return null;
      await _recordMediaCache(entry);
      return entry.id;
    } on MediaTooLargeException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<void> _recordMediaCache(MediaCacheEntry entry, {DateTime? now}) async {
    await into(mediaCacheRecords).insertOnConflictUpdate(
      MediaCacheRecordsCompanion(
        mediaId: Value(entry.id),
        path: Value(entry.path),
        mime: Value(entry.mime),
        byteSize: Value(entry.byteSize),
        createdAt: Value(now ?? DateTime.now().toUtc()),
      ),
    );
  }

  /// True when the row's media index entry exists and its cache file verifies.
  Future<bool> hasCachedMedia(String mediaId) async {
    if (!isMediaId(mediaId)) return false;
    final row = await (select(
      mediaCacheRecords,
    )..where((entry) => entry.mediaId.equals(mediaId))).getSingleOrNull();
    if (row == null) return false;
    final file = File(await mediaStore.cachePath(mediaId));
    if (!await file.exists()) return false;
    try {
      return MediaStore.hashBytes(await file.readAsBytes()) == mediaId;
    } on FileSystemException {
      return false;
    }
  }

  /// Reads and verifies a cached image for the LAN media endpoint. Null means
  /// the id is unknown or its file is gone; an oversized file is reported so
  /// the endpoint can answer with a clear error instead of truncating.
  Future<MediaBlob?> readMedia(String mediaId) async {
    if (!isMediaId(mediaId)) return null;
    final row = await (select(
      mediaCacheRecords,
    )..where((entry) => entry.mediaId.equals(mediaId))).getSingleOrNull();
    if (row == null || row.mime != MediaStore.mime) return null;
    // Serve only the content-addressed cache path for this id. The indexed path
    // is bookkeeping, never an arbitrary file the peer can name.
    final file = File(await mediaStore.cachePath(mediaId));
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length > MediaStore.maxBytes) throw MediaTooLargeException(length);
    final bytes = await file.readAsBytes();
    if (MediaStore.hashBytes(bytes) != mediaId) return null;
    return MediaBlob(id: mediaId, mime: row.mime, bytes: bytes);
  }

  /// Stores an image received from a peer after verifying its content address.
  Future<bool> installMedia(String mediaId, Uint8List bytes) async {
    final entry = await mediaStore.storeVerified(mediaId, bytes);
    if (entry == null) return false;
    await _recordMediaCache(entry);
    return true;
  }

  /// Image ids referenced by live rows but absent from the local cache. A pull
  /// retries these on every pass, so a temporarily offline peer cannot strand
  /// an image.
  Future<Set<String>> pendingMediaIds() async {
    final referenced = <String>{};
    for (final table in <TableInfo>[contextRecords, projectRecords]) {
      final rows = await customSelect(
        'SELECT DISTINCT image_media_id AS id FROM ${table.actualTableName} '
        'WHERE image_media_id IS NOT NULL AND deleted_at IS NULL',
      ).get();
      for (final row in rows) {
        final id = row.readNullable<String>('id');
        if (id != null && isMediaId(id)) referenced.add(id);
      }
    }
    final pending = <String>{};
    for (final id in referenced) {
      if (!await hasCachedMedia(id)) pending.add(id);
    }
    return pending;
  }

  /// Sets the display path for one row as a local consequence of a merge. The
  /// path is the shared cache file when the image has arrived, and null while
  /// it is pending. No sync change is recorded.
  Future<void> linkRowImagePath(String entity, String rowKey, String? mediaId) async {
    final TableInfo table = entity == 'project' ? projectRecords : contextRecords;
    String? path;
    if (mediaId != null && isMediaId(mediaId)) path = await mediaStore.displayPath(mediaId);
    await customUpdate(
      'UPDATE ${table.actualTableName} SET image_path = ? WHERE id = ?',
      variables: [Variable<String>(path), Variable.withString(rowKey)],
      updates: {table},
    );
  }

  /// Links every row that references [mediaIds] to a valid display path when
  /// its current path is missing. This is the recovery step after media sync.
  Future<int> linkMediaPaths(Iterable<String> mediaIds) async {
    var changed = 0;
    for (final mediaId in mediaIds.toSet()) {
      if (!isMediaId(mediaId)) continue;
      final cachePath = await mediaStore.displayPath(mediaId);
      if (cachePath == null) continue;
      for (final table in <TableInfo>[contextRecords, projectRecords]) {
        final rows = await customSelect(
          'SELECT id, image_path FROM ${table.actualTableName} WHERE image_media_id = ?',
          variables: [Variable.withString(mediaId)],
        ).get();
        for (final row in rows) {
          final current = row.readNullable<String>('image_path');
          if (current != null && current.isNotEmpty) {
            final file = File(current);
            if (await file.exists()) {
              try {
                if (MediaStore.hashBytes(await file.readAsBytes()) == mediaId) continue;
              } on FileSystemException {
                // Fall through and relink to the verified cache copy.
              }
            }
          }
          await customUpdate(
            'UPDATE ${table.actualTableName} SET image_path = ? WHERE id = ?',
            variables: [Variable.withString(cachePath), Variable.withString(row.read<String>('id'))],
            updates: {table},
          );
          changed++;
        }
      }
    }
    return changed;
  }

  /// Links every referenced image id. Used after a source replacement, where
  /// all rows were written while the local cache already held their media.
  Future<int> linkAllMediaPaths() async {
    final ids = <String>{};
    for (final table in <TableInfo>[contextRecords, projectRecords]) {
      final rows = await customSelect(
        'SELECT DISTINCT image_media_id AS id FROM ${table.actualTableName} WHERE image_media_id IS NOT NULL',
      ).get();
      for (final row in rows) {
        final id = row.readNullable<String>('id');
        if (id != null && isMediaId(id)) ids.add(id);
      }
    }
    return linkMediaPaths(ids);
  }

  Stream<List<Project>> watchProjects({String? spaceId, String? contextId}) {
    final query = select(projectRecords)..where((row) => row.deletedAt.isNull());
    if (spaceId != null) query.where((row) => row.spaceId.equals(spaceId));
    if (contextId != null) query.where((row) => row.contextId.equals(contextId));
    return query.watch().map((rows) {
      final projects = rows.map(_projectFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          if (byPosition != 0) return byPosition;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return projects;
    });
  }

  Future<void> saveProject(Project project) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('project');
      final existing = await (select(
        projectRecords,
      )..where((row) => row.id.equals(project.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      final imageMediaId = await _cacheImagePath(project.imagePath);
      await into(projectRecords).insertOnConflictUpdate(
        ProjectRecordsCompanion(
          id: Value(project.id),
          spaceId: Value(project.spaceId),
          contextId: Value(project.contextId),
          name: Value(project.name),
          description: Value(project.description),
          color: Value(project.colorValue),
          icon: Value(project.icon),
          imagePath: Value(project.imagePath),
          imageMediaId: Value(imageMediaId),
          position: Value(project.position),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
          deletedAt: Value(project.deletedAt),
        ),
      );
      await recordSyncAfter(spec, project.id, before: before);
    });
  }

  Future<void> softDeleteProject(String id) {
    return transaction(() async {
      final now = DateTime.now();
      final projectSpec = syncEntity('project');
      final projectBefore = await readSyncRow(projectSpec, id);
      final entrySpec = syncEntity('entry');
      final entries = await (select(
        entryRecords,
      )..where((row) => row.projectId.equals(id) & row.readOnly.equals(false))).get();
      final entryBefores = {for (final row in entries) row.id: entrySpec.serialize(row)};

      await (update(entryRecords)..where((row) => row.projectId.equals(id) & row.readOnly.equals(false)))
          .write(EntryRecordsCompanion(projectId: Value(null), updatedAt: Value(now)));
      await (update(projectRecords)..where((row) => row.id.equals(id))).write(
        ProjectRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      for (final entry in entries) {
        await recordSyncAfter(entrySpec, entry.id, before: entryBefores[entry.id]);
      }
      await recordSyncDelete(projectSpec, id, lastRow: projectBefore);
    });
  }

  Stream<List<Habit>> watchHabits({String? spaceId, String? contextId}) {
    final query = select(habitRecords)..where((row) => row.deletedAt.isNull());
    if (spaceId != null) query.where((row) => row.spaceId.equals(spaceId));
    if (contextId != null) query.where((row) => row.contextId.equals(contextId));
    return query.watch().map((rows) {
      final habits = rows.map(_habitFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          if (byPosition != 0) return byPosition;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return habits;
    });
  }

  Future<void> saveHabit(Habit habit) async {
    final now = DateTime.now();
    final spec = syncEntity('habit');
    final existing = await (select(habitRecords)..where((row) => row.id.equals(habit.id))).getSingleOrNull();
    final before = existing == null ? null : spec.serialize(existing);
    await into(habitRecords).insertOnConflictUpdate(
      HabitRecordsCompanion(
        id: Value(habit.id),
        spaceId: Value(habit.spaceId),
        contextId: Value(habit.contextId),
        name: Value(habit.name),
        description: Value(habit.description),
        color: Value(habit.colorValue),
        icon: Value(habit.icon),
        targetPerWeek: Value(habit.cleanTarget),
        weekdays: Value(habit.weekdaysKey),
        position: Value(habit.position),
        archived: Value(habit.archived),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
        deletedAt: Value(habit.deletedAt),
      ),
    );
    await recordSyncAfter(spec, habit.id, before: before);
  }

  Future<void> softDeleteHabit(String id) async {
    final spec = syncEntity('habit');
    final before = await readSyncRow(spec, id);
    final now = DateTime.now();
    await (update(habitRecords)..where((row) => row.id.equals(id))).write(
      HabitRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await recordSyncDelete(spec, id, lastRow: before);
  }

  Stream<Map<String, Set<LocalDate>>> watchHabitCompletions({String? habitId}) {
    final query = select(habitCompletionRecords);
    if (habitId != null) query.where((row) => row.habitId.equals(habitId));
    return query.watch().map((rows) {
      final result = <String, Set<LocalDate>>{};
      for (final row in rows) {
        (result[row.habitId] ??= <LocalDate>{}).add(LocalDate.fromKey(row.dateKey));
      }
      return result;
    });
  }

  Future<void> setHabitCompleted(String habitId, LocalDate date, {required bool completed}) async {
    final spec = syncEntity('habitCompletion');
    final existing = await (select(
      habitCompletionRecords,
    )..where((row) => row.habitId.equals(habitId) & row.dateKey.equals(date.key))).getSingleOrNull();
    if (completed) {
      if (existing != null) return;
      await into(habitCompletionRecords).insert(
        HabitCompletionRecordsCompanion.insert(
          habitId: habitId,
          dateKey: date.key,
          createdAt: DateTime.now(),
        ),
      );
      await recordSyncAfter(spec, spec.rowKey({'habit_id': habitId, 'date_key': date.key}));
      return;
    }
    if (existing == null) return;
    final before = spec.serialize(existing);
    await (delete(
      habitCompletionRecords,
    )..where((row) => row.habitId.equals(habitId) & row.dateKey.equals(date.key))).go();
    await recordSyncDelete(spec, spec.rowKey({'habit_id': habitId, 'date_key': date.key}), lastRow: before);
  }

  Stream<List<TimeEntry>> watchTimeEntriesForEntry(String entryId) {
    final query = select(timeEntryRecords)..where((row) => row.entryId.equals(entryId));
    return query.watch().map((rows) => rows.map(_timeEntryFromRow).toList());
  }

  Future<List<TimeEntry>> readTimeEntriesBetween(
    DateTime startUtc,
    DateTime endUtc, {
    String? entryId,
  }) async {
    final query = select(timeEntryRecords)
      ..where((row) => row.startedAt.isBiggerOrEqualValue(startUtc.toUtc()))
      ..where((row) => row.startedAt.isSmallerThanValue(endUtc.toUtc()));
    if (entryId != null) query.where((row) => row.entryId.equals(entryId));
    final rows = await query.get();
    return rows.map(_timeEntryFromRow).toList()..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  Future<TimeEntry?> readOpenTimeEntry(String entryId, {int? occurrenceDateKey}) async {
    final query = select(timeEntryRecords)
      ..where((row) => row.entryId.equals(entryId))
      ..where((row) => row.endedAt.isNull());
    if (occurrenceDateKey != null) {
      query.where((row) => row.occurrenceDateKey.equals(occurrenceDateKey) | row.occurrenceDateKey.isNull());
    }
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return _timeEntryFromRow(rows.first);
  }

  Future<TimeEntry> startTimeEntry({required String entryId, int? occurrenceDateKey, DateTime? at}) async {
    final entryRow = await (select(entryRecords)..where((row) => row.id.equals(entryId))).getSingleOrNull();
    if (entryRow?.readOnly == true) throw StateError('Imported entries are read-only');
    final now = (at ?? DateTime.now()).toUtc();
    final open = await readOpenTimeEntry(entryId, occurrenceDateKey: occurrenceDateKey);
    if (open != null) return open;
    final entry = TimeEntry(
      id: const Uuid().v4(),
      entryId: entryId,
      occurrenceDateKey: occurrenceDateKey,
      startedAt: now,
      createdAt: now,
    );
    await into(timeEntryRecords).insert(
      TimeEntryRecordsCompanion.insert(
        id: entry.id,
        entryId: entry.entryId,
        occurrenceDateKey: Value(entry.occurrenceDateKey),
        startedAt: entry.startedAt,
        createdAt: entry.createdAt,
      ),
    );
    await recordSyncAfter(syncEntity('timeEntry'), entry.id);
    return entry;
  }

  Future<TimeEntry?> stopTimeEntry(String entryId, {int? occurrenceDateKey, DateTime? at}) async {
    final open = await readOpenTimeEntry(entryId, occurrenceDateKey: occurrenceDateKey);
    if (open == null) return null;
    final spec = syncEntity('timeEntry');
    final before = await readSyncRow(spec, open.id);
    final now = (at ?? DateTime.now()).toUtc();
    await (update(
      timeEntryRecords,
    )..where((row) => row.id.equals(open.id))).write(TimeEntryRecordsCompanion(endedAt: Value(now)));
    await recordSyncAfter(spec, open.id, before: before);
    return TimeEntry(
      id: open.id,
      entryId: open.entryId,
      occurrenceDateKey: open.occurrenceDateKey,
      startedAt: open.startedAt,
      endedAt: now,
      note: open.note,
      createdAt: open.createdAt,
    );
  }

  Future<Map<String, String>> readSettings() async {
    final rows = await select(settingRecords).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<void> writeSetting(String key, String value) async {
    if (key != 'weekStart') {
      await into(
        settingRecords,
      ).insertOnConflictUpdate(SettingRecordsCompanion.insert(key: key, value: value));
      return;
    }
    await transaction(() async {
      final spec = syncEntity('setting');
      final before = await readSyncRow(spec, key);
      await into(
        settingRecords,
      ).insertOnConflictUpdate(SettingRecordsCompanion.insert(key: key, value: value));
      await recordSyncAfter(spec, key, before: before);
    });
  }

  static const syncDatasetSettingKey = 'syncDatasetId';

  /// The logical plan shared by paired devices. It is created once and kept
  /// device-local; backups never carry it, so a restore starts a new plan.
  Future<String> ensureSyncDatasetId() async => (await syncDeviceState()).datasetId;

  /// True when the user has planner data beyond the seeded spaces, default
  /// tags and reference rows. Pairing uses this to decide whether replacing a
  /// device would discard a real plan.
  Future<bool> hasUserData() async {
    final seededTags = [for (final tag in _defaultCategories) Variable.withString(tag.id)];
    final placeholders = List.filled(seededTags.length, '?').join(', ');
    final row = await customSelect('''
      SELECT
        EXISTS(SELECT 1 FROM entry_records) +
        EXISTS(SELECT 1 FROM context_records) +
        EXISTS(SELECT 1 FROM project_records) +
        EXISTS(SELECT 1 FROM habit_records) +
        EXISTS(SELECT 1 FROM habit_completion_records) +
        EXISTS(SELECT 1 FROM time_entry_records) +
        EXISTS(SELECT 1 FROM completion_records) +
        EXISTS(SELECT 1 FROM reminder_records) +
        EXISTS(SELECT 1 FROM shift_pattern_records) +
        EXISTS(SELECT 1 FROM shift_slot_records) +
        EXISTS(SELECT 1 FROM shift_exception_records) +
        EXISTS(SELECT 1 FROM shift_checklist_item_records) +
        EXISTS(SELECT 1 FROM shift_checklist_completion_records) +
        EXISTS(SELECT 1 FROM home_item_records) +
        EXISTS(SELECT 1 FROM home_item_location_records) +
        EXISTS(SELECT 1 FROM shopping_item_records) +
        EXISTS(SELECT 1 FROM home_purchase_records) +
        EXISTS(SELECT 1 FROM maintenance_log_records) +
        EXISTS(SELECT 1 FROM tag_records WHERE id NOT IN ($placeholders))
        AS count
      ''', variables: seededTags).getSingle();
    return row.read<int>('count') > 0;
  }

  Stream<List<EntryOccurrence>> watchEntriesBetween(LocalDate start, LocalDate end, String viewerTimeZone) {
    final query = _entriesQuery(start, end);
    return query.watch().map((rows) => _expandEntryRows(rows, start, end, viewerTimeZone));
  }

  Future<List<EntryOccurrence>> loadEntriesBetween(
    LocalDate start,
    LocalDate end,
    String viewerTimeZone,
  ) async {
    final rows = await _entriesQuery(start, end).get();
    return _expandEntryRows(rows, start, end, viewerTimeZone);
  }

  JoinedSelectStatement _entriesQuery(LocalDate start, LocalDate end) => select(entryRecords).join([
    leftOuterJoin(
      completionRecords,
      completionRecords.entryId.equalsExp(entryRecords.id) &
          completionRecords.dateKey.isBetweenValues(start.addDays(-2).key, end.addDays(2).key),
    ),
    leftOuterJoin(entryTagRecords, entryTagRecords.entryId.equalsExp(entryRecords.id)),
    leftOuterJoin(timeEntryRecords, timeEntryRecords.entryId.equalsExp(entryRecords.id)),
  ])..where(entryRecords.deletedAt.isNull());

  /// Open tasks with no date or a date up to [until]. Today uses this for
  /// unscheduled and overdue work that must stay visible.
  Stream<List<Entry>> watchOpenEntries(LocalDate until) {
    final query =
        select(
          entryRecords,
        ).join([leftOuterJoin(entryTagRecords, entryTagRecords.entryId.equalsExp(entryRecords.id))])..where(
          entryRecords.deletedAt.isNull() &
              entryRecords.status.isNotIn([EntryStatus.done.name, EntryStatus.cancelled.name]) &
              (entryRecords.dateKey.isNull() | entryRecords.dateKey.isSmallerOrEqualValue(until.key)),
        );

    return query.watch().map((rows) {
      final entryRows = <String, EntryRow>{};
      final tagIds = <String, Set<String>>{};
      for (final row in rows) {
        final entryRow = row.readTable(entryRecords);
        entryRows[entryRow.id] = entryRow;
        final tag = row.readTableOrNull(entryTagRecords);
        if (tag != null) (tagIds[entryRow.id] ??= <String>{}).add(tag.tagId);
      }
      final entries = [
        for (final row in entryRows.values) _entryFromRow(row, tagIds: tagIds[row.id] ?? const <String>{}),
      ];
      final now = DateTime.now().toUtc();
      entries.sort((a, b) {
        final byPriority = effectivePriority(b, now).index.compareTo(effectivePriority(a, now).index);
        if (byPriority != 0) return byPriority;
        final aDate = a.date;
        final bDate = b.date;
        if (aDate == null && bDate != null) return -1;
        if (aDate != null && bDate == null) return 1;
        if (aDate != null && bDate != null) {
          final byDate = aDate.compareTo(bDate);
          if (byDate != 0) return byDate;
        }
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return entries;
    });
  }

  List<EntryOccurrence> _expandEntryRows(
    List<TypedResult> rows,
    LocalDate start,
    LocalDate end,
    String viewerTimeZone,
  ) {
    final entryRows = <String, EntryRow>{};
    final completions = <String, Set<LocalDate>>{};
    final tagIds = <String, Set<String>>{};
    final timeRows = <String, Map<String, TimeEntryRow>>{};

    for (final row in rows) {
      final entryRow = row.readTable(entryRecords);
      entryRows[entryRow.id] = entryRow;
      final completion = row.readTableOrNull(completionRecords);
      if (completion != null) {
        (completions[entryRow.id] ??= <LocalDate>{}).add(LocalDate.fromKey(completion.dateKey));
      }
      final tag = row.readTableOrNull(entryTagRecords);
      if (tag != null) {
        (tagIds[entryRow.id] ??= <String>{}).add(tag.tagId);
      }
      final timeRow = row.readTableOrNull(timeEntryRecords);
      if (timeRow != null) {
        (timeRows[entryRow.id] ??= <String, TimeEntryRow>{})[timeRow.id] = timeRow;
      }
    }

    final entries = <String, Entry>{
      for (final row in entryRows.values)
        row.id: _entryFromRow(row, tagIds: tagIds[row.id] ?? const <String>{}),
    };

    final expanded = expandEntries(
      entries: entries.values,
      start: start,
      end: end,
      viewerTimeZone: viewerTimeZone,
      completions: completions,
    );
    final now = DateTime.now().toUtc();
    return [for (final occurrence in expanded) _withTracking(occurrence, timeRows[occurrence.entry.id], now)];
  }

  EntryOccurrence _withTracking(EntryOccurrence occurrence, Map<String, TimeEntryRow>? rows, DateTime now) {
    if (rows == null || rows.isEmpty) return occurrence;
    var tracked = Duration.zero;
    var clockedIn = false;
    for (final row in rows.values) {
      final key = row.occurrenceDateKey;
      if (key != null && occurrence.entry.recurrence != null && key != occurrence.date.key) continue;
      tracked += (row.endedAt ?? now).toUtc().difference(row.startedAt.toUtc());
      if (row.endedAt == null) clockedIn = true;
    }
    return occurrence.copyWith(tracked: tracked, clockedIn: clockedIn);
  }

  Stream<List<ShiftOccurrence>> watchShiftsBetween(LocalDate start, LocalDate end, String viewerTimeZone) {
    final query =
        select(shiftPatternRecords).join([
          leftOuterJoin(shiftSlotRecords, shiftSlotRecords.patternId.equalsExp(shiftPatternRecords.id)),
          leftOuterJoin(
            shiftExceptionRecords,
            shiftExceptionRecords.patternId.equalsExp(shiftPatternRecords.id),
          ),
          leftOuterJoin(
            shiftPatternTagRecords,
            shiftPatternTagRecords.patternId.equalsExp(shiftPatternRecords.id),
          ),
        ])..where(
          shiftPatternRecords.deletedAt.isNull() &
              shiftPatternRecords.enabled.equals(true) &
              shiftPatternRecords.spaceId.equals('work'),
        );

    return query.watch().map((rows) {
      final occurrences = <ShiftOccurrence>[];
      for (final pattern in _patternsFromRows(rows)) {
        for (final occurrence in pattern.occurrencesBetween(
          start.addDays(-2),
          end.addDays(2),
          viewerTimeZone: viewerTimeZone,
        )) {
          if (occurrence.displayDate.isBefore(start) || occurrence.displayDate.isAfter(end)) {
            continue;
          }
          occurrences.add(occurrence);
        }
      }

      occurrences.sort((a, b) {
        final byDate = a.displayDate.compareTo(b.displayDate);
        if (byDate != 0) return byDate;
        return a.startAt.compareTo(b.startAt);
      });
      return occurrences;
    });
  }

  Stream<List<ShiftPattern>> watchShiftPatterns() {
    final query = select(shiftPatternRecords).join([
      leftOuterJoin(shiftSlotRecords, shiftSlotRecords.patternId.equalsExp(shiftPatternRecords.id)),
      leftOuterJoin(shiftExceptionRecords, shiftExceptionRecords.patternId.equalsExp(shiftPatternRecords.id)),
      leftOuterJoin(
        shiftPatternTagRecords,
        shiftPatternTagRecords.patternId.equalsExp(shiftPatternRecords.id),
      ),
    ])..where(shiftPatternRecords.deletedAt.isNull() & shiftPatternRecords.spaceId.equals('work'));

    return query.watch().map((rows) {
      final patterns = _patternsFromRows(rows);
      patterns.sort((a, b) {
        final bySpace = a.spaceId.compareTo(b.spaceId);
        if (bySpace != 0) return bySpace;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return patterns;
    });
  }

  Future<void> saveEntry(Entry entry, {bool allowReadOnly = false, Set<String>? removedTagIds}) {
    return transaction(() async {
      final existing = await (select(
        entryRecords,
      )..where((row) => row.id.equals(entry.id))).getSingleOrNull();
      if (existing?.readOnly == true && !allowReadOnly) {
        throw StateError('Imported entries are read-only');
      }
      final spec = syncEntity('entry');
      final before = existing == null ? null : spec.serialize(existing);
      await into(entryRecords).insertOnConflictUpdate(_entryCompanion(entry));
      final after = await readSyncRow(spec, entry.id);
      if (after != null) {
        await recordSyncUpsert(spec, entry.id, before: before, after: after);
      }
      await saveEntryTags(entry.id, entry.tagIds, removedIds: removedTagIds);
    });
  }

  Stream<List<Tag>> watchTags() {
    final query = select(tagRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().map((rows) {
      final tags = rows.map(_tagFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          if (byPosition != 0) return byPosition;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return tags;
    });
  }

  Future<void> saveTag(Tag tag) async {
    final now = DateTime.now();
    final spec = syncEntity('tag');
    final existing = await (select(tagRecords)..where((row) => row.id.equals(tag.id))).getSingleOrNull();
    final before = existing == null ? null : spec.serialize(existing);
    await into(tagRecords).insertOnConflictUpdate(
      TagRecordsCompanion(
        id: Value(tag.id),
        spaceId: Value(tag.spaceId),
        name: Value(tag.name),
        color: Value(tag.colorValue),
        icon: Value(tag.icon),
        position: Value(tag.position),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );
    await recordSyncAfter(spec, tag.id, before: before);
  }

  Future<void> softDeleteTag(String id) {
    return transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('tag');
      final tagBefore = await readSyncRow(spec, id);
      final linkSpec = syncEntity('entryTag');
      final links = await (select(entryTagRecords)..where((row) => row.tagId.equals(id))).get();
      for (final link in links) {
        final key = linkSpec.rowKey({'entry_id': link.entryId, 'tag_id': link.tagId});
        final before = linkSpec.serialize(link);
        await (delete(
          entryTagRecords,
        )..where((row) => row.entryId.equals(link.entryId) & row.tagId.equals(link.tagId))).go();
        await recordSyncDelete(linkSpec, key, lastRow: before);
      }
      await (update(tagRecords)..where((row) => row.id.equals(id))).write(
        TagRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await recordSyncDelete(spec, id, lastRow: tagBefore);
    });
  }

  Stream<List<HomeCategory>> watchHomeCategories() {
    final query = select(homeCategoryRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().map((rows) {
      final categories = rows.map(_homeCategoryFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          return byPosition != 0 ? byPosition : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return categories;
    });
  }

  Future<void> saveHomeCategory(HomeCategory category) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeCategory');
      final existing = await (select(
        homeCategoryRecords,
      )..where((row) => row.id.equals(category.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      final renamed = existing != null && existing.name != category.name;
      final homeItems = renamed
          ? await (select(homeItemRecords)..where((row) => row.categoryId.equals(category.id))).get()
          : const <HomeItemRow>[];
      final shopping = renamed
          ? await (select(shoppingItemRecords)..where((row) => row.categoryId.equals(category.id))).get()
          : const <ShoppingItemRow>[];
      final homeBefores = {for (final row in homeItems) row.id: syncEntity('homeItem').serialize(row)};
      final shoppingBefores = {for (final row in shopping) row.id: syncEntity('shoppingItem').serialize(row)};

      await into(homeCategoryRecords).insertOnConflictUpdate(
        HomeCategoryRecordsCompanion(
          id: Value(category.id),
          name: Value(category.name),
          icon: Value(category.icon),
          color: Value(category.colorValue),
          position: Value(category.position),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
        ),
      );
      if (renamed) {
        await (update(homeItemRecords)..where((row) => row.categoryId.equals(category.id))).write(
          HomeItemRecordsCompanion(category: Value(category.name), updatedAt: Value(now)),
        );
        await (update(shoppingItemRecords)..where((row) => row.categoryId.equals(category.id))).write(
          ShoppingItemRecordsCompanion(category: Value(category.name), updatedAt: Value(now)),
        );
      }

      for (final row in homeItems) {
        await recordSyncAfter(syncEntity('homeItem'), row.id, before: homeBefores[row.id]);
      }
      for (final row in shopping) {
        await recordSyncAfter(syncEntity('shoppingItem'), row.id, before: shoppingBefores[row.id]);
      }
      await recordSyncAfter(spec, category.id, before: before);
    });
  }

  Future<void> deleteHomeCategory(String id) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeCategory');
      final before = await readSyncRow(spec, id);
      final homeItems = await (select(homeItemRecords)..where((row) => row.categoryId.equals(id))).get();
      final shopping = await (select(shoppingItemRecords)..where((row) => row.categoryId.equals(id))).get();
      final homeBefores = {for (final row in homeItems) row.id: syncEntity('homeItem').serialize(row)};
      final shoppingBefores = {for (final row in shopping) row.id: syncEntity('shoppingItem').serialize(row)};

      await (update(homeItemRecords)..where((row) => row.categoryId.equals(id))).write(
        HomeItemRecordsCompanion(categoryId: Value(null), updatedAt: Value(now)),
      );
      await (update(shoppingItemRecords)..where((row) => row.categoryId.equals(id))).write(
        ShoppingItemRecordsCompanion(categoryId: Value(null), updatedAt: Value(now)),
      );
      await (update(homeCategoryRecords)..where((row) => row.id.equals(id))).write(
        HomeCategoryRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

      for (final row in homeItems) {
        await recordSyncAfter(syncEntity('homeItem'), row.id, before: homeBefores[row.id]);
      }
      for (final row in shopping) {
        await recordSyncAfter(syncEntity('shoppingItem'), row.id, before: shoppingBefores[row.id]);
      }
      await recordSyncDelete(spec, id, lastRow: before);
    });
  }

  Stream<List<HomeLocation>> watchHomeLocations() {
    final query = select(homeLocationRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().map((rows) {
      final locations = rows.map(_homeLocationFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          return byPosition != 0 ? byPosition : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return locations;
    });
  }

  Future<void> saveHomeLocation(HomeLocation location) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeLocation');
      final existing = await (select(
        homeLocationRecords,
      )..where((row) => row.id.equals(location.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      final renamed = existing != null && existing.name != location.name;
      final links = renamed
          ? await (select(homeItemLocationRecords)..where((row) => row.locationId.equals(location.id))).get()
          : const <HomeItemLocationRow>[];
      final homeIds = {for (final link in links) link.homeItemId};
      final homeBefores = <String, Map<String, Object?>>{};
      for (final homeId in homeIds) {
        final row = await (select(
          homeItemRecords,
        )..where((item) => item.id.equals(homeId))).getSingleOrNull();
        if (row != null) homeBefores[homeId] = syncEntity('homeItem').serialize(row);
      }

      await into(homeLocationRecords).insertOnConflictUpdate(
        HomeLocationRecordsCompanion(
          id: Value(location.id),
          name: Value(location.name),
          icon: Value(location.icon),
          color: Value(location.colorValue),
          position: Value(location.position),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
        ),
      );
      if (renamed) {
        for (final link in links) {
          await _refreshHomeItemLocationText(link.homeItemId, now);
        }
      }

      for (final entry in homeBefores.entries) {
        await recordSyncAfter(syncEntity('homeItem'), entry.key, before: entry.value);
      }
      await recordSyncAfter(spec, location.id, before: before);
    });
  }

  Future<void> deleteHomeLocation(String id) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeLocation');
      final before = await readSyncRow(spec, id);
      final links = await (select(homeItemLocationRecords)..where((row) => row.locationId.equals(id))).get();
      final linkSpec = syncEntity('homeItemLocation');
      final homeIds = {for (final link in links) link.homeItemId};
      final homeBefores = <String, Map<String, Object?>>{};
      for (final homeId in homeIds) {
        final row = await (select(
          homeItemRecords,
        )..where((item) => item.id.equals(homeId))).getSingleOrNull();
        if (row != null) homeBefores[homeId] = syncEntity('homeItem').serialize(row);
      }

      await (delete(homeItemLocationRecords)..where((row) => row.locationId.equals(id))).go();
      for (final link in links) {
        final key = linkSpec.rowKey({'home_item_id': link.homeItemId, 'location_id': link.locationId});
        await recordSyncDelete(linkSpec, key, lastRow: linkSpec.serialize(link));
      }
      for (final link in links) {
        await _refreshHomeItemLocationText(link.homeItemId, now);
      }
      await (update(homeLocationRecords)..where((row) => row.id.equals(id))).write(
        HomeLocationRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );

      for (final entry in homeBefores.entries) {
        await recordSyncAfter(syncEntity('homeItem'), entry.key, before: entry.value);
      }
      await recordSyncDelete(spec, id, lastRow: before);
    });
  }

  Stream<List<HomeUnit>> watchHomeUnits() {
    final query = select(homeUnitRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().map((rows) {
      final units = rows.map(_homeUnitFromRow).toList()
        ..sort((a, b) {
          final byPosition = a.position.compareTo(b.position);
          return byPosition != 0 ? byPosition : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return units;
    });
  }

  Future<void> saveHomeUnit(HomeUnit unit) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeUnit');
      final existing = await (select(
        homeUnitRecords,
      )..where((row) => row.id.equals(unit.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      final renamed = existing != null && existing.name != unit.name;
      final homeItems = renamed
          ? await (select(homeItemRecords)..where((row) => row.unitId.equals(unit.id))).get()
          : const <HomeItemRow>[];
      final homeBefores = {for (final row in homeItems) row.id: syncEntity('homeItem').serialize(row)};

      await into(homeUnitRecords).insertOnConflictUpdate(
        HomeUnitRecordsCompanion(
          id: Value(unit.id),
          name: Value(unit.name),
          symbol: Value(unit.symbol),
          kind: Value(unit.kind.name),
          position: Value(unit.position),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
        ),
      );
      if (renamed) {
        await (update(homeItemRecords)..where((row) => row.unitId.equals(unit.id))).write(
          HomeItemRecordsCompanion(unit: Value(unit.name), updatedAt: Value(now)),
        );
      }

      for (final row in homeItems) {
        await recordSyncAfter(syncEntity('homeItem'), row.id, before: homeBefores[row.id]);
      }
      await recordSyncAfter(spec, unit.id, before: before);
    });
  }

  Future<void> deleteHomeUnit(String id) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeUnit');
      final before = await readSyncRow(spec, id);
      final homeItems = await (select(homeItemRecords)..where((row) => row.unitId.equals(id))).get();
      final homeBefores = {for (final row in homeItems) row.id: syncEntity('homeItem').serialize(row)};
      await (update(homeItemRecords)..where((row) => row.unitId.equals(id))).write(
        HomeItemRecordsCompanion(unitId: Value(null), updatedAt: Value(now)),
      );
      await (update(homeUnitRecords)..where((row) => row.id.equals(id))).write(
        HomeUnitRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      for (final row in homeItems) {
        await recordSyncAfter(syncEntity('homeItem'), row.id, before: homeBefores[row.id]);
      }
      await recordSyncDelete(spec, id, lastRow: before);
    });
  }

  Stream<List<HomeItem>> watchHomeItems() {
    final query = select(homeItemRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().asyncMap((rows) async {
      final links = await select(homeItemLocationRecords).get();
      final locationIds = <String, List<String>>{};
      for (final link in links) {
        (locationIds[link.homeItemId] ??= <String>[]).add(link.locationId);
      }
      final items =
          [
            for (final row in rows)
              _homeItemFromRow(row, locationIds: locationIds[row.id] ?? const <String>[]),
          ]..sort((a, b) {
            final byCategory = a.category.toLowerCase().compareTo(b.category.toLowerCase());
            if (byCategory != 0) return byCategory;
            final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            if (byName != 0) return byName;
            return a.packSize.toLowerCase().compareTo(b.packSize.toLowerCase());
          });
      return items;
    });
  }

  /// Saves one stock variant.
  ///
  /// [updateGroup] carries product-level fields (name, description, art and
  /// category) to every other size of the same product.
  Future<void> saveHomeItem(HomeItem item, {bool updateGroup = false}) async {
    await transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('homeItem');
      final linkSpec = syncEntity('homeItemLocation');
      final existing = await (select(
        homeItemRecords,
      )..where((row) => row.id.equals(item.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      final groupRows = updateGroup && item.groupId != null
          ? await (select(
              homeItemRecords,
            )..where((row) => row.groupId.equals(item.groupId!) & row.id.equals(item.id).not())).get()
          : const <HomeItemRow>[];
      final groupBefores = {for (final row in groupRows) row.id: spec.serialize(row)};
      final existingLinks = await (select(
        homeItemLocationRecords,
      )..where((row) => row.homeItemId.equals(item.id))).get();
      final existingLocationIds = {for (final link in existingLinks) link.locationId};

      final groupId = item.groupId ?? item.id;
      var categoryId = item.categoryId;
      var unitId = item.unitId;
      var locationIds = item.locationIds;
      if (categoryId == null && item.category.trim().isNotEmpty) {
        final match = await _activeCategoryByName(item.category.trim());
        categoryId = match?.id;
      }
      if (unitId == null && item.unit.trim().isNotEmpty) {
        final match = await _activeUnitByName(item.unit.trim());
        unitId = match?.id;
      }
      if (locationIds.isEmpty && item.location.trim().isNotEmpty) {
        final names = [
          for (final part in item.location.split(','))
            if (part.trim().isNotEmpty) part.trim().toLowerCase(),
        ];
        if (names.isNotEmpty) {
          final rows = await (select(
            homeLocationRecords,
          )..where((row) => row.name.lower().isIn(names) & row.deletedAt.isNull())).get();
          locationIds = [for (final row in rows) row.id];
        }
      }
      final categoryName = await _homeCategoryName(categoryId, item.category);
      final unitName = await _homeUnitName(unitId, item.unit);
      final locationText = await _homeLocationText(locationIds, item.location);
      final minimum = item.minimumStock;
      if (groupRows.isNotEmpty) {
        await (update(
          homeItemRecords,
        )..where((row) => row.groupId.equals(item.groupId!) & row.id.equals(item.id).not())).write(
          HomeItemRecordsCompanion(
            name: Value(item.name),
            description: Value(item.description),
            icon: Value(item.icon),
            color: Value(item.colorValue),
            catalogId: Value(item.catalogId),
            category: Value(categoryName),
            categoryId: Value(categoryId),
            updatedAt: Value(now),
          ),
        );
      }
      await into(homeItemRecords).insertOnConflictUpdate(
        HomeItemRecordsCompanion(
          id: Value(item.id),
          contextId: Value(item.contextId),
          groupId: Value(groupId),
          name: Value(item.name),
          description: Value(item.description),
          icon: Value(item.icon),
          color: Value(item.colorValue),
          catalogId: Value(item.catalogId),
          category: Value(categoryName),
          categoryId: Value(categoryId),
          location: Value(locationText),
          quantity: Value(item.quantity),
          minQuantity: Value(minimum),
          reorderLevel: Value(minimum),
          unit: Value(unitName),
          unitId: Value(unitId),
          packSize: Value(item.packSize),
          expiresDateKey: Value(item.expiresAt?.key),
          notes: Value(item.notes),
          lastPurchasedAt: Value(item.lastPurchasedAt),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
        ),
      );

      final incomingLocationIds = locationIds.toSet();
      for (final link in existingLinks) {
        if (incomingLocationIds.contains(link.locationId)) continue;
        final key = linkSpec.rowKey({'home_item_id': item.id, 'location_id': link.locationId});
        final linkBefore = linkSpec.serialize(link);
        await (delete(
          homeItemLocationRecords,
        )..where((row) => row.homeItemId.equals(item.id) & row.locationId.equals(link.locationId))).go();
        await recordSyncDelete(linkSpec, key, lastRow: linkBefore);
      }
      for (final locationId in incomingLocationIds) {
        if (existingLocationIds.contains(locationId)) continue;
        await into(homeItemLocationRecords).insert(
          HomeItemLocationRecordsCompanion.insert(homeItemId: item.id, locationId: locationId),
          mode: InsertMode.insertOrIgnore,
        );
        final key = linkSpec.rowKey({'home_item_id': item.id, 'location_id': locationId});
        final after = await readSyncRow(linkSpec, key);
        if (after != null) await recordSyncUpsert(linkSpec, key, after: after);
      }

      for (final row in groupRows) {
        await recordSyncAfter(spec, row.id, before: groupBefores[row.id]);
      }
      await recordSyncAfter(spec, item.id, before: before);
    });
  }

  Future<void> archiveHomeItem(String id) async {
    final now = DateTime.now();
    await transaction(() async {
      final spec = syncEntity('homeItem');
      final before = await readSyncRow(spec, id);
      final shopping = await (select(
        shoppingItemRecords,
      )..where((row) => row.homeItemId.equals(id) & row.deletedAt.isNull())).get();
      final shoppingBefores = {for (final row in shopping) row.id: syncEntity('shoppingItem').serialize(row)};
      // A removed size must not keep receiving stock from a stale shopping line.
      await (update(shoppingItemRecords)..where((row) => row.homeItemId.equals(id) & row.deletedAt.isNull()))
          .write(ShoppingItemRecordsCompanion(homeItemId: const Value(null), updatedAt: Value(now)));
      await (update(homeItemRecords)..where((row) => row.id.equals(id))).write(
        HomeItemRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      for (final row in shopping) {
        await recordSyncAfter(syncEntity('shoppingItem'), row.id, before: shoppingBefores[row.id]);
      }
      await recordSyncDelete(spec, id, lastRow: before);
    });
  }

  Future<void> archiveHomeGroup(String groupId) async {
    final now = DateTime.now();
    await transaction(() async {
      final spec = syncEntity('homeItem');
      final rows =
          await (select(homeItemRecords)..where(
                (row) => (row.groupId.equals(groupId) | row.id.equals(groupId)) & row.deletedAt.isNull(),
              ))
              .get();
      final shopping =
          await (select(shoppingItemRecords)..where(
                (row) => row.homeItemId.isIn([for (final item in rows) item.id]) & row.deletedAt.isNull(),
              ))
              .get();
      final shoppingBefores = {for (final row in shopping) row.id: syncEntity('shoppingItem').serialize(row)};
      final itemBefores = {for (final row in rows) row.id: spec.serialize(row)};
      for (final row in rows) {
        await (update(shoppingItemRecords)
              ..where((shopping) => shopping.homeItemId.equals(row.id) & shopping.deletedAt.isNull()))
            .write(ShoppingItemRecordsCompanion(homeItemId: const Value(null), updatedAt: Value(now)));
      }
      if (rows.isNotEmpty) {
        await (update(homeItemRecords)..where(
              (row) => (row.groupId.equals(groupId) | row.id.equals(groupId)) & row.deletedAt.isNull(),
            ))
            .write(HomeItemRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
      }
      for (final row in shopping) {
        await recordSyncAfter(syncEntity('shoppingItem'), row.id, before: shoppingBefores[row.id]);
      }
      for (final row in rows) {
        await recordSyncDelete(spec, row.id, lastRow: itemBefores[row.id]);
      }
    });
  }

  Future<String> _homeCategoryName(String? id, String fallback) async {
    if (id == null) return fallback;
    final row = await (select(homeCategoryRecords)..where((row) => row.id.equals(id))).getSingleOrNull();
    return row?.name ?? fallback;
  }

  Future<HomeCategoryRow?> _activeCategoryByName(String name) async {
    final rows = await (select(
      homeCategoryRecords,
    )..where((row) => row.name.lower().equals(name.toLowerCase()) & row.deletedAt.isNull())).get();
    if (rows.isEmpty) return null;
    rows.sort((a, b) => a.position.compareTo(b.position));
    return rows.first;
  }

  Future<HomeUnitRow?> _activeUnitByName(String name) async {
    final rows =
        await (select(homeUnitRecords)..where(
              (row) =>
                  (row.name.lower().equals(name.toLowerCase()) |
                      row.symbol.lower().equals(name.toLowerCase())) &
                  row.deletedAt.isNull(),
            ))
            .get();
    if (rows.isEmpty) return null;
    rows.sort((a, b) => a.position.compareTo(b.position));
    return rows.first;
  }

  Future<String> _homeUnitName(String? id, String fallback) async {
    if (id == null) return fallback;
    final row = await (select(homeUnitRecords)..where((row) => row.id.equals(id))).getSingleOrNull();
    return row?.name ?? fallback;
  }

  Future<String> _homeLocationText(List<String> ids, String fallback) async {
    if (ids.isEmpty) return fallback;
    final rows = await (select(homeLocationRecords)..where((row) => row.id.isIn(ids))).get();
    final names = [for (final row in rows) row.name];
    return names.isEmpty ? fallback : names.join(', ');
  }

  Future<void> _refreshHomeItemLocationText(String itemId, DateTime now) async {
    final links = await (select(
      homeItemLocationRecords,
    )..where((row) => row.homeItemId.equals(itemId))).get();
    final text = await _homeLocationText([for (final link in links) link.locationId], '');
    await (update(homeItemRecords)..where((row) => row.id.equals(itemId))).write(
      HomeItemRecordsCompanion(location: Value(text), updatedAt: Value(now)),
    );
  }

  /// Inserts the seeded reference rows once. A failed or partial seed leaves the
  /// flag unset so the next open can finish the job.
  Future<void> seedHomeReferenceDefaults() => _seedHomeReferenceDefaults();

  Future<void> _seedHomeReferenceDefaults() async {
    final seeded = await (select(
      settingRecords,
    )..where((row) => row.key.equals('homeReferenceSeeded'))).getSingleOrNull();
    if (seeded != null) return;
    final now = DateTime.now();
    await transaction(() async {
      final categories = await select(homeCategoryRecords).get();
      if (categories.isEmpty) {
        for (final category in defaultHomeCategories) {
          await into(homeCategoryRecords).insertOnConflictUpdate(
            HomeCategoryRecordsCompanion.insert(
              id: category.id,
              name: category.name,
              icon: Value(category.icon),
              color: category.colorValue,
              position: Value(category.position),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
      final locations = await select(homeLocationRecords).get();
      if (locations.isEmpty) {
        for (final location in defaultHomeLocations) {
          await into(homeLocationRecords).insertOnConflictUpdate(
            HomeLocationRecordsCompanion.insert(
              id: location.id,
              name: location.name,
              icon: Value(location.icon),
              color: location.colorValue,
              position: Value(location.position),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
      final units = await select(homeUnitRecords).get();
      if (units.isEmpty) {
        for (final unit in defaultHomeUnits) {
          await into(homeUnitRecords).insertOnConflictUpdate(
            HomeUnitRecordsCompanion.insert(
              id: unit.id,
              name: unit.name,
              symbol: Value(unit.symbol),
              kind: Value(unit.kind.name),
              position: Value(unit.position),
              createdAt: now,
              updatedAt: now,
            ),
          );
        }
      }
      await into(
        settingRecords,
      ).insertOnConflictUpdate(SettingRecordsCompanion.insert(key: 'homeReferenceSeeded', value: 'true'));
    });
  }

  /// Maps legacy category, location and unit text to the seeded reference rows.
  /// Explicit ids and join rows always win, so this is safe after a v13 backup.
  Future<void> repairHomeItemReferences() async {
    final categoryRows = await (select(homeCategoryRecords)..where((row) => row.deletedAt.isNull())).get();
    final locationRows = await (select(homeLocationRecords)..where((row) => row.deletedAt.isNull())).get();
    final unitRows = await (select(homeUnitRecords)..where((row) => row.deletedAt.isNull())).get();
    final categoriesByName = {for (final row in categoryRows) row.name.toLowerCase(): row};
    final locationsByName = {for (final row in locationRows) row.name.toLowerCase(): row};
    final unitsByName = {
      for (final row in unitRows) ...{row.name.toLowerCase(): row, row.symbol.toLowerCase(): row},
    };
    final homeSpec = syncEntity('homeItem');
    final linkSpec = syncEntity('homeItemLocation');
    final items = await select(homeItemRecords).get();
    final itemBefores = {for (final item in items) item.id: homeSpec.serialize(item)};
    final linksBefore = await select(homeItemLocationRecords).get();
    final beforeLinkKeys = {
      for (final link in linksBefore)
        linkSpec.rowKey({'home_item_id': link.homeItemId, 'location_id': link.locationId}): linkSpec
            .serialize(link),
    };
    for (final item in items) {
      final category = item.categoryId == null && item.category.trim().isNotEmpty
          ? categoriesByName[item.category.trim().toLowerCase()]
          : null;
      final unit = item.unitId == null && item.unit.trim().isNotEmpty
          ? unitsByName[item.unit.trim().toLowerCase()]
          : null;
      if (category != null || unit != null) {
        await (update(homeItemRecords)..where((row) => row.id.equals(item.id))).write(
          HomeItemRecordsCompanion(
            categoryId: Value(category?.id),
            unitId: Value(unit?.id),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      if (item.location.trim().isEmpty) continue;
      final existing = await (select(
        homeItemLocationRecords,
      )..where((row) => row.homeItemId.equals(item.id))).get();
      if (existing.isNotEmpty) continue;
      for (final part in item.location.split(',')) {
        final location = locationsByName[part.trim().toLowerCase()];
        if (location == null) continue;
        await into(homeItemLocationRecords).insert(
          HomeItemLocationRecordsCompanion.insert(homeItemId: item.id, locationId: location.id),
          mode: InsertMode.insertOrIgnore,
        );
      }
    }

    final linksAfter = await select(homeItemLocationRecords).get();
    final afterLinkKeys = {
      for (final link in linksAfter)
        linkSpec.rowKey({'home_item_id': link.homeItemId, 'location_id': link.locationId}),
    };
    for (final link in linksAfter) {
      final key = linkSpec.rowKey({'home_item_id': link.homeItemId, 'location_id': link.locationId});
      if (beforeLinkKeys.containsKey(key)) continue;
      await recordSyncAfter(linkSpec, key);
    }
    for (final entry in beforeLinkKeys.entries) {
      if (afterLinkKeys.contains(entry.key)) continue;
      await recordSyncDelete(linkSpec, entry.key, lastRow: entry.value);
    }
    for (final item in items) {
      await recordSyncAfter(homeSpec, item.id, before: itemBefores[item.id]);
    }
  }

  Stream<List<ShoppingItem>> watchShoppingItems() {
    final query = select(shoppingItemRecords)..where((row) => row.deletedAt.isNull());
    return query.watch().map((rows) {
      final items = rows.map(_shoppingItemFromRow).toList()
        ..sort((a, b) {
          if (a.checked != b.checked) return a.checked ? 1 : -1;
          final byPosition = a.position.compareTo(b.position);
          if (byPosition != 0) return byPosition;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return items;
    });
  }

  Future<void> saveShoppingItem(ShoppingItem item) async {
    final now = DateTime.now();
    final spec = syncEntity('shoppingItem');
    final existing = await (select(
      shoppingItemRecords,
    )..where((row) => row.id.equals(item.id))).getSingleOrNull();
    final before = existing == null ? null : spec.serialize(existing);
    var unit = item.unit;
    var packSize = item.packSize;
    var categoryId = item.categoryId;
    var icon = item.icon;
    var color = item.colorValue;
    if (item.homeItemId != null) {
      final linked = await (select(
        homeItemRecords,
      )..where((row) => row.id.equals(item.homeItemId!) & row.deletedAt.isNull())).getSingleOrNull();
      if (linked != null) {
        unit = linked.unit;
        packSize = linked.packSize;
        categoryId = linked.categoryId;
        icon = linked.icon;
        color = linked.color;
      }
    }
    final categoryName = await _homeCategoryName(categoryId, item.category);
    var position = item.position;
    if (existing == null) {
      final rows = await select(shoppingItemRecords).get();
      final highest = rows.isEmpty ? -1 : rows.map((row) => row.position).reduce((a, b) => a > b ? a : b);
      if (position <= 0) position = highest + 1;
    }
    await into(shoppingItemRecords).insertOnConflictUpdate(
      ShoppingItemRecordsCompanion(
        id: Value(item.id),
        contextId: Value(item.contextId),
        name: Value(item.name),
        quantity: Value(item.quantity),
        unit: Value(unit),
        packSize: Value(packSize),
        checked: Value(item.checked),
        note: Value(item.note),
        homeItemId: Value(item.homeItemId),
        catalogId: Value(item.catalogId),
        category: Value(categoryName),
        categoryId: Value(categoryId),
        icon: Value(icon),
        color: Value(color),
        position: Value(position),
        createdAt: Value(existing?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );
    await recordSyncAfter(spec, item.id, before: before);
  }

  /// Moves a line one slot up or down inside the unchecked part of the list.
  /// Positions are renumbered so repeated moves stay stable.
  Future<void> moveShoppingItem(String id, int delta) async {
    await transaction(() async {
      final rows = await (select(shoppingItemRecords)..where((row) => row.deletedAt.isNull())).get();
      final before = {for (final row in rows) row.id: syncEntity('shoppingItem').serialize(row)};
      final ordered = rows.toList()
        ..sort((a, b) {
          if (a.checked != b.checked) return a.checked ? 1 : -1;
          final byPosition = a.position.compareTo(b.position);
          if (byPosition != 0) return byPosition;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      final index = ordered.indexWhere((row) => row.id == id);
      if (index < 0) return;
      final target = index + delta;
      if (target < 0 || target >= ordered.length) return;
      final moved = ordered.removeAt(index);
      ordered.insert(target, moved);
      final now = DateTime.now();
      for (var i = 0; i < ordered.length; i++) {
        await (update(shoppingItemRecords)..where((row) => row.id.equals(ordered[i].id))).write(
          ShoppingItemRecordsCompanion(position: Value(i), updatedAt: Value(now)),
        );
      }
      for (final row in ordered) {
        await recordSyncAfter(syncEntity('shoppingItem'), row.id, before: before[row.id]);
      }
    });
  }

  Future<void> clearCheckedShopping({String? contextId}) async {
    final now = DateTime.now();
    final spec = syncEntity('shoppingItem');
    var predicate = shoppingItemRecords.checked.equals(true) & shoppingItemRecords.deletedAt.isNull();
    if (contextId != null) predicate = predicate & shoppingItemRecords.contextId.equals(contextId);
    final query = select(shoppingItemRecords)..where((row) => predicate);
    final rows = await query.get();
    final befores = {for (final row in rows) row.id: spec.serialize(row)};
    await (update(shoppingItemRecords)..where((row) => predicate)).write(
      ShoppingItemRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    for (final row in rows) {
      await recordSyncDelete(spec, row.id, lastRow: befores[row.id]);
    }
  }

  Future<void> deleteShoppingItem(String id) async {
    final now = DateTime.now();
    final spec = syncEntity('shoppingItem');
    final before = await readSyncRow(spec, id);
    await (update(shoppingItemRecords)..where((row) => row.id.equals(id))).write(
      ShoppingItemRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await recordSyncDelete(spec, id, lastRow: before);
  }

  /// Checking a linked shopping item updates the household quantity, the
  /// last-purchased time and the lightweight purchase history. Unchecking
  /// reverses the quantity that was actually purchased, even if the line was
  /// edited or relinked in the meantime.
  Future<void> setShoppingChecked(String id, bool checked) {
    return transaction(() async {
      final now = DateTime.now();
      final shoppingSpec = syncEntity('shoppingItem');
      final homeSpec = syncEntity('homeItem');
      final purchaseSpec = syncEntity('homePurchase');
      final row = await (select(shoppingItemRecords)..where((item) => item.id.equals(id))).getSingleOrNull();
      if (row == null || row.checked == checked) return;
      final shoppingBefore = shoppingSpec.serialize(row);

      if (checked) {
        final homeId = row.homeItemId;
        if (homeId != null) {
          final home = await (select(
            homeItemRecords,
          )..where((item) => item.id.equals(homeId) & item.deletedAt.isNull())).getSingleOrNull();
          if (home != null) {
            final homeBefore = homeSpec.serialize(home);
            final quantity = (home.quantity + row.quantity).clamp(0.0, double.infinity).toDouble();
            await (update(homeItemRecords)..where((item) => item.id.equals(homeId))).write(
              HomeItemRecordsCompanion(
                quantity: Value(quantity),
                lastPurchasedAt: Value(now),
                updatedAt: Value(now),
              ),
            );
            final purchaseId = const Uuid().v4();
            await into(homePurchaseRecords).insert(
              HomePurchaseRecordsCompanion.insert(
                id: purchaseId,
                homeItemId: homeId,
                shoppingItemId: Value(id),
                quantity: row.quantity,
                purchasedAt: now,
              ),
            );
            await recordSyncAfter(purchaseSpec, purchaseId);
            await recordSyncAfter(homeSpec, homeId, before: homeBefore);
          }
        }
      } else {
        final purchases = await (select(
          homePurchaseRecords,
        )..where((purchase) => purchase.shoppingItemId.equals(id))).get();
        final homeIds = {for (final purchase in purchases) purchase.homeItemId};
        final homeBefores = <String, Map<String, Object?>>{};
        for (final homeId in homeIds) {
          final home = await (select(
            homeItemRecords,
          )..where((item) => item.id.equals(homeId))).getSingleOrNull();
          if (home != null) homeBefores[homeId] = homeSpec.serialize(home);
        }
        for (final purchase in purchases) {
          final home = await (select(
            homeItemRecords,
          )..where((item) => item.id.equals(purchase.homeItemId))).getSingleOrNull();
          if (home != null) {
            final quantity = (home.quantity - purchase.quantity).clamp(0.0, double.infinity).toDouble();
            await (update(homeItemRecords)..where((item) => item.id.equals(home.id))).write(
              HomeItemRecordsCompanion(quantity: Value(quantity), updatedAt: Value(now)),
            );
          }
          await recordSyncDelete(purchaseSpec, purchase.id, lastRow: purchaseSpec.serialize(purchase));
          await (delete(homePurchaseRecords)..where((row) => row.id.equals(purchase.id))).go();
        }
        for (final homeId in homeIds) {
          await recordSyncAfter(homeSpec, homeId, before: homeBefores[homeId]);
        }
      }

      await (update(shoppingItemRecords)..where((item) => item.id.equals(id))).write(
        ShoppingItemRecordsCompanion(checked: Value(checked), updatedAt: Value(now)),
      );
      await recordSyncAfter(shoppingSpec, id, before: shoppingBefore);
    });
  }

  /// Applies a manual stock adjustment and keeps a purchase row for increases.
  Future<void> adjustHomeQuantity(String id, double delta, {String note = ''}) {
    return transaction(() async {
      final now = DateTime.now();
      final homeSpec = syncEntity('homeItem');
      final home = await (select(
        homeItemRecords,
      )..where((item) => item.id.equals(id) & item.deletedAt.isNull())).getSingleOrNull();
      if (home == null) return;
      final before = homeSpec.serialize(home);
      final quantity = (home.quantity + delta).clamp(0.0, double.infinity).toDouble();
      await (update(homeItemRecords)..where((item) => item.id.equals(id))).write(
        HomeItemRecordsCompanion(
          quantity: Value(quantity),
          lastPurchasedAt: Value(delta > 0 ? now : home.lastPurchasedAt),
          updatedAt: Value(now),
        ),
      );
      if (delta > 0) {
        final purchaseId = const Uuid().v4();
        await into(homePurchaseRecords).insert(
          HomePurchaseRecordsCompanion.insert(
            id: purchaseId,
            homeItemId: id,
            quantity: delta,
            note: Value(note),
            purchasedAt: now,
          ),
        );
        await recordSyncAfter(syncEntity('homePurchase'), purchaseId);
      }
      await recordSyncAfter(homeSpec, id, before: before);
    });
  }

  Future<List<HomePurchase>> readPurchaseHistory(String homeItemId, {int limit = 30}) async {
    final rows = await (select(homePurchaseRecords)..where((row) => row.homeItemId.equals(homeItemId))).get();
    final purchases = rows.map(_homePurchaseFromRow).toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
    return purchases.take(limit).toList();
  }

  Future<List<ShiftChecklistItem>> readShiftChecklistItems(String patternId) async {
    final rows = await (select(
      shiftChecklistItemRecords,
    )..where((row) => row.patternId.equals(patternId))).get();
    final items = rows.map(_checklistItemFromRow).toList()..sort((a, b) => a.position.compareTo(b.position));
    return items;
  }

  /// Live checklist items for a pattern. The Today and calendar views use this
  /// so an item added in the pattern editor appears without remounting them.
  Stream<List<ShiftChecklistItem>> watchShiftChecklistItems(String patternId) {
    final query = select(shiftChecklistItemRecords)..where((row) => row.patternId.equals(patternId));
    return query.watch().map((rows) {
      final items = rows.map(_checklistItemFromRow).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      return items;
    });
  }

  Future<void> saveShiftChecklistItems(
    String patternId,
    List<ShiftChecklistItem> items, {
    Set<String>? previousIds,
  }) {
    return transaction(() async {
      final spec = syncEntity('shiftChecklistItem');
      final completionSpec = syncEntity('shiftChecklistCompletion');
      final existing = await (select(
        shiftChecklistItemRecords,
      )..where((row) => row.patternId.equals(patternId))).get();
      final byId = {for (final row in existing) row.id: row};
      final keepIds = items.map((item) => item.id).toSet();
      final removed = [
        for (final row in existing)
          if (!keepIds.contains(row.id) && (previousIds == null || previousIds.contains(row.id))) row,
      ];
      for (final row in removed) {
        final completions = await (select(
          shiftChecklistCompletionRecords,
        )..where((item) => item.itemId.equals(row.id))).get();
        for (final completion in completions) {
          final before = completionSpec.serialize(completion);
          final key = completionSpec.rowKey({
            'item_id': completion.itemId,
            'date_key': completion.dateKey,
            'slot_key': completion.slotKey,
          });
          await recordSyncDelete(completionSpec, key, lastRow: before);
        }
        if (completions.isNotEmpty) {
          await (delete(shiftChecklistCompletionRecords)..where((item) => item.itemId.equals(row.id))).go();
        }
        final before = spec.serialize(row);
        await (delete(shiftChecklistItemRecords)..where((item) => item.id.equals(row.id))).go();
        await recordSyncDelete(spec, row.id, lastRow: before);
      }

      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final existingRow = byId[item.id];
        final before = existingRow == null ? null : spec.serialize(existingRow);
        if (existingRow != null) {
          await (update(shiftChecklistItemRecords)..where((row) => row.id.equals(item.id))).write(
            ShiftChecklistItemRecordsCompanion(
              label: Value(item.label),
              dayIndex: Value(item.dayIndex),
              position: Value(index),
            ),
          );
        } else {
          await into(shiftChecklistItemRecords).insert(
            ShiftChecklistItemRecordsCompanion(
              id: Value(item.id),
              patternId: Value(patternId),
              label: Value(item.label),
              dayIndex: Value(item.dayIndex),
              position: Value(index),
            ),
          );
        }
        final after = await readSyncRow(spec, item.id);
        if (after != null) {
          await recordSyncUpsert(spec, item.id, before: before, after: after);
        }
      }
    });
  }

  Future<Set<String>> readShiftChecklistCompletions(
    String patternId,
    LocalDate date, {
    required String slotKey,
  }) async {
    final itemRows = await (select(
      shiftChecklistItemRecords,
    )..where((row) => row.patternId.equals(patternId))).get();
    final itemIds = itemRows.map((row) => row.id).toList();
    if (itemIds.isEmpty) return <String>{};
    final rows =
        await (select(shiftChecklistCompletionRecords)..where(
              (row) =>
                  row.dateKey.equals(date.key) &
                  row.itemId.isIn(itemIds) &
                  (row.slotKey.equals(slotKey) | row.slotKey.equals('')),
            ))
            .get();
    return {for (final row in rows) row.itemId};
  }

  Future<void> setShiftChecklistCompleted(
    String itemId,
    LocalDate date, {
    required bool completed,
    required String slotKey,
  }) async {
    final spec = syncEntity('shiftChecklistCompletion');
    if (completed) {
      final key = spec.rowKey({'item_id': itemId, 'date_key': date.key, 'slot_key': slotKey});
      if (await readSyncRow(spec, key) != null) return;
      await into(shiftChecklistCompletionRecords).insert(
        ShiftChecklistCompletionRecordsCompanion.insert(
          itemId: itemId,
          dateKey: date.key,
          slotKey: Value(slotKey),
          createdAt: DateTime.now(),
        ),
      );
      await recordSyncAfter(spec, key);
      return;
    }
    final rows =
        await (select(shiftChecklistCompletionRecords)..where(
              (row) =>
                  row.itemId.equals(itemId) &
                  row.dateKey.equals(date.key) &
                  (row.slotKey.equals(slotKey) | row.slotKey.equals('')),
            ))
            .get();
    for (final row in rows) {
      final key = spec.rowKey({'item_id': row.itemId, 'date_key': row.dateKey, 'slot_key': row.slotKey});
      final before = spec.serialize(row);
      await (delete(shiftChecklistCompletionRecords)..where(
            (item) =>
                item.itemId.equals(row.itemId) &
                item.dateKey.equals(row.dateKey) &
                item.slotKey.equals(row.slotKey),
          ))
          .go();
      await recordSyncDelete(spec, key, lastRow: before);
    }
  }

  Future<LocalIdentity?> readIdentity() async {
    final row = await (select(identityRecords)..where((row) => row.id.equals(1))).getSingleOrNull();
    return row == null ? null : _identityFromRow(row);
  }

  Future<void> saveIdentity(LocalIdentity identity) async {
    await into(identityRecords).insertOnConflictUpdate(
      IdentityRecordsCompanion(
        id: const Value(1),
        deviceId: Value(identity.deviceId),
        deviceName: Value(identity.deviceName),
        username: Value(identity.username),
        pinSalt: Value(identity.pinSalt),
        pinHash: Value(identity.pinHash),
        certificatePem: Value(identity.certificatePem),
        privateKeyPem: Value(identity.privateKeyPem),
        mcpToken: Value(identity.mcpToken),
        createdAt: Value(identity.createdAt),
        updatedAt: Value(identity.updatedAt),
      ),
    );
  }

  Stream<List<PairedDevice>> watchPairedDevices() {
    final query = select(pairedDeviceRecords);
    return query.watch().map(
      (rows) =>
          rows.map(_pairedDeviceFromRow).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  Future<List<PairedDevice>> readPairedDevices() async {
    final rows = await select(pairedDeviceRecords).get();
    return rows.map(_pairedDeviceFromRow).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> savePairedDevice(PairedDevice device) async {
    await into(pairedDeviceRecords).insertOnConflictUpdate(
      PairedDeviceRecordsCompanion(
        id: Value(device.id),
        name: Value(device.name),
        username: Value(device.username),
        certificateFingerprint: Value(device.certificateFingerprint),
        sharedKey: Value(device.sharedKey),
        host: Value(device.host),
        port: Value(device.port),
        lastSeenAt: Value(device.lastSeenAt),
        createdAt: Value(device.createdAt),
        updatedAt: Value(device.updatedAt),
      ),
    );
  }

  Future<void> removePairedDevice(String id) async {
    await (delete(pairedDeviceRecords)..where((row) => row.id.equals(id))).go();
  }

  Future<void> updatePairedDevicePresence(
    String id, {
    required String host,
    required int port,
    required DateTime seenAt,
  }) async {
    await (update(pairedDeviceRecords)..where((row) => row.id.equals(id))).write(
      PairedDeviceRecordsCompanion(
        host: Value(host),
        port: Value(port),
        lastSeenAt: Value(seenAt),
        updatedAt: Value(seenAt),
      ),
    );
  }

  Stream<List<RemoteSnapshot>> watchRemoteSnapshots() {
    return select(remoteSnapshotRecords).watch().map((rows) {
      final snapshots = [for (final row in rows) _remoteSnapshotFromRow(row)]
        ..sort((a, b) => a.deviceName.toLowerCase().compareTo(b.deviceName.toLowerCase()));
      return snapshots;
    });
  }

  Future<List<RemoteSnapshot>> readRemoteSnapshots() async {
    final rows = await select(remoteSnapshotRecords).get();
    return [for (final row in rows) _remoteSnapshotFromRow(row)];
  }

  Future<void> saveRemoteSnapshot(RemoteSnapshot snapshot) async {
    await into(remoteSnapshotRecords).insertOnConflictUpdate(
      RemoteSnapshotRecordsCompanion(
        deviceId: Value(snapshot.deviceId),
        deviceName: Value(snapshot.deviceName),
        fetchedAt: Value(snapshot.fetchedAt),
        payloadJson: Value(jsonEncode(snapshot.payload)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> pruneRemoteSnapshots(Set<String> keepDeviceIds) async {
    final rows = await select(remoteSnapshotRecords).get();
    final stale = [
      for (final row in rows)
        if (!keepDeviceIds.contains(row.deviceId)) row.deviceId,
    ];
    if (stale.isEmpty) return;
    await (delete(remoteSnapshotRecords)..where((row) => row.deviceId.isIn(stale))).go();
  }

  Future<void> deleteRemoteSnapshot(String deviceId) async {
    await (delete(remoteSnapshotRecords)..where((row) => row.deviceId.equals(deviceId))).go();
  }

  /// Global search over entry titles and notes, tag names, and household item
  /// name, category, location and notes.
  Future<SearchResults> search(String query) async {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return const SearchResults(entries: [], homeItems: []);

    final matchingEntries =
        await (select(entryRecords)..where(
              (row) =>
                  row.deletedAt.isNull() &
                  (row.title.lower().contains(term) | row.notes.lower().contains(term)),
            ))
            .get();
    final matchingTags = await (select(
      tagRecords,
    )..where((row) => row.deletedAt.isNull() & row.name.lower().contains(term))).get();

    final entryIds = <String>{for (final row in matchingEntries) row.id};
    if (matchingTags.isNotEmpty) {
      final links = await (select(
        entryTagRecords,
      )..where((row) => row.tagId.isIn(matchingTags.map((tag) => tag.id).toList()))).get();
      entryIds.addAll(links.map((row) => row.entryId));
    }

    final entries = <Entry>[];
    if (entryIds.isNotEmpty) {
      final rows = await (select(
        entryRecords,
      )..where((row) => row.id.isIn(entryIds) & row.deletedAt.isNull())).get();
      final links = await (select(entryTagRecords)..where((row) => row.entryId.isIn(entryIds))).get();
      final tagIds = <String, Set<String>>{};
      for (final link in links) {
        (tagIds[link.entryId] ??= <String>{}).add(link.tagId);
      }
      entries.addAll(rows.map((row) => _entryFromRow(row, tagIds: tagIds[row.id] ?? const <String>{})));
      entries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }

    final homeRows =
        await (select(homeItemRecords)..where(
              (row) =>
                  row.deletedAt.isNull() &
                  (row.name.lower().contains(term) |
                      row.description.lower().contains(term) |
                      row.category.lower().contains(term) |
                      row.location.lower().contains(term) |
                      row.notes.lower().contains(term)),
            ))
            .get();
    final homeIds = homeRows.map((row) => row.id).toList();
    final homeLinks = homeIds.isEmpty
        ? const <HomeItemLocationRow>[]
        : await (select(homeItemLocationRecords)..where((row) => row.homeItemId.isIn(homeIds))).get();
    final homeLocationIds = <String, List<String>>{};
    for (final link in homeLinks) {
      (homeLocationIds[link.homeItemId] ??= <String>[]).add(link.locationId);
    }
    final homeItems =
        homeRows
            .map((row) => _homeItemFromRow(row, locationIds: homeLocationIds[row.id] ?? const <String>[]))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return SearchResults(entries: entries, homeItems: homeItems);
  }

  Future<bool> hasImportedEntry(String source, String externalId) async {
    final row = await (select(
      entryRecords,
    )..where((row) => row.source.equals(source) & row.externalId.equals(externalId))).getSingleOrNull();
    return row != null;
  }

  /// Whether a live entry already matches the identifying fields a CSV row can
  /// express. CSV has no stable ids, so matching user entries as well as
  /// earlier imports is what keeps a round-trip from duplicating the plan.
  Future<bool> hasEntryLike({
    required String title,
    required String spaceId,
    required LocalDate date,
    required bool allDay,
    required int? startMinute,
    required int? endMinute,
  }) async {
    final row =
        await (select(entryRecords)..where(
              (row) =>
                  row.deletedAt.isNull() &
                  row.title.equals(title) &
                  row.spaceId.equals(spaceId) &
                  row.dateKey.equals(date.key) &
                  row.allDay.equals(allDay) &
                  row.startMinute.equalsNullable(startMinute) &
                  row.endMinute.equalsNullable(endMinute),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<Entry?> readImportedEntry(String source, String externalId) async {
    final row = await (select(
      entryRecords,
    )..where((row) => row.source.equals(source) & row.externalId.equals(externalId))).getSingleOrNull();
    if (row == null) return null;
    final tags = await (select(entryTagRecords)..where((tag) => tag.entryId.equals(row.id))).get();
    return _entryFromRow(row, tagIds: {for (final tag in tags) tag.tagId});
  }

  /// Completes a maintenance task and moves its date forward from the day it
  /// was actually completed. Records the completion and a service log row.
  Future<LocalDate?> completeMaintenanceEntry(
    String id,
    LocalDate completionDate, {
    String note = '',
    int? durationMinutes,
    Entry? calendarEvent,
  }) async {
    final row = await (select(entryRecords)..where((entry) => entry.id.equals(id))).getSingleOrNull();
    final interval = row?.repeatAfterCompletionDays;
    if (row == null || row.readOnly || interval == null || interval <= 0) return null;
    final currentDate = row.dateKey == null ? null : LocalDate.fromKey(row.dateKey!);
    if (currentDate == null) return null;
    await stopTimeEntry(id);

    final now = DateTime.now();
    final nextDate = completionDate.addDays(interval);
    final performedAt = instantAt(completionDate, 12 * 60, row.timeZone ?? 'UTC');
    final endShift = row.endDateKey == null ? null : row.endDateKey! - row.dateKey!;
    DateTime? startAt;
    DateTime? endAt;
    if (!row.allDay && row.timeZone != null && row.startMinute != null && row.endMinute != null) {
      startAt = instantAt(nextDate, row.startMinute!, row.timeZone!);
      endAt = instantAt(nextDate, row.endMinute!, row.timeZone!);
    }

    await transaction(() async {
      final entrySpec = syncEntity('entry');
      final entryBefore = await readSyncRow(entrySpec, id);
      final completionSpec = syncEntity('completion');
      final completionKey = completionSpec.rowKey({'entry_id': id, 'date_key': completionDate.key});
      final existingCompletion = await readSyncRow(completionSpec, completionKey);
      if (existingCompletion == null) {
        await into(
          completionRecords,
        ).insert(CompletionRecordsCompanion.insert(entryId: id, dateKey: completionDate.key, createdAt: now));
        await recordSyncAfter(completionSpec, completionKey);
      }
      final logId = const Uuid().v4();
      await into(maintenanceLogRecords).insert(
        MaintenanceLogRecordsCompanion.insert(
          id: logId,
          entryId: id,
          performedDateKey: completionDate.key,
          nextDueDateKey: nextDate.key,
          note: Value(note),
          durationMinutes: Value(durationMinutes),
          createdAt: now,
        ),
      );
      await recordSyncAfter(syncEntity('maintenanceLog'), logId);
      await (update(entryRecords)..where((entry) => entry.id.equals(id))).write(
        EntryRecordsCompanion(
          dateKey: Value(nextDate.key),
          endDateKey: Value(endShift == null ? null : nextDate.addDays(endShift).key),
          startAt: Value(startAt),
          endAt: Value(endAt),
          lastCompletedAt: Value(performedAt),
          status: Value(EntryStatus.open.name),
          updatedAt: Value(now),
        ),
      );
      await recordSyncAfter(entrySpec, id, before: entryBefore);
      if (calendarEvent != null) {
        final eventBefore = await readSyncRow(entrySpec, calendarEvent.id);
        await into(entryRecords).insertOnConflictUpdate(_entryCompanion(calendarEvent));
        await recordSyncAfter(entrySpec, calendarEvent.id, before: eventBefore);
      }
    });
    return nextDate;
  }

  Stream<List<MaintenanceLog>> watchMaintenanceLogs(String entryId) {
    final query = select(maintenanceLogRecords)
      ..where((row) => row.entryId.equals(entryId))
      ..orderBy([(row) => OrderingTerm.desc(row.performedDateKey)]);
    return query.watch().map((rows) => rows.map(_maintenanceLogFromRow).toList());
  }

  /// Moves a gadget's next due date without recording a service. The wall-clock
  /// time and multi-day shape are preserved.
  Future<LocalDate?> rescheduleMaintenance(String entryId, LocalDate nextDue) async {
    final row = await (select(entryRecords)..where((entry) => entry.id.equals(entryId))).getSingleOrNull();
    if (row == null || row.readOnly || row.repeatAfterCompletionDays == null) return null;
    final endShift = row.endDateKey == null || row.dateKey == null ? null : row.endDateKey! - row.dateKey!;
    DateTime? startAt;
    DateTime? endAt;
    if (!row.allDay && row.timeZone != null && row.startMinute != null && row.endMinute != null) {
      startAt = instantAt(nextDue, row.startMinute!, row.timeZone!);
      endAt = instantAt(nextDue, row.endMinute!, row.timeZone!);
    }
    final spec = syncEntity('entry');
    final before = await readSyncRow(spec, entryId);
    await (update(entryRecords)..where((entry) => entry.id.equals(entryId))).write(
      EntryRecordsCompanion(
        dateKey: Value(nextDue.key),
        endDateKey: Value(endShift == null ? null : nextDue.addDays(endShift).key),
        startAt: Value(startAt),
        endAt: Value(endAt),
        status: Value(EntryStatus.open.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await recordSyncAfter(spec, entryId, before: before);
    return nextDue;
  }

  Future<void> setEntryStatus(String id, EntryStatus status) async {
    final existing = await (select(entryRecords)..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing?.readOnly == true) throw StateError('Imported entries are read-only');
    if (status == EntryStatus.done) await stopTimeEntry(id);
    final spec = syncEntity('entry');
    final before = existing == null ? null : spec.serialize(existing);
    final now = DateTime.now();
    await (update(entryRecords)..where((row) => row.id.equals(id))).write(
      EntryRecordsCompanion(
        status: Value(status.name),
        completedAt: Value(status == EntryStatus.done ? now.toUtc() : null),
        updatedAt: Value(now),
      ),
    );
    await recordSyncAfter(spec, id, before: before);
  }

  /// Deletes every user row and re-seeds the three spaces and default
  /// categories. Pairing identity is removed too; the caller must stop the
  /// network services afterwards. Managed image files and the content cache are
  /// removed after the database transaction commits.
  Future<void> clearAllData() async {
    final imagePaths = <String>{};
    await transaction(() async {
      for (final row in await select(contextRecords).get()) {
        final path = row.imagePath;
        if (path != null && path.isNotEmpty) imagePaths.add(path);
      }
      for (final row in await select(projectRecords).get()) {
        final path = row.imagePath;
        if (path != null && path.isNotEmpty) imagePaths.add(path);
      }
      // Draft-v9 builds kept gadgets in a side table. Remove any leftover so
      // delete-all never leaves household history behind.
      await customStatement('DROP TABLE IF EXISTS gadget_records');
      await delete(habitCompletionRecords).go();
      await delete(timeEntryRecords).go();
      await delete(completionRecords).go();
      await delete(reminderRecords).go();
      await delete(entryTagRecords).go();
      await delete(maintenanceLogRecords).go();
      await delete(entryRecords).go();
      await delete(shiftChecklistCompletionRecords).go();
      await delete(shiftChecklistItemRecords).go();
      await delete(shiftPatternTagRecords).go();
      await delete(shiftSlotRecords).go();
      await delete(shiftExceptionRecords).go();
      await delete(shiftPatternRecords).go();
      // Purchases reference both the shopping line they came from and the
      // inventory item, so they must go first.
      await delete(homePurchaseRecords).go();
      await delete(homeItemLocationRecords).go();
      await delete(shoppingItemRecords).go();
      await delete(homeItemRecords).go();
      await delete(homeCategoryRecords).go();
      await delete(homeLocationRecords).go();
      await delete(homeUnitRecords).go();
      await delete(projectRecords).go();
      await delete(habitRecords).go();
      await delete(contextRecords).go();
      await delete(tagRecords).go();
      await delete(settingRecords).go();
      await delete(mediaCacheRecords).go();
      await delete(remoteSnapshotRecords).go();
      await delete(syncChangeRecords).go();
      await delete(syncFieldVersionRecords).go();
      await delete(syncTombstoneRecords).go();
      await delete(syncPeerStateRecords).go();
      await delete(syncDeviceStateRecords).go();
      _syncHlcClock = null;
      await delete(pairedDeviceRecords).go();
      await delete(identityRecords).go();
      await seedDefaults();
    });
    await mediaStore.clearCacheIfConfigured();
    for (final path in imagePaths) {
      if (MediaStore.isCachePath(path)) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // A leftover display file is harmless after the plan was cleared.
      }
    }
  }

  Future<Entry?> readEntry(String id) async {
    final row = await (select(entryRecords)..where((entry) => entry.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final tags = await (select(entryTagRecords)..where((tag) => tag.entryId.equals(id))).get();
    return _entryFromRow(row, tagIds: {for (final tag in tags) tag.tagId});
  }

  /// Resolves tracked sessions whose entries are outside the visible range.
  Future<Map<String, Entry>> readEntriesByIds(Set<String> ids) async {
    if (ids.isEmpty) return const <String, Entry>{};
    final rows = await (select(entryRecords)..where((row) => row.id.isIn(ids))).get();
    if (rows.isEmpty) return const <String, Entry>{};
    final tagRows = await (select(entryTagRecords)..where((tag) => tag.entryId.isIn(ids))).get();
    final tags = <String, Set<String>>{};
    for (final tag in tagRows) {
      (tags[tag.entryId] ??= <String>{}).add(tag.tagId);
    }
    return {for (final row in rows) row.id: _entryFromRow(row, tagIds: tags[row.id] ?? const <String>{})};
  }

  Future<List<Reminder>> readRemindersForEntry(String entryId) async {
    final rows = await (select(reminderRecords)..where((row) => row.entryId.equals(entryId))).get();
    final reminders = rows.map(_reminderFromRow).toList()
      ..sort((a, b) => a.offsetMinutes.compareTo(b.offsetMinutes));
    return reminders;
  }

  Future<Map<String, List<Reminder>>> readAllReminders() async {
    final rows = await (select(reminderRecords)..where((row) => row.enabled.equals(true))).get();
    final byEntry = <String, List<Reminder>>{};
    for (final row in rows) {
      (byEntry[row.entryId] ??= <Reminder>[]).add(_reminderFromRow(row));
    }
    for (final reminders in byEntry.values) {
      reminders.sort((a, b) => a.offsetMinutes.compareTo(b.offsetMinutes));
    }
    return byEntry;
  }

  Future<void> saveRemindersForEntry(
    String entryId,
    List<Reminder> reminders, {
    Set<String>? removedReminderIds,
  }) {
    return transaction(() async {
      final spec = syncEntity('reminder');
      final idFor = {
        for (final reminder in reminders)
          reminder.id.isEmpty ? Reminder.idFor(entryId, reminder.offsetMinutes) : reminder.id: reminder,
      };
      final existing = await (select(reminderRecords)..where((row) => row.entryId.equals(entryId))).get();
      final existingById = {for (final row in existing) row.id: row};
      final toDelete = [
        for (final row in existing)
          if (!idFor.containsKey(row.id) &&
              (removedReminderIds == null || removedReminderIds.contains(row.id)))
            row,
      ];
      for (final row in toDelete) {
        final before = spec.serialize(row);
        await (delete(reminderRecords)..where((item) => item.id.equals(row.id))).go();
        await recordSyncDelete(spec, row.id, lastRow: before);
      }

      for (final entry in idFor.entries) {
        final id = entry.key;
        final reminder = entry.value;
        final existingRow = existingById[id];
        final before = existingRow == null ? null : spec.serialize(existingRow);
        await into(reminderRecords).insertOnConflictUpdate(
          ReminderRecordsCompanion(
            id: Value(id),
            entryId: Value(entryId),
            offsetMinutes: Value(reminder.offsetMinutes),
            timeMinute: Value(reminder.timeMinute),
            enabled: Value(reminder.enabled),
          ),
        );
        final after = await readSyncRow(spec, id);
        if (after != null) await recordSyncUpsert(spec, id, before: before, after: after);
      }
    });
  }

  /// Marks one occurrence of a recurring entry done without touching the
  /// others. Used by daily chores and shift checklists.
  Future<void> setOccurrenceCompleted(String entryId, LocalDate date, {required bool completed}) async {
    final existing = await (select(entryRecords)..where((row) => row.id.equals(entryId))).getSingleOrNull();
    if (existing?.readOnly == true) throw StateError('Imported entries are read-only');
    final spec = syncEntity('completion');
    final key = spec.rowKey({'entry_id': entryId, 'date_key': date.key});
    final existingCompletion = await readSyncRow(spec, key);
    if (completed) {
      if (existingCompletion != null) return;
      await stopTimeEntry(entryId, occurrenceDateKey: date.key);
      await into(completionRecords).insert(
        CompletionRecordsCompanion.insert(entryId: entryId, dateKey: date.key, createdAt: DateTime.now()),
      );
      await recordSyncAfter(spec, key);
      return;
    }

    if (existingCompletion == null) return;
    await (delete(
      completionRecords,
    )..where((row) => row.entryId.equals(entryId) & row.dateKey.equals(date.key))).go();
    await recordSyncDelete(spec, key, lastRow: existingCompletion);
  }

  Future<void> softDeleteEntry(String id) async {
    final existing = await (select(entryRecords)..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing?.readOnly == true) throw StateError('Imported entries are read-only');
    final spec = syncEntity('entry');
    final before = existing == null ? null : spec.serialize(existing);
    final now = DateTime.now();
    await (update(entryRecords)..where((row) => row.id.equals(id))).write(
      EntryRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await recordSyncDelete(spec, id, lastRow: before);
  }

  Future<void> saveShiftPattern(ShiftPattern pattern, {ShiftPattern? previous}) {
    if (pattern.spaceId != 'work') {
      throw ArgumentError.value(pattern.spaceId, 'spaceId', 'Shifts belong to the Work space');
    }
    return transaction(() async {
      final now = DateTime.now();
      final spec = syncEntity('shiftPattern');
      final existing = await (select(
        shiftPatternRecords,
      )..where((row) => row.id.equals(pattern.id))).getSingleOrNull();
      final before = existing == null ? null : spec.serialize(existing);
      await into(shiftPatternRecords).insertOnConflictUpdate(
        ShiftPatternRecordsCompanion(
          id: Value(pattern.id),
          spaceId: Value(pattern.spaceId),
          name: Value(pattern.name),
          contextId: Value(pattern.contextId),
          timeZone: Value(pattern.timeZone),
          cycleDays: Value(pattern.cycleDays),
          anchorDateKey: Value(pattern.anchorDate.key),
          commuteMinutes: Value(pattern.commuteMinutes),
          windDownMinutes: Value(pattern.windDownMinutes),
          enabled: Value(pattern.enabled),
          createdAt: Value(existing?.createdAt ?? now),
          updatedAt: Value(now),
        ),
      );
      final after = await readSyncRow(spec, pattern.id);
      if (after != null) {
        await recordSyncUpsert(spec, pattern.id, before: before, after: after);
      }

      await saveShiftSlots(
        pattern.id,
        pattern.slots,
        previousIds: _previousShiftChildIds(
          previous?.slots.map((slot) => slot.syncId),
          previous?.slots.length ?? 0,
        ),
      );
      await saveShiftExceptions(
        pattern.id,
        pattern.exceptions,
        previousIds: _previousShiftChildIds(
          previous?.exceptions.map((exception) => exception.syncId),
          previous?.exceptions.length ?? 0,
        ),
      );
      await saveShiftPatternTags(pattern.id, pattern.tagIds, previousIds: previous?.tagIds);
    });
  }

  /// Names the shift child rows the caller knew about, or null for the legacy
  /// replace-all path. A caller holding a pattern from before sync ids existed
  /// cannot identify its rows, so keeping them would leave stale children.
  Set<String>? _previousShiftChildIds(Iterable<String>? syncIds, int count) {
    if (syncIds == null) return null;
    final ids = {
      for (final id in syncIds)
        if (id.isNotEmpty) id,
    };
    if (ids.isEmpty && count > 0) return null;
    return ids;
  }

  /// Replaces every exception on [date] for [patternId] with [exception].
  ///
  /// A null [exception] removes the override and lets the pattern's own slots
  /// decide again. Slots, tags and checklist items are left untouched, so a
  /// per-day edit never rewrites the pattern itself.
  Future<void> setShiftDayOverride(String patternId, LocalDate date, ShiftException? exception) {
    return transaction(() async {
      final now = DateTime.now();
      await (update(
        shiftPatternRecords,
      )..where((row) => row.id.equals(patternId))).write(ShiftPatternRecordsCompanion(updatedAt: Value(now)));

      final spec = syncEntity('shiftException');
      final existing = await (select(
        shiftExceptionRecords,
      )..where((row) => row.patternId.equals(patternId) & row.dateKey.equals(date.key))).get();
      for (final row in existing) {
        final before = spec.serialize(row);
        await (delete(shiftExceptionRecords)..where((item) => item.id.equals(row.id))).go();
        await recordSyncDelete(spec, row.syncId, lastRow: before);
      }
      if (exception == null) return;

      // The day sheet's action is one row per pattern and date, so concurrent
      // edits of the same day resolve by HLC instead of creating duplicates.
      final syncId = exception.syncId.isNotEmpty ? exception.syncId : 'day:$patternId:${date.key}';
      await into(shiftExceptionRecords).insert(
        ShiftExceptionRecordsCompanion.insert(
          syncId: Value(syncId),
          patternId: patternId,
          dateKey: date.key,
          type: exception.type.name,
          startMinute: Value(exception.startMinute),
          endMinute: Value(exception.endMinute),
          note: Value(exception.note),
        ),
      );
      final after = await readSyncRow(spec, syncId);
      if (after != null) await recordSyncUpsert(spec, syncId, after: after);
    });
  }

  Future<void> softDeleteShiftPattern(String id) async {
    final spec = syncEntity('shiftPattern');
    final before = await readSyncRow(spec, id);
    final now = DateTime.now();
    await (update(shiftPatternRecords)..where((row) => row.id.equals(id))).write(
      ShiftPatternRecordsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
    await recordSyncDelete(spec, id, lastRow: before);
  }

  List<ShiftPattern> _patternsFromRows(Iterable<TypedResult> rows) {
    final patternRows = <String, ShiftPatternRow>{};
    final slots = <String, Map<int, ShiftSlot>>{};
    final exceptions = <String, Map<int, ShiftException>>{};
    final tagIds = <String, Set<String>>{};

    for (final row in rows) {
      final patternRow = row.readTable(shiftPatternRecords);
      patternRows[patternRow.id] = patternRow;

      final tagRow = row.readTableOrNull(shiftPatternTagRecords);
      if (tagRow != null) {
        (tagIds[patternRow.id] ??= <String>{}).add(tagRow.tagId);
      }

      final slotRow = row.readTableOrNull(shiftSlotRecords);
      if (slotRow != null) {
        (slots[patternRow.id] ??= <int, ShiftSlot>{})[slotRow.id] = ShiftSlot(
          syncId: slotRow.syncId,
          dayIndex: slotRow.dayIndex,
          label: slotRow.label,
          startMinute: slotRow.startMinute,
          endMinute: slotRow.endMinute,
        );
      }

      final exceptionRow = row.readTableOrNull(shiftExceptionRecords);
      if (exceptionRow != null) {
        (exceptions[patternRow.id] ??= <int, ShiftException>{})[exceptionRow.id] = ShiftException(
          syncId: exceptionRow.syncId,
          date: LocalDate.fromKey(exceptionRow.dateKey),
          type: ShiftExceptionType.values.byName(exceptionRow.type),
          startMinute: exceptionRow.startMinute,
          endMinute: exceptionRow.endMinute,
          note: exceptionRow.note,
        );
      }
    }

    return [
      for (final row in patternRows.values)
        _patternFromRow(
          row,
          slots[row.id]?.values.toList() ?? const <ShiftSlot>[],
          exceptions[row.id]?.values.toList() ?? const <ShiftException>[],
          tagIds[row.id] ?? const <String>{},
        ),
    ];
  }

  Future<void> _migrateToV2(Migrator m) async {
    final safeZone = isKnownTimeZone(defaultTimeZone) ? defaultTimeZone : 'UTC';

    // The old one-slot JSON has to be read before alterTable drops the column.
    final legacyPatterns = await customSelect('SELECT id, slots_json FROM shift_pattern_records').get();

    await m.addColumn(entryRecords, entryRecords.timeZone);
    await m.addColumn(entryRecords, entryRecords.startAt);
    await m.addColumn(entryRecords, entryRecords.endAt);
    await m.createTable(shiftSlotRecords);
    await m.createTable(shiftExceptionRecords);
    await m.addColumn(shiftPatternRecords, shiftPatternRecords.timeZone);

    await update(shiftPatternRecords).write(ShiftPatternRecordsCompanion(timeZone: Value(safeZone)));

    final patternColumns = await customSelect('PRAGMA table_info(shift_pattern_records)').get();
    final hasLegacySlots = patternColumns.any((row) => row.read<String>('name') == 'slots_json');

    for (final row in legacyPatterns) {
      final patternId = row.read<String>('id');
      final raw = row.readNullable<String>('slots_json');
      if (raw == null || raw.isEmpty) continue;
      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;

      for (final value in decoded) {
        if (value is! Map) continue;
        final ShiftSlot slot;
        try {
          slot = ShiftSlot.fromJson(Map<String, Object?>.from(value));
        } on FormatException {
          // One malformed legacy slot must not make the whole plan unopenable.
          continue;
        }
        await into(shiftSlotRecords).insert(
          ShiftSlotRecordsCompanion.insert(
            patternId: patternId,
            dayIndex: slot.dayIndex,
            label: Value(slot.label),
            startMinute: slot.startMinute,
            endMinute: slot.endMinute,
          ),
        );
      }
    }

    if (hasLegacySlots) {
      await customStatement('ALTER TABLE shift_pattern_records DROP COLUMN slots_json');
    }

    final legacyEntries = await select(entryRecords).get();
    for (final row in legacyEntries) {
      final date = row.dateKey == null ? null : LocalDate.fromKey(row.dateKey!);
      final startMinute = row.startMinute;
      if (row.allDay || date == null || startMinute == null) {
        if (!row.allDay && date != null && startMinute == null) {
          await (update(entryRecords)..where((entry) => entry.id.equals(row.id))).write(
            const EntryRecordsCompanion(allDay: Value(true)),
          );
        }
        continue;
      }

      final endMinute = row.endMinute == null || row.endMinute! <= startMinute
          ? startMinute + 60
          : row.endMinute!;
      await (update(entryRecords)..where((entry) => entry.id.equals(row.id))).write(
        EntryRecordsCompanion(
          timeZone: Value(safeZone),
          startAt: Value(instantAt(date, startMinute, safeZone)),
          endAt: Value(instantAt(date, endMinute, safeZone)),
        ),
      );
    }

    final personal = await (select(
      spaceRecords,
    )..where((row) => row.id.equals('personal'))).getSingleOrNull();
    if (personal == null) {
      final now = DateTime.now();
      await into(spaceRecords).insert(
        SpaceRecordsCompanion.insert(
          id: 'personal',
          name: 'Personal',
          color: 0xFFB07D5C,
          position: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await (update(
      spaceRecords,
    )..where((row) => row.id.equals('work'))).write(const SpaceRecordsCompanion(position: Value(1)));
    await (update(
      spaceRecords,
    )..where((row) => row.id.equals('home'))).write(const SpaceRecordsCompanion(position: Value(2)));
  }

  Future<void> _migrateToV3(Migrator m) async {
    await m.createTable(tagRecords);
    await m.createTable(entryTagRecords);
  }

  Future<void> _migrateToV4(Migrator m) async {
    await m.createTable(shiftChecklistItemRecords);
    await m.createTable(shiftChecklistCompletionRecords);
    await m.createTable(homeItemRecords);
    await m.createTable(shoppingItemRecords);
  }

  Future<void> _migrateToV5(Migrator m) async {
    await m.createTable(identityRecords);
    await m.createTable(pairedDeviceRecords);
  }

  Future<void> _migrateToV6(Migrator m) async {
    final patternColumns = await customSelect('PRAGMA table_info(shift_pattern_records)').get();
    final patternNames = patternColumns.map((row) => row.read<String>('name')).toSet();
    if (!patternNames.contains('commute_minutes')) {
      await m.addColumn(shiftPatternRecords, shiftPatternRecords.commuteMinutes);
    }
    if (!patternNames.contains('wind_down_minutes')) {
      await m.addColumn(shiftPatternRecords, shiftPatternRecords.windDownMinutes);
    }

    final tables = await customSelect('SELECT name FROM sqlite_master WHERE type = \'table\'').get();
    final tableNames = tables.map((row) => row.read<String>('name')).toSet();
    if (!tableNames.contains('shift_pattern_tag_records')) {
      await m.createTable(shiftPatternTagRecords);
    }

    final completionColumns = await customSelect(
      'PRAGMA table_info(shift_checklist_completion_records)',
    ).get();
    final completionNames = completionColumns.map((row) => row.read<String>('name')).toSet();
    if (!completionNames.contains('slot_key')) {
      await customStatement('ALTER TABLE shift_checklist_completion_records RENAME TO _completion_v5');
      await customStatement('''
        CREATE TABLE "shift_checklist_completion_records" (
          "item_id" TEXT NOT NULL REFERENCES shift_checklist_item_records (id),
          "date_key" INTEGER NOT NULL,
          "slot_key" TEXT NOT NULL DEFAULT '',
          "created_at" INTEGER NOT NULL,
          PRIMARY KEY ("item_id", "date_key", "slot_key")
        )
      ''');
      await customStatement('''
        INSERT INTO shift_checklist_completion_records (item_id, date_key, slot_key, created_at)
        SELECT item_id, date_key, '', created_at FROM _completion_v5
      ''');
      await customStatement('DROP TABLE _completion_v5');
    }

    await _backfillShiftChecklistSlotKeys();
  }

  /// Existing completions were keyed by pattern + date. Assign them to the
  /// first slot of that date so a single-slot history survives the v6 key.
  Future<void> _backfillShiftChecklistSlotKeys() async {
    final legacy = await customSelect(
      "SELECT item_id, date_key FROM shift_checklist_completion_records WHERE slot_key = ''",
    ).get();
    if (legacy.isEmpty) return;

    final patterns = <String, ShiftPattern?>{};
    for (final row in legacy) {
      final itemId = row.read<String>('item_id');
      final dateKey = row.read<int>('date_key');
      final item = await (select(
        shiftChecklistItemRecords,
      )..where((table) => table.id.equals(itemId))).getSingleOrNull();
      if (item == null) continue;
      final pattern = patterns.putIfAbsent(item.patternId, () => null);
      if (pattern == null && !patterns.containsKey(item.patternId)) {
        patterns[item.patternId] = await _loadPattern(item.patternId);
      }
      final resolved = patterns[item.patternId] ?? await _loadPattern(item.patternId);
      patterns[item.patternId] = resolved;
      if (resolved == null) continue;
      final slots = resolved.slotsFor(LocalDate.fromKey(dateKey));
      if (slots.isEmpty) continue;
      await customUpdate(
        'UPDATE shift_checklist_completion_records SET slot_key = ? '
        'WHERE item_id = ? AND date_key = ? AND slot_key = \'\'',
        variables: [
          Variable.withString(slots.first.key),
          Variable.withString(itemId),
          Variable.withInt(dateKey),
        ],
        updates: {shiftChecklistCompletionRecords},
      );
    }
  }

  /// v7 adds manual shopping order and the lightweight purchase history.
  Future<void> _migrateToV7(Migrator m) async {
    final shoppingColumns = await customSelect('PRAGMA table_info(shopping_item_records)').get();
    final shoppingNames = shoppingColumns.map((row) => row.read<String>('name')).toSet();
    if (!shoppingNames.contains('position')) {
      await m.addColumn(shoppingItemRecords, shoppingItemRecords.position);
    }

    final tables = await customSelect('SELECT name FROM sqlite_master WHERE type = \'table\'').get();
    final tableNames = tables.map((row) => row.read<String>('name')).toSet();
    if (!tableNames.contains('home_purchase_records')) {
      await m.createTable(homePurchaseRecords);
    }
  }

  /// v8 adds absolute reminder times and persistent read-only LAN snapshots.
  Future<void> _migrateToV8(Migrator m) async {
    final reminderColumns = await customSelect('PRAGMA table_info(reminder_records)').get();
    final reminderNames = reminderColumns.map((row) => row.read<String>('name')).toSet();
    if (!reminderNames.contains('time_minute')) {
      await m.addColumn(reminderRecords, reminderRecords.timeMinute);
    }

    final tables = await customSelect('SELECT name FROM sqlite_master WHERE type = \'table\'').get();
    final tableNames = tables.map((row) => row.read<String>('name')).toSet();
    if (!tableNames.contains('remote_snapshot_records')) {
      await m.createTable(remoteSnapshotRecords);
    }
  }

  /// v9 adds contexts, projects, habits, tracked time and per-day checklists.
  Future<void> _migrateToV9(Migrator m) async {
    final tables = await customSelect('SELECT name FROM sqlite_master WHERE type = \'table\'').get();
    final tableNames = tables.map((row) => row.read<String>('name')).toSet();

    if (!tableNames.contains('context_records')) await m.createTable(contextRecords);
    if (!tableNames.contains('project_records')) await m.createTable(projectRecords);
    if (!tableNames.contains('habit_records')) await m.createTable(habitRecords);
    if (!tableNames.contains('habit_completion_records')) await m.createTable(habitCompletionRecords);
    if (!tableNames.contains('time_entry_records')) await m.createTable(timeEntryRecords);

    final entryColumns = await customSelect('PRAGMA table_info(entry_records)').get();
    final entryNames = entryColumns.map((row) => row.read<String>('name')).toSet();
    if (!entryNames.contains('context_id')) await m.addColumn(entryRecords, entryRecords.contextId);
    if (!entryNames.contains('project_id')) await m.addColumn(entryRecords, entryRecords.projectId);
    if (!entryNames.contains('priority')) await m.addColumn(entryRecords, entryRecords.priority);
    if (!entryNames.contains('completed_at')) await m.addColumn(entryRecords, entryRecords.completedAt);

    final checklistColumns = await customSelect('PRAGMA table_info(shift_checklist_item_records)').get();
    final checklistNames = checklistColumns.map((row) => row.read<String>('name')).toSet();
    if (tableNames.contains('shift_checklist_item_records') && !checklistNames.contains('day_index')) {
      await m.addColumn(shiftChecklistItemRecords, shiftChecklistItemRecords.dayIndex);
    }

    final homeColumns = await customSelect('PRAGMA table_info(home_item_records)').get();
    if (tableNames.contains('home_item_records') &&
        !homeColumns.any((row) => row.read<String>('name') == 'context_id')) {
      await m.addColumn(homeItemRecords, homeItemRecords.contextId);
    }

    final shoppingColumns = await customSelect('PRAGMA table_info(shopping_item_records)').get();
    if (tableNames.contains('shopping_item_records') &&
        !shoppingColumns.any((row) => row.read<String>('name') == 'context_id')) {
      await m.addColumn(shoppingItemRecords, shoppingItemRecords.contextId);
    }

    final patternColumns = await customSelect('PRAGMA table_info(shift_pattern_records)').get();
    if (!patternColumns.any((row) => row.read<String>('name') == 'context_id')) {
      await m.addColumn(shiftPatternRecords, shiftPatternRecords.contextId);
    }

    final tagColumns = await customSelect('PRAGMA table_info(tag_records)').get();
    if (tableNames.contains('tag_records') && !tagColumns.any((row) => row.read<String>('name') == 'icon')) {
      await m.addColumn(tagRecords, tagRecords.icon);
    }
  }

  /// The first v9 build shipped `space_unit_records`, `task_session_records`,
  /// `habit_check_records` and `gadget_records`, and stored priorities as
  /// integers. The final model renamed those tables without bumping the
  /// schema, so a database written by that build still reports v9 while missing
  /// `context_records`, `time_entry_records` and the shipped entry columns.
  /// This step maps the draft shape onto the final one and is a no-op for
  /// databases that already have it.
  Future<void> _migrateToV10(Migrator m) async {
    Future<Set<String>> tables() async => (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();

    Future<Set<String>> columnsOf(String table) async => (await customSelect(
      'PRAGMA table_info($table)',
    ).get()).map((row) => row.read<String>('name')).toSet();

    var tableNames = await tables();

    // Contexts were called space units. Keep every row, including the seeded
    // personal/work/home units and any job or home the user added.
    if (tableNames.contains('space_unit_records')) {
      if (!tableNames.contains('context_records')) {
        await customStatement('ALTER TABLE space_unit_records RENAME TO context_records');
      } else {
        await customStatement(
          'INSERT OR IGNORE INTO context_records '
          '(id, space_id, name, description, color, icon, image_path, position, created_at, updated_at, deleted_at) '
          "SELECT id, space_id, name, '', color, icon, image_path, position, created_at, updated_at, deleted_at "
          'FROM space_unit_records',
        );
      }
      tableNames = await tables();
    }
    if (tableNames.contains('context_records')) {
      final contextColumns = await columnsOf('context_records');
      if (!contextColumns.contains('description')) {
        await m.addColumn(contextRecords, contextRecords.description);
      }
      // The draft table carried NOT NULL columns the shipped model never
      // writes. Rebuild it so new contexts can be inserted after migration.
      if (contextColumns.contains('kind')) {
        await m.alterTable(TableMigration(contextRecords));
        tableNames = await tables();
      }
    }

    if (tableNames.contains('habit_check_records') && !tableNames.contains('habit_completion_records')) {
      await customStatement('ALTER TABLE habit_check_records RENAME TO habit_completion_records');
      tableNames = await tables();
    }

    if (tableNames.contains('task_session_records') && !tableNames.contains('time_entry_records')) {
      await customStatement('ALTER TABLE task_session_records RENAME TO time_entry_records');
      tableNames = await tables();
    }
    if (tableNames.contains('time_entry_records')) {
      final timeColumns = await columnsOf('time_entry_records');
      if (!timeColumns.contains('occurrence_date_key')) {
        await m.addColumn(timeEntryRecords, timeEntryRecords.occurrenceDateKey);
      }
      // The draft session table kept a NOT NULL updated_at that the shipped
      // model does not write. Rebuild it instead of leaving inserts broken.
      if (timeColumns.contains('updated_at')) {
        await m.alterTable(TableMigration(timeEntryRecords));
        tableNames = await tables();
      }
    }

    if (tableNames.contains('project_records')) {
      final projectColumns = await columnsOf('project_records');
      if (projectColumns.contains('space_unit_id')) {
        await m.alterTable(
          TableMigration(
            projectRecords,
            newColumns: [projectRecords.contextId],
            columnTransformer: {projectRecords.contextId: const CustomExpression<String>('space_unit_id')},
          ),
        );
      } else if (!projectColumns.contains('context_id')) {
        await m.addColumn(projectRecords, projectRecords.contextId);
      }
    }

    if (tableNames.contains('entry_records')) {
      final entryColumns = await columnsOf('entry_records');
      final draft =
          entryColumns.contains('space_unit_id') ||
          entryColumns.contains('estimated_minutes') ||
          entryColumns.contains('sort_order');
      if (draft) {
        await m.alterTable(
          TableMigration(
            entryRecords,
            newColumns: [
              if (!entryColumns.contains('context_id')) entryRecords.contextId,
              if (!entryColumns.contains('completed_at')) entryRecords.completedAt,
            ],
            columnTransformer: {
              if (entryColumns.contains('space_unit_id'))
                entryRecords.contextId: const CustomExpression<String>('space_unit_id'),
              entryRecords.priority: const CustomExpression<String>(
                "CASE priority WHEN 1 THEN 'low' WHEN 2 THEN 'medium' WHEN 3 THEN 'high' ELSE 'none' END",
              ),
            },
          ),
        );
      } else if (!entryColumns.contains('context_id')) {
        await m.addColumn(entryRecords, entryRecords.contextId);
      }
    }

    if (tableNames.contains('habit_records')) {
      final habitColumns = await columnsOf('habit_records');
      if (habitColumns.contains('space_unit_id')) {
        await m.alterTable(
          TableMigration(
            habitRecords,
            newColumns: [
              if (!habitColumns.contains('space_id')) habitRecords.spaceId,
              habitRecords.contextId,
              if (!habitColumns.contains('description')) habitRecords.description,
              if (!habitColumns.contains('target_per_week')) habitRecords.targetPerWeek,
              if (!habitColumns.contains('position')) habitRecords.position,
              if (!habitColumns.contains('archived')) habitRecords.archived,
            ],
            columnTransformer: {
              habitRecords.spaceId: const CustomExpression<String>(
                'COALESCE((SELECT u.space_id FROM context_records u '
                "WHERE u.id = habit_records.space_unit_id), 'personal')",
              ),
              habitRecords.contextId: const CustomExpression<String>('space_unit_id'),
            },
          ),
        );
      }
    }

    // Jobs on shift patterns and homes on inventory rows kept their data but
    // moved to the shared context table.
    if (tableNames.contains('shift_pattern_records')) {
      final patternColumns = await columnsOf('shift_pattern_records');
      if (!patternColumns.contains('context_id')) {
        await m.addColumn(shiftPatternRecords, shiftPatternRecords.contextId);
      }
      if (patternColumns.contains('space_unit_id')) {
        await customStatement(
          'UPDATE shift_pattern_records SET context_id = space_unit_id WHERE context_id IS NULL',
        );
      }
      // Shifts are a Work concept. Legacy Home/Personal patterns are repaired
      // into Work instead of disappearing from the calendar.
      await customStatement("UPDATE shift_pattern_records SET space_id = 'work' WHERE space_id != 'work'");
    }

    if (tableNames.contains('home_item_records')) {
      final itemColumns = await columnsOf('home_item_records');
      if (!itemColumns.contains('context_id')) {
        await m.addColumn(homeItemRecords, homeItemRecords.contextId);
      }
      if (itemColumns.contains('space_unit_id')) {
        await customStatement(
          'UPDATE home_item_records SET context_id = space_unit_id WHERE context_id IS NULL',
        );
      }
    }

    if (tableNames.contains('shopping_item_records')) {
      final itemColumns = await columnsOf('shopping_item_records');
      if (!itemColumns.contains('context_id')) {
        await m.addColumn(shoppingItemRecords, shoppingItemRecords.contextId);
      }
      if (itemColumns.contains('space_unit_id')) {
        await customStatement(
          'UPDATE shopping_item_records SET context_id = space_unit_id WHERE context_id IS NULL',
        );
      }
    }

    // Draft gadgets are Home maintenance tasks in the shipped model. Convert
    // each row once, then drop the draft table so no untracked household data
    // survives a delete-all.
    if (tableNames.contains('gadget_records')) {
      final gadgetColumns = await columnsOf('gadget_records');
      final gadgets = await customSelect('SELECT * FROM gadget_records').get();
      for (final row in gadgets) {
        final gadgetId = row.read<String>('id');
        final migrated = await customSelect(
          "SELECT 1 AS found FROM entry_records WHERE source = 'legacy-gadget' AND external_id = ?",
          variables: [Variable.withString(gadgetId)],
        ).getSingleOrNull();
        if (migrated != null) continue;

        final intervalDays = row.read<int>('interval_days');
        final interval = intervalDays <= 0 ? 1 : intervalDays;
        final lastServiced = gadgetColumns.contains('last_serviced_at')
            ? row.readNullable<int>('last_serviced_at')
            : null;
        final createdAt = row.read<int>('created_at');
        final updatedAt = row.read<int>('updated_at');
        final deletedAt = gadgetColumns.contains('deleted_at') ? row.readNullable<int>('deleted_at') : null;
        final base = DateTime.fromMillisecondsSinceEpoch((lastServiced ?? createdAt) * 1000, isUtc: true);
        final due = LocalDate.fromDateTime(base).addDays(interval);

        // Gadgets belong to Home units only. A draft gadget filed under a
        // Work or Personal unit keeps its data but loses that context, because
        // no shipped screen would otherwise show it.
        String? contextId;
        final unitId = gadgetColumns.contains('space_unit_id')
            ? row.readNullable<String>('space_unit_id')
            : null;
        if (unitId != null) {
          final unit = await customSelect(
            'SELECT space_id FROM context_records WHERE id = ?',
            variables: [Variable.withString(unitId)],
          ).getSingleOrNull();
          if (unit?.read<String>('space_id') == 'home') contextId = unitId;
        }

        await customStatement(
          'INSERT INTO entry_records '
          '(id, space_id, title, notes, kind, date_key, context_id, priority, all_day, status, '
          'source, external_id, read_only, last_completed_at, repeat_after_completion_days, '
          'created_at, updated_at, deleted_at) '
          "VALUES (?, 'home', ?, ?, 'task', ?, ?, 'none', 1, 'open', 'legacy-gadget', ?, 0, ?, ?, ?, ?, ?)",
          [
            'gadget-$gadgetId',
            row.read<String>('name'),
            gadgetColumns.contains('notes') ? row.read<String>('notes') : '',
            due.key,
            contextId,
            gadgetId,
            lastServiced,
            interval,
            createdAt,
            updatedAt,
            deletedAt,
          ],
        );
      }
      await customStatement('DROP TABLE gadget_records');
      tableNames = await tables();
    }
  }

  Future<ShiftPattern?> _loadPattern(String id) async {
    final row = await (select(shiftPatternRecords)..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final slotRows = await (select(shiftSlotRecords)..where((table) => table.patternId.equals(id))).get();
    final exceptionRows = await (select(
      shiftExceptionRecords,
    )..where((table) => table.patternId.equals(id))).get();
    return _patternFromRow(
      row,
      [
        for (final slot in slotRows)
          ShiftSlot(
            dayIndex: slot.dayIndex,
            label: slot.label,
            startMinute: slot.startMinute,
            endMinute: slot.endMinute,
          ),
      ],
      [
        for (final exception in exceptionRows)
          ShiftException(
            date: LocalDate.fromKey(exception.dateKey),
            type: ShiftExceptionType.values.byName(exception.type),
            startMinute: exception.startMinute,
            endMinute: exception.endMinute,
            note: exception.note,
          ),
      ],
      const <String>{},
    );
  }

  /// Habit weekday schedules were added after v10. Existing habits keep every
  /// day until the user narrows them.
  Future<void> _migrateToV11(Migrator m) async {
    final columns = await customSelect('PRAGMA table_info(habit_records)').get();
    if (!columns.any((row) => row.read<String>('name') == 'weekdays')) {
      await m.addColumn(habitRecords, habitRecords.weekdays);
    }
  }

  /// Home gadgets gained a per-entry icon after v11.
  Future<void> _migrateToV12(Migrator m) async {
    final columns = await customSelect('PRAGMA table_info(entry_records)').get();
    // A partial or hand-made database may lack the table; real v11 files
    // always have it, and createAll handles a fresh install.
    if (columns.isEmpty) return;
    if (!columns.any((row) => row.read<String>('name') == 'icon')) {
      await m.addColumn(entryRecords, entryRecords.icon);
    }
  }

  /// v13 turns inventory rows into stock variants with persisted categories,
  /// locations, units, expiry dates and maintenance service logs.
  Future<void> _migrateToV13(Migrator m) async {
    Future<Set<String>> tables() async => (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();

    Future<Set<String>> columnsOf(String table) async => (await customSelect(
      'PRAGMA table_info($table)',
    ).get()).map((row) => row.read<String>('name')).toSet();

    final tableNames = await tables();
    if (!tableNames.contains('home_category_records')) await m.createTable(homeCategoryRecords);
    if (!tableNames.contains('home_location_records')) await m.createTable(homeLocationRecords);
    if (!tableNames.contains('home_unit_records')) await m.createTable(homeUnitRecords);
    if (!tableNames.contains('home_item_location_records')) await m.createTable(homeItemLocationRecords);
    if (!tableNames.contains('maintenance_log_records')) await m.createTable(maintenanceLogRecords);

    if (tableNames.contains('home_item_records')) {
      final columns = await columnsOf('home_item_records');
      if (!columns.contains('group_id')) await m.addColumn(homeItemRecords, homeItemRecords.groupId);
      if (!columns.contains('description')) await m.addColumn(homeItemRecords, homeItemRecords.description);
      if (!columns.contains('icon')) await m.addColumn(homeItemRecords, homeItemRecords.icon);
      if (!columns.contains('color')) await m.addColumn(homeItemRecords, homeItemRecords.color);
      if (!columns.contains('catalog_id')) await m.addColumn(homeItemRecords, homeItemRecords.catalogId);
      if (!columns.contains('category_id')) await m.addColumn(homeItemRecords, homeItemRecords.categoryId);
      if (!columns.contains('unit_id')) await m.addColumn(homeItemRecords, homeItemRecords.unitId);
      if (!columns.contains('pack_size')) await m.addColumn(homeItemRecords, homeItemRecords.packSize);
      if (!columns.contains('min_quantity')) await m.addColumn(homeItemRecords, homeItemRecords.minQuantity);
      if (!columns.contains('expires_date_key')) {
        await m.addColumn(homeItemRecords, homeItemRecords.expiresDateKey);
      }
    }

    if (tableNames.contains('shopping_item_records')) {
      final columns = await columnsOf('shopping_item_records');
      if (!columns.contains('pack_size')) {
        await m.addColumn(shoppingItemRecords, shoppingItemRecords.packSize);
      }
      if (!columns.contains('catalog_id')) {
        await m.addColumn(shoppingItemRecords, shoppingItemRecords.catalogId);
      }
      if (!columns.contains('category')) {
        await m.addColumn(shoppingItemRecords, shoppingItemRecords.category);
      }
      if (!columns.contains('category_id')) {
        await m.addColumn(shoppingItemRecords, shoppingItemRecords.categoryId);
      }
      if (!columns.contains('icon')) await m.addColumn(shoppingItemRecords, shoppingItemRecords.icon);
      if (!columns.contains('color')) await m.addColumn(shoppingItemRecords, shoppingItemRecords.color);
    }

    if (tableNames.contains('setting_records')) {
      await _seedHomeReferenceDefaults();
    }

    if (!tableNames.contains('home_item_records')) return;
    final categoryRows = await (select(homeCategoryRecords)..where((row) => row.deletedAt.isNull())).get();
    final locationRows = await (select(homeLocationRecords)..where((row) => row.deletedAt.isNull())).get();
    final unitRows = await (select(homeUnitRecords)..where((row) => row.deletedAt.isNull())).get();
    final categoriesByName = {for (final row in categoryRows) row.name.toLowerCase(): row};
    final locationsByName = {for (final row in locationRows) row.name.toLowerCase(): row};
    final unitsByName = {
      for (final row in unitRows) ...{row.name.toLowerCase(): row, row.symbol.toLowerCase(): row},
    };
    final homeColumns = await columnsOf('home_item_records');
    final items = await customSelect('SELECT * FROM home_item_records').get();
    for (final row in items) {
      final id = row.read<String>('id');
      final categoryText = homeColumns.contains('category') ? row.read<String>('category') : '';
      final locationText = homeColumns.contains('location') ? row.read<String>('location') : '';
      final unitText = homeColumns.contains('unit') ? row.read<String>('unit') : '';
      final reorder = homeColumns.contains('reorder_level')
          ? row.readNullable<double>('reorder_level')
          : null;
      final category = categoriesByName[categoryText.trim().toLowerCase()];
      final unit = unitsByName[unitText.trim().toLowerCase()];
      final icon = category?.icon ?? 'inventory';
      final color = category?.color;
      await customStatement(
        'UPDATE home_item_records SET '
        'group_id = COALESCE(group_id, id), '
        "description = COALESCE(NULLIF(description, ''), ''), "
        "icon = CASE WHEN COALESCE(icon, '') IN ('', 'inventory') THEN ? ELSE icon END, "
        'color = COALESCE(color, ?), '
        'category_id = COALESCE(category_id, ?), '
        'unit_id = COALESCE(unit_id, ?), '
        'min_quantity = COALESCE(min_quantity, ?) '
        'WHERE id = ?',
        [icon, color, category?.id, unit?.id, reorder, id],
      );
      if (locationText.trim().isNotEmpty) {
        for (final part in locationText.split(',')) {
          final location = locationsByName[part.trim().toLowerCase()];
          if (location == null) continue;
          await into(homeItemLocationRecords).insert(
            HomeItemLocationRecordsCompanion.insert(homeItemId: id, locationId: location.id),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    }

    if (!tableNames.contains('shopping_item_records')) return;
    final shoppingColumns = await columnsOf('shopping_item_records');
    if (!shoppingColumns.contains('home_item_id')) return;
    final shopping = await customSelect(
      'SELECT id, home_item_id FROM shopping_item_records WHERE home_item_id IS NOT NULL',
    ).get();
    for (final row in shopping) {
      final homeId = row.read<String>('home_item_id');
      final home = await (select(homeItemRecords)..where((item) => item.id.equals(homeId))).getSingleOrNull();
      if (home == null) continue;
      await customStatement(
        'UPDATE shopping_item_records SET '
        "category = CASE WHEN COALESCE(category, '') = '' THEN ? ELSE category END, "
        'category_id = COALESCE(category_id, ?), '
        "icon = CASE WHEN COALESCE(icon, '') IN ('', 'shopping_basket') THEN ? ELSE icon END, "
        'color = COALESCE(color, ?), '
        "pack_size = CASE WHEN COALESCE(pack_size, '') = '' THEN ? ELSE pack_size END "
        'WHERE id = ?',
        [home.category, home.categoryId, home.icon, home.color, home.packSize, row.read<String>('id')],
      );
    }
  }

  /// v14 adds the sync metadata tables, stable sync ids for shift slots and
  /// exceptions, and a base version for every existing row.
  Future<void> _migrateToV14(Migrator m) async {
    Future<Set<String>> tables() async => (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();

    Future<Set<String>> columnsOf(String table) async => (await customSelect(
      'PRAGMA table_info($table)',
    ).get()).map((row) => row.read<String>('name')).toSet();

    var tableNames = await tables();
    if (!tableNames.contains('sync_device_state_records')) {
      await m.createTable(syncDeviceStateRecords);
    }
    if (!tableNames.contains('sync_change_records')) await m.createTable(syncChangeRecords);
    if (!tableNames.contains('sync_field_version_records')) {
      await m.createTable(syncFieldVersionRecords);
    }
    if (!tableNames.contains('sync_tombstone_records')) {
      await m.createTable(syncTombstoneRecords);
    }
    if (!tableNames.contains('sync_peer_state_records')) {
      await m.createTable(syncPeerStateRecords);
    }

    if (!tableNames.contains('shift_slot_records')) await m.createTable(shiftSlotRecords);
    if (!tableNames.contains('shift_exception_records')) await m.createTable(shiftExceptionRecords);

    tableNames = await tables();
    if (tableNames.contains('shift_slot_records')) {
      final columns = await columnsOf('shift_slot_records');
      if (!columns.contains('sync_id')) {
        await m.addColumn(shiftSlotRecords, shiftSlotRecords.syncId);
      }
    }
    if (tableNames.contains('shift_exception_records')) {
      final columns = await columnsOf('shift_exception_records');
      if (!columns.contains('sync_id')) {
        await m.addColumn(shiftExceptionRecords, shiftExceptionRecords.syncId);
      }
    }

    await _backfillShiftSyncIds();
    await _ensureShiftSyncIndexes();
    await syncDeviceState();
    await seedSyncFieldVersionsForAll();
  }

  /// v15 adds content-addressed image ids and the device-local media index.
  /// Existing display files are hashed into the cache so the first sync after
  /// the upgrade carries the images already on this device.
  Future<void> _migrateToV15(Migrator m) async {
    Future<Set<String>> tables() async => (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();

    Future<Set<String>> columnsOf(String table) async => (await customSelect(
      'PRAGMA table_info($table)',
    ).get()).map((row) => row.read<String>('name')).toSet();

    var tableNames = await tables();
    if (tableNames.contains('context_records')) {
      final columns = await columnsOf('context_records');
      if (!columns.contains('image_media_id')) {
        await m.addColumn(contextRecords, contextRecords.imageMediaId);
      }
    }
    if (tableNames.contains('project_records')) {
      final columns = await columnsOf('project_records');
      if (!columns.contains('image_media_id')) {
        await m.addColumn(projectRecords, projectRecords.imageMediaId);
      }
    }
    if (!tableNames.contains('media_cache_records')) {
      await m.createTable(mediaCacheRecords);
    }

    await _backfillMediaIds();
    // Older sync versions could not seed contexts/projects because the media
    // column was missing, so give every restored image and field a base
    // version now that the schema is complete.
    await seedSyncFieldVersionsForAll();
  }

  /// Hashes each existing context/project image into the content-addressed
  /// cache. A missing or unreadable file leaves that row's media id null; one
  /// bad file must never abort the upgrade.
  Future<void> _backfillMediaIds() async {
    final tableNames = (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();
    for (final table in const ['context_records', 'project_records']) {
      if (!tableNames.contains(table)) continue;
      final columns = (await customSelect(
        'PRAGMA table_info($table)',
      ).get()).map((row) => row.read<String>('name')).toSet();
      if (!columns.contains('image_path') || !columns.contains('image_media_id')) continue;
      final rows = await customSelect(
        'SELECT id, image_path FROM $table WHERE image_media_id IS NULL AND image_path IS NOT NULL',
      ).get();
      for (final row in rows) {
        final path = row.readNullable<String>('image_path');
        if (path == null || path.trim().isEmpty) continue;
        try {
          final entry = await mediaStore.cacheFromFile(path);
          if (entry == null) continue;
          await _recordMediaCache(entry);
          await customStatement('UPDATE $table SET image_media_id = ? WHERE id = ?', [
            entry.id,
            row.read<String>('id'),
          ]);
        } on Object {
          // A stale path, an oversized file or an unreadable disk is not a
          // reason to fail the whole database upgrade.
        }
      }
    }
  }

  Future<void> _backfillShiftSyncIds() async {
    final tableNames = (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();
    for (final table in const ['shift_slot_records', 'shift_exception_records']) {
      if (!tableNames.contains(table)) continue;
      final rows = await customSelect("SELECT id FROM $table WHERE sync_id IS NULL OR sync_id = ''").get();
      for (final row in rows) {
        await customStatement('UPDATE $table SET sync_id = ? WHERE id = ?', [
          const Uuid().v4(),
          row.read<int>('id'),
        ]);
      }
    }
  }

  Future<void> _ensureShiftSyncIndexes() async {
    final tableNames = (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();
    if (tableNames.contains('shift_slot_records')) {
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS shift_slot_sync_id ON shift_slot_records(sync_id)',
      );
    }
    if (tableNames.contains('shift_exception_records')) {
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS shift_exception_sync_id ON shift_exception_records(sync_id)',
      );
    }
  }

  Future<void> _addV14ColumnsEarly(Migrator m) async {
    final tableNames = (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    ).get()).map((row) => row.read<String>('name')).toSet();
    if (tableNames.contains('shift_slot_records')) {
      final columns = (await customSelect(
        'PRAGMA table_info(shift_slot_records)',
      ).get()).map((row) => row.read<String>('name')).toSet();
      if (!columns.contains('sync_id')) {
        await m.addColumn(shiftSlotRecords, shiftSlotRecords.syncId);
      }
    }
    if (tableNames.contains('shift_exception_records')) {
      final columns = (await customSelect(
        'PRAGMA table_info(shift_exception_records)',
      ).get()).map((row) => row.read<String>('name')).toSet();
      if (!columns.contains('sync_id')) {
        await m.addColumn(shiftExceptionRecords, shiftExceptionRecords.syncId);
      }
    }
  }

  Future<void> _addV4EntryColumns(Migrator m) async {
    await m.addColumn(entryRecords, entryRecords.source);
    await m.addColumn(entryRecords, entryRecords.externalId);
    await m.addColumn(entryRecords, entryRecords.readOnly);
    await m.addColumn(entryRecords, entryRecords.lastCompletedAt);
    await m.addColumn(entryRecords, entryRecords.repeatAfterCompletionDays);
  }
}

const _defaultSpaces = <Space>[
  Space(id: 'personal', name: 'Personal', colorValue: 0xFFB07D5C, position: 0),
  Space(id: 'work', name: 'Work', colorValue: 0xFF4A6FA5, position: 1),
  Space(id: 'home', name: 'Home', colorValue: 0xFF5B7F6B, position: 2),
];

/// Streak's default category vocabulary, with the same icon meanings.
const _defaultCategories = <Tag>[
  Tag(id: 'seed-health', name: 'Health', colorValue: 0xFF34C759, icon: 'favorite', position: 0),
  Tag(id: 'seed-fitness', name: 'Fitness', colorValue: 0xFFFF9500, icon: 'bolt', position: 1),
  Tag(id: 'seed-mindfulness', name: 'Mindfulness', colorValue: 0xFF5AC8FA, icon: 'psychology', position: 2),
  Tag(id: 'seed-productivity', name: 'Productivity', colorValue: 0xFFFFCC00, icon: 'star', position: 3),
  Tag(id: 'seed-learning', name: 'Learning', colorValue: 0xFF7C3AED, icon: 'menu_book', position: 4),
  Tag(id: 'seed-finance', name: 'Finance', colorValue: 0xFF00C853, icon: 'target', position: 5),
];

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'sundial.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

Space _spaceFromRow(SpaceRow row) =>
    Space(id: row.id, name: row.name, colorValue: row.color, position: row.position);

Tag _tagFromRow(TagRow row) => Tag(
  id: row.id,
  spaceId: row.spaceId,
  name: row.name,
  colorValue: row.color,
  icon: row.icon,
  position: row.position,
);

PlannerContext _contextFromRow(ContextRow row) => PlannerContext(
  id: row.id,
  spaceId: row.spaceId,
  name: row.name,
  description: row.description,
  colorValue: row.color,
  icon: row.icon,
  imagePath: row.imagePath,
  position: row.position,
  deletedAt: row.deletedAt,
);

Project _projectFromRow(ProjectRow row) => Project(
  id: row.id,
  spaceId: row.spaceId,
  contextId: row.contextId,
  name: row.name,
  description: row.description,
  colorValue: row.color,
  icon: row.icon,
  imagePath: row.imagePath,
  position: row.position,
  deletedAt: row.deletedAt,
);

Habit _habitFromRow(HabitRow row) => Habit(
  id: row.id,
  spaceId: row.spaceId,
  contextId: row.contextId,
  name: row.name,
  description: row.description,
  colorValue: row.color,
  icon: row.icon,
  targetPerWeek: row.targetPerWeek,
  weekdays: Habit.parseWeekdays(row.weekdays),
  position: row.position,
  archived: row.archived,
  createdAt: row.createdAt,
  deletedAt: row.deletedAt,
);

TimeEntry _timeEntryFromRow(TimeEntryRow row) => TimeEntry(
  id: row.id,
  entryId: row.entryId,
  occurrenceDateKey: row.occurrenceDateKey,
  startedAt: row.startedAt.toUtc(),
  endedAt: row.endedAt?.toUtc(),
  note: row.note,
  createdAt: row.createdAt,
);

Reminder _reminderFromRow(ReminderRow row) => Reminder(
  id: row.id,
  entryId: row.entryId,
  offsetMinutes: row.offsetMinutes,
  timeMinute: row.timeMinute,
  enabled: row.enabled,
);

RemoteSnapshot _remoteSnapshotFromRow(RemoteSnapshotRow row) {
  Map<String, Object?> payload = const {};
  try {
    final decoded = jsonDecode(row.payloadJson);
    if (decoded is Map) payload = Map<String, Object?>.from(decoded);
  } on FormatException {
    // A damaged display snapshot must never prevent the app from opening.
  }
  return RemoteSnapshot.fromPayload(
    deviceId: row.deviceId,
    deviceName: row.deviceName,
    fetchedAt: row.fetchedAt,
    data: payload,
  );
}

HomeItem _homeItemFromRow(HomeItemRow row, {List<String> locationIds = const <String>[]}) => HomeItem(
  id: row.id,
  contextId: row.contextId,
  groupId: row.groupId,
  name: row.name,
  description: row.description,
  icon: row.icon,
  colorValue: row.color,
  catalogId: row.catalogId,
  category: row.category,
  categoryId: row.categoryId,
  location: row.location,
  locationIds: locationIds,
  quantity: row.quantity,
  unit: row.unit,
  unitId: row.unitId,
  packSize: row.packSize,
  minQuantity: row.minQuantity,
  reorderLevel: row.reorderLevel,
  expiresAt: row.expiresDateKey == null ? null : LocalDate.fromKey(row.expiresDateKey!),
  notes: row.notes,
  lastPurchasedAt: row.lastPurchasedAt,
);

ShoppingItem _shoppingItemFromRow(ShoppingItemRow row) => ShoppingItem(
  id: row.id,
  contextId: row.contextId,
  name: row.name,
  quantity: row.quantity,
  unit: row.unit,
  packSize: row.packSize,
  checked: row.checked,
  note: row.note,
  homeItemId: row.homeItemId,
  catalogId: row.catalogId,
  category: row.category,
  categoryId: row.categoryId,
  icon: row.icon,
  colorValue: row.color,
  position: row.position,
);

HomeCategory _homeCategoryFromRow(HomeCategoryRow row) =>
    HomeCategory(id: row.id, name: row.name, icon: row.icon, colorValue: row.color, position: row.position);

HomeLocation _homeLocationFromRow(HomeLocationRow row) =>
    HomeLocation(id: row.id, name: row.name, icon: row.icon, colorValue: row.color, position: row.position);

HomeUnit _homeUnitFromRow(HomeUnitRow row) => HomeUnit(
  id: row.id,
  name: row.name,
  symbol: row.symbol,
  kind: HomeUnitKind.values.firstWhere((kind) => kind.name == row.kind, orElse: () => HomeUnitKind.other),
  position: row.position,
);

MaintenanceLog _maintenanceLogFromRow(MaintenanceLogRow row) => MaintenanceLog(
  id: row.id,
  entryId: row.entryId,
  performedOn: LocalDate.fromKey(row.performedDateKey),
  nextDue: LocalDate.fromKey(row.nextDueDateKey),
  note: row.note,
  durationMinutes: row.durationMinutes,
  createdAt: row.createdAt,
);

HomePurchase _homePurchaseFromRow(HomePurchaseRow row) => HomePurchase(
  id: row.id,
  homeItemId: row.homeItemId,
  shoppingItemId: row.shoppingItemId,
  quantity: row.quantity,
  note: row.note,
  purchasedAt: row.purchasedAt,
);

ShiftChecklistItem _checklistItemFromRow(ShiftChecklistItemRow row) => ShiftChecklistItem(
  id: row.id,
  patternId: row.patternId,
  label: row.label,
  dayIndex: row.dayIndex,
  position: row.position,
);

LocalIdentity _identityFromRow(IdentityRow row) => LocalIdentity(
  deviceId: row.deviceId,
  deviceName: row.deviceName,
  username: row.username,
  pinSalt: row.pinSalt,
  pinHash: row.pinHash,
  certificatePem: row.certificatePem,
  privateKeyPem: row.privateKeyPem,
  mcpToken: row.mcpToken,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

PairedDevice _pairedDeviceFromRow(PairedDeviceRow row) => PairedDevice(
  id: row.id,
  name: row.name,
  username: row.username,
  certificateFingerprint: row.certificateFingerprint,
  sharedKey: row.sharedKey,
  host: row.host,
  port: row.port,
  lastSeenAt: row.lastSeenAt,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

Entry _entryFromRow(EntryRow row, {Set<String> tagIds = const <String>{}}) => Entry(
  id: row.id,
  spaceId: row.spaceId,
  title: row.title,
  notes: row.notes,
  kind: EntryKind.values.byName(row.kind),
  date: row.dateKey == null ? null : LocalDate.fromKey(row.dateKey!),
  endDate: row.endDateKey == null ? null : LocalDate.fromKey(row.endDateKey!),
  startMinute: row.startMinute,
  endMinute: row.endMinute,
  timeZone: row.timeZone,
  contextId: row.contextId,
  projectId: row.projectId,
  icon: row.icon,
  priority: EntryPriority.values.byName(row.priority),
  completedAt: row.completedAt?.toUtc(),
  tagIds: tagIds,
  allDay: row.allDay,
  status: EntryStatus.values.byName(row.status),
  recurrence: row.recurrenceJson == null
      ? null
      : RecurrenceRule.fromJson(Map<String, Object?>.from(jsonDecode(row.recurrenceJson!) as Map)),
  source: row.source,
  externalId: row.externalId,
  readOnly: row.readOnly,
  lastCompletedAt: row.lastCompletedAt?.toUtc(),
  repeatAfterCompletionDays: row.repeatAfterCompletionDays,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
  deletedAt: row.deletedAt,
  startAt: row.startAt?.toUtc(),
  endAt: row.endAt?.toUtc(),
);

EntryRecordsCompanion _entryCompanion(Entry entry) => EntryRecordsCompanion(
  id: Value(entry.id),
  spaceId: Value(entry.spaceId),
  title: Value(entry.title),
  notes: Value(entry.notes),
  kind: Value(entry.kind.name),
  dateKey: Value(entry.date?.key),
  endDateKey: Value(entry.endDate?.key),
  startMinute: Value(entry.startMinute),
  endMinute: Value(entry.endMinute),
  timeZone: Value(entry.timeZone),
  contextId: Value(entry.contextId),
  projectId: Value(entry.projectId),
  icon: Value(entry.icon),
  priority: Value(entry.priority.name),
  startAt: Value(entry.startAt),
  endAt: Value(entry.endAt),
  allDay: Value(entry.allDay),
  status: Value(entry.status.name),
  recurrenceJson: Value(entry.recurrence == null ? null : jsonEncode(entry.recurrence!.toJson())),
  source: Value(entry.source),
  externalId: Value(entry.externalId),
  readOnly: Value(entry.readOnly),
  lastCompletedAt: Value(entry.lastCompletedAt),
  repeatAfterCompletionDays: Value(entry.repeatAfterCompletionDays),
  completedAt: Value(entry.completedAt),
  createdAt: Value(entry.createdAt),
  updatedAt: Value(entry.updatedAt),
  deletedAt: Value(entry.deletedAt),
);

ShiftPattern _patternFromRow(
  ShiftPatternRow row,
  List<ShiftSlot> slots,
  List<ShiftException> exceptions,
  Set<String> tagIds,
) => ShiftPattern(
  id: row.id,
  spaceId: row.spaceId,
  name: row.name,
  contextId: row.contextId,
  timeZone: row.timeZone,
  cycleDays: row.cycleDays,
  anchorDate: LocalDate.fromKey(row.anchorDateKey),
  slots: slots,
  exceptions: exceptions,
  tagIds: tagIds,
  commuteMinutes: row.commuteMinutes,
  windDownMinutes: row.windDownMinutes,
  enabled: row.enabled,
);
