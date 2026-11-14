import 'dart:ffi';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/models/home_item.dart';
import 'package:mane/models/shift_checklist.dart';
import 'package:mane/models/shopping_item.dart';
import 'package:mane/services/app_database.dart';
import 'package:mane/services/planner_repository.dart';
import 'package:mane_core/mane_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase database;
  late PlannerRepository repository;
  final now = DateTime.utc(2026, 11, 9, 8);
  final day = LocalDate.parse('2026-11-09');

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    repository = PlannerRepository(database);
    await database.seedDefaults();
  });

  tearDown(() => database.close());

  test('stores contexts, projects and habits with their new fields', () async {
    await database.saveContext(
      const PlannerContext(
        id: 'cafe',
        spaceId: 'work',
        name: 'Cafe',
        colorValue: 0xFF2F7ED8,
        icon: 'local_cafe',
        imagePath: '/tmp/cafe.png',
      ),
    );
    await database.saveProject(
      const Project(
        id: 'reno',
        spaceId: 'work',
        contextId: 'cafe',
        name: 'Renovation',
        colorValue: 0xFF2FA98F,
        icon: 'build',
      ),
    );
    await database.saveHabit(
      const Habit(id: 'walk', spaceId: 'personal', name: 'Walk', colorValue: 0xFF00AA00, targetPerWeek: 3),
    );
    await database.setHabitCompleted('walk', day, completed: true);

    expect((await database.watchContexts(spaceId: 'work').first).single.imagePath, '/tmp/cafe.png');
    expect((await database.watchProjects(contextId: 'cafe').first).single.name, 'Renovation');
    expect((await database.watchHabits(spaceId: 'personal').first).single.targetPerWeek, 3);
    expect((await database.watchHabitCompletions().first)['walk'], {day});
  });

  test('expands clock-in, deadline and anytime tasks with priority', () async {
    await database.saveEntry(
      Entry(
        id: 'clock',
        spaceId: 'work',
        title: 'Clock task',
        date: day,
        startMinute: 9 * 60,
        timeZone: 'Europe/Madrid',
        priority: EntryPriority.medium,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.saveEntry(
      Entry(
        id: 'deadline',
        spaceId: 'personal',
        title: 'Deadline',
        date: day,
        endMinute: 17 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.saveEntry(
      Entry(id: 'anytime', spaceId: 'home', title: 'Anytime', date: day, createdAt: now, updatedAt: now),
    );

    final occurrences = await database.watchEntriesBetween(day, day, 'Europe/Madrid').first;
    final clock = occurrences.firstWhere((item) => item.entry.id == 'clock');
    final deadline = occurrences.firstWhere((item) => item.entry.id == 'deadline');
    final anytime = occurrences.firstWhere((item) => item.entry.id == 'anytime');

    expect(clock.startAt, isNotNull);
    expect(clock.endAt, isNull);
    expect(clock.entry.priority, EntryPriority.medium);
    expect(deadline.startAt, isNull);
    expect(deadline.endAt, isNotNull);
    expect(anytime.startAt, isNull);
    expect(anytime.endAt, isNull);
  });

  test('clocking out stores a session and keeps a start-only task resumable', () async {
    await database.saveEntry(
      Entry(
        id: 'clock',
        spaceId: 'work',
        title: 'Clock task',
        date: day,
        startMinute: 9 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final occurrence = (await database.watchEntriesBetween(day, day, 'Europe/Madrid').first).single;
    await repository.clockIn(occurrence, at: DateTime.utc(2026, 11, 9, 8));
    await repository.clockOut(occurrence, at: DateTime.utc(2026, 11, 9, 9, 30));

    final sessions = await repository.readTimeEntriesBetween(
      DateTime.utc(2026, 11, 9),
      DateTime.utc(2026, 11, 10),
    );
    expect(sessions, hasLength(1));
    expect(sessions.single.durationAt(now), const Duration(minutes: 90));

    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, isNull);
    expect(saved.timing, EntryTiming.clockIn);
  });

  test('shifts are rejected outside the Work space', () async {
    expect(
      () => database.saveShiftPattern(
        ShiftPattern(
          id: 'home-shift',
          spaceId: 'home',
          name: 'Home shift',
          timeZone: 'Europe/Madrid',
          cycleDays: 7,
          anchorDate: day,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('shift checklists keep the cycle-day scope', () async {
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'bar',
        spaceId: 'work',
        name: 'Bar',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: day,
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 540, endMinute: 780)],
      ),
    );
    await repository.saveShiftChecklistItems('bar', const [
      ShiftChecklistItem(id: 'open', patternId: 'bar', label: 'Open', dayIndex: 0),
      ShiftChecklistItem(id: 'close', patternId: 'bar', label: 'Close', dayIndex: 1),
      ShiftChecklistItem(id: 'all', patternId: 'bar', label: 'Always'),
    ]);

    final items = await repository.readShiftChecklistItems('bar');
    expect(items.map((item) => item.dayIndex), containsAll([0, 1, null]));
  });

  test('imported entries reject user edits, completion and deletion', () async {
    final imported = Entry(
      id: 'imported',
      spaceId: 'personal',
      title: 'Imported',
      date: day,
      allDay: true,
      source: 'ics',
      externalId: 'uid:imported',
      readOnly: true,
      createdAt: now,
      updatedAt: now,
    );
    await repository.saveImportedEntry(imported);

    await expectLater(repository.saveEntry(imported.copyWith(title: 'Changed')), throwsStateError);
    await expectLater(repository.setEntryStatus('imported', EntryStatus.done), throwsStateError);
    await expectLater(repository.setOccurrenceCompleted('imported', day, true), throwsStateError);
    await expectLater(repository.deleteEntry('imported'), throwsStateError);

    await repository.saveImportedEntry(imported.copyWith(title: 'Re-imported'));
    expect((await repository.readEntry('imported'))!.title, 'Re-imported');
  });

  test('completion stops a running session and scopes recurring occurrences', () async {
    await repository.saveEntry(
      Entry(
        id: 'recurring',
        spaceId: 'work',
        title: 'Recurring',
        date: day,
        startMinute: 9 * 60,
        timeZone: 'Europe/Madrid',
        recurrence: RecurrenceRule(frequency: RecurrenceFrequency.daily),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final occurrence = (await repository.loadEntries(day, day, 'Europe/Madrid')).single;
    await repository.clockIn(occurrence, at: DateTime.utc(2026, 11, 9, 8));

    await repository.setCompletion(occurrence, completed: true);

    final sessions = await repository.readTimeEntriesBetween(
      DateTime.utc(2026, 11, 9),
      DateTime.utc(2026, 11, 10),
    );
    expect(sessions.single.endedAt, isNotNull);
    final nextDay = day.addDays(1);
    final next = (await repository.loadEntries(nextDay, nextDay, 'Europe/Madrid')).single;
    expect(next.completed, isFalse);
    expect((await repository.loadEntries(day, day, 'Europe/Madrid')).single.completed, isTrue);
  });

  test('tracked sessions resolve entries outside the visible range', () async {
    await repository.saveEntry(
      Entry(
        id: 'overdue',
        spaceId: 'home',
        title: 'Overdue chore',
        date: day,
        startMinute: 9 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final occurrence = (await repository.loadEntries(day, day, 'Europe/Madrid')).single;
    await repository.clockIn(occurrence, at: DateTime.utc(2026, 11, 10, 8));
    await repository.clockOut(occurrence, at: DateTime.utc(2026, 11, 10, 8, 45));

    final rangeStart = DateTime.utc(2026, 11, 10);
    final sessions = await repository.readTimeEntriesBetween(
      rangeStart,
      rangeStart.add(const Duration(days: 1)),
    );
    final resolved = await repository.readEntriesByIds({for (final session in sessions) session.entryId});

    expect(sessions, hasLength(1));
    expect(resolved['overdue']?.spaceId, 'home');
    expect(
      sessions.fold(Duration.zero, (sum, item) => sum + item.durationAt(now)),
      const Duration(minutes: 45),
    );
  });

  test('clearing bought shopping lines is scoped to one home', () async {
    await database.saveContext(
      const PlannerContext(id: 'flat', spaceId: 'home', name: 'Flat', colorValue: 0xFF5B7F6B),
    );
    await database.saveContext(
      const PlannerContext(id: 'house', spaceId: 'home', name: 'House', colorValue: 0xFF5B7F6B),
    );
    await database.saveShoppingItem(
      const ShoppingItem(id: 'flat-milk', name: 'Milk', contextId: 'flat', checked: true),
    );
    await database.saveShoppingItem(
      const ShoppingItem(id: 'house-milk', name: 'Milk', contextId: 'house', checked: true),
    );

    await database.clearCheckedShopping(contextId: 'flat');

    final remaining = await database.watchShoppingItems().first;
    expect(remaining.map((item) => item.id), ['house-milk']);
  });

  test('deleting a project detaches its tasks', () async {
    await database.saveContext(
      const PlannerContext(id: 'cafe', spaceId: 'work', name: 'Cafe', colorValue: 0xFF2F7ED8),
    );
    await database.saveProject(
      const Project(
        id: 'reno',
        spaceId: 'work',
        contextId: 'cafe',
        name: 'Renovation',
        colorValue: 0xFF2FA98F,
      ),
    );
    await database.saveEntry(
      Entry(
        id: 'till',
        spaceId: 'work',
        title: 'Fix till',
        date: day,
        allDay: true,
        contextId: 'cafe',
        projectId: 'reno',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await database.softDeleteProject('reno');

    final entry = await database.readEntry('till');
    expect(entry!.contextId, 'cafe');
    expect(entry.projectId, isNull);
  });

  test('deleting a context detaches tasks and hides owned rows', () async {
    await database.saveContext(
      const PlannerContext(id: 'cafe', spaceId: 'work', name: 'Cafe', colorValue: 0xFF2F7ED8),
    );
    await database.saveProject(
      const Project(
        id: 'reno',
        spaceId: 'work',
        contextId: 'cafe',
        name: 'Renovation',
        colorValue: 0xFF2FA98F,
      ),
    );
    await database.saveEntry(
      Entry(
        id: 'till',
        spaceId: 'work',
        title: 'Fix till',
        date: day,
        allDay: true,
        contextId: 'cafe',
        projectId: 'reno',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'bar',
        spaceId: 'work',
        contextId: 'cafe',
        name: 'Bar',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: day,
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 540, endMinute: 780)],
      ),
    );
    await database.saveHabit(
      const Habit(id: 'open', spaceId: 'personal', contextId: 'cafe', name: 'Open', colorValue: 0xFF00AA00),
    );
    await database.saveHomeItem(const HomeItem(id: 'beans', contextId: 'cafe', name: 'Beans', quantity: 2));

    await database.softDeleteContext('cafe');

    final entry = await database.readEntry('till');
    expect(entry!.contextId, isNull);
    expect(entry.projectId, isNull);
    expect(await database.watchProjects(contextId: 'cafe').first, isEmpty);
    expect(await database.watchShiftPatterns().first, isEmpty);
    expect(await database.watchHabits(spaceId: 'personal').first, isEmpty);
    expect((await database.watchHomeItems().first).single.contextId, isNull);
  });

  test('clearAllData removes user rows but reseeds the defaults', () async {
    await database.saveContext(
      const PlannerContext(id: 'cafe', spaceId: 'work', name: 'Cafe', colorValue: 0xFF2F7ED8),
    );
    await database.saveEntry(
      Entry(
        id: 'task',
        spaceId: 'home',
        title: 'Task',
        date: day,
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.clearAllData();

    expect(await repository.readEntry('task'), isNull);
    expect(await database.watchContexts().first, isEmpty);
    expect((await database.watchSpaces().first).map((space) => space.id), ['personal', 'work', 'home']);
    expect(await database.watchTags().first, isNotEmpty);
  });
}
