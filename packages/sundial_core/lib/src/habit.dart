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
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
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

  /// Scheduled weekdays, 1 = Monday through 7 = Sunday. An empty set means the
  /// habit has no fixed days and behaves like every day.
  final Set<int> weekdays;

  final int position;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool isScheduled(LocalDate date) => weekdays.isEmpty || weekdays.contains(date.weekday);

  int get scheduledPerWeek => weekdays.isEmpty ? 7 : weekdays.length.clamp(1, 7);

  /// A habit whose target covers every scheduled day runs a day streak;
  /// anything lighter runs a weekly streak.
  bool get isDaily => cleanTarget >= scheduledPerWeek;

  int get cleanTarget => targetPerWeek.clamp(1, scheduledPerWeek);

  /// Completions in the week that starts on [weekStart], counting only
  /// scheduled days.
  int weekProgress(Set<LocalDate> completions, LocalDate anyDayInWeek, int weekStart) {
    final start = anyDayInWeek.startOfWeek(weekStart);
    var count = 0;
    for (var index = 0; index < 7; index++) {
      final day = start.addDays(index);
      if (isScheduled(day) && completions.contains(day)) count++;
    }
    return count;
  }

  /// Consecutive checked days for a daily habit, or qualifying weeks for a
  /// weekly-target habit.
  ///
  /// Unscheduled days neither add to nor break a daily streak, so a Mon/Wed/Fri
  /// habit keeps its run across Tuesday. A 3x/week habit completed Monday to
  /// Wednesday already has one qualifying week, and the rest of that week does
  /// not break it.
  int streak(Set<LocalDate> completions, LocalDate today, {int weekStart = DateTime.monday}) {
    if (isDaily) {
      var cursor = isScheduled(today) ? today : _previousScheduled(today);
      if (!completions.contains(cursor)) cursor = _previousScheduled(cursor.addDays(-1));
      var count = 0;
      // A bounded walk keeps a corrupt schedule from looping forever.
      for (var guard = 0; guard < 400; guard++) {
        if (isScheduled(cursor)) {
          if (!completions.contains(cursor)) break;
          count++;
        }
        cursor = cursor.addDays(-1);
      }
      return count;
    }

    final weekStartDate = today.startOfWeek(weekStart);
    // Weekly-target habits count consecutive qualifying weeks, not raw
    // check-ins. The current week counts once its target is met; a week still
    // in progress does not break the previous run.
    var count = weekProgress(completions, today, weekStart) >= cleanTarget ? 1 : 0;
    var previous = weekStartDate.addDays(-7);
    while (weekProgress(completions, previous, weekStart) >= cleanTarget) {
      count++;
      previous = previous.addDays(-7);
    }
    return count;
  }

  LocalDate _previousScheduled(LocalDate from) {
    var cursor = from;
    for (var guard = 0; guard < 14 && !isScheduled(cursor); guard++) {
      cursor = cursor.addDays(-1);
    }
    return cursor;
  }

  /// Comma-separated weekday numbers, sorted, for storage and backups.
  String get weekdaysKey => (weekdays.toList()..sort()).join(',');

  static Set<int> parseWeekdays(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {1, 2, 3, 4, 5, 6, 7};
    final parsed = <int>{};
    for (final part in raw.split(',')) {
      final day = int.tryParse(part.trim());
      if (day != null && day >= 1 && day <= 7) parsed.add(day);
    }
    return parsed.isEmpty ? const {1, 2, 3, 4, 5, 6, 7} : parsed;
  }
}
