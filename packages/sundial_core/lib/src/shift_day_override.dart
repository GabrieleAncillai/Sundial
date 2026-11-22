import 'local_date.dart';
import 'shift_pattern.dart';

/// What one pattern does on one date, from the user's point of view.
///
/// This is the three-way choice the calendar offers for a single day:
/// follow the pattern, work, or take the day free.
enum ShiftDayOverride {
  /// No exception: the pattern's own slots decide.
  pattern,

  /// The date carries at least one shift.
  working,

  /// The date is explicitly free.
  free,
}

/// The override in force for [date], or [ShiftDayOverride.pattern] when the
/// pattern has no exception on it.
///
/// `free` wins over everything, then `override`, then `extra`, matching the
/// precedence in [ShiftPattern.slotsFor].
ShiftDayOverride shiftDayOverrideFor(ShiftPattern pattern, LocalDate date) {
  var hasExtra = false;
  for (final exception in pattern.exceptions) {
    if (exception.date != date) continue;
    switch (exception.type) {
      case ShiftExceptionType.free:
        return ShiftDayOverride.free;
      case ShiftExceptionType.override:
        return ShiftDayOverride.working;
      case ShiftExceptionType.extra:
        hasExtra = true;
    }
  }
  return hasExtra ? ShiftDayOverride.working : ShiftDayOverride.pattern;
}

/// Times to offer when the user adds a shift to [date].
///
/// Prefers the slots the pattern already has that day, then the shift the user
/// recorded nearest to that date, then the pattern's first slot. The nearest
/// exception is what makes a floating weekend keep its hours: the pattern has
/// no weekend slot, but last week's shift does.
///
/// Returns null when the pattern has never carried a shift with times.
({int startMinute, int endMinute})? suggestedShiftTimes(ShiftPattern pattern, LocalDate date) {
  final slots = pattern.slotsFor(date);
  if (slots.isNotEmpty) {
    return (startMinute: slots.first.startMinute, endMinute: slots.first.endMinute);
  }

  ShiftException? nearest;
  var nearestDistance = 0;
  for (final exception in pattern.exceptions) {
    if (!exception.hasTimes) continue;
    final distance = exception.date.differenceInDays(date).abs();
    final closer = nearest == null || distance < nearestDistance;
    final sameDistanceEarlier =
        nearest != null && distance == nearestDistance && exception.date.isBefore(nearest.date);
    if (!closer && !sameDistanceEarlier) continue;
    nearest = exception;
    nearestDistance = distance;
  }
  if (nearest != null) {
    return (startMinute: nearest.startMinute!, endMinute: nearest.endMinute!);
  }

  if (pattern.slots.isEmpty) return null;
  final first = pattern.slots.reduce((a, b) => a.dayIndex <= b.dayIndex ? a : b);
  return (startMinute: first.startMinute, endMinute: first.endMinute);
}
