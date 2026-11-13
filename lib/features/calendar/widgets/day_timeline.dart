import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
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
    required this.onAdd,
  });

  final LocalDate day;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final VoidCallback onAdd;

  static const hourHeight = 54.0;

  @override
  ConsumerState<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends ConsumerState<DayTimeline> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat.yMMMMEEEEd(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(day.toDateTime()),
                style: ManeType.title(15, color: c.text),
              ),
            ),
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
                    color: c.softForSpace(entry.entry.spaceId),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.forSpace(entry.entry.spaceId).withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    entry.entry.title,
                    style: ManeType.body(11.5, weight: FontWeight.w700, color: c.text),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        if (timedEntries.isEmpty && deadlineEntries.isEmpty && shifts.isEmpty && allDayEntries.isEmpty)
          AppEmptyState(icon: Icons.event_available_outlined, title: l10n.noEntriesOnDay, compact: true)
        else
          SizedBox(
            height: viewportHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
                      child: Stack(
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
                                        style: ManeType.label(9.5, color: c.textTertiary),
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
                          for (final shift in shifts)
                            _shiftBlock(context, shift, dayStart, dayEnd, c, timelineHeight),
                          for (final entry in timedEntries)
                            _entryBlock(context, entry, dayStart, dayEnd, c, timelineHeight),
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (shifts.isNotEmpty) ...[
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
    ManeColors c,
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
          color: c.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
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
                style: ManeType.label(10.5, color: c.warning),
              ),
            ),
            Text(time, style: ManeType.label(9.5, color: c.warning)),
          ],
        ),
      ),
    );
  }

  Widget _shiftBlock(
    BuildContext context,
    ShiftOccurrence shift,
    DateTime dayStart,
    DateTime dayEnd,
    ManeColors c,
    double height,
  ) {
    final start = shift.startAt.isBefore(dayStart) ? dayStart : shift.startAt;
    final end = shift.endAt.isAfter(dayEnd) ? dayEnd : shift.endAt;
    if (!end.isAfter(start)) return const SizedBox.shrink();
    final top = start.difference(dayStart).inMinutes / 60 * DayTimeline.hourHeight;
    final blockHeight = (end.difference(start).inMinutes / 60 * DayTimeline.hourHeight).clamp(18.0, height);
    final color = c.forSpace(shift.pattern.spaceId);
    return Positioned(
      left: 56,
      right: 8,
      top: top,
      child: Container(
        height: blockHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.softForSpace(shift.pattern.spaceId),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Text(
          shift.pattern.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ManeType.body(11, weight: FontWeight.w700, color: color),
        ),
      ),
    );
  }

  Widget _entryBlock(
    BuildContext context,
    EntryOccurrence entry,
    DateTime dayStart,
    DateTime dayEnd,
    ManeColors c,
    double height,
  ) {
    final start = entry.startAt!;
    final end = entry.endAt ?? start;
    final clippedStart = start.isBefore(dayStart) ? dayStart : start;
    final clippedEnd = end.isAfter(dayEnd) ? dayEnd : end;
    if (!clippedEnd.isAfter(clippedStart)) return const SizedBox.shrink();
    final top = clippedStart.difference(dayStart).inMinutes / 60 * DayTimeline.hourHeight;
    final blockHeight = (clippedEnd.difference(clippedStart).inMinutes / 60 * DayTimeline.hourHeight).clamp(
      22.0,
      height,
    );
    final color = c.forSpace(entry.entry.spaceId);
    return Positioned(
      left: 72,
      right: 20,
      top: top,
      child: Container(
        height: blockHeight,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          boxShadow: [BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Text(
          entry.entry.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ManeType.body(11.5, weight: FontWeight.w700, color: c.text),
        ),
      ),
    );
  }
}
