import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sundial_core/sundial_core.dart';

import '../core/i18n/l10n.dart';
import '../core/icons/aero_glyph.dart';
import '../core/sound/sound_service.dart';
import '../core/widgets/ui_kit.dart';
import '../features/home_widget/home_widget_service.dart';
import '../features/plan/pages/plan_page.dart';
import '../features/search/pages/search_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/spaces/pages/space_overview_page.dart';
import '../features/stats/pages/stats_page.dart';
import '../features/sync/pairing_request.dart';
import '../features/sync/sync_models.dart';
import '../features/sync/widgets/pairing_approval_dialog.dart';
import '../features/tags/widgets/tag_filter_sheet.dart';
import '../models/app_settings.dart';
import '../screens/entry_editor.dart';
import '../screens/today_screen.dart';
import '../services/notification_service.dart';
import '../services/reminder_planner.dart';
import '../state/providers.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _index = 0;
  Timer? _clockTimer;
  late final AnimationController _swap;
  final _sideSearch = TextEditingController();
  final _sideSearchFocus = FocusNode();
  StreamSubscription<PairingRequest>? _pairingSubscription;
  StreamSubscription<SyncApplyResult>? _syncApplySubscription;
  bool _pairingDialogOpen = false;

  static const _destinations = <_Destination>[
    _Destination(label: _Label.today, icon: Icons.today_outlined, selectedIcon: Icons.today),
    _Destination(label: _Label.work, icon: Icons.work_outline, selectedIcon: Icons.work),
    _Destination(label: _Label.home, icon: Icons.home_outlined, selectedIcon: Icons.home),
    _Destination(label: _Label.personal, icon: Icons.people_outline, selectedIcon: Icons.people),
    _Destination(label: _Label.plan, icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month),
    _Destination(label: _Label.stats, icon: Icons.insights_outlined, selectedIcon: Icons.insights),
  ];

  @override
  void initState() {
    super.initState();
    _swap = AnimationController(vsync: this, duration: const Duration(milliseconds: 280), value: 1);
    WidgetsBinding.instance.addObserver(this);
    _pairingSubscription = ref.read(syncServiceProvider).incomingPairingRequests.listen(_onPairingRequest);
    _syncApplySubscription = ref.read(syncServiceProvider).applyEvents.listen(_onSyncApplied);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) ref.invalidate(nowProvider);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pairingSubscription?.cancel();
    _syncApplySubscription?.cancel();
    _swap.dispose();
    _sideSearch.dispose();
    _sideSearchFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshTimeZoneAndSchedule();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final notifications = ref.read(notificationServiceProvider);
    notifications.onOpenEntry = _openEntry;
    notifications.onAction = _handleNotificationAction;
    final pending = notifications.takePendingEntry();
    if (pending != null) await _openEntry(pending);
    final pendingAction = notifications.takePendingAction();
    if (pendingAction != null) {
      await _handleNotificationAction(pendingAction.$1, pendingAction.$2, pendingAction.$3);
    }
    if (!mounted) return;
    await ref.read(reminderCoordinatorProvider).reschedule();
    await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
    ref.read(soundControllerProvider).preload();
    await _updateHomeWidget();
    unawaited(_runAutoBackup());
  }

  Future<void> _refreshTimeZoneAndSchedule() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      if (isKnownTimeZone(info.identifier)) {
        ref.read(deviceTimeZoneProvider.notifier).set(info.identifier);
      }
    } catch (_) {
      // Keep the last known zone when the platform lookup is unavailable.
    }
    if (!mounted) return;
    await ref.read(reminderCoordinatorProvider).reschedule();
    final settings = ref.read(settingsProvider);
    await ref.read(serviceCoordinatorProvider).apply(settings);
    if (settings.onlineEnabled) {
      await ref.read(syncServiceProvider).refresh();
    }
    await _updateHomeWidget();
    unawaited(_runAutoBackup());
  }

  Future<void> _onSyncApplied(SyncApplyResult result) async {
    if (!mounted) return;
    try {
      final entities = result.changedEntities;
      if (entities.contains('setting')) {
        await ref.read(settingsProvider.notifier).reload();
      }
      const reminderEntities = {
        'entry',
        'reminder',
        'shiftPattern',
        'shiftSlot',
        'shiftException',
        'completion',
        'shiftChecklistCompletion',
      };
      if (entities.any(reminderEntities.contains)) {
        await ref.read(reminderCoordinatorProvider).reschedule();
      }
      await _updateHomeWidget();
    } catch (error) {
      debugPrint('Sync side effects failed: $error');
    }
  }

  Future<void> _runAutoBackup() async {
    final settings = ref.read(settingsProvider);
    if (!settings.autoBackupEnabled) return;
    try {
      await ref.read(autoBackupServiceProvider).runIfDue(enabled: true, keep: settings.autoBackupKeep);
    } catch (error) {
      debugPrint('Auto backup failed: $error');
    }
  }

  Future<void> _updateHomeWidget() async {
    if (!mounted) return;
    final timeZone = ref.read(deviceTimeZoneProvider);
    final now = DateTime.now();
    final today = localDateAt(now, timeZone);
    final repository = ref.read(repositoryProvider);
    final entries = await repository.loadEntries(today, today, timeZone);
    final shifts = await repository.watchShifts(today, today, timeZone).first;
    final upcoming = await repository.watchShifts(today, today.addDays(7), timeZone).first;
    if (!mounted) return;
    await ref
        .read(homeWidgetServiceProvider)
        .update(
          buildHomeWidgetData(
            todayEntries: entries,
            todayShifts: shifts,
            upcomingShifts: upcoming,
            now: now,
            timeZone: timeZone,
            title: context.l10n.today,
            emptyText: context.l10n.noPlanToday,
            nextPrefix: context.l10n.nextShiftPrefix,
          ),
        );
  }

  Future<void> _openEntry(String id) async {
    final entry = await ref.read(repositoryProvider).readEntry(id);
    if (entry == null || !mounted) return;
    final spaces = ref.read(spacesProvider).value ?? fallbackSpaces;
    await showEntryEditor(context, entry: entry, initialDate: entry.date, spaces: spaces);
  }

  Future<void> _handleNotificationAction(String actionId, String entryId, LocalDate? date) async {
    final repository = ref.read(repositoryProvider);
    final entry = await repository.readEntry(entryId);
    if (entry == null || entry.deletedAt != null) return;
    // Imported entries are read-only. A notification action that arrives late
    // must be ignored, not thrown as an unhandled error.
    if (entry.readOnly) return;
    final timeZone = ref.read(deviceTimeZoneProvider);
    final today = localDateAt(ref.read(nowProvider), timeZone);

    if (actionId == NotificationService.completeAction) {
      if (entry.isMaintenance) {
        await repository.completeMaintenanceEntry(entryId, today);
      } else if (entry.recurrence != null && date != null) {
        await repository.setOccurrenceCompleted(entryId, date, true);
      } else {
        await repository.setEntryStatus(entryId, EntryStatus.done);
      }
      await ref.read(reminderCoordinatorProvider).reschedule();
      await _updateHomeWidget();
      return;
    }

    if (actionId == NotificationService.snoozeAction) {
      final occurrenceDate = date ?? today;
      await ref
          .read(notificationServiceProvider)
          .scheduleSnooze(
            notificationId: notificationIdFor(entryId, 'snooze', occurrenceDate.key),
            entryId: entryId,
            date: occurrenceDate,
            title: entry.title,
            body: entry.notes,
            fireAt: ref.read(clockProvider)().toUtc().add(const Duration(minutes: 10)),
          );
    }
  }

  Future<void> _onPairingRequest(PairingRequest request) async {
    if (!mounted || !request.pending || _pairingDialogOpen) return;
    _pairingDialogOpen = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PairingApprovalDialog(request: request),
      );
    } finally {
      _pairingDialogOpen = false;
    }
  }

  void _selectTab(int value) {
    if (value == _index) return;
    ref.read(soundControllerProvider).play(UiSound.nav);
    setState(() => _index = value);
    if (!MediaQuery.disableAnimationsOf(context)) _swap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      final becameEnabled = next.soundsEnabled && previous?.soundsEnabled != true;
      final packChanged = next.soundsEnabled && previous?.soundPack != next.soundPack;
      if (becameEnabled || packChanged) ref.read(soundControllerProvider).preload();
    });
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final c = context.mc;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _openSearch,
        for (var index = 0; index < _destinations.length; index++)
          SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + index), control: true): () =>
              _selectTab(index),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: AppBackground(
            style: settings.backgroundStyle,
            customColor: Color(settings.backgroundCustomColor),
            performanceMode: settings.performanceMode,
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 900;
                  final content = _shellContent(context, settings, spaces, c, desktop);
                  if (!desktop) return content;
                  final rail = _SideRail(
                    index: _index,
                    items: _destinations,
                    settings: settings,
                    searchController: _sideSearch,
                    searchFocus: _sideSearchFocus,
                    onSearchSubmitted: _submitSideSearch,
                    filterCount: ref.watch(tagFilterProvider).length,
                    onSelected: _selectTab,
                    onAdd: () => showEntryEditor(context, spaces: spaces),
                    onSettings: _openSettings,
                    onFilter: () => showTagFilterSheet(context),
                  );
                  return Row(
                    children: settings.navSide == SundialNavSide.right
                        ? [Expanded(child: content), rail]
                        : [rail, Expanded(child: content)],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _shellContent(
    BuildContext context,
    AppSettings settings,
    List<Space> spaces,
    SundialColors c,
    bool desktop,
  ) {
    final l10n = context.l10n;
    final filterCount = ref.watch(tagFilterProvider).length;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(desktop ? 20 : 18, 10, 16, 6),
          child: Row(
            children: [
              if (!desktop) ...[
                const SundialLogo(size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.appName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SundialType.headline(21, color: c.text),
                  ),
                ),
              ] else
                const Spacer(),
              if (!desktop) ...[
                SundialAddButton(
                  tooltip: l10n.addEntry,
                  size: 40,
                  onTap: () => showEntryEditor(context, spaces: spaces),
                ),
                const SizedBox(width: 8),
                GlassIconButton(icon: Icons.search, tooltip: l10n.search, onTap: _openSearch),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: filterCount > 0 ? Icons.filter_alt : Icons.filter_alt_outlined,
                  tooltip: l10n.filterByTag,
                  onTap: () => showTagFilterSheet(context),
                  badge: filterCount == 0 ? null : _FilterBadge(count: filterCount),
                ),
                const SizedBox(width: 8),
                GlassIconButton(icon: Icons.settings_outlined, tooltip: l10n.settings, onTap: _openSettings),
              ],
            ],
          ),
        ),
        Expanded(
          child: FadeThrough(
            animation: _swap,
            child: IndexedStack(
              index: _index,
              children: const [
                SundialContentPane(child: TodayScreen()),
                SundialContentPane(child: SpaceOverviewPage(spaceId: 'work')),
                SundialContentPane(child: SpaceOverviewPage(spaceId: 'home')),
                SundialContentPane(child: SpaceOverviewPage(spaceId: 'personal')),
                // Plan is a canvas: the month and week grids use the full width.
                PlanPage(),
                SundialContentPane(child: StatsPage()),
              ],
            ),
          ),
        ),
        if (!desktop)
          Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 12 + MediaQuery.paddingOf(context).bottom),
            child: SundialNavBar(
              index: _index,
              onSelected: _selectTab,
              items: [
                for (final item in _destinations)
                  (icon: item.icon, selectedIcon: item.selectedIcon, label: _label(context, item.label)),
              ],
            ),
          ),
      ],
    );
  }

  void _openSettings() {
    playUiSound(context, UiSound.open);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  void _openSearch() {
    if (MediaQuery.sizeOf(context).width >= 900) {
      _sideSearchFocus.requestFocus();
      return;
    }
    playUiSound(context, UiSound.open);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchPage()));
  }

  void _submitSideSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    _sideSearchFocus.unfocus();
    playUiSound(context, UiSound.open);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SearchPage(initialQuery: query)));
  }

  static String _label(BuildContext context, _Label label) => switch (label) {
    _Label.today => context.l10n.todayTab,
    _Label.work => context.l10n.workTab,
    _Label.home => context.l10n.homeTab,
    _Label.personal => context.l10n.personalTab,
    _Label.plan => context.l10n.planTab,
    _Label.stats => context.l10n.statsTab,
  };
}

enum _Label { today, work, home, personal, plan, stats }

/// The tag-filter count, shared by the phone header and the desktop rail.
class _FilterBadge extends StatelessWidget {
  const _FilterBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(SundialRadii.xs)),
      child: Text('$count', style: SundialType.label(9, color: c.onAccent)),
    );
  }
}

class _Destination {
  const _Destination({required this.label, required this.icon, required this.selectedIcon});

  final _Label label;
  final IconData icon;
  final IconData selectedIcon;
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.items,
    required this.settings,
    required this.searchController,
    required this.searchFocus,
    required this.onSearchSubmitted,
    required this.filterCount,
    required this.onSelected,
    required this.onAdd,
    required this.onSettings,
    required this.onFilter,
  });

  final int index;
  final List<_Destination> items;
  final AppSettings settings;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchSubmitted;
  final int filterCount;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;
  final VoidCallback onSettings;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final l10n = context.l10n;
    return SundialSidebar(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              children: [
                const SundialLogo(size: 38),
                const SizedBox(width: 10),
                Text(l10n.appName, style: SundialType.headline(20, color: c.text)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SundialSearchField(
              controller: searchController,
              focusNode: searchFocus,
              hint: l10n.search,
              onChanged: (_) {},
              onSubmitted: onSearchSubmitted,
              trailing: SundialSearchAction(
                icon: filterCount > 0 ? Icons.filter_alt : Icons.filter_alt_outlined,
                tooltip: l10n.filterByTag,
                selected: filterCount > 0,
                onTap: onFilter,
                badge: filterCount == 0 ? null : _FilterBadge(count: filterCount),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SundialSidebarList(
              children: [
                for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
                  SundialSidebarItem(
                    icon: items[itemIndex].icon,
                    selectedIcon: items[itemIndex].selectedIcon,
                    title: _AppShellState._label(context, items[itemIndex].label),
                    selected: itemIndex == index,
                    onTap: () => onSelected(itemIndex),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 19),
                label: Text(l10n.addEntry),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: SundialSidebarItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              title: l10n.settings,
              onTap: onSettings,
            ),
          ),
        ],
      ),
    );
  }
}
