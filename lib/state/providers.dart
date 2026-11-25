import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../features/backup/auto_backup_service.dart';
import '../features/backup/backup_service.dart';
import '../features/home_widget/home_widget_service.dart';
import '../features/mcp/mcp_server.dart';
import '../features/sync/identity_service.dart';
import '../features/sync/lan_client.dart';
import '../features/sync/lan_server.dart';
import '../features/sync/peer_discovery.dart';
import '../features/sync/sync_debug_models.dart';
import '../features/sync/sync_engine.dart';
import '../features/sync/sync_store.dart';
import '../features/sync/sync_service.dart';
import '../models/date_range.dart';
import '../models/home_item.dart';
import '../models/home_reference.dart';
import '../models/maintenance_log.dart';
import '../models/time_entry.dart';
import '../models/local_identity.dart';
import '../models/paired_device.dart';
import '../models/shopping_item.dart';
import '../models/shift_checklist.dart';
import '../models/app_settings.dart';
import '../state/settings_controller.dart';
import '../services/app_database.dart';
import '../services/notification_service.dart';
import '../services/planner_repository.dart';
import '../services/reminder_coordinator.dart';

/// Overridden in `main()` with the opened database.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError('databaseProvider must be overridden');
});

/// The device's IANA timezone. Overridden in `main()` from the platform and
/// refreshed on app resume when the system zone changes.
class DeviceTimeZoneController extends Notifier<String> {
  DeviceTimeZoneController({this.initial = 'UTC'});

  final String initial;

  @override
  String build() => initial;

  void set(String value) {
    if (isKnownTimeZone(value) && value != state) state = value;
  }
}

final deviceTimeZoneProvider = NotifierProvider<DeviceTimeZoneController, String>(
  DeviceTimeZoneController.new,
);

/// Wall clock for screens and tests. Override in tests to keep dates stable.
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

/// A clock for services that need the current instant when they run.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Overridden in `main()` with the initialised notification plugin.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw StateError('notificationServiceProvider must be overridden');
});

final reminderCoordinatorProvider = Provider<ReminderCoordinator>(
  (ref) => ReminderCoordinator(
    repository: ref.watch(repositoryProvider),
    notifications: ref.watch(notificationServiceProvider),
    deviceTimeZone: ref.watch(deviceTimeZoneProvider),
    clock: ref.watch(clockProvider),
    settings: ref.watch(settingsProvider),
  ),
);

final repositoryProvider = Provider<PlannerRepository>(
  (ref) => PlannerRepository(ref.watch(databaseProvider)),
);

final spacesProvider = StreamProvider<List<Space>>((ref) => ref.watch(repositoryProvider).watchSpaces());

final contextsProvider = StreamProvider.family<List<PlannerContext>, String?>(
  (ref, spaceId) => ref.watch(repositoryProvider).watchContexts(spaceId: spaceId),
);

final projectsProvider = StreamProvider.family<List<Project>, String?>(
  (ref, spaceId) => ref.watch(repositoryProvider).watchProjects(spaceId: spaceId),
);

final contextProjectsProvider = StreamProvider.family<List<Project>, String>(
  (ref, contextId) => ref.watch(repositoryProvider).watchProjects(contextId: contextId),
);

final habitsProvider = StreamProvider.family<List<Habit>, String?>(
  (ref, spaceId) => ref.watch(repositoryProvider).watchHabits(spaceId: spaceId),
);

final habitCompletionsProvider = StreamProvider<Map<String, HabitCompletions>>(
  (ref) => ref.watch(repositoryProvider).watchHabitCompletions(),
);

final openEntriesProvider = StreamProvider.family<List<Entry>, LocalDate>(
  (ref, until) => ref.watch(repositoryProvider).watchOpenEntries(until),
);

final entryTimeProvider = StreamProvider.family<List<TimeEntry>, String>(
  (ref, entryId) => ref.watch(repositoryProvider).watchTimeEntriesForEntry(entryId),
);

final timeEntriesRangeProvider = FutureProvider.family<List<TimeEntry>, ({DateTime start, DateTime end})>(
  (ref, range) => ref.watch(repositoryProvider).readTimeEntriesBetween(range.start, range.end),
);

/// Entries referenced by tracked sessions, even when they are outside the
/// visible occurrence range. Reports use this so totals always reconcile.
final trackedEntriesProvider = FutureProvider.family<Map<String, Entry>, ({DateTime start, DateTime end})>((
  ref,
  range,
) async {
  final sessions = await ref.watch(timeEntriesRangeProvider(range).future);
  final ids = {for (final session in sessions) session.entryId};
  return ref.watch(repositoryProvider).readEntriesByIds(ids);
});

final tagsProvider = StreamProvider<List<Tag>>((ref) => ref.watch(repositoryProvider).watchTags());

final homeItemsProvider = StreamProvider<List<HomeItem>>(
  (ref) => ref.watch(repositoryProvider).watchHomeItems(),
);

final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>(
  (ref) => ref.watch(repositoryProvider).watchShoppingItems(),
);

final homeCategoriesProvider = StreamProvider<List<HomeCategory>>(
  (ref) => ref.watch(repositoryProvider).watchHomeCategories(),
);

final homeLocationsProvider = StreamProvider<List<HomeLocation>>(
  (ref) => ref.watch(repositoryProvider).watchHomeLocations(),
);

final homeUnitsProvider = StreamProvider<List<HomeUnit>>(
  (ref) => ref.watch(repositoryProvider).watchHomeUnits(),
);

final maintenanceLogsProvider = StreamProvider.family<List<MaintenanceLog>, String>(
  (ref, entryId) => ref.watch(repositoryProvider).watchMaintenanceLogs(entryId),
);

/// Open home gadgets regardless of how far their next due date is.
final maintenanceEntriesProvider = StreamProvider<List<Entry>>((ref) {
  final now = ref.watch(nowProvider);
  final timeZone = ref.watch(deviceTimeZoneProvider);
  final today = localDateAt(now, timeZone);
  return ref
      .watch(repositoryProvider)
      .watchOpenEntries(today.addDays(3650))
      .map((entries) => entries.where((entry) => entry.isMaintenance).toList());
});

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(databaseProvider)));

final autoBackupServiceProvider = Provider<AutoBackupService>(
  (ref) => AutoBackupService(ref.watch(backupServiceProvider)),
);

final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) => HomeWidgetService());

class TagFilterController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void toggle(String tagId) {
    state = state.contains(tagId) ? (state.toSet()..remove(tagId)) : (state.toSet()..add(tagId));
  }

  void clear() => state = const <String>{};
}

final tagFilterProvider = NotifierProvider<TagFilterController, Set<String>>(TagFilterController.new);

/// Used only if a screen is built before the first space stream arrives.
/// The app seeds these rows on first launch.
const fallbackSpaces = <Space>[
  Space(id: 'personal', name: 'Personal', colorValue: 0xFFB07D5C, position: 0),
  Space(id: 'work', name: 'Work', colorValue: 0xFF4A6FA5, position: 1),
  Space(id: 'home', name: 'Home', colorValue: 0xFF5B7F6B, position: 2),
];

final entriesProvider = StreamProvider.family<List<EntryOccurrence>, DateRange>((ref, range) {
  final timeZone = ref.watch(deviceTimeZoneProvider);
  final filter = ref.watch(tagFilterProvider);
  final knownTags = ref.watch(tagsProvider).value;
  return ref.watch(repositoryProvider).watchEntries(range.start, range.end, timeZone).map((items) {
    final active = knownTags == null ? filter : filter.intersection(knownTags.map((tag) => tag.id).toSet());
    if (active.isEmpty) return items;
    return items.where((item) => item.entry.tagIds.any(active.contains)).toList();
  });
});

final shiftsProvider = StreamProvider.family<List<ShiftOccurrence>, DateRange>((ref, range) {
  final timeZone = ref.watch(deviceTimeZoneProvider);
  final filter = ref.watch(tagFilterProvider);
  final knownTags = ref.watch(tagsProvider).value;
  return ref.watch(repositoryProvider).watchShifts(range.start, range.end, timeZone).map((items) {
    final active = knownTags == null ? filter : filter.intersection(knownTags.map((tag) => tag.id).toSet());
    if (active.isEmpty) return items;
    return items.where((item) => item.pattern.tagIds.any(active.contains)).toList();
  });
});

final shiftPatternsProvider = StreamProvider<List<ShiftPattern>>(
  (ref) => ref.watch(repositoryProvider).watchShiftPatterns(),
);

final shiftChecklistItemsProvider = StreamProvider.family<List<ShiftChecklistItem>, String>(
  (ref, patternId) => ref.watch(repositoryProvider).watchShiftChecklistItems(patternId),
);

final identityServiceProvider = Provider<IdentityService>(
  (ref) => IdentityService(ref.watch(repositoryProvider)),
);

final identityProvider = FutureProvider<LocalIdentity?>(
  (ref) => ref.watch(repositoryProvider).readIdentity(),
);

final pairedDevicesProvider = StreamProvider<List<PairedDevice>>(
  (ref) => ref.watch(repositoryProvider).watchPairedDevices(),
);

final lanClientProvider = Provider<LanClient>(
  (ref) => LanClient(ref.read(repositoryProvider), clock: ref.read(clockProvider)),
);

final syncStoreProvider = Provider<SyncStore>((ref) => SyncStore(ref.read(databaseProvider)));

/// Read-only replica bookkeeping for the developer sync log. The stream
/// watches the sync tables, so new field-level changes appear without a manual
/// refresh. It stays alive only while the debug page listens.
final syncDebugSnapshotProvider = StreamProvider<SyncDebugSnapshot>(
  (ref) => ref.watch(syncStoreProvider).watchDebugSnapshot(),
  isAutoDispose: true,
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(store: ref.read(syncStoreProvider), transport: ref.read(lanClientProvider)),
);

final lanServerProvider = Provider<LanServer>(
  (ref) => LanServer(
    repository: ref.read(repositoryProvider),
    syncStore: ref.read(syncStoreProvider),
    deviceTimeZone: () => ref.read(deviceTimeZoneProvider),
    clock: ref.read(clockProvider),
  ),
);

final peerDiscoveryProvider = Provider<PeerDiscovery>((ref) => BonsoirPeerDiscovery());

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(
    repository: ref.read(repositoryProvider),
    identityService: ref.read(identityServiceProvider),
    client: ref.read(lanClientProvider),
    server: ref.read(lanServerProvider),
    discovery: ref.read(peerDiscoveryProvider),
    store: ref.read(syncStoreProvider),
    engine: ref.read(syncEngineProvider),
    backupBeforeReplace: () =>
        ref.read(autoBackupServiceProvider).runNow(keep: ref.read(settingsProvider).autoBackupKeep),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final mcpServerProvider = Provider<McpServer>((ref) {
  final server = McpServer(
    repository: ref.read(repositoryProvider),
    deviceTimeZone: () => ref.read(deviceTimeZoneProvider),
    clock: ref.read(clockProvider),
  );
  ref.onDispose(server.stop);
  return server;
});

final serviceCoordinatorProvider = Provider<ServiceCoordinator>(
  (ref) => ServiceCoordinator(
    repository: ref.read(repositoryProvider),
    sync: ref.read(syncServiceProvider),
    mcp: ref.read(mcpServerProvider),
  ),
);

class ServiceCoordinator {
  ServiceCoordinator({required this.repository, required this.sync, required this.mcp});

  final PlannerRepository repository;
  final SyncService sync;
  final McpServer mcp;

  /// Applies the opt-in switches. Failures are surfaced through each service's
  /// own state; the planner keeps working either way.
  Future<void> apply(AppSettings settings) async {
    if (settings.onlineEnabled) {
      await sync.start();
    } else {
      await sync.stop();
    }
    final identity = await repository.readIdentity();
    if (settings.onlineEnabled && settings.mcpEnabled && identity != null) {
      try {
        await mcp.start(identity: identity, writesEnabled: settings.mcpWritesEnabled, port: settings.mcpPort);
      } catch (_) {
        // A busy or invalid port must not take the app down. The switch checks
        // `mcp.lastError` and reverts with a notice.
      }
    } else {
      await mcp.stop();
    }
  }
}
