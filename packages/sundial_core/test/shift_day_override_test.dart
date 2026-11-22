import 'package:sundial_core/sundial_core.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(initializeTimeZones);

  final monday = LocalDate.parse('2026-11-09');
  final saturday = monday.addDays(5);
  final sunday = monday.addDays(6);

  /// A weekday job: Monday to Friday, nothing on the weekend.
  ShiftPattern weekdayJob({List<ShiftException> exceptions = const <ShiftException>[]}) => ShiftPattern(
    id: 'pizza',
    spaceId: 'work',
    name: 'Pizza',
    timeZone: 'Europe/Madrid',
    cycleDays: 7,
    anchorDate: monday,
    slots: const [
      ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 22 * 60),
      ShiftSlot(dayIndex: 1, startMinute: 15 * 60, endMinute: 22 * 60),
      ShiftSlot(dayIndex: 2, startMinute: 15 * 60, endMinute: 22 * 60),
      ShiftSlot(dayIndex: 3, startMinute: 15 * 60, endMinute: 22 * 60),
      ShiftSlot(dayIndex: 4, startMinute: 15 * 60, endMinute: 22 * 60),
    ],
    exceptions: exceptions,
  );

  /// A Saturday job: every Saturday works, with one Saturday free per month.
  ShiftPattern saturdayJob({List<ShiftException> exceptions = const <ShiftException>[]}) => ShiftPattern(
    id: 'shop',
    spaceId: 'work',
    name: 'Shop',
    timeZone: 'Europe/Madrid',
    cycleDays: 7,
    anchorDate: monday,
    slots: const [ShiftSlot(dayIndex: 5, startMinute: 9 * 60, endMinute: 17 * 60)],
    exceptions: exceptions,
  );

  group('shiftDayOverrideFor', () {
    test('reports the pattern when there is no exception', () {
      expect(shiftDayOverrideFor(weekdayJob(), saturday), ShiftDayOverride.pattern);
      expect(shiftDayOverrideFor(saturdayJob(), saturday), ShiftDayOverride.pattern);
    });

    test('reads an extra shift as working', () {
      final pattern = weekdayJob(
        exceptions: [
          ShiftException(date: saturday, type: ShiftExceptionType.extra, startMinute: 600, endMinute: 1380),
        ],
      );
      expect(shiftDayOverrideFor(pattern, saturday), ShiftDayOverride.working);
    });

    test('reads an override as working', () {
      final pattern = saturdayJob(
        exceptions: [
          ShiftException(
            date: saturday,
            type: ShiftExceptionType.override,
            startMinute: 600,
            endMinute: 1380,
          ),
        ],
      );
      expect(shiftDayOverrideFor(pattern, saturday), ShiftDayOverride.working);
    });

    test('reads a free day as free', () {
      final pattern = saturdayJob(
        exceptions: [ShiftException(date: saturday, type: ShiftExceptionType.free)],
      );
      expect(shiftDayOverrideFor(pattern, saturday), ShiftDayOverride.free);
    });

    test('free wins over an extra on the same date', () {
      final pattern = weekdayJob(
        exceptions: [
          ShiftException(date: saturday, type: ShiftExceptionType.extra, startMinute: 600, endMinute: 1380),
          ShiftException(date: saturday, type: ShiftExceptionType.free),
        ],
      );
      expect(shiftDayOverrideFor(pattern, saturday), ShiftDayOverride.free);
    });

    test('ignores exceptions on other dates', () {
      final pattern = saturdayJob(
        exceptions: [ShiftException(date: sunday, type: ShiftExceptionType.free)],
      );
      expect(shiftDayOverrideFor(pattern, saturday), ShiftDayOverride.pattern);
    });
  });

  group('suggestedShiftTimes', () {
    test('uses the slots the pattern already has that day', () {
      expect(suggestedShiftTimes(saturdayJob(), saturday), (startMinute: 9 * 60, endMinute: 17 * 60));
    });

    test('falls back to the first slot when the day is empty', () {
      expect(suggestedShiftTimes(weekdayJob(), saturday), (startMinute: 15 * 60, endMinute: 22 * 60));
    });

    test('prefers the recorded shift nearest to the date', () {
      final pattern = weekdayJob(
        exceptions: [
          ShiftException(date: saturday, type: ShiftExceptionType.extra, startMinute: 600, endMinute: 1380),
          ShiftException(
            date: saturday.addDays(21),
            type: ShiftExceptionType.extra,
            startMinute: 660,
            endMinute: 1440,
          ),
        ],
      );
      expect(suggestedShiftTimes(pattern, saturday.addDays(14)), (startMinute: 660, endMinute: 1440));
    });

    test('prefers the earlier shift when two are equally near', () {
      final pattern = weekdayJob(
        exceptions: [
          ShiftException(date: saturday, type: ShiftExceptionType.extra, startMinute: 600, endMinute: 1380),
          ShiftException(
            date: saturday.addDays(14),
            type: ShiftExceptionType.extra,
            startMinute: 660,
            endMinute: 1440,
          ),
        ],
      );
      expect(suggestedShiftTimes(pattern, saturday.addDays(7)), (startMinute: 600, endMinute: 1380));
    });

    test('ignores free days when looking for times', () {
      final pattern = saturdayJob(
        exceptions: [
          ShiftException(date: saturday, type: ShiftExceptionType.free),
          ShiftException(
            date: saturday.addDays(7),
            type: ShiftExceptionType.extra,
            startMinute: 600,
            endMinute: 1380,
          ),
        ],
      );
      expect(suggestedShiftTimes(pattern, saturday), (startMinute: 600, endMinute: 1380));
    });

    test('returns null when the pattern has no times at all', () {
      final pattern = ShiftPattern(
        id: 'empty',
        spaceId: 'work',
        name: 'Empty',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: monday,
      );
      expect(suggestedShiftTimes(pattern, saturday), isNull);
    });
  });
}
