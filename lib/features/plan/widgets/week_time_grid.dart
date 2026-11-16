import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../shifts/shift_lane_layout.dart';
import '../../shifts/shift_lane_painter.dart';
import '../../shifts/shift_palette.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

class WeekTimeGrid extends StatefulWidget {
  const WeekTimeGrid({
    super.key,
    required this.weekStart,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
    required this.timeZone,
    required this.now,
    required this.onOpen,
    required this.onCreate,
    required this.onMove,
    required this.onResize,
  });

  final LocalDate weekStart;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;
  final String timeZone;
  final DateTime now;
  final ValueChanged<EntryOccurrence> onOpen;
  final void Function(LocalDate date, int startMinute, int endMinute) onCreate;
  final void Function(EntryOccurrence occurrence, LocalDate date, int startMinute, int endMinute) onMove;
  final void Function(EntryOccurrence occurrence, int endMinute) onResize;

  @override
  State<WeekTimeGrid> createState() => _WeekTimeGridState();
}

class _WeekTimeGridState extends State<WeekTimeGrid> {
  static const hourHeight = 52.0;
  static const _gutter = 46.0;

  final _scroll = ScrollController();

  int? _createDay;
  int? _createStart;
  int? _createEnd;
  int? _hoverDay;
  int? _hoverMinute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(math.min(_scroll.position.maxScrollExtent, hourHeight * 7));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final l10n = context.l10n;
    final today = localDateAt(widget.now, widget.timeZone);
    final entriesByDay = <int, List<EntryOccurrence>>{};
    for (var index = 0; index < 7; index++) {
      final day = widget.weekStart.addDays(index);
      entriesByDay[index] = widget.entries.where((item) => item.displayDate == day).toList();
    }
    final shiftsByDay = <int, List<ShiftOccurrence>>{};
    for (var index = 0; index < 7; index++) {
      final day = widget.weekStart.addDays(index);
      shiftsByDay[index] = widget.shifts.where((item) => item.displayDate == day).toList();
    }
    final allDayByDay = <int, List<EntryOccurrence>>{};
    for (var index = 0; index < 7; index++) {
      allDayByDay[index] = entriesByDay[index]!.where((item) => item.startAt == null).toList();
    }
    final allDayLines = allDayByDay.values.fold<int>(0, (lines, items) {
      final count = math.min(items.length, 3) + (items.length > 3 ? 1 : 0);
      return math.max(lines, count);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: _gutter, bottom: 6),
          child: Row(
            children: [
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _weekdayLabel(context, widget.weekStart.addDays(index)),
                        style: ManeType.label(
                          10,
                          color: widget.weekStart.addDays(index) == today ? c.accent : c.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.weekStart.addDays(index) == today ? c.accent : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.weekStart.addDays(index).day}',
                          style: ManeType.body(
                            12.5,
                            weight: FontWeight.w700,
                            color: widget.weekStart.addDays(index) == today ? c.onAccent : c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: allDayLines * 17.0,
          child: Padding(
            padding: const EdgeInsets.only(left: _gutter),
            child: Row(
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in allDayByDay[index]!.take(3))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: _AllDayChip(occurrence: item, onTap: () => widget.onOpen(item)),
                            ),
                          if (allDayByDay[index]!.length > 3)
                            Text(
                              '+${allDayByDay[index]!.length - 3}',
                              style: ManeType.label(8, color: c.textTertiary),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              color: c.surfaceAlt.withValues(alpha: 0.42),
              child: SingleChildScrollView(
                controller: _scroll,
                child: SizedBox(
                  height: 24 * hourHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: _gutter,
                        child: Stack(
                          children: [
                            for (var hour = 0; hour < 24; hour++)
                              Positioned(
                                top: hour * hourHeight - 5,
                                right: 6,
                                child: Text(
                                  DateFormat.Hm(
                                    Localizations.localeOf(context).toLanguageTag(),
                                  ).format(DateTime(2020, 1, 1, hour)),
                                  style: ManeType.label(9, color: c.textTertiary),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            for (var hour = 1; hour < 24; hour++)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: hour * hourHeight,
                                child: Container(height: 1, color: c.border.withValues(alpha: 0.7)),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var day = 0; day < 7; day++)
                                  Expanded(
                                    child: _DayColumn(
                                      day: day,
                                      date: widget.weekStart.addDays(day),
                                      entries: entriesByDay[day]!,
                                      shifts: shiftsByDay[day]!,
                                      spaces: widget.spaces,
                                      contexts: widget.contexts,
                                      timeZone: widget.timeZone,
                                      now: widget.now,
                                      hoverMinute: _hoverDay == day ? _hoverMinute : null,
                                      creating: _createDay == day,
                                      createStart: _createDay == day ? _createStart : null,
                                      createEnd: _createDay == day ? _createEnd : null,
                                      onOpen: widget.onOpen,
                                      onHover: (minute) => setState(() {
                                        _hoverDay = day;
                                        _hoverMinute = minute;
                                      }),
                                      onHoverEnd: () => setState(() => _hoverDay = null),
                                      onDrop: (occurrence, minute) {
                                        if (occurrence.startAt == null) return;
                                        final duration = (occurrence.endAt ?? occurrence.startAt!)
                                            .difference(occurrence.startAt!)
                                            .inMinutes;
                                        final start = _snap(minute);
                                        widget.onMove(
                                          occurrence,
                                          widget.weekStart.addDays(day),
                                          start,
                                          start + math.max(15, duration),
                                        );
                                        setState(() => _hoverDay = null);
                                      },
                                      onPanStart: (minute) => setState(() {
                                        _createDay = day;
                                        _createStart = _snap(minute);
                                        _createEnd = _snap(minute + 15);
                                      }),
                                      onPanUpdate: (minute) => setState(() {
                                        _createEnd = _snap(minute);
                                      }),
                                      onPanEnd: () {
                                        final start = _createStart;
                                        final end = _createEnd;
                                        setState(() {
                                          _createDay = null;
                                          _createStart = null;
                                          _createEnd = null;
                                        });
                                        if (start == null || end == null) return;
                                        final low = math.min(start, end);
                                        final high = math.max(start, end);
                                        if (high - low < 15) return;
                                        widget.onCreate(widget.weekStart.addDays(day), low, high);
                                      },
                                      onResize: (occurrence, deltaMinutes) {
                                        final end = _endMinute(occurrence);
                                        if (end == null) return;
                                        widget.onResize(occurrence, _snap(end + deltaMinutes));
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            IgnorePointer(
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _NowPainter(
                                  minute: _nowMinute(today),
                                  color: c.danger,
                                  hourHeight: hourHeight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(l10n.desktopWeekHint, style: ManeType.body(10.5, color: c.textTertiary)),
      ],
    );
  }

  int? _nowMinute(LocalDate today) {
    final index = today.differenceInDays(widget.weekStart);
    if (index < 0 || index > 6) return null;
    return widget.now.hour * 60 + widget.now.minute;
  }

  static int _snap(int minute) => ((minute.clamp(0, 24 * 60 - 15)) / 15).round() * 15;

  int? _endMinute(EntryOccurrence occurrence) {
    final end = occurrence.endAt;
    if (end == null || occurrence.displayDate != localDateAt(end, widget.timeZone)) return null;
    return localMinuteAt(end, widget.timeZone);
  }

  static String _weekdayLabel(BuildContext context, LocalDate date) =>
      DateFormat.E(Localizations.localeOf(context).toLanguageTag()).format(date.toDateTime());
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.date,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
    required this.timeZone,
    required this.now,
    required this.hoverMinute,
    required this.creating,
    required this.createStart,
    required this.createEnd,
    required this.onOpen,
    required this.onHover,
    required this.onHoverEnd,
    required this.onDrop,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onResize,
  });

  final int day;
  final LocalDate date;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;
  final String timeZone;
  final DateTime now;
  final int? hoverMinute;
  final bool creating;
  final int? createStart;
  final int? createEnd;
  final ValueChanged<EntryOccurrence> onOpen;
  final ValueChanged<int> onHover;
  final VoidCallback onHoverEnd;
  final void Function(EntryOccurrence occurrence, int minute) onDrop;
  final ValueChanged<int> onPanStart;
  final ValueChanged<int> onPanUpdate;
  final VoidCallback onPanEnd;
  final void Function(EntryOccurrence occurrence, int deltaMinutes) onResize;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return DragTarget<EntryOccurrence>(
      onMove: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(details.offset);
        onHover((local.dy / _WeekTimeGridState.hourHeight * 60).round());
      },
      onLeave: (_) => onHoverEnd(),
      onAcceptWithDetails: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(details.offset);
        onDrop(details.data, (local.dy / _WeekTimeGridState.hourHeight * 60).round());
      },
      builder: (context, candidates, rejects) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => onPanStart(_minuteAt(details.localPosition)),
          onPanUpdate: (details) => onPanUpdate(_minuteAt(details.localPosition)),
          onPanEnd: (_) => onPanEnd(),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.border.withValues(alpha: 0.6))),
              color: candidates.isNotEmpty
                  ? c.accentSoft.withValues(alpha: 0.35)
                  : date == localDateAt(now, timeZone)
                  ? c.accentSoft.withValues(alpha: 0.18)
                  : Colors.transparent,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final shiftRenders = _shiftRenders(constraints.maxWidth, context);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (shiftRenders.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ShiftLanePainter(
                              blocks: [
                                for (final render in shiftRenders)
                                  ShiftLanePaintBlock(
                                    rects: render.rects,
                                    fillColor: render.fillColor,
                                    stripeColor: render.stripeColor,
                                    overlaps: render.overlaps,
                                  ),
                              ],
                              warningColor: c.danger.withValues(alpha: 0.65),
                              cornerRadius: 0,
                              stripeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    for (final render in shiftRenders)
                      if (render.rects.isNotEmpty)
                        Positioned(
                          left: render.rects.first.left + 4,
                          top: render.rects.first.top + 2,
                          width: math.max(0.0, render.rects.first.width - 8),
                          child: IgnorePointer(
                            child: Text(
                              render.shift.pattern.name,
                              maxLines: render.rects.length > 1 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: ManeType.label(8.5, color: c.text),
                            ),
                          ),
                        ),
                    for (final entry in entries.where((item) => item.startAt != null))
                      _EntryBlock(
                        occurrence: entry,
                        timeZone: timeZone,
                        spaces: spaces,
                        onOpen: () => onOpen(entry),
                        onResize: (delta) => onResize(entry, delta),
                      ),
                    if (creating && createStart != null && createEnd != null)
                      Positioned(
                        left: 3,
                        right: 3,
                        top: math.min(createStart!, createEnd!) / 60 * _WeekTimeGridState.hourHeight,
                        height: math.max(
                          16,
                          (math.max(createStart!, createEnd!) - math.min(createStart!, createEnd!)) /
                              60 *
                              _WeekTimeGridState.hourHeight,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.accent),
                          ),
                        ),
                      ),
                    if (hoverMinute != null)
                      Positioned(
                        left: 2,
                        right: 2,
                        top: (_WeekTimeGridState._snap(hoverMinute!) / 60) * _WeekTimeGridState.hourHeight,
                        height: 2,
                        child: Container(color: c.accent),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  static int _minuteAt(Offset local) =>
      (local.dy / _WeekTimeGridState.hourHeight * 60).clamp(0, 24 * 60).round();

  List<_ShiftRender> _shiftRenders(double columnWidth, BuildContext context) {
    final bounds = <({ShiftOccurrence shift, int start, int end})>[];
    for (final shift in shifts) {
      final start = localDateAt(shift.startAt, timeZone).isBefore(shift.displayDate)
          ? 0
          : localMinuteAt(shift.startAt, timeZone);
      final end = localDateAt(shift.endAt, timeZone).isAfter(shift.displayDate)
          ? 24 * 60
          : localMinuteAt(shift.endAt, timeZone);
      if (end > start) bounds.add((shift: shift, start: start, end: end));
    }
    final layouts = layoutShiftLanes([
      for (final item in bounds) ShiftLaneInterval(startMinute: item.start, endMinute: item.end),
    ]);
    return [
      for (var index = 0; index < bounds.length; index++)
        _ShiftRender(
          shift: bounds[index].shift,
          rects: [
            for (final segment in layouts[index].segments)
              Rect.fromLTWH(
                shiftLaneLeft(columnWidth, segment.lane, segment.laneCount),
                segment.startMinute / 60 * _WeekTimeGridState.hourHeight,
                shiftLaneWidth(columnWidth, segment.laneCount),
                (segment.endMinute - segment.startMinute) / 60 * _WeekTimeGridState.hourHeight,
              ),
          ],
          fillColor: shiftSoftColor(context, bounds[index].shift.pattern, contexts),
          stripeColor: shiftColor(context, bounds[index].shift.pattern, contexts).withValues(alpha: 0.7),
          overlaps: layouts[index].overlaps,
        ),
    ];
  }
}

class _EntryBlock extends StatelessWidget {
  const _EntryBlock({
    required this.occurrence,
    required this.timeZone,
    required this.spaces,
    required this.onOpen,
    required this.onResize,
  });

  final EntryOccurrence occurrence;
  final String timeZone;
  final List<Space> spaces;
  final VoidCallback onOpen;
  final ValueChanged<int> onResize;

  @override
  Widget build(BuildContext context) {
    final start = _startMinute();
    final end = _endMinute();
    if (start == null || end == null || end <= start) return const SizedBox.shrink();
    final color = _spaceColor(context);
    final block = _block(context, start, end, color);
    if (occurrence.entry.readOnly) {
      return Positioned(
        left: 3,
        right: 3,
        top: start / 60 * _WeekTimeGridState.hourHeight,
        height: math.max(18, (end - start) / 60 * _WeekTimeGridState.hourHeight),
        child: GestureDetector(onTap: onOpen, child: block),
      );
    }
    return Positioned(
      left: 3,
      right: 3,
      top: start / 60 * _WeekTimeGridState.hourHeight,
      height: math.max(18, (end - start) / 60 * _WeekTimeGridState.hourHeight),
      child: Draggable<EntryOccurrence>(
        data: occurrence,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(width: 130, child: _block(context, start, end, color, shadow: true)),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: block),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: onOpen, child: block),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 0,
              height: 9,
              child: _ResizeHandle(color: color, onResize: onResize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(BuildContext context, int start, int end, Color color, {bool shadow = false}) {
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: shadow
            ? [BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: c.shadow.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            occurrence.entry.title,
            maxLines: end - start >= 60 ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: ManeType.body(10.5, weight: FontWeight.w700, color: c.text),
          ),
          if (end - start >= 45)
            Text(
              '${_time(context, start)} – ${_time(context, end)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ManeType.label(9, color: c.textTertiary),
            ),
        ],
      ),
    );
  }

  int? _startMinute() {
    final displayDate = occurrence.displayDate;
    if (occurrence.startAt == null) return null;
    if (localDateAt(occurrence.startAt!, timeZone).isBefore(displayDate)) return 0;
    return localMinuteAt(occurrence.startAt!, timeZone);
  }

  int? _endMinute() {
    final endAt = occurrence.endAt;
    if (endAt == null) return null;
    if (localDateAt(endAt, timeZone).isAfter(occurrence.displayDate)) return 24 * 60;
    return localMinuteAt(endAt, timeZone);
  }

  String _time(BuildContext context, int minute) => DateFormat.Hm(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(DateTime(2020, 1, 1, minute ~/ 60 % 24, minute % 60));

  Color _spaceColor(BuildContext context) {
    for (final space in spaces) {
      if (space.id == occurrence.entry.spaceId) return Color(space.colorValue);
    }
    return context.mc.accent;
  }
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.color, required this.onResize});

  final Color color;
  final ValueChanged<int> onResize;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double _delta = 0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _delta = 0,
        onVerticalDragUpdate: (details) => _delta += details.delta.dy,
        onVerticalDragEnd: (_) {
          final minutes = (_delta / _WeekTimeGridState.hourHeight * 60).round();
          if (minutes.abs() >= 5) widget.onResize(minutes);
          _delta = 0;
        },
        child: Center(
          child: Container(
            width: 22,
            height: 3,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftRender {
  const _ShiftRender({
    required this.shift,
    required this.rects,
    required this.fillColor,
    required this.stripeColor,
    required this.overlaps,
  });

  final ShiftOccurrence shift;
  final List<Rect> rects;
  final Color fillColor;
  final Color stripeColor;
  final bool overlaps;
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.occurrence, required this.onTap});

  final EntryOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final color = c.forSpace(occurrence.entry.spaceId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          occurrence.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ManeType.label(8, color: color),
        ),
      ),
    );
  }
}

class _NowPainter extends CustomPainter {
  _NowPainter({required this.minute, required this.color, required this.hourHeight});

  final int? minute;
  final Color color;
  final double hourHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final value = minute;
    if (value == null) return;
    final y = value / 60 * hourHeight;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_NowPainter oldDelegate) => oldDelegate.minute != minute || oldDelegate.color != color;
}
