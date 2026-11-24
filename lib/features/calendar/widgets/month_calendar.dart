import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/sundial_style.dart';
import '../../shifts/shift_palette.dart';

/// A full-surface month grid with one cell per day and chips for everything
/// planned on it.
///
/// This is the expanded Plan view. The compact [MonthGrid] stays in the
/// Calendar page, where a month is only a date picker and markers are enough.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.today,
    required this.weekStart,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
    required this.viewerTimeZone,
    required this.onSelected,
    required this.onOpenEntry,
  });

  /// First day of the visible month.
  final LocalDate month;
  final LocalDate selected;
  final LocalDate today;
  final int weekStart;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;
  final String viewerTimeZone;
  final ValueChanged<LocalDate> onSelected;
  final ValueChanged<EntryOccurrence> onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final firstOfMonth = LocalDate(month.year, month.month, 1);
    final gridStart = firstOfMonth.startOfWeek(weekStart);
    final leading = firstOfMonth.differenceInDays(gridStart);
    // A four-week February would leave a very tall, sparse month. Five rows
    // keep the surface stable; six is the normal maximum.
    final weeks = math.max(5, ((leading + month.daysInMonth) / 7).ceil());
    final items = _groupItems(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Column(
      children: [
        _WeekdayHeader(weekStart: weekStart, background: c.surfaceAlt.withValues(alpha: 0.75)),
        Expanded(
          child: Column(
            children: [
              for (var row = 0; row < weeks; row++)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < 7; column++)
                        Expanded(
                          child: _DayCell(
                            date: gridStart.addDays(row * 7 + column),
                            month: month,
                            selected: selected,
                            today: today,
                            items: items,
                            locale: locale,
                            onSelected: onSelected,
                            onOpenEntry: onOpenEntry,
                            borderRight: column < 6,
                            borderBottom: row < weeks - 1,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Map<int, List<_MonthItem>> _groupItems(BuildContext context) {
    final colors = <String, Color>{for (final space in spaces) space.id: Color(space.colorValue)};
    final grouped = <int, List<_MonthItem>>{};

    for (final entry in entries) {
      final color = colors[entry.entry.spaceId] ?? context.mc.forSpace(entry.entry.spaceId);
      (grouped[entry.displayDate.key] ??= <_MonthItem>[]).add(
        _MonthItem(
          title: entry.entry.title,
          color: color,
          soft: color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.24 : 0.15),
          startAt: entry.startAt,
          displayDate: entry.displayDate,
          viewerTimeZone: viewerTimeZone,
          completed: entry.completed,
          isShift: false,
          occurrence: entry,
        ),
      );
    }

    for (final shift in shifts) {
      final color = shiftColor(context, shift.pattern, contexts);
      (grouped[shift.displayDate.key] ??= <_MonthItem>[]).add(
        _MonthItem(
          title: shift.slot.label.isEmpty
              ? shift.pattern.name
              : '${shift.pattern.name} · ${shift.slot.label}',
          color: color,
          soft: shiftSoftColor(context, shift.pattern, contexts),
          startAt: shift.startAt,
          displayDate: shift.displayDate,
          viewerTimeZone: viewerTimeZone,
          completed: false,
          isShift: true,
        ),
      );
    }

    for (final dayItems in grouped.values) {
      dayItems.sort((a, b) {
        final byMinute = a.sortMinute.compareTo(b.sortMinute);
        if (byMinute != 0) return byMinute;
        return a.title.compareTo(b.title);
      });
    }
    return grouped;
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.weekStart, required this.background});

  final int weekStart;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: c.border.withValues(alpha: 0.8))),
      ),
      child: Row(
        children: [
          for (final weekday in weekdaysFrom(weekStart))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Text(
                  shortWeekday(context, weekday).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SundialType.label(10, color: c.textTertiary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.date,
    required this.month,
    required this.selected,
    required this.today,
    required this.items,
    required this.locale,
    required this.onSelected,
    required this.onOpenEntry,
    required this.borderRight,
    required this.borderBottom,
  });

  final LocalDate date;
  final LocalDate month;
  final LocalDate selected;
  final LocalDate today;
  final Map<int, List<_MonthItem>> items;
  final String locale;
  final ValueChanged<LocalDate> onSelected;
  final ValueChanged<EntryOccurrence> onOpenEntry;
  final bool borderRight;
  final bool borderBottom;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final date = widget.date;
    final inMonth = date.month == widget.month.month && date.year == widget.month.year;
    final isSelected = date == widget.selected;
    final isToday = date == widget.today;
    final dayItems = inMonth ? widget.items[date.key] ?? const <_MonthItem>[] : const <_MonthItem>[];
    final itemCount = widget.items[date.key]?.length ?? 0;
    final background = isSelected
        ? c.accentSoft
        : _hovered
        ? c.surfaceAlt.withValues(alpha: 0.55)
        : Colors.transparent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: context.l10n.calendarDaySemantics(formatFullDate(context, date.toDateTime()), itemCount),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          key: ValueKey('month-day-${date.iso}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onSelected(date),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            decoration: BoxDecoration(
              color: background,
              border: Border(
                right: widget.borderRight
                    ? BorderSide(color: c.border.withValues(alpha: 0.7))
                    : BorderSide.none,
                bottom: widget.borderBottom
                    ? BorderSide(color: c.border.withValues(alpha: 0.7))
                    : BorderSide.none,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(7, 5, 6, 2),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          width: 23,
                          height: 23,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: style.hasControlGradient ? null : c.accent,
                            gradient: style.controlGradient,
                            shape: BoxShape.circle,
                            border: style.hasControlGradient
                                ? Border.all(color: style.highlight.withValues(alpha: 0.5))
                                : null,
                            boxShadow: style.hasControlGradient ? style.cardShadows.take(1).toList() : null,
                          ),
                          foregroundDecoration: style.hasControlGradient && style.gloss
                              ? BoxDecoration(shape: BoxShape.circle, gradient: style.glossGradient)
                              : null,
                          child: Text('${date.day}', style: SundialType.label(11, color: c.onAccent)),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                          child: Text(
                            '${date.day}',
                            style: SundialType.title(
                              12,
                              color: inMonth ? c.text : c.textTertiary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      if (isSelected) ...[
                        const Spacer(),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);
                      final line = 18 * scale;
                      const gap = 2.5;
                      final capacity = ((constraints.maxHeight + gap) / (line + gap)).floor();
                      if (capacity <= 0 || dayItems.isEmpty) return const SizedBox.shrink();
                      final hidden = dayItems.length > capacity;
                      final shown = hidden ? math.max(0, capacity - 1) : dayItems.length;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 0; index < shown; index++) ...[
                              if (index > 0) const SizedBox(height: gap),
                              _EventChip(
                                item: dayItems[index],
                                locale: widget.locale,
                                height: line,
                                onTap: dayItems[index].occurrence == null
                                    ? null
                                    : () => widget.onOpenEntry(dayItems[index].occurrence!),
                              ),
                            ],
                            if (hidden) ...[
                              if (shown > 0) const SizedBox(height: gap),
                              Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Text(
                                  '+${dayItems.length - shown}',
                                  style: SundialType.label(9, color: c.textTertiary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({required this.item, required this.locale, required this.height, required this.onTap});

  final _MonthItem item;
  final String locale;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final startAt = item.startAt;
    // A timed entry or overnight shift repeats on every day it covers. Show
    // the clock time only on the day it actually starts.
    final time = startAt == null || localDateAt(startAt, item.viewerTimeZone) != item.displayDate
        ? null
        : DateFormat.Hm(locale).format(localDateTimeAt(startAt, item.viewerTimeZone));
    final textColor = item.completed ? c.textTertiary : c.text;

    return Semantics(
      button: onTap != null,
      label: [if (item.isShift) context.l10n.shiftsSection, ?time, item.title].join(', '),
      child: Pressable(
        onTap: onTap,
        scale: 0.98,
        child: Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: style.hasSurfaceGradient ? null : item.soft,
            gradient: style.hasSurfaceGradient
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [item.soft, style.colors.surface],
                  )
                : null,
            borderRadius: BorderRadius.circular(SundialRadii.marker),
            border: style.hasSurfaceGradient ? Border.all(color: item.color.withValues(alpha: 0.24)) : null,
          ),
          foregroundDecoration: style.hasSurfaceGradient && style.gloss
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(SundialRadii.marker),
                  gradient: style.glossGradient,
                )
              : null,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Phone cells are too narrow to spend on a clock label. The
              // title and the space stripe carry the meaning there.
              final showTime = time != null && constraints.maxWidth >= 104;
              return Row(
                children: [
                  Container(width: 3, height: height, color: item.color),
                  const SizedBox(width: 5),
                  if (showTime) ...[
                    Text(time, style: SundialType.label(8.5, color: item.color)),
                    const SizedBox(width: 3),
                  ],
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.label(
                        9,
                        color: textColor,
                      ).copyWith(decoration: item.completed ? TextDecoration.lineThrough : null),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MonthItem {
  const _MonthItem({
    required this.title,
    required this.color,
    required this.soft,
    required this.startAt,
    required this.displayDate,
    required this.viewerTimeZone,
    required this.completed,
    required this.isShift,
    this.occurrence,
  });

  final String title;
  final Color color;
  final Color soft;
  final DateTime? startAt;
  final LocalDate displayDate;
  final String viewerTimeZone;
  final bool completed;
  final bool isShift;
  final EntryOccurrence? occurrence;

  /// All-day and continuing items come first; the remaining items are ordered
  /// by their wall-clock start on this day.
  int get sortMinute {
    final start = startAt;
    if (start == null) return -1;
    if (localDateAt(start, viewerTimeZone) != displayDate) return -1;
    return localMinuteAt(start, viewerTimeZone);
  }
}
