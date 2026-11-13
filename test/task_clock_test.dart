import 'dart:ffi';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/models/time_entry.dart';
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
  final createdAt = DateTime.utc(2026, 11, 9, 7);
  final day = LocalDate.parse('2026-11-09');
  final firstStart = DateTime.utc(2026, 11, 9, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    repository = PlannerRepository(database);
    await database.seedDefaults();
  });

  tearDown(() => database.close());

  Future<EntryOccurrence> seedClockTask({int startMinute = 9 * 60}) async {
    await repository.saveEntry(
      Entry(
        id: 'clock',
        spaceId: 'work',
        title: 'Clock task',
        date: day,
        startMinute: startMinute,
        timeZone: 'Europe/Madrid',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    return (await repository.loadEntries(day, day, 'Europe/Madrid')).single;
  }

  Future<List<TimeEntry>> sessions() => database.readTimeEntriesBetween(
    DateTime.utc(2026, 11, 9),
    DateTime.utc(2026, 11, 12),
    entryId: 'clock',
  );

  test('pausing keeps a clock-in task resumable and records one session', () async {
    final occurrence = await seedClockTask();

    await repository.clockIn(occurrence, at: firstStart);
    final stopped = await repository.clockOut(occurrence, at: firstStart.add(const Duration(minutes: 30)));

    expect(stopped, isNotNull);
    expect(stopped!.endedAt, firstStart.add(const Duration(minutes: 30)));
    final recorded = await sessions();
    expect(recorded, hasLength(1));
    expect(recorded.single.durationAt(firstStart), const Duration(minutes: 30));

    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, isNull);
    expect(saved.timing, EntryTiming.clockIn);
    expect(saved.status, EntryStatus.open);
  });

  test('a paused task resumes the next day and totals both sessions', () async {
    final occurrence = await seedClockTask();

    await repository.clockIn(occurrence, at: firstStart);
    await repository.clockOut(occurrence, at: firstStart.add(const Duration(minutes: 30)));

    final secondStart = firstStart.add(const Duration(hours: 24));
    await repository.clockIn(occurrence, at: secondStart);
    await repository.clockOut(occurrence, at: secondStart.add(const Duration(minutes: 30)));

    final recorded = await sessions();
    expect(recorded, hasLength(2));
    final total = recorded.fold(Duration.zero, (sum, item) => sum + item.durationAt(secondStart));
    expect(total, const Duration(hours: 1));

    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, isNull);
    expect(saved.timing, EntryTiming.clockIn);
  });

  test('finishTracked ends the session and writes the entry end', () async {
    final occurrence = await seedClockTask();

    await repository.clockIn(occurrence, at: firstStart);
    final stopped = await repository.finishTracked(
      occurrence,
      at: firstStart.add(const Duration(minutes: 45)),
    );

    expect(stopped, isNotNull);
    final recorded = await sessions();
    expect(recorded, hasLength(1));
    expect(recorded.single.endedAt, isNotNull);

    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, 9 * 60 + 45);
    expect(saved.timing, EntryTiming.scheduled);
    expect(saved.status, EntryStatus.open);
  });

  test('finishTracked writes an end after midnight past the start', () async {
    final occurrence = await seedClockTask(startMinute: 23 * 60);

    await repository.clockIn(occurrence, at: DateTime.utc(2026, 11, 9, 22));
    await repository.finishTracked(occurrence, at: DateTime.utc(2026, 11, 9, 23, 30));

    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, 24 * 60 + 30);
    expect(saved.timing, EntryTiming.scheduled);
  });

  test('finishTracked without a running session uses the supplied time', () async {
    final occurrence = await seedClockTask();

    final stopped = await repository.finishTracked(
      occurrence,
      at: firstStart.add(const Duration(minutes: 45)),
    );

    expect(stopped, isNull);
    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, 9 * 60 + 45);
    expect(saved.timing, EntryTiming.scheduled);
  });

  test('clocking in twice keeps a single open session', () async {
    final occurrence = await seedClockTask();

    final first = await repository.clockIn(occurrence, at: firstStart);
    final second = await repository.clockIn(occurrence, at: firstStart.add(const Duration(minutes: 10)));

    expect(second.id, first.id);
    final recorded = await sessions();
    expect(recorded, hasLength(1));
    expect(recorded.single.endedAt, isNull);
  });

  test('pausing without a running session leaves the entry untouched', () async {
    final occurrence = await seedClockTask();

    final stopped = await repository.clockOut(occurrence, at: firstStart);

    expect(stopped, isNull);
    final saved = await repository.readEntry('clock');
    expect(saved!.endMinute, isNull);
    expect(saved.timing, EntryTiming.clockIn);
  });
}
