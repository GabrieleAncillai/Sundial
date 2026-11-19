import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../screens/entry_editor.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../calendar/widgets/day_timeline.dart';
import '../../calendar/widgets/month_calendar.dart';
import '../widgets/week_day_strip.dart';
import '../widgets/week_time_grid.dart';

enum _PlanView { month, timeline }

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> with SingleTickerProviderStateMixin {
  late LocalDate _selected;
  late LocalDate _visibleMonth;
  bool _expanded = true;
  late final AnimationController _fold;

  @override
  void initState() {
    super.initState();
    final today = localDateAt(ref.read(nowProvider), ref.read(deviceTimeZoneProvider));
    _selected = today;
    _visibleMonth = LocalDate(today.year, today.month, 1);
    _fold = AnimationController(vsync: this, duration: const Duration(milliseconds: 360), value: 1);
  }

  @override
  void dispose() {
    _fold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final now = ref.watch(nowProvider);
    final today = localDateAt(now, timeZone);
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final contexts = ref.watch(contextsProvider(null)).value ?? const <PlannerContext>[];
    final weekStart = settings.weekStart;
    final desktop = MediaQuery.sizeOf(context).width >= 1024;

    // The month surface always fetches every possible grid row, so flipping
    // between months never shows an empty tail.
    final monthFirst = _visibleMonth.startOfWeek(weekStart);
    final monthRange = (start: monthFirst, end: monthFirst.addDays(41));
    final timelineStart = desktop ? _selected.startOfWeek(weekStart) : _selected;
    final timelineRange = (start: timelineStart, end: desktop ? timelineStart.addDays(6) : timelineStart);

    final monthEntriesState = ref.watch(entriesProvider(monthRange));
    final monthShiftsState = ref.watch(shiftsProvider(monthRange));
    final timelineEntriesState = ref.watch(entriesProvider(timelineRange));
    final timelineShiftsState = ref.watch(shiftsProvider(timelineRange));

    bool showsEntry(EntryOccurrence entry) {
      if (entry.entry.spaceId != 'work') return true;
      if (settings.hideWorkSpace) return false;
      if (entry.entry.kind == EntryKind.deadline) return true;
      return settings.isWorkTime(now, timeZone);
    }

    List<EntryOccurrence> visibleEntries(AsyncValue<List<EntryOccurrence>> state) =>
        (state.value ?? const <EntryOccurrence>[]).where(showsEntry).toList();

    List<ShiftOccurrence> visibleShifts(AsyncValue<List<ShiftOccurrence>> state) =>
        settings.hideWorkSpace || !settings.isWorkTime(now, timeZone)
        ? const <ShiftOccurrence>[]
        : state.value ?? const <ShiftOccurrence>[];

    final monthEntries = visibleEntries(monthEntriesState);
    final monthShifts = visibleShifts(monthShiftsState);
    final timelineEntries = visibleEntries(timelineEntriesState);
    final timelineShifts = visibleShifts(timelineShiftsState);
    final entriesError = monthEntriesState.error ?? timelineEntriesState.error;
    final shiftsError = monthShiftsState.error ?? timelineShiftsState.error;

    return Padding(
      padding: EdgeInsets.fromLTRB(desktop ? 20 : 16, 10, desktop ? 16 : 16, 8),
      child: Column(
        children: [
          _PlanHeader(
            title: _title(context, desktop),
            previousTooltip: _expanded
                ? l10n.previousMonth
                : desktop
                ? l10n.previousWeek
                : l10n.previousDay,
            nextTooltip: _expanded
                ? l10n.nextMonth
                : desktop
                ? l10n.nextWeek
                : l10n.nextDay,
            onPrevious: () => _step(desktop, -1),
            onNext: () => _step(desktop, 1),
          ),
          if (entriesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SundialNotice(text: l10n.couldNotLoadDay('$entriesError')),
            ),
          if (shiftsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SundialNotice(text: l10n.couldNotLoadShifts('$shiftsError')),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final timeline = _timelinePanel(
                  context,
                  desktop: desktop,
                  entries: timelineEntries,
                  shifts: timelineShifts,
                  spaces: spaces,
                  contexts: contexts,
                  timeZone: timeZone,
                  now: now,
                  today: today,
                  weekStart: weekStart,
                );
                final month = _monthPanel(
                  context,
                  entries: monthEntries,
                  shifts: monthShifts,
                  spaces: spaces,
                  contexts: contexts,
                  today: today,
                  weekStart: weekStart,
                  timeZone: timeZone,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    KeyedSubtree(
                      key: ValueKey(desktop ? 'plan-week' : 'plan-day'),
                      child: ExcludeSemantics(
                        excluding: _expanded,
                        child: IgnorePointer(ignoring: _expanded, child: timeline),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _fold,
                      builder: (context, child) {
                        final extent = Curves.easeInOutCubic.transform(_fold.value);
                        if (extent <= 0) return const SizedBox.shrink();
                        return Positioned(
                          left: 0,
                          top: 0,
                          right: 0,
                          height: constraints.maxHeight * extent,
                          child: DecoratedBox(
                            key: const ValueKey('plan-fold'),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(SundialRadii.lg),
                              boxShadow: [
                                if (extent > 0 && extent < 1)
                                  BoxShadow(
                                    color: context.mc.shadow,
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                              ],
                            ),
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topCenter,
                                minHeight: constraints.maxHeight,
                                maxHeight: constraints.maxHeight,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: KeyedSubtree(key: const ValueKey('plan-month'), child: month),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _PlanToolbar(
            expanded: _expanded,
            desktop: desktop,
            onCollapse: () => _setExpanded(false),
            onExpand: () => _setExpanded(true),
            onToday: () => _goToToday(today),
            onViewChanged: (view) => _setExpanded(view == _PlanView.month),
            onAdd: () => showEntryEditor(context, initialDate: _selected, spaces: spaces),
          ),
        ],
      ),
    );
  }

  Widget _monthPanel(
    BuildContext context, {
    required List<EntryOccurrence> entries,
    required List<ShiftOccurrence> shifts,
    required List<Space> spaces,
    required List<PlannerContext> contexts,
    required LocalDate today,
    required int weekStart,
    required String timeZone,
  }) {
    final c = context.mc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SundialRadii.lg),
        border: Border.all(color: c.border),
      ),
      child: MonthCalendar(
        month: _visibleMonth,
        selected: _selected,
        today: today,
        weekStart: weekStart,
        entries: entries,
        shifts: shifts,
        spaces: spaces,
        contexts: contexts,
        viewerTimeZone: timeZone,
        onSelected: _select,
        onOpenEntry: (occurrence) =>
            showEntryEditor(context, entry: occurrence.entry, initialDate: occurrence.date, spaces: spaces),
      ),
    );
  }

  Widget _timelinePanel(
    BuildContext context, {
    required bool desktop,
    required List<EntryOccurrence> entries,
    required List<ShiftOccurrence> shifts,
    required List<Space> spaces,
    required List<PlannerContext> contexts,
    required String timeZone,
    required DateTime now,
    required LocalDate today,
    required int weekStart,
  }) {
    final c = context.mc;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(SundialRadii.lg),
        border: Border.all(color: c.border),
      ),
      padding: EdgeInsets.fromLTRB(10, 10, 10, desktop ? 6 : 8),
      child: desktop
          ? WeekTimeGrid(
              weekStart: _selected.startOfWeek(ref.read(settingsProvider).weekStart),
              entries: entries,
              shifts: shifts,
              spaces: spaces,
              contexts: contexts,
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
            )
          : Column(
              children: [
                WeekDayStrip(selected: _selected, today: today, weekStart: weekStart, onSelected: _select),
                const SizedBox(height: 4),
                Expanded(
                  child: DayTimeline(
                    fill: true,
                    day: _selected,
                    entries: entries,
                    shifts: shifts,
                    spaces: spaces,
                    contexts: contexts,
                    onAdd: () => showEntryEditor(context, initialDate: _selected, spaces: spaces),
                  ),
                ),
              ],
            ),
    );
  }

  String _title(BuildContext context, bool desktop) {
    if (_expanded) return formatMonthYear(context, _visibleMonth.toDateTime());
    if (desktop) {
      final start = _selected.startOfWeek(ref.read(settingsProvider).weekStart);
      final end = start.addDays(6);
      return '${formatShortDate(context, start.toDateTime())} – '
          '${formatShortDate(context, end.toDateTime())}';
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return '${DateFormat.EEEE(locale).format(_selected.toDateTime())} · '
        '${formatShortDate(context, _selected.toDateTime())}';
  }

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    setState(() => _expanded = value);
    if (MediaQuery.disableAnimationsOf(context)) {
      _fold.value = value ? 1 : 0;
    } else if (value) {
      _fold.forward();
    } else {
      _fold.reverse();
    }
  }

  void _step(bool desktop, int direction) {
    setState(() {
      if (_expanded) {
        final index = _visibleMonth.year * 12 + _visibleMonth.month - 1 + direction;
        final month = LocalDate(index ~/ 12, index % 12 + 1, 1);
        final day = _selected.day.clamp(1, month.daysInMonth);
        _visibleMonth = month;
        _selected = LocalDate(month.year, month.month, day);
      } else {
        _selected = desktop
            ? _selected.startOfWeek(ref.read(settingsProvider).weekStart).addDays(7 * direction)
            : _selected.addDays(direction);
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
    // The grid and task cards hand back the expanded occurrence, whose title
    // and notes already include the override. Persist against the stored series
    // so an occurrence rename never rewrites every occurrence.
    final series = await repository.readEntry(entry.id) ?? entry;
    if (series.readOnly) return;
    final now = DateTime.now().toUtc();
    // The grid gives wall-clock minutes in the device zone. Store them in the
    // entry's own zone so an entry defined elsewhere keeps its local clock time.
    final deviceZone = ref.read(deviceTimeZoneProvider);
    final storedZone = series.timeZone;
    final LocalDate targetDate;
    final int targetStart;
    if (storedZone != null && storedZone != deviceZone && series.timing != EntryTiming.anytime) {
      final instant = instantAt(date, start, deviceZone);
      targetDate = localDateAt(instant, storedZone);
      targetStart = localMinuteAt(instant, storedZone);
    } else {
      targetDate = date;
      targetStart = start;
    }
    final shapeStart = series.timing == EntryTiming.deadline || series.timing == EntryTiming.anytime
        ? null
        : targetStart;
    final targetEnd = storedZone != null && storedZone != deviceZone && series.timing == EntryTiming.deadline
        ? localMinuteAt(instantAt(date, end, deviceZone), storedZone)
        : end;
    final shapedEnd = _movedEnd(series, targetStart, targetEnd);
    try {
      if (series.recurrence != null) {
        final rule = series.recurrence!;
        final previous = _existingOverride(rule, occurrence.date);
        final overrides = [
          for (final override in rule.overrides)
            if (override.date != occurrence.date) override,
          RecurrenceOverride(
            date: occurrence.date,
            dateOverride: targetDate == occurrence.date ? null : targetDate,
            startMinute: shapeStart,
            endMinute: shapedEnd,
            allDay: previous?.allDay,
            title: previous?.title,
            notes: previous?.notes,
          ),
        ];
        await repository.saveEntry(
          series.copyWith(
            recurrence: rule.copyWith(overrides: overrides),
            updatedAt: now,
          ),
        );
      } else {
        final span = series.date != null && series.endDate != null
            ? series.endDate!.differenceInDays(series.date!)
            : 0;
        await repository.saveEntry(
          series.copyWith(
            date: targetDate,
            endDate: span > 0 ? targetDate.addDays(span) : null,
            startMinute: shapeStart,
            endMinute: shapedEnd,
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

  /// End minute for a moved block. A multi-day timed entry keeps its template
  /// end on the shifted end date; a single-day entry keeps its duration.
  int? _movedEnd(Entry series, int start, int end) {
    if (series.timing == EntryTiming.clockIn || series.timing == EntryTiming.anytime) return null;
    if (series.endDate != null) return series.endMinute;
    final templateStart = series.startMinute;
    final templateEnd = series.endMinute;
    if (templateStart == null || templateEnd == null) return end;
    return start + (templateEnd - templateStart);
  }

  RecurrenceOverride? _existingOverride(RecurrenceRule rule, LocalDate date) {
    for (final override in rule.overrides) {
      if (override.date == date) return override;
    }
    return null;
  }

  Future<void> _resize(BuildContext context, EntryOccurrence occurrence, int end) async {
    final repository = ref.read(repositoryProvider);
    final series = await repository.readEntry(occurrence.entry.id) ?? occurrence.entry;
    if (series.readOnly || series.timing != EntryTiming.scheduled) return;
    final deviceZone = ref.read(deviceTimeZoneProvider);
    final storedZone = series.timeZone ?? deviceZone;
    final start = occurrence.startAt == null
        ? series.startMinute!
        : _minuteOfDay(occurrence.startAt!, storedZone);
    final endMinute = storedZone == deviceZone
        ? end
        : _minuteOfDay(instantAt(occurrence.displayDate, end, deviceZone), storedZone);
    var safeEnd = math.max(start + 15, endMinute);
    if (series.endDate != null) safeEnd = math.min(1439, safeEnd);
    final now = DateTime.now().toUtc();
    try {
      if (series.recurrence != null) {
        final rule = series.recurrence!;
        final previous = _existingOverride(rule, occurrence.date);
        final overrides = [
          for (final override in rule.overrides)
            if (override.date != occurrence.date) override,
          RecurrenceOverride(
            date: occurrence.date,
            dateOverride: previous?.dateOverride,
            startMinute: start,
            endMinute: safeEnd,
            allDay: previous?.allDay,
            title: previous?.title,
            notes: previous?.notes,
          ),
        ];
        await repository.saveEntry(
          series.copyWith(
            recurrence: rule.copyWith(overrides: overrides),
            updatedAt: now,
          ),
        );
      } else {
        await repository.saveEntry(series.copyWith(endMinute: safeEnd, updatedAt: now));
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
    required this.previousTooltip,
    required this.nextTooltip,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String previousTooltip;
  final String nextTooltip;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(context.l10n.plan, color: c.accent),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: Align(
                  key: ValueKey(title),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SundialType.headline(24, color: c.text),
                  ),
                ),
              ),
            ],
          ),
        ),
        GlassIconButton(icon: Icons.chevron_left, tooltip: previousTooltip, size: 36, onTap: onPrevious),
        const SizedBox(width: 8),
        GlassIconButton(icon: Icons.chevron_right, tooltip: nextTooltip, size: 36, onTap: onNext),
      ],
    );
  }
}

class _PlanToolbar extends StatelessWidget {
  const _PlanToolbar({
    required this.expanded,
    required this.desktop,
    required this.onCollapse,
    required this.onExpand,
    required this.onToday,
    required this.onViewChanged,
    required this.onAdd,
  });

  final bool expanded;
  final bool desktop;
  final VoidCallback onCollapse;
  final VoidCallback onExpand;
  final VoidCallback onToday;
  final ValueChanged<_PlanView> onViewChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final l10n = context.l10n;
    final narrow = MediaQuery.sizeOf(context).width < 520;

    final today = narrow
        ? GlassIconButton(icon: Icons.today_outlined, tooltip: l10n.jumpToToday, size: 32, onTap: onToday)
        : GlassPill(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onTap: onToday,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.today_outlined, size: 14, color: c.textSecondary),
                const SizedBox(width: 5),
                Text(l10n.today, style: SundialType.label(11.5, color: c.text)),
              ],
            ),
          );

    // Phones do not have room for two chevrons plus Today and the view switch,
    // so the chevron becomes a single toggle. Desktop keeps the pair.
    final controls = narrow
        ? <Widget>[
            GlassIconButton(
              icon: expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              tooltip: expanded ? l10n.collapseCalendar : l10n.expandCalendar,
              size: 32,
              onTap: expanded ? onCollapse : onExpand,
            ),
            const SizedBox(width: 6),
            today,
          ]
        : <Widget>[
            GlassIconButton(
              icon: Icons.keyboard_arrow_up,
              tooltip: l10n.collapseCalendar,
              size: 32,
              onTap: expanded ? onCollapse : null,
            ),
            const SizedBox(width: 2),
            GlassIconButton(
              icon: Icons.keyboard_arrow_down,
              tooltip: l10n.expandCalendar,
              size: 32,
              onTap: expanded ? null : onExpand,
            ),
            const SizedBox(width: 6),
            today,
          ];

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min, children: controls),
          ),
        ),
        SundialSegmented<_PlanView>(
          segments: [
            SundialSegment(value: _PlanView.month, label: l10n.monthView),
            SundialSegment(value: _PlanView.timeline, label: desktop ? l10n.weekView : l10n.dayView),
          ],
          selected: expanded ? _PlanView.month : _PlanView.timeline,
          onChanged: onViewChanged,
          compact: true,
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: GlassIconButton(icon: Icons.add, tooltip: l10n.addEntry, size: 34, onTap: onAdd),
          ),
        ),
      ],
    );
  }
}
