import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../models/time_entry.dart';
import '../../../screens/entry_editor.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// A friendly task row used by Today, space overviews and project screens.
///
/// It accepts either a calendar occurrence (for recurring entries) or a bare
/// entry (for unscheduled and overdue tasks).
class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.entry, this.occurrence, this.compact = false});

  final Entry entry;
  final EntryOccurrence? occurrence;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final now = ref.watch(nowProvider);
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final contexts = ref.watch(contextsProvider(null)).value ?? const <PlannerContext>[];
    final projects = ref.watch(projectsProvider(null)).value ?? const <Project>[];
    final entryTimes = ref.watch(entryTimeProvider(entry.id)).value ?? const <TimeEntry>[];
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final sessions = _relevant(entryTimes);
    final tracked = sessions.fold(Duration.zero, (total, item) => total + item.durationAt(now.toUtc()));
    final running = sessions.any((item) => item.isRunning);
    final completed = occurrence?.completed ?? entry.isDone;
    final plannerContext = _contextFor(contexts);
    final project = _projectFor(projects);
    final startAt = occurrence?.startAt ?? entry.startAt;
    final endAt = occurrence?.endAt ?? entry.endAt;

    return Pressable(
      onTap: () => showEntryEditor(context, entry: entry, initialDate: occurrence?.date, spaces: spaces),
      child: Container(
        padding: EdgeInsets.fromLTRB(compact ? 10 : 12, compact ? 9 : 11, 10, compact ? 9 : 11),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.readOnly)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 2),
                child: Icon(Icons.lock_outline, size: 20, color: c.textTertiary),
              )
            else
              _Check(
                completed: completed,
                color: Color(plannerContext?.colorValue ?? _spaceColor(spaces)),
                onTap: () => _toggleComplete(ref, timeZone),
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              ManeType.body(
                                compact ? 13.5 : 14.5,
                                weight: FontWeight.w700,
                                color: completed ? c.textTertiary : c.text,
                              ).copyWith(
                                decoration: completed ? TextDecoration.lineThrough : null,
                                decorationColor: c.textTertiary,
                              ),
                        ),
                      ),
                      if (!completed) _PriorityChip(entry: entry, now: now),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (startAt != null)
                        _Meta(
                          icon: entry.isDeadline ? Icons.flag_outlined : Icons.schedule,
                          text: _timeLabel(context, startAt, endAt, timeZone),
                          color: entry.isDeadline ? c.warning : c.textSecondary,
                        )
                      else if (endAt != null && entry.date != null)
                        _Meta(
                          icon: Icons.flag_outlined,
                          text: DateFormat.Hm(
                            Localizations.localeOf(context).toLanguageTag(),
                          ).format(localDateTimeAt(endAt, timeZone)),
                          color: c.warning,
                        )
                      else if (entry.timing == EntryTiming.anytime)
                        _Meta(icon: Icons.all_inclusive, text: l10n.anytime, color: c.textTertiary),
                      if (plannerContext != null)
                        _Meta(
                          icon: Icons.circle,
                          text: plannerContext.name,
                          color: Color(plannerContext.colorValue),
                          tinyIcon: true,
                        ),
                      if (project != null)
                        _Meta(icon: Icons.folder_outlined, text: project.name, color: c.textSecondary),
                      if (sessions.isNotEmpty)
                        _Meta(
                          icon: running ? Icons.timer : Icons.timer_outlined,
                          text: _durationText(tracked),
                          color: running ? c.success : c.textSecondary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!entry.readOnly && !completed && entry.timing != EntryTiming.scheduled)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: IconButton(
                  tooltip: running ? l10n.pauseTask : l10n.resumeTask,
                  onPressed: () => _toggleClock(ref, timeZone),
                  icon: Icon(
                    running ? Icons.pause_circle_outlined : Icons.play_circle_outline,
                    color: running ? c.success : c.accent,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _spaceColor(List<Space> spaces) {
    for (final space in spaces) {
      if (space.id == entry.spaceId) return space.colorValue;
    }
    return 0xFF4F6D5A;
  }

  PlannerContext? _contextFor(List<PlannerContext> contexts) {
    final id = entry.contextId;
    if (id == null) return null;
    for (final context in contexts) {
      if (context.id == id) return context;
    }
    return null;
  }

  Project? _projectFor(List<Project> projects) {
    final id = entry.projectId;
    if (id == null) return null;
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  List<TimeEntry> _relevant(List<TimeEntry> entries) {
    final occurrenceDate = occurrence?.date;
    if (occurrenceDate == null || entry.recurrence == null) return entries;
    return entries
        .where((item) => item.occurrenceDateKey == null || item.occurrenceDateKey == occurrenceDate.key)
        .toList();
  }

  EntryOccurrence _asOccurrence(String timeZone) {
    final existing = occurrence;
    if (existing != null) return existing;
    final today = localDateAt(DateTime.now().toUtc(), timeZone);
    final date = entry.recurrence?.occursOn(today, entry.date ?? today) == true
        ? today
        : (entry.date ?? today);
    return EntryOccurrence(
      date: date,
      displayDate: date,
      entry: entry,
      completed: entry.isDone,
      startAt: entry.startAt,
      endAt: entry.endAt,
    );
  }

  Future<void> _toggleComplete(WidgetRef ref, String timeZone) async {
    if (entry.readOnly) return;
    final completed = occurrence?.completed ?? entry.isDone;
    final repository = ref.read(repositoryProvider);
    await repository.setCompletion(_asOccurrence(timeZone), completed: !completed);
    ref.read(soundControllerProvider).play(completed ? UiSound.toggleOff : UiSound.toggleOn);
  }

  Future<void> _toggleClock(WidgetRef ref, String timeZone) async {
    if (entry.readOnly) return;
    final repository = ref.read(repositoryProvider);
    final occ = _asOccurrence(timeZone);
    final running = _relevant(
      ref.read(entryTimeProvider(entry.id)).value ?? const <TimeEntry>[],
    ).any((item) => item.isRunning);
    if (running) {
      await repository.clockOut(occ);
    } else {
      await repository.clockIn(occ);
    }
    ref.read(soundControllerProvider).play(running ? UiSound.toggleOff : UiSound.toggleOn);
  }

  String _timeLabel(BuildContext context, DateTime startAt, DateTime? endAt, String timeZone) {
    final format = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    final start = format.format(localDateTimeAt(startAt, timeZone));
    if (endAt == null) return start;
    final end = format.format(localDateTimeAt(endAt, timeZone));
    return '$start – $end';
  }

  String _durationText(Duration value) {
    final minutes = value.inMinutes;
    final hours = minutes ~/ 60;
    final rest = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$rest';
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.completed, required this.color, required this.onTap});

  final bool completed;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      semanticLabel: completed ? context.l10n.reopenTask : context.l10n.completeTask,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 1),
        decoration: BoxDecoration(
          color: completed ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: completed ? color : context.mc.borderStrong, width: 1.7),
        ),
        child: completed ? const Icon(Icons.check, size: 15, color: Colors.white) : null,
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.entry, required this.now});

  final Entry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final priority = effectivePriority(entry, now);
    if (priority == EntryPriority.none) return const SizedBox.shrink();
    final l10n = context.l10n;
    final color = switch (priority) {
      EntryPriority.none => context.mc.textTertiary,
      EntryPriority.low => context.mc.info,
      EntryPriority.medium => context.mc.warning,
      EntryPriority.high => context.mc.danger,
    };
    final label = switch (priority) {
      EntryPriority.none => l10n.priorityNone,
      EntryPriority.low => l10n.priorityLow,
      EntryPriority.medium => l10n.priorityMedium,
      EntryPriority.high => l10n.priorityHigh,
    };
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(7)),
      child: Text(
        label,
        style: ManeType.label(9.5, color: color).copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color, this.tinyIcon = false});

  final IconData icon;
  final String text;
  final Color color;
  final bool tinyIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: tinyIcon ? 7 : 13, color: color),
        const SizedBox(width: 4),
        Text(text, style: ManeType.label(10.5, color: color)),
      ],
    );
  }
}
