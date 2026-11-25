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

/// The period a habit target is measured in.
///
/// Weekly habits count check-ins inside one week. Monthly habits count them
/// inside one calendar month, which covers quotas such as "use the card seven
/// times this month" or "gym twelve times".
enum HabitTargetPeriod { week, month }

/// Check-in counts per calendar day.
///
/// A day may hold more than one check-in, so a set of dates is not enough for
/// monthly quotas. Weekly habits normally use 0 or 1 per day.
typedef HabitCompletions = Map<LocalDate, int>;

/// A habit inside Personal.
///
/// [targetCount] is the number of check-ins wanted in [targetPeriod]. Weekly
/// habits clamp the count to the number of active weekdays; monthly habits
/// allow up to 31, because a quota is not tied to a weekday schedule.
class Habit {
  const Habit({
    required this.id,
    required this.spaceId,
    this.contextId,
    required this.name,
    this.description = '',
    required this.colorValue,
    this.icon = 'star',
    this.targetCount = 7,
    this.targetPeriod = HabitTargetPeriod.week,
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
  final int targetCount;
  final HabitTargetPeriod targetPeriod;

  /// Scheduled weekdays, 1 = Monday through 7 = Sunday. An empty set means the
  /// habit has no fixed days and behaves like every day.
  final Set<int> weekdays;

  final int position;
  final bool archived;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isWeekly => targetPeriod == HabitTargetPeriod.week;

  bool get isMonthly => targetPeriod == HabitTargetPeriod.month;

  bool isScheduled(LocalDate date) => weekdays.isEmpty || weekdays.contains(date.weekday);

  int get scheduledPerWeek => weekdays.isEmpty ? 7 : weekdays.length.clamp(1, 7);

  /// A weekly habit whose target covers every scheduled day runs a day
  /// streak; anything lighter runs a weekly streak. Monthly habits always run
  /// a monthly streak.
  bool get isDaily => isWeekly && cleanTarget >= scheduledPerWeek;

  int get cleanTarget => isMonthly ? targetCount.clamp(1, 31) : targetCount.clamp(1, scheduledPerWeek);

  /// How many check-ins were recorded on [date].
  int countOn(HabitCompletions completions, LocalDate date) => completions[date] ?? 0;

  /// Check-ins in the week that starts on [weekStart], counting only scheduled
  /// days.
  int weekProgress(HabitCompletions completions, LocalDate anyDayInWeek, int weekStart) {
    final start = anyDayInWeek.startOfWeek(weekStart);
    var count = 0;
    for (var index = 0; index < 7; index++) {
      final day = start.addDays(index);
      if (isScheduled(day)) count += countOn(completions, day);
    }
    return count;
  }

  /// Check-ins in the calendar month that contains [anyDayInMonth], counting
  /// only scheduled days.
  int monthProgress(HabitCompletions completions, LocalDate anyDayInMonth) {
    final start = LocalDate(anyDayInMonth.year, anyDayInMonth.month, 1);
    final days = start.daysInMonth;
    var count = 0;
    for (var index = 0; index < days; index++) {
      final day = start.addDays(index);
      if (isScheduled(day)) count += countOn(completions, day);
    }
    return count;
  }

  /// Progress in the habit's own target period.
  int progress(HabitCompletions completions, LocalDate anyDay, {int weekStart = DateTime.monday}) =>
      isMonthly ? monthProgress(completions, anyDay) : weekProgress(completions, anyDay, weekStart);

  /// How many check-ins [start]..[end] should hold for the habit's target.
  ///
  /// Weekly targets scale by days. Monthly targets scale by the fraction of
  /// each touched calendar month inside the range, so a week inside a month is
  /// about a quarter of that month's target.
  double targetForRange(LocalDate start, LocalDate end) {
    if (end.isBefore(start)) return 0;
    if (isWeekly) {
      return cleanTarget * (end.differenceInDays(start) + 1) / 7;
    }
    var months = 0.0;
    var month = LocalDate(start.year, start.month, 1);
    while (!month.isAfter(end)) {
      final monthEnd = LocalDate(month.year, month.month, month.daysInMonth);
      final from = LocalDate.max(start, month);
      final to = LocalDate.min(end, monthEnd);
      final days = to.differenceInDays(from) + 1;
      months += days / month.daysInMonth;
      month = month.addDays(month.daysInMonth);
    }
    return cleanTarget * months;
  }

  /// Consecutive checked days for a weekly daily habit, or qualifying weeks
  /// for a weekly-target habit, or qualifying months for a monthly habit.
  ///
  /// Unscheduled days neither add to nor break a daily streak, so a Mon/Wed/Fri
  /// habit keeps its run across Tuesday. A weekly habit completed Monday to
  /// Wednesday already has one qualifying week, and the rest of that week does
  /// not break it. A monthly habit counts the current month once its target is
  /// met and then walks backwards through qualifying months.
  int streak(HabitCompletions completions, LocalDate today, {int weekStart = DateTime.monday}) {
    if (isMonthly) {
      final month = LocalDate(today.year, today.month, 1);
      var count = monthProgress(completions, month) >= cleanTarget ? 1 : 0;
      var previous = month.addMonths(-1);
      // A bounded walk keeps a corrupt completion map from looping forever.
      for (var guard = 0; guard < 1200; guard++) {
        if (monthProgress(completions, previous) < cleanTarget) break;
        count++;
        previous = previous.addMonths(-1);
      }
      return count;
    }

    if (isDaily) {
      var cursor = isScheduled(today) ? today : _previousScheduled(today);
      if (countOn(completions, cursor) <= 0) {
        cursor = _previousScheduled(cursor.addDays(-1));
      }
      var count = 0;
      // A bounded walk keeps a corrupt schedule from looping forever.
      for (var guard = 0; guard < 400; guard++) {
        if (isScheduled(cursor)) {
          if (countOn(completions, cursor) <= 0) break;
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

  /// Parses a stored period name, defaulting to the original weekly rule.
  static HabitTargetPeriod parseTargetPeriod(String? raw) {
    for (final period in HabitTargetPeriod.values) {
      if (period.name == raw) return period;
    }
    return HabitTargetPeriod.week;
  }
}
