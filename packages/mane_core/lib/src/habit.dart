import 'entry.dart';
import 'local_date.dart';

/// How urgent a dated deadline is right now.
///
/// Explicit priority is still a user choice; a deadline's urgency is the floor
/// that stops a due-today task from sitting behind a "low" label.
enum DeadlineUrgency { none, low, medium, high }

DeadlineUrgency deadlineUrgency(Entry entry, DateTime now) {
  final due = entry.endAt;
  if (due == null || entry.endMinute == null || entry.startMinute != null) {
    return DeadlineUrgency.none;
  }
  final remaining = due.difference(now.toUtc());
  if (remaining <= Duration.zero) return DeadlineUrgency.high;
  if (remaining <= const Duration(hours: 6)) return DeadlineUrgency.high;
  if (remaining <= const Duration(hours: 24)) return DeadlineUrgency.medium;
  if (remaining <= const Duration(hours: 72)) return DeadlineUrgency.low;
  return DeadlineUrgency.none;
}

EntryPriority effectivePriority(Entry entry, DateTime now) {
  final explicit = entry.priority;
  final urgency = switch (deadlineUrgency(entry, now)) {
    DeadlineUrgency.none => EntryPriority.none,
    DeadlineUrgency.low => EntryPriority.low,
    DeadlineUrgency.medium => EntryPriority.medium,
    DeadlineUrgency.high => EntryPriority.high,
  };
  return urgency.index > explicit.index ? urgency : explicit;
}

/// A weekly habit inside Personal.
///
/// [targetPerWeek] is the number of days the user wants to check in. Daily
/// habits use 7; a three-times-a-week habit uses 3.
class Habit {
  const Habit({
    required this.id,
    required this.spaceId,
    this.contextId,
    required this.name,
    this.description = '',
    required this.colorValue,
    this.icon = 'star',
    this.targetPerWeek = 7,
    this.position = 0,
    this.archived = false,
    this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String spaceId;
  final String? contextId;
  final String name;
  final String description;
  final int colorValue;
  final String icon;
  final int targetPerWeek;
  final int position;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isDaily => targetPerWeek >= 7;

  int get cleanTarget => targetPerWeek.clamp(1, 7);

  /// Completions in the week that starts on [weekStart].
  int weekProgress(Set<LocalDate> completions, LocalDate anyDayInWeek, int weekStart) {
    final start = anyDayInWeek.startOfWeek(weekStart);
    var count = 0;
    for (var index = 0; index < 7; index++) {
      if (completions.contains(start.addDays(index))) count++;
    }
    return count;
  }

  /// Consecutive checked days for a daily habit, or completed check-ins across
  /// qualifying weeks for a weekly-target habit.
  ///
  /// A 3x/week habit completed Monday to Wednesday keeps a three-day streak on
  /// Sunday even though Sunday itself is unchecked. Previous weeks that met
  /// the target add to the same count.
  int streak(Set<LocalDate> completions, LocalDate today, {int weekStart = DateTime.monday}) {
    if (isDaily) {
      var cursor = today;
      if (!completions.contains(cursor)) cursor = cursor.addDays(-1);
      var count = 0;
      while (completions.contains(cursor)) {
        count++;
        cursor = cursor.addDays(-1);
      }
      return count;
    }

    final weekStartDate = today.startOfWeek(weekStart);
    var count = weekProgress(completions, today, weekStart);
    var previous = weekStartDate.addDays(-7);
    while (weekProgress(completions, previous, weekStart) >= cleanTarget) {
      count += cleanTarget;
      previous = previous.addDays(-7);
    }
    return count;
  }
}
