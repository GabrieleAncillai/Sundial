import 'package:sundial_core/sundial_core.dart';

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
import 'app_database.dart';

/// The single read/write seam for the planner.
///
/// UI and, later, the LAN server and MCP adapter call this instead of touching
/// Drift directly. That keeps the agent-facing tools on the same rules as the
/// screens.
class PlannerRepository {
  PlannerRepository(this._database);

  final AppDatabase _database;

  Stream<List<Space>> watchSpaces() => _database.watchSpaces();

  Stream<List<PlannerContext>> watchContexts({String? spaceId}) => _database.watchContexts(spaceId: spaceId);

  Future<void> saveContext(PlannerContext context) => _database.saveContext(context);

  Future<void> deleteContext(String id) => _database.softDeleteContext(id);

  Stream<List<Project>> watchProjects({String? spaceId, String? contextId}) =>
      _database.watchProjects(spaceId: spaceId, contextId: contextId);

  Future<void> saveProject(Project project) => _database.saveProject(project);

  Future<void> deleteProject(String id) => _database.softDeleteProject(id);

  Stream<List<Habit>> watchHabits({String? spaceId, String? contextId}) =>
      _database.watchHabits(spaceId: spaceId, contextId: contextId);

  Future<void> saveHabit(Habit habit) => _database.saveHabit(habit);

  Future<void> deleteHabit(String id) => _database.softDeleteHabit(id);

  Stream<Map<String, Set<LocalDate>>> watchHabitCompletions({String? habitId}) =>
      _database.watchHabitCompletions(habitId: habitId);

  Future<void> setHabitCompleted(String habitId, LocalDate date, {required bool completed}) =>
      _database.setHabitCompleted(habitId, date, completed: completed);

  Stream<List<Entry>> watchOpenEntries(LocalDate until) => _database.watchOpenEntries(until);

  Stream<List<Tag>> watchTags() => _database.watchTags();

  Future<void> saveTag(Tag tag) => _database.saveTag(tag);

  Future<void> deleteTag(String id) => _database.softDeleteTag(id);

  Stream<List<HomeItem>> watchHomeItems() => _database.watchHomeItems();

  Future<void> saveHomeItem(HomeItem item, {bool updateGroup = false}) =>
      _database.saveHomeItem(item, updateGroup: updateGroup);

  Future<void> archiveHomeItem(String id) => _database.archiveHomeItem(id);

  Future<void> archiveHomeGroup(String groupId) => _database.archiveHomeGroup(groupId);

  Stream<List<HomeCategory>> watchHomeCategories() => _database.watchHomeCategories();

  Future<void> saveHomeCategory(HomeCategory category) => _database.saveHomeCategory(category);

  Future<void> deleteHomeCategory(String id) => _database.deleteHomeCategory(id);

  Stream<List<HomeLocation>> watchHomeLocations() => _database.watchHomeLocations();

  Future<void> saveHomeLocation(HomeLocation location) => _database.saveHomeLocation(location);

  Future<void> deleteHomeLocation(String id) => _database.deleteHomeLocation(id);

  Stream<List<HomeUnit>> watchHomeUnits() => _database.watchHomeUnits();

  Future<void> saveHomeUnit(HomeUnit unit) => _database.saveHomeUnit(unit);

  Future<void> deleteHomeUnit(String id) => _database.deleteHomeUnit(id);

  Future<void> repairHomeItemReferences() => _database.repairHomeItemReferences();

  Stream<List<ShoppingItem>> watchShoppingItems() => _database.watchShoppingItems();

  Future<void> saveShoppingItem(ShoppingItem item) => _database.saveShoppingItem(item);

  Future<void> deleteShoppingItem(String id) => _database.deleteShoppingItem(id);

  Future<void> setShoppingChecked(String id, bool checked) => _database.setShoppingChecked(id, checked);

  Future<void> moveShoppingItem(String id, int delta) => _database.moveShoppingItem(id, delta);

  Future<void> clearCheckedShopping({String? contextId}) =>
      _database.clearCheckedShopping(contextId: contextId);

  Future<void> adjustHomeQuantity(String id, double delta, {String note = ''}) =>
      _database.adjustHomeQuantity(id, delta, note: note);

  Future<List<HomePurchase>> readPurchaseHistory(String homeItemId, {int limit = 30}) =>
      _database.readPurchaseHistory(homeItemId, limit: limit);

  Future<List<ShiftChecklistItem>> readShiftChecklistItems(String patternId) =>
      _database.readShiftChecklistItems(patternId);

  Future<void> saveShiftChecklistItems(String patternId, List<ShiftChecklistItem> items) =>
      _database.saveShiftChecklistItems(patternId, items);

  Future<Set<String>> readShiftChecklistCompletions(
    String patternId,
    LocalDate date, {
    required String slotKey,
  }) => _database.readShiftChecklistCompletions(patternId, date, slotKey: slotKey);

  Future<void> setShiftChecklistCompleted(
    String itemId,
    LocalDate date, {
    required bool completed,
    required String slotKey,
  }) => _database.setShiftChecklistCompleted(itemId, date, completed: completed, slotKey: slotKey);

  Future<bool> hasImportedEntry(String source, String externalId) =>
      _database.hasImportedEntry(source, externalId);

  Future<bool> hasEntryLike({
    required String title,
    required String spaceId,
    required LocalDate date,
    required bool allDay,
    required int? startMinute,
    required int? endMinute,
  }) => _database.hasEntryLike(
    title: title,
    spaceId: spaceId,
    date: date,
    allDay: allDay,
    startMinute: startMinute,
    endMinute: endMinute,
  );

  Future<Entry?> readImportedEntry(String source, String externalId) =>
      _database.readImportedEntry(source, externalId);

  Future<LocalDate?> completeMaintenanceEntry(String id, LocalDate completionDate) =>
      _database.completeMaintenanceEntry(id, completionDate);

  /// Records a service on a gadget, optionally inserting the calendar event the
  /// user created for the work in the same transaction.
  Future<LocalDate?> logMaintenanceService({
    required String entryId,
    required LocalDate performedOn,
    String note = '',
    int? durationMinutes,
    Entry? calendarEvent,
  }) => _database.completeMaintenanceEntry(
    entryId,
    performedOn,
    note: note,
    durationMinutes: durationMinutes,
    calendarEvent: calendarEvent,
  );

  Stream<List<MaintenanceLog>> watchMaintenanceLogs(String entryId) =>
      _database.watchMaintenanceLogs(entryId);

  Future<LocalDate?> rescheduleMaintenance(String entryId, LocalDate nextDue) =>
      _database.rescheduleMaintenance(entryId, nextDue);

  Future<Map<String, String>> readSettings() => _database.readSettings();

  Future<LocalIdentity?> readIdentity() => _database.readIdentity();

  Future<void> saveIdentity(LocalIdentity identity) => _database.saveIdentity(identity);

  Stream<List<PairedDevice>> watchPairedDevices() => _database.watchPairedDevices();

  Future<List<PairedDevice>> readPairedDevices() => _database.readPairedDevices();

  Future<void> savePairedDevice(PairedDevice device) => _database.savePairedDevice(device);

  Future<void> removePairedDevice(String id) => _database.removePairedDevice(id);

  Stream<List<RemoteSnapshot>> watchRemoteSnapshots() => _database.watchRemoteSnapshots();

  Future<List<RemoteSnapshot>> readRemoteSnapshots() => _database.readRemoteSnapshots();

  Future<void> saveRemoteSnapshot(RemoteSnapshot snapshot) => _database.saveRemoteSnapshot(snapshot);

  Future<void> pruneRemoteSnapshots(Set<String> keepDeviceIds) =>
      _database.pruneRemoteSnapshots(keepDeviceIds);

  Future<void> deleteRemoteSnapshot(String deviceId) => _database.deleteRemoteSnapshot(deviceId);

  Future<void> updatePairedDevicePresence(
    String id, {
    required String host,
    required int port,
    required DateTime seenAt,
  }) => _database.updatePairedDevicePresence(id, host: host, port: port, seenAt: seenAt);

  Future<void> writeSetting(String key, String value) => _database.writeSetting(key, value);

  /// Entries whose viewer-local date falls between [start] and [end].
  Stream<List<EntryOccurrence>> watchEntries(LocalDate start, LocalDate end, String viewerTimeZone) =>
      _database.watchEntriesBetween(start, end, viewerTimeZone);

  Future<List<EntryOccurrence>> loadEntries(LocalDate start, LocalDate end, String viewerTimeZone) =>
      _database.loadEntriesBetween(start, end, viewerTimeZone);

  Future<SearchResults> search(String query) => _database.search(query);

  /// Shifts whose viewer-local date falls between [start] and [end].
  Stream<List<ShiftOccurrence>> watchShifts(LocalDate start, LocalDate end, String viewerTimeZone) =>
      _database.watchShiftsBetween(start, end, viewerTimeZone);

  Stream<List<ShiftPattern>> watchShiftPatterns() => _database.watchShiftPatterns();

  Future<void> saveEntry(Entry entry) => _database.saveEntry(entry);

  /// Importers replace their own read-only rows. User-facing writes use
  /// [saveEntry] and are rejected for those rows.
  Future<void> saveImportedEntry(Entry entry) => _database.saveEntry(entry, allowReadOnly: true);

  Future<Entry?> readEntry(String id) => _database.readEntry(id);

  Future<Map<String, Entry>> readEntriesByIds(Set<String> ids) => _database.readEntriesByIds(ids);

  Future<List<Reminder>> readRemindersForEntry(String entryId) => _database.readRemindersForEntry(entryId);

  Future<Map<String, List<Reminder>>> readAllReminders() => _database.readAllReminders();

  Future<void> saveRemindersForEntry(String entryId, List<Reminder> reminders) =>
      _database.saveRemindersForEntry(entryId, reminders);

  Future<void> setEntryStatus(String id, EntryStatus status) => _database.setEntryStatus(id, status);

  Future<void> setOccurrenceCompleted(String entryId, LocalDate date, bool completed) =>
      _database.setOccurrenceCompleted(entryId, date, completed: completed);

  /// One completion path for every task surface.
  ///
  /// Recurring tasks are completed per occurrence, maintenance tasks advance
  /// their next date, and a running clock session is closed when the task is
  /// marked done. Read-only imports are refused by the database layer.
  Future<void> setCompletion(EntryOccurrence occurrence, {required bool completed, DateTime? at}) async {
    final entry = occurrence.entry;
    if (entry.readOnly) throw StateError('Imported entries are read-only');
    if (completed) {
      if (entry.repeatAfterCompletionDays != null) {
        await _database.completeMaintenanceEntry(entry.id, occurrence.date);
        return;
      }
      if (entry.recurrence != null) {
        await _database.setOccurrenceCompleted(entry.id, occurrence.date, completed: true);
        return;
      }
      await _database.setEntryStatus(entry.id, EntryStatus.done);
      return;
    }

    if (entry.recurrence != null) {
      await _database.setOccurrenceCompleted(entry.id, occurrence.date, completed: false);
    } else {
      await _database.setEntryStatus(entry.id, EntryStatus.open);
    }
  }

  Future<void> deleteEntry(String id) => _database.softDeleteEntry(id);

  Stream<List<TimeEntry>> watchTimeEntriesForEntry(String entryId) =>
      _database.watchTimeEntriesForEntry(entryId);

  Future<List<TimeEntry>> readTimeEntriesBetween(DateTime startUtc, DateTime endUtc) =>
      _database.readTimeEntriesBetween(startUtc, endUtc);

  Future<TimeEntry> clockIn(EntryOccurrence occurrence, {DateTime? at}) => _database.startTimeEntry(
    entryId: occurrence.entry.id,
    occurrenceDateKey: _occurrenceDateKey(occurrence),
    at: at,
  );

  /// Stops the running session and returns it, or null if none was running.
  ///
  /// Pausing never rewrites the entry: a clock-in task keeps its start and no
  /// end, so it stays resumable on a later day. Finishing is separate.
  Future<TimeEntry?> clockOut(EntryOccurrence occurrence, {DateTime? at}) =>
      _database.stopTimeEntry(occurrence.entry.id, occurrenceDateKey: _occurrenceDateKey(occurrence), at: at);

  /// Stops the running session and, for a clock-in task, records the entry's
  /// end. This is the explicit finish path; it does not complete the entry.
  Future<TimeEntry?> finishTracked(EntryOccurrence occurrence, {DateTime? at}) async {
    final stopped = await _database.stopTimeEntry(
      occurrence.entry.id,
      occurrenceDateKey: _occurrenceDateKey(occurrence),
      at: at,
    );
    final entry = occurrence.entry;
    if (entry.isClockInTask && entry.timeZone != null) {
      final endedAt = stopped?.endedAt ?? at ?? DateTime.now().toUtc();
      var minute = localMinuteAt(endedAt, entry.timeZone!);
      if (minute <= entry.startMinute!) minute += 1440;
      await saveEntry(entry.copyWith(endMinute: minute, updatedAt: DateTime.now().toUtc()));
    }
    return stopped;
  }

  int? _occurrenceDateKey(EntryOccurrence occurrence) =>
      occurrence.entry.recurrence == null ? null : occurrence.date.key;

  Future<void> clearAllData() => _database.clearAllData();

  Future<void> saveShiftPattern(ShiftPattern pattern) => _database.saveShiftPattern(pattern);

  Future<void> deleteShiftPattern(String id) => _database.softDeleteShiftPattern(id);
}
