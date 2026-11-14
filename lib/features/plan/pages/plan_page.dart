import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../screens/entry_editor.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../calendar/widgets/day_detail.dart';
import '../../calendar/widgets/day_timeline.dart';
import '../../calendar/widgets/month_grid.dart';
import '../../calendar/widgets/week_strip.dart';
import '../widgets/week_time_grid.dart';

enum _MobileMode { list, timeline }

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  late LocalDate _selected;
  late LocalDate _visibleMonth;
  bool _expanded = true;
  _MobileMode _mode = _MobileMode.list;

  @override
  void initState() {
    super.initState();
    final today = localDateAt(ref.read(nowProvider), ref.read(deviceTimeZoneProvider));
    _selected = today;
    _visibleMonth = LocalDate(today.year, today.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final now = ref.watch(nowProvider);
    final today = localDateAt(now, timeZone);
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final weekStart = settings.weekStart;
    final selectedWeek = _selected.startOfWeek(weekStart);
    final rangeStart = _expanded ? _visibleMonth.startOfWeek(weekStart) : selectedWeek;
    final rangeEnd = _expanded ? rangeStart.addDays(55) : selectedWeek.addDays(6);
    final range = (start: rangeStart, end: rangeEnd);
    final entriesState = ref.watch(entriesProvider(range));
    final shiftsState = ref.watch(shiftsProvider(range));
    final visibleEntries = (entriesState.value ?? const <EntryOccurrence>[]).where((entry) {
      if (entry.entry.spaceId != 'work') return true;
      if (settings.hideWorkSpace) return false;
      if (entry.entry.kind == EntryKind.deadline) return true;
      return settings.isWorkTime(now, timeZone);
    }).toList();
    final visibleShifts = settings.hideWorkSpace || !settings.isWorkTime(now, timeZone)
        ? const <ShiftOccurrence>[]
        : shiftsState.value ?? const <ShiftOccurrence>[];

    final colors = {for (final space in spaces) space.id: space.colorValue};
    final markers = <int, Set<int>>{};
    for (final entry in visibleEntries) {
      (markers[entry.displayDate.key] ??= <int>{}).add(colors[entry.entry.spaceId] ?? 0xFF888888);
    }
    final shiftDays = {for (final shift in visibleShifts) shift.displayDate.key};
    final selectedEntries = visibleEntries.where((entry) => entry.displayDate == _selected).toList();
    final selectedShifts = visibleShifts.where((shift) => shift.displayDate == _selected).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // The shell switches to the side rail at 900 window px. Plan content
        // loses the rail width, so use the window width here as well.
        final desktop = MediaQuery.sizeOf(context).width >= 900;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
              child: _PlanHeader(
                title: _title(context),
                desktop: desktop,
                onPrevious: () => _step(context, -1),
                onNext: () => _step(context, 1),
                onToday: () => _goToToday(today),
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
            ),
            if (entriesState.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ManeNotice(text: l10n.couldNotLoadDay('${entriesState.error}')),
              ),
            if (shiftsState.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ManeNotice(text: l10n.couldNotLoadShifts('${shiftsState.error}')),
              ),
            Expanded(
              child: desktop
                  ? _desktop(
                      context,
                      spaces: spaces,
                      entries: visibleEntries,
                      shifts: visibleShifts,
                      markers: markers,
                      shiftDays: shiftDays,
                      today: today,
                      weekStart: weekStart,
                      timeZone: timeZone,
                      now: now,
                    )
                  : _mobile(
                      context,
                      spaces: spaces,
                      selectedEntries: selectedEntries,
                      selectedShifts: selectedShifts,
                      markers: markers,
                      shiftDays: shiftDays,
                      today: today,
                      weekStart: weekStart,
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _mobile(
    BuildContext context, {
    required List<Space> spaces,
    required List<EntryOccurrence> selectedEntries,
    required List<ShiftOccurrence> selectedShifts,
    required Map<int, Set<int>> markers,
    required Set<int> shiftDays,
    required LocalDate today,
    required int weekStart,
  }) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        SoftCard(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? MonthGrid(
                    month: _visibleMonth,
                    selected: _selected,
                    today: today,
                    weekStart: weekStart,
                    markers: markers,
                    shiftDays: shiftDays,
                    onSelected: _select,
                  )
                : WeekStrip(
                    selected: _selected,
                    today: today,
                    weekStart: weekStart,
                    markers: markers,
                    shiftDays: shiftDays,
                    onSelected: _select,
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(l10n.selectedDay, style: ManeType.label(11, color: context.mc.textTertiary)),
            ),
            ManeSegmented<_MobileMode>(
              segments: [
                ManeSegment(value: _MobileMode.list, label: l10n.listView, icon: Icons.checklist),
                ManeSegment(
                  value: _MobileMode.timeline,
                  label: l10n.timelineView,
                  icon: Icons.view_day_outlined,
                ),
              ],
              selected: _mode,
              onChanged: (value) => setState(() => _mode = value),
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          child: _mode == _MobileMode.list
              ? SoftCard(
                  key: const ValueKey('plan-list'),
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: CalendarDayDetail(
                    date: _selected,
                    entries: selectedEntries,
                    shifts: selectedShifts,
                    spaces: spaces,
                    onAdd: () => showEntryEditor(context, initialDate: _selected, spaces: spaces),
                  ),
                )
              : SoftCard(
                  key: const ValueKey('plan-timeline'),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: DayTimeline(
                    day: _selected,
                    entries: selectedEntries,
                    shifts: selectedShifts,
                    spaces: spaces,
                    onAdd: () => showEntryEditor(context, initialDate: _selected, spaces: spaces),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _desktop(
    BuildContext context, {
    required List<Space> spaces,
    required List<EntryOccurrence> entries,
    required List<ShiftOccurrence> shifts,
    required Map<int, Set<int>> markers,
    required Set<int> shiftDays,
    required LocalDate today,
    required int weekStart,
    required String timeZone,
    required DateTime now,
  }) {
    final week = _selected.startOfWeek(weekStart);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 286,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: SoftCard(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: AnimatedSize(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _expanded
                            ? MonthGrid(
                                month: _visibleMonth,
                                selected: _selected,
                                today: today,
                                weekStart: weekStart,
                                markers: markers,
                                shiftDays: shiftDays,
                                onSelected: _select,
                              )
                            : WeekStrip(
                                selected: _selected,
                                today: today,
                                weekStart: weekStart,
                                markers: markers,
                                shiftDays: shiftDays,
                                onSelected: _select,
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: WeekTimeGrid(
              weekStart: week,
              entries: entries,
              shifts: shifts,
              spaces: spaces,
              timeZone: timeZone,
              now: now,
              onOpen: (occurrence) => showEntryEditor(
                context,
                entry: occurrence.entry,
                initialDate: occurrence.date,
                spaces: spaces,
              ),
              onCreate: (date, start, end) => showEntryEditor(
                context,
                initialDate: date,
                initialStartMinute: start,
                initialEndMinute: end,
                spaces: spaces,
              ),
              onMove: (occurrence, date, start, end) => _move(context, occurrence, date, start, end),
              onResize: (occurrence, end) => _resize(context, occurrence, end),
            ),
          ),
        ],
      ),
    );
  }

  String _title(BuildContext context) => formatMonthYear(
    context,
    (_expanded ? _visibleMonth : _selected.startOfWeek(ref.read(settingsProvider).weekStart)).toDateTime(),
  );

  void _step(BuildContext context, int direction) {
    setState(() {
      if (_expanded) {
        final index = _visibleMonth.year * 12 + _visibleMonth.month - 1 + direction;
        _visibleMonth = LocalDate(index ~/ 12, index % 12 + 1, 1);
        _selected = _visibleMonth;
      } else {
        _selected = _selected.startOfWeek(ref.read(settingsProvider).weekStart).addDays(7 * direction);
        _visibleMonth = LocalDate(_selected.year, _selected.month, 1);
      }
    });
  }

  void _select(LocalDate date) {
    setState(() {
      _selected = date;
      _visibleMonth = LocalDate(date.year, date.month, 1);
    });
  }

  void _goToToday(LocalDate today) {
    setState(() {
      _selected = today;
      _visibleMonth = LocalDate(today.year, today.month, 1);
    });
  }

  Future<void> _move(
    BuildContext context,
    EntryOccurrence occurrence,
    LocalDate date,
    int start,
    int end,
  ) async {
    final entry = occurrence.entry;
    if (entry.readOnly) return;
    final repository = ref.read(repositoryProvider);
    final now = DateTime.now().toUtc();
    try {
      if (entry.recurrence != null) {
        final rule = entry.recurrence!;
        final overrides = [
          for (final override in rule.overrides)
            if (override.date != occurrence.date) override,
          RecurrenceOverride(
            date: occurrence.date,
            dateOverride: date == occurrence.date ? null : date,
            startMinute: start,
            endMinute: end,
          ),
        ];
        await repository.saveEntry(
          entry.copyWith(
            recurrence: rule.copyWith(overrides: overrides),
            updatedAt: now,
          ),
        );
      } else {
        final span = entry.date != null && entry.endDate != null
            ? entry.endDate!.differenceInDays(entry.date!)
            : 0;
        await repository.saveEntry(
          entry.copyWith(
            date: date,
            endDate: span > 0 ? date.addDays(span) : null,
            startMinute: start,
            endMinute: end,
            updatedAt: now,
          ),
        );
      }
      await ref.read(reminderCoordinatorProvider).reschedule();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotMoveEntry('$error'))));
    }
  }

  Future<void> _resize(BuildContext context, EntryOccurrence occurrence, int end) async {
    final entry = occurrence.entry;
    if (entry.readOnly || entry.startMinute == null) return;
    final start = occurrence.startAt == null
        ? entry.startMinute!
        : _minuteOfDay(occurrence.startAt!, ref.read(deviceTimeZoneProvider));
    var safeEnd = math.max(start + 15, end);
    if (entry.endDate != null) safeEnd = math.min(1439, safeEnd);
    final repository = ref.read(repositoryProvider);
    final now = DateTime.now().toUtc();
    try {
      if (entry.recurrence != null) {
        final rule = entry.recurrence!;
        final overrides = [
          for (final override in rule.overrides)
            if (override.date != occurrence.date) override,
          RecurrenceOverride(
            date: occurrence.date,
            dateOverride: null,
            startMinute: start,
            endMinute: safeEnd,
          ),
        ];
        await repository.saveEntry(
          entry.copyWith(
            recurrence: rule.copyWith(overrides: overrides),
            updatedAt: now,
          ),
        );
      } else {
        await repository.saveEntry(entry.copyWith(endMinute: safeEnd, updatedAt: now));
      }
      await ref.read(reminderCoordinatorProvider).reschedule();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotMoveEntry('$error'))));
    }
  }

  int _minuteOfDay(DateTime instant, String timeZone) => localMinuteAt(instant, timeZone);
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({
    required this.title,
    required this.desktop,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final bool desktop;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(l10n.plan, color: c.accent),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ManeType.headline(24, color: c.text),
              ),
            ],
          ),
        ),
        GlassIconButton(icon: Icons.today, tooltip: l10n.jumpToToday, size: 34, onTap: onToday),
        const SizedBox(width: 4),
        GlassIconButton(
          icon: Icons.chevron_left,
          tooltip: desktop ? l10n.previousWeek : l10n.previousMonth,
          size: 34,
          onTap: onPrevious,
        ),
        GlassIconButton(
          icon: Icons.chevron_right,
          tooltip: desktop ? l10n.nextWeek : l10n.nextMonth,
          size: 34,
          onTap: onNext,
        ),
        const SizedBox(width: 4),
        GlassIconButton(
          icon: expanded ? Icons.unfold_less : Icons.unfold_more,
          tooltip: expanded ? l10n.collapseCalendar : l10n.expandCalendar,
          size: 34,
          onTap: onToggle,
        ),
      ],
    );
  }
}
