import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/sundial_style.dart';
import '../../calendar/widgets/open_end_entry_block.dart';
import '../../shifts/shift_block_layout.dart';
import '../../shifts/shift_block_painter.dart';
import '../../shifts/shift_palette.dart';
import '../../shifts/widgets/shift_checklist_view.dart';

/// A 24-hour day view. Shifts are drawn as background blocks; entries sit in
/// front, so a collision is visible without opening anything.
class DayTimeline extends ConsumerStatefulWidget {
  const DayTimeline({
    super.key,
    required this.day,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
    required this.onAdd,
    this.onShifts,
    this.fill = false,
  });

  final LocalDate day;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;
  final VoidCallback onAdd;

  /// Opens the per-day shift sheet. Null when there is no pattern to adjust.
  final VoidCallback? onShifts;

  /// Fill the available height instead of a card-sized viewport. The Plan page
  /// uses this for its collapsed phone day, where the timeline owns the screen.
  final bool fill;

  static const hourHeight = 54.0;

  @override
  ConsumerState<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends ConsumerState<DayTimeline> {
  static const _labelLineHeight = 14.0;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToRelevantHour());
  }

  @override
  void didUpdateWidget(covariant DayTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToRelevantHour());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Opens near the current time on today, and near the first booked item on
  /// other days. Starting at midnight hides the part of the day people care
  /// about.
  void _jumpToRelevantHour() {
    if (!mounted || !_scroll.hasClients) return;
    final timeZone = ref.read(deviceTimeZoneProvider);
    final now = ref.read(nowProvider);
    final dayStart = instantAt(widget.day, 0, timeZone);
    final dayEnd = instantAt(widget.day.addDays(1), 0, timeZone);
    var minute = 8 * 60;
    if (!now.isBefore(dayStart) && now.isBefore(dayEnd)) {
      minute = now.difference(dayStart).inMinutes;
    } else {
      final starts = [
        for (final entry in widget.entries)
          if (entry.startAt != null) localMinuteAt(entry.startAt!, timeZone),
        for (final shift in widget.shifts) localMinuteAt(shift.startAt, timeZone),
      ];
      if (starts.isNotEmpty) minute = starts.reduce((a, b) => a < b ? a : b);
    }
    final target = (minute / 60 * DayTimeline.hourHeight - _scroll.position.viewportDimension * 0.3).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final l10n = context.l10n;
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final now = ref.watch(nowProvider);
    final day = widget.day;
    final entries = widget.entries;
    final shifts = widget.shifts;
    final dayStart = instantAt(day, 0, timeZone);
    final dayEnd = instantAt(day.addDays(1), 0, timeZone);
    final allDayEntries = entries.where((entry) => entry.startAt == null && entry.endAt == null).toList();
    final deadlineEntries = entries.where((entry) => entry.startAt == null && entry.endAt != null).toList();
    final timedEntries = entries.where((entry) => entry.startAt != null).toList();
    final timelineHeight = DayTimeline.hourHeight * 24;
    final nowOffset = now.difference(dayStart).inMinutes / 60 * DayTimeline.hourHeight;
    final viewportHeight = (MediaQuery.sizeOf(context).height * 0.55).clamp(360.0, 640.0);

    Widget timelineCard() => ClipRRect(
      borderRadius: BorderRadius.circular(SundialRadii.lg),
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(c.textTertiary.withValues(alpha: 0.35)),
          thickness: const WidgetStatePropertyAll(3),
        ),
        child: Scrollbar(
          controller: _scroll,
          radius: const Radius.circular(2),
          child: SingleChildScrollView(
            controller: _scroll,
            child: Container(
              height: timelineHeight,
              color: c.surfaceAlt.withValues(alpha: 0.45),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shiftRenders = _shiftRenders(shifts, dayStart, dayEnd, constraints.maxWidth, context);
                  return Stack(
                    children: [
                      for (var hour = 0; hour <= 24; hour++)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: hour * DayTimeline.hourHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 52,
                                child: Transform.translate(
                                  offset: Offset(0, hour == 0 ? 2 : -6),
                                  child: Text(
                                    hour == 24 ? '' : TimeOfDay(hour: hour, minute: 0).format(context),
                                    textAlign: TextAlign.right,
                                    style: SundialType.label(9.5, color: c.textTertiary),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  height: 1,
                                  color: hour == 24 ? Colors.transparent : c.border,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                cornerRadius: 10,
                                stripeWidth: 3,
                              ),
                            ),
                          ),
                        ),
                      for (final render in shiftRenders)
                        Positioned(
                          left: render.rect.left + 7,
                          top: render.labelTop,
                          width: math.max(0.0, render.rect.width - 10),
                          child: IgnorePointer(
                            child: Text(
                              render.shift.pattern.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: SundialType.body(11, weight: FontWeight.w700, color: c.text),
                            ),
                          ),
                        ),
                      for (final entry in timedEntries)
                        _entryBlock(context, entry, dayStart, dayEnd, timeZone, c, timelineHeight),
                      for (final entry in deadlineEntries)
                        _deadlineBlock(context, entry, dayStart, dayEnd, timeZone, c, timelineHeight),
                      if (now.isAfter(dayStart) && now.isBefore(dayEnd))
                        Positioned(
                          left: 52,
                          right: 8,
                          top: nowOffset.clamp(0, timelineHeight - 1),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: c.danger, shape: BoxShape.circle),
                              ),
                              Expanded(child: Container(height: 1.4, color: c.danger)),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final empty = timedEntries.isEmpty && deadlineEntries.isEmpty && shifts.isEmpty && allDayEntries.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.fill)
          Row(
            children: [
              Expanded(
                child: Text(
                  formatFullDate(context, day.toDateTime()),
                  style: SundialType.title(15, color: c.text),
                ),
              ),
              if (widget.onShifts != null) ...[
                GlassIconButton(
                  icon: Icons.work_outline,
                  tooltip: l10n.adjustShifts,
                  size: 34,
                  onTap: widget.onShifts!,
                ),
                const SizedBox(width: 8),
              ],
              GlassIconButton(icon: Icons.add, tooltip: l10n.addOnThisDay, size: 34, onTap: widget.onAdd),
            ],
          ),
        if (allDayEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in allDayEntries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.hasSurfaceGradient ? null : c.softForSpace(entry.entry.spaceId),
                    gradient: style.hasSurfaceGradient
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.softForSpace(entry.entry.spaceId), style.colors.surface],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(SundialRadii.xs),
                    border: Border.all(
                      color: c
                          .forSpace(entry.entry.spaceId)
                          .withValues(alpha: style.hasSurfaceGradient ? 0.34 : 0.2),
                    ),
                  ),
                  foregroundDecoration: style.hasSurfaceGradient && style.gloss
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(SundialRadii.xs),
                          gradient: style.glossGradient,
                        )
                      : null,
                  child: Text(
                    entry.entry.title,
                    style: SundialType.body(11.5, weight: FontWeight.w700, color: c.text),
                  ),
                ),
            ],
          ),
        ],
        if (!widget.fill || allDayEntries.isNotEmpty) const SizedBox(height: 10),
        if (widget.fill)
          Expanded(child: timelineCard())
        else if (empty)
          AppEmptyState(icon: Icons.event_available_outlined, title: l10n.noEntriesOnDay, compact: true)
        else
          SizedBox(height: viewportHeight, child: timelineCard()),
        if (!widget.fill && shifts.isNotEmpty) ...[
          const SizedBox(height: 12),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(l10n.shiftChecklist),
                for (final shift in shifts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ShiftChecklistSection(
                      patternId: shift.pattern.id,
                      date: shift.date,
                      slotKey: shift.slotKey,
                      dayIndex: shift.pattern.cycleIndexFor(shift.date),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _deadlineBlock(
    BuildContext context,
    EntryOccurrence entry,
    DateTime dayStart,
    DateTime dayEnd,
    String timeZone,
    SundialColors c,
    double height,
  ) {
    final due = entry.endAt!;
    if (due.isBefore(dayStart) || !due.isBefore(dayEnd)) return const SizedBox.shrink();
    final top = (due.difference(dayStart).inMinutes / 60 * DayTimeline.hourHeight).clamp(0.0, height - 22);
    final time = DateFormat.Hm(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(localDateTimeAt(due, timeZone));
    return Positioned(
      left: 72,
      right: 20,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: context.style.hasSurfaceGradient ? null : c.warning.withValues(alpha: 0.10),
          gradient: context.style.hasSurfaceGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.warning.withValues(alpha: 0.16), context.style.colors.surface],
                )
              : null,
          borderRadius: BorderRadius.circular(SundialRadii.xs),
          border: Border.all(color: c.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 12, color: c.warning),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                entry.entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SundialType.label(10.5, color: c.warning),
              ),
            ),
            Text(time, style: SundialType.label(9.5, color: c.warning)),
          ],
        ),
      ),
    );
  }

  List<_ShiftRender> _shiftRenders(
    List<ShiftOccurrence> shifts,
    DateTime dayStart,
    DateTime dayEnd,
    double width,
    BuildContext context,
  ) {
    const leftGutter = 56.0;
    const rightGutter = 8.0;
    final available = math.max(0.0, width - leftGutter - rightGutter);
    final bounds = <({ShiftOccurrence shift, int start, int end})>[];
    for (final shift in shifts) {
      final start = shift.startAt.isBefore(dayStart) ? dayStart : shift.startAt;
      final end = shift.endAt.isAfter(dayEnd) ? dayEnd : shift.endAt;
      if (!end.isAfter(start)) continue;
      bounds.add((
        shift: shift,
        start: start.difference(dayStart).inMinutes,
        end: end.difference(dayStart).inMinutes,
      ));
    }
    final blocks = orderShiftBlocks([
      for (final item in bounds) ShiftBlockSpan(startMinute: item.start, endMinute: item.end),
    ]);
    final labelOffsets = shiftLabelOffsets(
      blocks,
      labelMinuteHeight: (_labelLineHeight / DayTimeline.hourHeight * 60).ceil(),
    );
    final renders = <_ShiftRender>[];
    for (var position = 0; position < blocks.length; position++) {
      final block = blocks[position];
      final item = bounds[block.index];
      final top = block.startMinute / 60 * DayTimeline.hourHeight;
      renders.add(
        _ShiftRender(
          shift: item.shift,
          rect: Rect.fromLTWH(
            leftGutter,
            top,
            available,
            (block.endMinute - block.startMinute) / 60 * DayTimeline.hourHeight,
          ),
          labelTop: top + 5 + labelOffsets[position] / 60 * DayTimeline.hourHeight,
          fillColor: shiftSoftColor(context, item.shift.pattern, widget.contexts),
          stripeColor: shiftColor(context, item.shift.pattern, widget.contexts),
        ),
      );
    }
    return renders;
  }

  Widget _entryBlock(
    BuildContext context,
    EntryOccurrence entry,
    DateTime dayStart,
    DateTime dayEnd,
    String timeZone,
    SundialColors c,
    double height,
  ) {
    final start = entry.startAt!;
    final openEnded = entry.endAt == null;
    final end = entry.endAt ?? start;
    final clippedStart = start.isBefore(dayStart) ? dayStart : start;
    final clippedEnd = end.isAfter(dayEnd) ? dayEnd : end;
    if (!openEnded && !clippedEnd.isAfter(clippedStart)) return const SizedBox.shrink();
    final top = clippedStart.difference(dayStart).inMinutes / 60 * DayTimeline.hourHeight;
    final color = c.forSpace(entry.entry.spaceId);
    if (openEnded) {
      return Positioned(
        left: 72,
        right: 20,
        top: top,
        child: OpenEndEntryBlock(
          title: entry.entry.title,
          color: color,
          timeLabel: '${_time(context, clippedStart, timeZone)} –',
          outlined: true,
        ),
      );
    }
    final blockHeight = (clippedEnd.difference(clippedStart).inMinutes / 60 * DayTimeline.hourHeight).clamp(
      22.0,
      height,
    );
    return Positioned(
      left: 72,
      right: 20,
      top: top,
      child: Container(
        height: blockHeight,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: context.style.hasSurfaceGradient ? null : c.surface,
          gradient: context.style.hasSurfaceGradient ? context.style.surfaceGradient : null,
          borderRadius: BorderRadius.circular(SundialRadii.xs),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          boxShadow: context.style.hasSurfaceGradient
              ? context.style.cardShadows.take(1).toList()
              : [BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        foregroundDecoration: context.style.hasSurfaceGradient && context.style.gloss
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(SundialRadii.xs),
                gradient: context.style.glossGradient,
              )
            : null,
        child: Text(
          entry.entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SundialType.body(11.5, weight: FontWeight.w700, color: c.text),
        ),
      ),
    );
  }

  String _time(BuildContext context, DateTime instant, String timeZone) => DateFormat.Hm(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(localDateTimeAt(instant, timeZone));
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
