import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../core/i18n/date_labels.dart';
import '../core/i18n/l10n.dart';
import '../core/widgets/ui_kit.dart';
import '../features/calendar/widgets/day_timeline.dart';
import '../features/entries/widgets/task_card.dart';
import '../features/sleep/sleep_window_card.dart';
import '../features/shifts/widgets/shift_checklist_view.dart';
import '../state/providers.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';
import '../widgets/entry_widgets.dart';
import 'entry_editor.dart';

enum _TodayMode { list, timeline }

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  _TodayMode _mode = _TodayMode.list;

  @override
  Widget build(BuildContext context) {
    final deviceTimeZone = ref.watch(deviceTimeZoneProvider);
    final now = ref.watch(nowProvider);
    final today = localDateAt(now, deviceTimeZone);
    final range = (start: today, end: today);
    final settings = ref.watch(settingsProvider);
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final contexts = ref.watch(contextsProvider(null)).value ?? const <PlannerContext>[];
    final entriesState = ref.watch(entriesProvider(range));
    final shiftsState = ref.watch(shiftsProvider(range));
    final openState = ref.watch(openEntriesProvider(today));
    final l10n = context.l10n;
    final c = context.mc;

    final occurrences = (entriesState.value ?? const <EntryOccurrence>[]).where((entry) {
      if (entry.entry.spaceId != 'work') return true;
      if (settings.hideWorkSpace) return false;
      if (entry.entry.kind == EntryKind.deadline) return true;
      return settings.isWorkTime(now, deviceTimeZone);
    }).toList();
    final shifts = settings.hideWorkSpace || !settings.isWorkTime(now, deviceTimeZone)
        ? const <ShiftOccurrence>[]
        : shiftsState.value ?? const <ShiftOccurrence>[];
    final occurrenceIds = {for (final occurrence in occurrences) occurrence.entry.id};
    final extras = (openState.value ?? const <Entry>[]).where((entry) {
      if (occurrenceIds.contains(entry.id)) return false;
      // A recurring series only belongs in Today on a day it occurs.
      if (entry.recurrence != null && !entry.occursOn(today)) return false;
      if (entry.spaceId != 'work') return true;
      if (settings.hideWorkSpace) return false;
      if (entry.kind == EntryKind.deadline) return true;
      return settings.isWorkTime(now, deviceTimeZone);
    }).toList();
    final done = occurrences.where((occurrence) => occurrence.completed).length;
    final total = occurrences.length + extras.length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(entriesProvider(range));
        ref.invalidate(shiftsProvider(range));
        ref.invalidate(openEntriesProvider(today));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _TodayHeader(date: today)),
              SundialSegmented<_TodayMode>(
                segments: [
                  SundialSegment(value: _TodayMode.list, label: l10n.listView, icon: Icons.checklist),
                  SundialSegment(
                    value: _TodayMode.timeline,
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
          const SizedBox(height: 14),
          _ProgressCard(done: done, total: total),
          if (shifts.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionLabel(l10n.shiftsSection),
            for (final item in shifts) ...[
              ShiftTile(occurrence: item, contexts: contexts),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 0, 10),
                child: ShiftChecklistSection(
                  patternId: item.pattern.id,
                  date: item.date,
                  slotKey: item.slotKey,
                  dayIndex: item.pattern.cycleIndexFor(item.date),
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          if (entriesState.hasError)
            _ErrorNotice(text: l10n.couldNotLoadDay('${entriesState.error}'))
          else
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: _mode == _TodayMode.list
                  ? _TodayList(
                      key: const ValueKey('today-list'),
                      occurrences: occurrences,
                      extras: extras,
                      spaces: spaces,
                      shifts: shifts,
                    )
                  : _TodayTimeline(
                      key: const ValueKey('today-timeline'),
                      date: today,
                      occurrences: occurrences,
                      extras: extras,
                      shifts: shifts,
                      spaces: spaces,
                      contexts: contexts,
                    ),
            ),
          if (occurrences.isEmpty && extras.isEmpty && shifts.isEmpty) ...[
            const SizedBox(height: 10),
            SoftCard(
              padding: EdgeInsets.zero,
              color: c.surface.withValues(alpha: 0.7),
              child: AppEmptyState(
                icon: Icons.event_available_outlined,
                title: l10n.noPlanToday,
                message: l10n.noPlanTodayHint,
                action: FilledButton.tonalIcon(
                  onPressed: () => showEntryEditor(context, spaces: spaces),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addSomething),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const SleepWindowCard(),
        ],
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.date});

  final LocalDate date;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.today, color: c.accent),
        Text(
          DateFormat('EEEE', locale).format(date.toDateTime()),
          style: SundialType.display(31, color: c.text),
        ),
        const SizedBox(height: 2),
        Text(formatFullDate(context, date.toDateTime()), style: SundialType.body(14, color: c.textSecondary)),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final ratio = total == 0 ? 0.0 : done / total;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(context.l10n.progressToday, style: SundialType.label(11.5, color: c.textSecondary)),
              const Spacer(),
              Text(
                total == 0 ? context.l10n.noPlanToday : context.l10n.doneOfTotal(done, total),
                style: SundialType.label(11.5, color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(SundialRadii.xs),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: c.surfaceHigh,
              color: c.accent,
            ),
          ),
          if (total > 0 && done == total) ...[
            const SizedBox(height: 8),
            Text(context.l10n.allDone, style: SundialType.body(11.5, color: c.success)),
          ],
        ],
      ),
    );
  }
}

class _TodayList extends StatelessWidget {
  const _TodayList({
    super.key,
    required this.occurrences,
    required this.extras,
    required this.spaces,
    required this.shifts,
  });

  final List<EntryOccurrence> occurrences;
  final List<Entry> extras;
  final List<Space> spaces;
  final List<ShiftOccurrence> shifts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final grouped = <String, List<Widget>>{};
    for (final occurrence in occurrences) {
      (grouped[occurrence.entry.spaceId] ??= []).add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(occurrence: occurrence, entry: occurrence.entry),
        ),
      );
    }
    for (final entry in extras) {
      (grouped[entry.spaceId] ??= []).add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(entry: entry),
        ),
      );
    }
    final orderedSpaces = [
      ...spaces,
      for (final id in grouped.keys)
        if (!spaces.any((space) => space.id == id)) Space(id: id, name: id, colorValue: 0xFF888888),
    ];
    final children = <Widget>[];
    for (final space in orderedSpaces) {
      final items = grouped.remove(space.id);
      if (items == null || items.isEmpty) continue;
      children
        ..add(const SizedBox(height: 14))
        ..add(
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: Color(space.colorValue), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(space.name.toUpperCase(), style: SundialType.kicker(color: c.textTertiary)),
            ],
          ),
        )
        ..add(const SizedBox(height: 7))
        ..addAll(items);
    }
    if (shifts.isEmpty && children.isEmpty) {
      return Text(l10n.noPlanToday, style: SundialType.body(12.5, color: c.textTertiary));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _TodayTimeline extends StatelessWidget {
  const _TodayTimeline({
    super.key,
    required this.date,
    required this.occurrences,
    required this.extras,
    required this.shifts,
    required this.spaces,
    required this.contexts,
  });

  final LocalDate date;
  final List<EntryOccurrence> occurrences;
  final List<Entry> extras;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (extras.isNotEmpty) ...[
          SectionLabel(context.l10n.unscheduledTasks),
          const SizedBox(height: 6),
          for (final entry in extras)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskCard(entry: entry, compact: true),
            ),
          const SizedBox(height: 12),
        ],
        SoftCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: DayTimeline(
            day: date,
            entries: occurrences,
            shifts: shifts,
            spaces: spaces,
            contexts: contexts,
            onAdd: () => showEntryEditor(context, initialDate: date, spaces: spaces),
          ),
        ),
        if (occurrences.isEmpty && shifts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(context.l10n.noPlanToday, style: SundialType.body(12.5, color: c.textTertiary)),
          ),
        if (shifts.isNotEmpty) const SizedBox(height: 4),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.dangerSoft,
        borderRadius: BorderRadius.circular(SundialRadii.md),
        border: Border.all(color: c.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: c.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: SundialType.body(12.5, color: c.danger)),
          ),
        ],
      ),
    );
  }
}
