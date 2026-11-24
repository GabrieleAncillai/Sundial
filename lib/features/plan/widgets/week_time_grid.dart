import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../theme/app_radii.dart';
import '../../calendar/widgets/open_end_entry_block.dart';
import '../../shifts/shift_block_layout.dart';
import '../../shifts/shift_block_painter.dart';
import '../../shifts/shift_palette.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/sundial_style.dart';

/// A mouse press-drag creates an event immediately. Touch and pen hold first so
/// a scroll gesture never starts a creation. Trackpads are deliberately absent:
/// two-finger pan arrives as a pan/zoom gesture and used to be mistaken for a
/// drag, which created events while scrolling.
const _pointerDragDevices = <PointerDeviceKind>{PointerDeviceKind.mouse};

const _holdDragDevices = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

const _resizeDevices = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

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
  final _columnKeys = List<GlobalKey>.generate(7, (_) => GlobalKey());

  int? _createDay;
  int? _createStart;
  int? _createEnd;
  _EntryDrag? _entryDrag;
  Timer? _dragSettleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      // Land just above the 07:00 line so its label is not clipped by the
      // viewport edge.
      _scroll.jumpTo(math.min(_scroll.position.maxScrollExtent, hourHeight * 7 - 14));
    });
  }

  @override
  void didUpdateWidget(covariant WeekTimeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the moved block where the user dropped it until the repository
    // pushes the new span, then let the real occurrence take over.
    final drag = _entryDrag;
    if (drag == null) return;
    final targetDate = widget.weekStart.addDays(drag.dayIndex);
    // A recurring override keeps the series anchor date; a one-off entry moves
    // its own date. Matching the wrong one would clear the preview too early or
    // too late.
    final expectedDate = drag.occurrence.entry.recurrence != null ? drag.occurrence.date : targetDate;
    final landed = widget.entries.any(
      (item) =>
          item.entry.id == drag.occurrence.entry.id &&
          item.date == expectedDate &&
          item.displayDate == targetDate &&
          item.startAt != null &&
          localMinuteAt(item.startAt!, widget.timeZone) == drag.startMinute,
    );
    if (!landed) return;
    _dragSettleTimer?.cancel();
    _entryDrag = null;
  }

  @override
  void dispose() {
    _dragSettleTimer?.cancel();
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
                        style: SundialType.label(
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
                          style: SundialType.body(
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
          height: allDayLines * 20.0,
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
                              style: SundialType.label(8, color: c.textTertiary),
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
            borderRadius: BorderRadius.circular(SundialRadii.lg),
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
                                  style: SundialType.label(9, color: c.textTertiary),
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
                                      key: _columnKeys[day],
                                      day: day,
                                      date: widget.weekStart.addDays(day),
                                      entries: entriesByDay[day]!,
                                      shifts: shiftsByDay[day]!,
                                      spaces: widget.spaces,
                                      contexts: widget.contexts,
                                      timeZone: widget.timeZone,
                                      now: widget.now,
                                      drag: _entryDrag,
                                      creating: _createDay == day,
                                      createStart: _createDay == day ? _createStart : null,
                                      createEnd: _createDay == day ? _createEnd : null,
                                      onOpen: widget.onOpen,
                                      onEntryDragStart: _beginEntryDrag,
                                      onEntryDragUpdate: _updateEntryDrag,
                                      onEntryDragEnd: _endEntryDrag,
                                      onEntryDragCancel: _cancelEntryDrag,
                                      onPanStart: (minute) => setState(() {
                                        _entryDrag = null;
                                        _createDay = day;
                                        _createStart = _snap(minute);
                                        _createEnd = _snap(minute + 15);
                                      }),
                                      onPanUpdate: (minute) => setState(() {
                                        _createEnd = _snap(minute);
                                      }),
                                      onPanCancel: () => setState(() {
                                        _createDay = null;
                                        _createStart = null;
                                        _createEnd = null;
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
                                      onResize: widget.onResize,
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
        Text(l10n.desktopWeekHint, style: SundialType.body(10.5, color: c.textTertiary)),
      ],
    );
  }

  int? _nowMinute(LocalDate today) {
    final index = today.differenceInDays(widget.weekStart);
    if (index < 0 || index > 6) return null;
    return widget.now.hour * 60 + widget.now.minute;
  }

  static int _snap(int minute) => ((minute.clamp(0, 24 * 60 - 15)) / 15).round() * 15;

  void _beginEntryDrag(EntryOccurrence occurrence, Offset globalPosition, int blockStartMinute) {
    final startAt = occurrence.startAt;
    if (startAt == null) return;
    final target = _targetAt(globalPosition);
    if (target == null) return;
    final endAt = occurrence.endAt;
    final duration = endAt == null ? 15 : math.max(15, endAt.difference(startAt).inMinutes);
    final int grab = math.min<int>(
      math.max(target.minute - blockStartMinute, 0),
      math.max(0, math.min<int>(duration, 24 * 60) - 15),
    );
    final int maxStart = math.max(0, 24 * 60 - math.min<int>(duration, 24 * 60));
    setState(() {
      _createDay = null;
      _createStart = null;
      _createEnd = null;
      _entryDrag = _EntryDrag(
        occurrence: occurrence,
        dayIndex: target.day,
        startMinute: _snap(math.min(target.minute - grab, maxStart)),
        durationMinutes: duration,
        grabMinutes: grab,
      );
    });
  }

  void _updateEntryDrag(Offset globalPosition) {
    final drag = _entryDrag;
    if (drag == null) return;
    final target = _targetAt(globalPosition);
    if (target == null) return;
    final int maxStart = math.max(0, 24 * 60 - math.min<int>(drag.durationMinutes, 24 * 60));
    final start = _snap(math.min<int>(math.max(target.minute - drag.grabMinutes, 0), maxStart));
    if (target.day == drag.dayIndex && start == drag.startMinute) return;
    setState(() => _entryDrag = drag.copyWith(dayIndex: target.day, startMinute: start));
  }

  void _endEntryDrag() {
    final drag = _entryDrag;
    if (drag == null) return;
    final startAt = drag.occurrence.startAt;
    if (startAt == null) {
      setState(() => _entryDrag = null);
      return;
    }
    final date = widget.weekStart.addDays(drag.dayIndex);
    final originalStart = localMinuteAt(startAt, widget.timeZone);
    if (date == drag.occurrence.displayDate && drag.startMinute == originalStart) {
      setState(() => _entryDrag = null);
      return;
    }
    widget.onMove(drag.occurrence, date, drag.startMinute, drag.startMinute + drag.durationMinutes);
    _dragSettleTimer?.cancel();
    _dragSettleTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _entryDrag != drag) return;
      setState(() => _entryDrag = null);
    });
  }

  void _cancelEntryDrag() {
    if (_entryDrag == null) return;
    _dragSettleTimer?.cancel();
    setState(() => _entryDrag = null);
  }

  /// Resolves the day column and minute under a global pointer position. When
  /// the pointer leaves the grid horizontally the nearest column is used, so a
  /// drag across days keeps a sensible target.
  ({int day, int minute})? _targetAt(Offset globalPosition) {
    RenderBox? nearest;
    var nearestDay = 0;
    for (var index = 0; index < _columnKeys.length; index++) {
      final box = _columnKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if (nearest == null) {
        nearest = box;
        nearestDay = index;
      }
      final origin = box.localToGlobal(Offset.zero);
      final right = origin.dx + box.size.width;
      if (globalPosition.dx >= origin.dx && globalPosition.dx <= right) {
        nearest = box;
        nearestDay = index;
        break;
      }
      if (globalPosition.dx < origin.dx) break;
      nearest = box;
      nearestDay = index;
    }
    if (nearest == null || !nearest.hasSize) return null;
    final origin = nearest.localToGlobal(Offset.zero);
    final minute = ((globalPosition.dy - origin.dy) / hourHeight * 60).clamp(0, 24 * 60 - 1).toInt();
    return (day: nearestDay, minute: minute);
  }

  static String _weekdayLabel(BuildContext context, LocalDate date) =>
      DateFormat.E(Localizations.localeOf(context).toLanguageTag()).format(date.toDateTime());
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    super.key,
    required this.day,
    required this.date,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
    required this.timeZone,
    required this.now,
    required this.drag,
    required this.creating,
    required this.createStart,
    required this.createEnd,
    required this.onOpen,
    required this.onEntryDragStart,
    required this.onEntryDragUpdate,
    required this.onEntryDragEnd,
    required this.onEntryDragCancel,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
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
  final _EntryDrag? drag;
  final bool creating;
  final int? createStart;
  final int? createEnd;
  final ValueChanged<EntryOccurrence> onOpen;
  final void Function(EntryOccurrence occurrence, Offset globalPosition, int blockStartMinute)
  onEntryDragStart;
  final ValueChanged<Offset> onEntryDragUpdate;
  final VoidCallback onEntryDragEnd;
  final VoidCallback onEntryDragCancel;
  final ValueChanged<int> onPanStart;
  final ValueChanged<int> onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onPanCancel;
  final void Function(EntryOccurrence occurrence, int endMinute) onResize;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final activeDrag = drag;
    final dropTarget = activeDrag != null && activeDrag.dayIndex == day;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: c.border.withValues(alpha: 0.6))),
        color: dropTarget
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
              Positioned.fill(child: _creationArea()),
              if (shiftRenders.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ShiftBlockPainter(
                        blocks: [
                          for (final render in shiftRenders)
                            ShiftBlockPaint(
                              rect: render.rect,
                              fillColor: render.fillColor,
                              stripeColor: render.stripeColor,
                            ),
                        ],
                        cornerRadius: 0,
                        stripeWidth: 2,
                      ),
                    ),
                  ),
                ),
              for (final render in shiftRenders)
                Positioned(
                  left: render.rect.left + 4,
                  top: render.labelTop,
                  width: math.max(0.0, render.rect.width - 8),
                  child: IgnorePointer(
                    child: Text(
                      render.shift.pattern.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.label(8.5, color: c.text),
                    ),
                  ),
                ),
              for (final entry in entries.where((item) => item.startAt != null))
                _EntryBlock(
                  occurrence: entry,
                  timeZone: timeZone,
                  spaces: spaces,
                  dragging: _isDragging(entry),
                  onOpen: () => onOpen(entry),
                  onDragStart: (globalPosition, startMinute) =>
                      onEntryDragStart(entry, globalPosition, startMinute),
                  onDragUpdate: onEntryDragUpdate,
                  onDragEnd: onEntryDragEnd,
                  onDragCancel: onEntryDragCancel,
                  onResize: (end) => onResize(entry, end),
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
                      borderRadius: BorderRadius.circular(SundialRadii.xs),
                      border: Border.all(color: c.accent),
                    ),
                  ),
                ),
              if (dropTarget) _dragPreview(context, activeDrag),
            ],
          );
        },
      ),
    );
  }

  bool _isDragging(EntryOccurrence entry) {
    final active = drag;
    return active != null &&
        active.occurrence.entry.id == entry.entry.id &&
        active.occurrence.date == entry.date;
  }

  /// The empty-area gesture layer sits behind entries, so a press on an event
  /// never bubbles into event creation. Mouse drags start immediately; touch
  /// and pen hold first, which keeps scroll gestures out of the creator.
  Widget _creationArea() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      supportedDevices: _holdDragDevices,
      dragStartBehavior: DragStartBehavior.down,
      onLongPressStart: (details) => onPanStart(_minuteAt(details.localPosition)),
      onLongPressMoveUpdate: (details) => onPanUpdate(_minuteAt(details.localPosition)),
      onLongPressEnd: (_) => onPanEnd(),
      onLongPressCancel: onPanCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        supportedDevices: _pointerDragDevices,
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) => onPanStart(_minuteAt(details.localPosition)),
        onPanUpdate: (details) => onPanUpdate(_minuteAt(details.localPosition)),
        onPanEnd: (_) => onPanEnd(),
        onPanCancel: onPanCancel,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _dragPreview(BuildContext context, _EntryDrag drag) {
    final openEnded = drag.occurrence.endAt == null;
    final available = math.max(0, 24 * 60 - drag.startMinute);
    final int? end = openEnded ? null : drag.startMinute + math.min<int>(drag.durationMinutes, available);
    final height = end == null
        ? OpenEndEntryBlock.defaultHeight
        : math.max(18.0, (end - drag.startMinute) / 60 * _WeekTimeGridState.hourHeight);
    return Positioned(
      left: 3,
      right: 3,
      top: drag.startMinute / 60 * _WeekTimeGridState.hourHeight,
      height: height,
      child: IgnorePointer(
        child: _EntryCard(
          occurrence: drag.occurrence,
          start: drag.startMinute,
          end: end,
          color: _spaceColorFor(context, drag.occurrence, spaces),
          shadow: true,
        ),
      ),
    );
  }

  static const _labelLineHeight = 14.0;

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
    final blocks = orderShiftBlocks([
      for (final item in bounds) ShiftBlockSpan(startMinute: item.start, endMinute: item.end),
    ]);
    final labelOffsets = shiftLabelOffsets(
      blocks,
      labelMinuteHeight: (_labelLineHeight / _WeekTimeGridState.hourHeight * 60).ceil(),
    );
    final renders = <_ShiftRender>[];
    for (var position = 0; position < blocks.length; position++) {
      final block = blocks[position];
      final item = bounds[block.index];
      final top = block.startMinute / 60 * _WeekTimeGridState.hourHeight;
      renders.add(
        _ShiftRender(
          shift: item.shift,
          rect: Rect.fromLTWH(
            0,
            top,
            columnWidth,
            (block.endMinute - block.startMinute) / 60 * _WeekTimeGridState.hourHeight,
          ),
          labelTop: top + 2 + labelOffsets[position] / 60 * _WeekTimeGridState.hourHeight,
          fillColor: shiftSoftColor(context, item.shift.pattern, contexts),
          stripeColor: shiftColor(context, item.shift.pattern, contexts).withValues(alpha: 0.7),
        ),
      );
    }
    return renders;
  }
}

class _EntryBlock extends StatefulWidget {
  const _EntryBlock({
    required this.occurrence,
    required this.timeZone,
    required this.spaces,
    required this.dragging,
    required this.onOpen,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onResize,
  });

  final EntryOccurrence occurrence;
  final String timeZone;
  final List<Space> spaces;
  final bool dragging;
  final VoidCallback onOpen;
  final void Function(Offset globalPosition, int blockStartMinute) onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onDragCancel;
  final ValueChanged<int> onResize;

  @override
  State<_EntryBlock> createState() => _EntryBlockState();
}

class _EntryBlockState extends State<_EntryBlock> {
  int? _previewEnd;
  int? _committedEnd;
  Timer? _settleTimer;

  @override
  void didUpdateWidget(covariant _EntryBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_committedEnd == null || widget.occurrence.endAt == oldWidget.occurrence.endAt) return;
    _settleTimer?.cancel();
    _previewEnd = null;
    _committedEnd = null;
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = _startMinute();
    if (start == null) return const SizedBox.shrink();
    final end = _endMinute();
    if (end != null && end <= start) return const SizedBox.shrink();

    final displayEnd = end == null ? null : (_previewEnd ?? end);
    final color = _spaceColor(context);
    final height = displayEnd == null
        ? OpenEndEntryBlock.defaultHeight
        : math.max(18.0, (displayEnd - start) / 60 * _WeekTimeGridState.hourHeight);
    final card = _EntryCard(
      occurrence: widget.occurrence,
      start: start,
      end: displayEnd,
      color: color,
      shadow: widget.dragging,
    );

    Widget content;
    if (widget.occurrence.entry.readOnly) {
      content = GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onOpen, child: card);
    } else {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _dragGesture(start, card)),
          // A block without an end has no bottom edge to resize; finishing the
          // task is what sets its end time.
          if (end != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 0,
              height: 9,
              child: _ResizeHandle(
                color: color,
                onDelta: _previewResize,
                onEnd: _commitResize,
                onCancel: _cancelResize,
              ),
            ),
        ],
      );
    }

    return Positioned(
      left: 3,
      right: 3,
      top: start / 60 * _WeekTimeGridState.hourHeight,
      height: height,
      // Keep the gesture subtree mounted for the whole drag: swapping it out
      // when the drag starts would dispose the recognizer mid-gesture.
      child: Opacity(opacity: widget.dragging ? 0.22 : 1, child: content),
    );
  }

  Widget _dragGesture(int start, Widget card) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      supportedDevices: _pointerDragDevices,
      dragStartBehavior: DragStartBehavior.down,
      onTap: widget.onOpen,
      onPanStart: (details) => widget.onDragStart(details.globalPosition, start),
      onPanUpdate: (details) => widget.onDragUpdate(details.globalPosition),
      onPanEnd: (_) => widget.onDragEnd(),
      onPanCancel: widget.onDragCancel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        supportedDevices: _holdDragDevices,
        dragStartBehavior: DragStartBehavior.down,
        onTap: widget.onOpen,
        onLongPressStart: (details) => widget.onDragStart(details.globalPosition, start),
        onLongPressMoveUpdate: (details) => widget.onDragUpdate(details.globalPosition),
        onLongPressEnd: (_) => widget.onDragEnd(),
        onLongPressCancel: widget.onDragCancel,
        child: card,
      ),
    );
  }

  void _previewResize(int deltaMinutes) {
    final start = _startMinute();
    final end = _endMinute();
    if (start == null || end == null) return;
    final next = _WeekTimeGridState._snap(end + deltaMinutes);
    final bounded = math.max(start + 15, next);
    if (bounded == _previewEnd) return;
    setState(() => _previewEnd = bounded);
  }

  void _commitResize() {
    final end = _previewEnd;
    if (end == null) return;
    if (end == _endMinute()) {
      setState(() => _previewEnd = null);
      return;
    }
    // Hold the resized height while the write is in flight. The next
    // occurrence with a different end clears it; the timer is the fallback for
    // a failed write.
    setState(() => _committedEnd = end);
    widget.onResize(end);
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _committedEnd != end) return;
      setState(() {
        _previewEnd = null;
        _committedEnd = null;
      });
    });
  }

  void _cancelResize() {
    if (_previewEnd == null) return;
    _settleTimer?.cancel();
    setState(() {
      _previewEnd = null;
      _committedEnd = null;
    });
  }

  int? _startMinute() {
    final displayDate = widget.occurrence.displayDate;
    if (widget.occurrence.startAt == null) return null;
    if (localDateAt(widget.occurrence.startAt!, widget.timeZone).isBefore(displayDate)) return 0;
    return localMinuteAt(widget.occurrence.startAt!, widget.timeZone);
  }

  int? _endMinute() {
    final endAt = widget.occurrence.endAt;
    if (endAt == null) return null;
    if (localDateAt(endAt, widget.timeZone).isAfter(widget.occurrence.displayDate)) return 24 * 60;
    return localMinuteAt(endAt, widget.timeZone);
  }

  Color _spaceColor(BuildContext context) => _spaceColorFor(context, widget.occurrence, widget.spaces);
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.occurrence,
    required this.start,
    required this.end,
    required this.color,
    this.shadow = false,
  });

  final EntryOccurrence occurrence;
  final int start;
  final int? end;
  final Color color;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final endMinute = end;
    if (endMinute == null) {
      return OpenEndEntryBlock(
        title: occurrence.entry.title,
        color: color,
        timeLabel: '${_formatMinute(context, start)} –',
        dense: true,
        shadow: shadow,
      );
    }
    final style = context.style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: style.hasSurfaceGradient ? null : c.surface,
        gradient: style.surfaceGradient,
        borderRadius: BorderRadius.circular(SundialRadii.xs),
        border: style.hasSurfaceGradient
            ? Border.all(color: style.rim.withValues(alpha: 0.5))
            : Border(left: BorderSide(color: color, width: 3)),
        boxShadow: style.hasSurfaceGradient
            ? (shadow ? style.chromeShadows.take(1).toList() : style.cardShadows.take(1).toList())
            : shadow
            ? [BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: c.shadow.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      foregroundDecoration: style.hasSurfaceGradient && style.gloss
          ? BoxDecoration(borderRadius: BorderRadius.circular(SundialRadii.xs), gradient: style.glossGradient)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            occurrence.entry.title,
            maxLines: endMinute - start >= 60 ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: SundialType.body(10.5, weight: FontWeight.w700, color: c.text),
          ),
          if (endMinute - start >= 45)
            Text(
              '${_formatMinute(context, start)} – ${_formatMinute(context, endMinute)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SundialType.label(9, color: c.textTertiary),
            ),
        ],
      ),
    );
  }

  static String _formatMinute(BuildContext context, int minute) => DateFormat.Hm(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(DateTime(2020, 1, 1, minute ~/ 60 % 24, minute % 60));
}

Color _spaceColorFor(BuildContext context, EntryOccurrence occurrence, List<Space> spaces) {
  for (final space in spaces) {
    if (space.id == occurrence.entry.spaceId) return Color(space.colorValue);
  }
  return context.mc.accent;
}

class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
    required this.color,
    required this.onDelta,
    required this.onEnd,
    required this.onCancel,
  });

  final Color color;
  final ValueChanged<int> onDelta;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

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
        supportedDevices: _resizeDevices,
        dragStartBehavior: DragStartBehavior.down,
        onVerticalDragStart: (_) {
          _delta = 0;
          widget.onDelta(0);
        },
        onVerticalDragUpdate: (details) {
          _delta += details.delta.dy;
          widget.onDelta((_delta / _WeekTimeGridState.hourHeight * 60).round());
        },
        onVerticalDragEnd: (_) {
          _delta = 0;
          widget.onEnd();
        },
        onVerticalDragCancel: () {
          _delta = 0;
          widget.onCancel();
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

class _EntryDrag {
  const _EntryDrag({
    required this.occurrence,
    required this.dayIndex,
    required this.startMinute,
    required this.durationMinutes,
    required this.grabMinutes,
  });

  final EntryOccurrence occurrence;
  final int dayIndex;
  final int startMinute;
  final int durationMinutes;
  final int grabMinutes;

  _EntryDrag copyWith({int? dayIndex, int? startMinute}) => _EntryDrag(
    occurrence: occurrence,
    dayIndex: dayIndex ?? this.dayIndex,
    startMinute: startMinute ?? this.startMinute,
    durationMinutes: durationMinutes,
    grabMinutes: grabMinutes,
  );
}

class _ShiftRender {
  const _ShiftRender({
    required this.shift,
    required this.rect,
    required this.labelTop,
    required this.fillColor,
    required this.stripeColor,
  });

  final ShiftOccurrence shift;
  final Rect rect;
  final double labelTop;
  final Color fillColor;
  final Color stripeColor;
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({required this.occurrence, required this.onTap});

  final EntryOccurrence occurrence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final color = c.forSpace(occurrence.entry.spaceId);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: style.hasSurfaceGradient ? null : color.withValues(alpha: 0.12),
          gradient: style.hasSurfaceGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.20), style.colors.surface],
                )
              : null,
          borderRadius: BorderRadius.circular(SundialRadii.marker),
          border: style.hasSurfaceGradient ? Border.all(color: color.withValues(alpha: 0.28)) : null,
        ),
        child: Text(
          occurrence.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SundialType.label(8, color: color),
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
