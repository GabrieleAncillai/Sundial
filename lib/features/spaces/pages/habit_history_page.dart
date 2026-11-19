import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Twelve weeks of check-ins for one habit, plus its current streak and target.
class HabitHistoryPage extends ConsumerWidget {
  const HabitHistoryPage({super.key, required this.habit});

  final Habit habit;

  static const _weeks = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final today = localDateAt(ref.watch(nowProvider), ref.watch(deviceTimeZoneProvider));
    final weekStart = ref.watch(settingsProvider).weekStart;
    final completions = ref.watch(habitCompletionsProvider).value?[habit.id] ?? const <LocalDate>{};
    final color = Color(habit.colorValue);
    final currentWeekStart = today.startOfWeek(weekStart);
    final progress = habit.weekProgress(completions, today, weekStart);
    final streak = habit.streak(completions, today, weekStart: weekStart);
    final doneEver = completions.where((date) => !date.isAfter(today)).length;

    return SundialPage(
      title: habit.name,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SoftCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(label: l10n.thisWeek, value: '$progress/${habit.cleanTarget}'),
                ),
                Expanded(
                  child: _Stat(
                    label: l10n.habitHistory,
                    value: habit.isDaily ? l10n.streakDays(streak) : l10n.streakWeeks(streak),
                  ),
                ),
                Expanded(
                  child: _Stat(label: l10n.habitCheckIns, value: '$doneEver'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l10n.habitHistoryHint, style: SundialType.body(11.5, color: c.textTertiary)),
          ),
          const SizedBox(height: 14),
          for (var offset = _weeks - 1; offset >= 0; offset--)
            _WeekRow(
              start: currentWeekStart.addDays(-7 * offset),
              today: today,
              completions: completions,
              habit: habit,
              color: color,
            ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({
    required this.start,
    required this.today,
    required this.completions,
    required this.habit,
    required this.color,
  });

  final LocalDate start;
  final LocalDate today;
  final Set<LocalDate> completions;
  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final label = formatShortDate(context, start.toDateTime());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label, style: SundialType.label(10.5, color: c.textTertiary)),
          ),
          for (var index = 0; index < 7; index++)
            Expanded(
              child: Center(
                child: _DayDot(
                  date: start.addDays(index),
                  today: today,
                  done: completions.contains(start.addDays(index)),
                  scheduled: habit.isScheduled(start.addDays(index)),
                  color: color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.date,
    required this.today,
    required this.done,
    required this.scheduled,
    required this.color,
  });

  final LocalDate date;
  final LocalDate today;
  final bool done;
  final bool scheduled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final future = date.isAfter(today);
    return Semantics(
      label: formatShortDate(context, date.toDateTime()),
      selected: done,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: done ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: scheduled && !future
              ? Border.all(color: date == today ? color : c.borderStrong, width: date == today ? 1.8 : 1.2)
              : null,
        ),
        child: done ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: SundialType.title(15, color: c.text),
        ),
        const SizedBox(height: 2),
        Text(label, style: SundialType.label(10.5, color: c.textTertiary)),
      ],
    );
  }
}
