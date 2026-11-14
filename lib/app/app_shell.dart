import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:mane_core/mane_core.dart';

import '../core/i18n/l10n.dart';
import '../core/sound/sound_service.dart';
import '../core/widgets/ui_kit.dart';
import '../features/home_widget/home_widget_service.dart';
import '../features/plan/pages/plan_page.dart';
import '../features/search/pages/search_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/spaces/pages/space_overview_page.dart';
import '../features/stats/pages/stats_page.dart';
import '../features/tags/widgets/tag_filter_sheet.dart';
import '../models/app_settings.dart';
import '../screens/entry_editor.dart';
import '../screens/today_screen.dart';
import '../services/notification_service.dart';
import '../services/reminder_planner.dart';
import '../state/providers.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
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
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) ref.invalidate(nowProvider);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
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

  void _selectTab(int value) {
    if (value == _index) return;
    ref.read(soundControllerProvider).play(UiSound.tap);
    setState(() => _index = value);
    if (!MediaQuery.disableAnimationsOf(context)) _swap.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
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
            aero: settings.isAero,
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
                    children: settings.navSide == ManeNavSide.right
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
    ManeColors c,
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(13)),
                  child: Icon(Icons.event_note, size: 21, color: c.onAccent),
                ),
                const SizedBox(width: 10),
                Text(l10n.appName, style: ManeType.headline(21, color: c.text)),
              ],
              const Spacer(),
              if (!desktop) ...[
                GlassIconButton(icon: Icons.search, tooltip: l10n.search, onTap: _openSearch),
                const SizedBox(width: 8),
                GlassIconButton(
                  icon: filterCount > 0 ? Icons.filter_alt : Icons.filter_alt_outlined,
                  tooltip: l10n.filterByTag,
                  onTap: () => showTagFilterSheet(context),
                  badge: filterCount == 0
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(8)),
                          child: Text('$filterCount', style: ManeType.label(9, color: c.onAccent)),
                        ),
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
                TodayScreen(),
                SpaceOverviewPage(spaceId: 'work'),
                SpaceOverviewPage(spaceId: 'home'),
                SpaceOverviewPage(spaceId: 'personal'),
                PlanPage(),
                StatsPage(),
              ],
            ),
          ),
        ),
        if (!desktop)
          Padding(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 10 + MediaQuery.paddingOf(context).bottom),
            child: Row(
              children: [
                Expanded(
                  child: ManeNavBar(
                    index: _index,
                    onSelected: _selectTab,
                    items: [
                      for (final item in _destinations)
                        (
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: _label(context, item.label),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ManeAddButton(
                  tooltip: l10n.addEntry,
                  onTap: () => showEntryEditor(context, spaces: spaces),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  void _openSearch() {
    if (MediaQuery.sizeOf(context).width >= 900) {
      _sideSearchFocus.requestFocus();
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchPage()));
  }

  void _submitSideSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    _sideSearchFocus.unfocus();
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
    return Container(
      width: 236,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: c.navBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 26, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(13)),
                  child: Icon(Icons.event_note, size: 21, color: c.onAccent),
                ),
                const SizedBox(width: 10),
                Text(l10n.appName, style: ManeType.headline(20, color: c.text)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onFilter,
                  tooltip: l10n.filterByTag,
                  icon: Badge(
                    isLabelVisible: filterCount > 0,
                    label: Text('$filterCount'),
                    child: const Icon(Icons.filter_alt_outlined, size: 19),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
                  _RailItem(
                    item: items[itemIndex],
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
            child: _RailItem(
              item: const _Destination(
                label: _Label.stats,
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
              ),
              labelOverride: l10n.settings,
              selected: false,
              onTap: onSettings,
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.item, required this.selected, required this.onTap, this.labelOverride});

  final _Destination item;
  final bool selected;
  final VoidCallback onTap;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final label = labelOverride ?? _AppShellState._label(context, item.label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Pressable(
        onTap: onTap,
        semanticButton: true,
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: selected ? Border.all(color: c.accent.withValues(alpha: 0.2)) : null,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: selected ? c.accent : c.textSecondary,
              ),
              const SizedBox(width: 11),
              Text(
                label,
                style: ManeType.body(
                  13,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c.accent : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
