import 'package:sundial_core/sundial_core.dart';
import 'package:test/test.dart';

void main() {
  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 12);
  const zone = 'Europe/Madrid';

  Entry build({int? start, int? end, bool allDay = false}) => Entry(
    id: 'one',
    spaceId: 'work',
    title: 'Task',
    date: allDay ? null : day,
    allDay: allDay,
    startMinute: allDay ? null : start,
    endMinute: allDay ? null : end,
    timeZone: allDay || (start == null && end == null) ? null : zone,
    createdAt: now,
    updatedAt: now,
  );

  test('a start and end make a scheduled entry', () {
    final entry = build(start: 9 * 60, end: 10 * 60);
    expect(entry.timing, EntryTiming.scheduled);
    expect(entry.startAt, isNotNull);
    expect(entry.endAt, isNotNull);
  });

  test('a start without an end is a clock-in task', () {
    final entry = build(start: 9 * 60);
    expect(entry.timing, EntryTiming.clockIn);
    expect(entry.isClockInTask, isTrue);
    expect(entry.startAt, isNotNull);
    expect(entry.endAt, isNull);
  });

  test('an end without a start is a deadline', () {
    final entry = build(end: 18 * 60);
    expect(entry.timing, EntryTiming.deadline);
    expect(entry.isDeadline, isTrue);
    expect(entry.startAt, isNull);
    expect(entry.endAt, isNotNull);
  });

  test('no start or end is an anytime task', () {
    final entry = build();
    expect(entry.timing, EntryTiming.anytime);
    expect(entry.isAnytime, isTrue);
    expect(entry.startAt, isNull);
    expect(entry.endAt, isNull);
  });

  test('deadline urgency raises the effective priority', () {
    final dueSoon = build(end: 13 * 60);
    expect(deadlineUrgency(dueSoon, now), DeadlineUrgency.high);
    expect(effectivePriority(dueSoon, now), EntryPriority.high);

    final tomorrow = Entry(
      id: 'later',
      spaceId: 'work',
      title: 'Later',
      date: day.addDays(1),
      endMinute: 12 * 60,
      timeZone: zone,
      createdAt: now,
      updatedAt: now,
    );
    expect(deadlineUrgency(tomorrow, now), DeadlineUrgency.medium);
    expect(effectivePriority(tomorrow.copyWith(priority: EntryPriority.low), now), EntryPriority.medium);
  });

  test('expansion keeps clock-in, deadline and anytime tasks on their day', () {
    final entries = [build(start: 9 * 60), build(end: 17 * 60), build()];
    final occurrences = expandEntries(entries: entries, start: day, end: day, viewerTimeZone: zone);
    expect(occurrences, hasLength(3));
    expect(occurrences.where((item) => item.entry.isClockInTask), hasLength(1));
    expect(occurrences.where((item) => item.entry.isDeadline), hasLength(1));
    expect(occurrences.where((item) => item.entry.isAnytime), hasLength(1));
  });

  test('habit progress and streaks use the configured week start', () {
    final habit = Habit(
      id: 'walk',
      spaceId: 'personal',
      name: 'Walk',
      colorValue: 0xFF00AA00,
      targetPerWeek: 3,
    );
    final completions = {day, day.addDays(1), day.addDays(2)};
    final today = day.addDays(2);
    expect(habit.weekProgress(completions, today, DateTime.monday), 3);
    expect(habit.streak(completions, today, weekStart: DateTime.monday), 1);

    // Sunday of the same week: the weekly target still qualifies as one week.
    final sunday = day.addDays(6);
    expect(habit.streak(completions, sunday, weekStart: DateTime.monday), 1);

    // A second qualifying week makes a two-week streak.
    final secondWeek = {...completions, day.addDays(7), day.addDays(8), day.addDays(9)};
    expect(habit.streak(secondWeek, day.addDays(13), weekStart: DateTime.monday), 2);
  });

  test('habit weekday schedules scope progress and skip off days', () {
    // Monday, Wednesday and Friday only.
    final habit = Habit(
      id: 'gym',
      spaceId: 'personal',
      name: 'Gym',
      colorValue: 0xFF00AA00,
      targetPerWeek: 3,
      weekdays: const {1, 3, 5},
    );
    expect(habit.cleanTarget, 3);
    expect(habit.scheduledPerWeek, 3);
    expect(habit.isDaily, isTrue);

    final monday = LocalDate.parse('2026-11-09');
    final wednesday = monday.addDays(2);
    final friday = monday.addDays(4);
    final tuesday = monday.addDays(1);

    // A Tuesday check-in does not count towards a Mon/Wed/Fri habit.
    expect(habit.weekProgress({tuesday}, monday, DateTime.monday), 0);
    expect(habit.weekProgress({monday, wednesday, friday}, friday, DateTime.monday), 3);

    // Tuesday is skipped by the day streak instead of breaking it.
    expect(habit.streak({monday, wednesday}, wednesday, weekStart: DateTime.monday), 2);
    expect(habit.streak({monday, wednesday}, tuesday, weekStart: DateTime.monday), 1);

    // A lighter target keeps a weekly streak.
    final twice = Habit(
      id: 'run',
      spaceId: 'personal',
      name: 'Run',
      colorValue: 0xFF00AA00,
      targetPerWeek: 2,
      weekdays: const {1, 3, 5},
    );
    expect(twice.isDaily, isFalse);
    expect(twice.streak({monday, wednesday}, friday, weekStart: DateTime.monday), 1);
  });

  test('habit weekdays round-trip through storage', () {
    expect(Habit.parseWeekdays('5,1,3'), {1, 3, 5});
    expect(Habit.parseWeekdays(''), {1, 2, 3, 4, 5, 6, 7});
    expect(Habit.parseWeekdays('0,8,2'), {2});
    const habit = Habit(id: 'x', spaceId: 'personal', name: 'X', colorValue: 0, weekdays: {3, 1, 5});
    expect(habit.weekdaysKey, '1,3,5');
  });

  test('maintenance due dates follow the service anchor', () {
    final today = LocalDate.parse('2026-11-09');
    final due = LocalDate.parse('2026-12-09');

    // Serviced dates win over the old due date.
    expect(
      nextMaintenanceDue(
        lastServiced: LocalDate.parse('2026-11-01'),
        currentDue: due,
        currentInterval: 30,
        interval: 90,
        today: today,
      ),
      LocalDate.parse('2027-01-30'),
    );

    // Never serviced: changing the interval keeps the anchor, not a second
    // interval on top of the existing due date.
    expect(
      nextMaintenanceDue(currentDue: due, currentInterval: 30, interval: 60, today: today),
      LocalDate.parse('2027-01-08'),
    );

    // A new gadget counts from today.
    expect(nextMaintenanceDue(interval: 30, today: today), LocalDate.parse('2026-12-09'));

    // A broken interval falls back to one day.
    expect(nextMaintenanceDue(interval: 0, today: today), today.addDays(1));
  });
}
