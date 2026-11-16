import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/export/csv_interchange.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/services/planner_repository.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
  });

  late AppDatabase database;
  late PlannerRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
    repository = PlannerRepository(database);
  });

  tearDown(() => database.close());

  test('CSV parser handles quotes, commas and newlines', () {
    final rows = CsvInterchangeService.decodeCsv(
      'name,note\r\n'
      '"Rice, basmati","Line one\nLine two"\r\n'
      '"He said ""hi""",plain\r\n',
    );
    expect(rows, [
      ['name', 'note'],
      ['Rice, basmati', 'Line one\nLine two'],
      ['He said "hi"', 'plain'],
    ]);
  });

  test('entry export and import keeps dates, times and tags', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveTag(const Tag(id: 'job', spaceId: 'work', name: 'Job A', colorValue: 0xFF4A6FA5));
    await database.saveEntry(
      Entry(
        id: 'standup',
        spaceId: 'work',
        title: 'Standup, daily',
        notes: 'Bring notes\nand coffee',
        kind: EntryKind.event,
        date: LocalDate.parse('2026-11-09'),
        startMinute: 9 * 60,
        endMinute: 9 * 60 + 30,
        timeZone: 'Europe/Madrid',
        tagIds: const {'job'},
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly, weekdays: {1}),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final csv = await CsvInterchangeService(repository).exportEntries(
      start: LocalDate.parse('2026-11-09'),
      end: LocalDate.parse('2026-11-15'),
      viewerTimeZone: 'Europe/Madrid',
    );
    expect(csv, contains('"Standup, daily"'));

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await target.seedDefaults();
    await target.saveTag(const Tag(id: 'job', spaceId: 'work', name: 'Job A', colorValue: 0xFF4A6FA5));
    final report = await CsvInterchangeService(
      PlannerRepository(target),
    ).importEntries(csv, defaultTimeZone: 'Europe/Madrid');
    expect(report.imported, 1);

    final entries = await target
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    final entry = entries.single.entry;
    expect(entry.title, 'Standup, daily');
    expect(entry.notes, 'Bring notes\nand coffee');
    expect(entry.spaceId, 'work');
    expect(entry.startMinute, 9 * 60);
    expect(entry.endMinute, 9 * 60 + 30);
    expect(entry.timeZone, 'Europe/Madrid');
    expect(entry.tagIds, {'job'});
    expect(entry.recurrence, isNotNull);
    expect(entry.source, 'csv');
  });

  test('CSV round-trip preserves clock-in, deadline and anytime shapes', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    final day = LocalDate.parse('2026-11-09');
    for (final entry in [
      Entry(
        id: 'clock',
        spaceId: 'work',
        title: 'Clock in',
        date: day,
        startMinute: 9 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
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
      Entry(id: 'anytime', spaceId: 'home', title: 'Anytime', date: day, createdAt: now, updatedAt: now),
    ]) {
      await database.saveEntry(entry);
    }

    final csv = await CsvInterchangeService(
      repository,
    ).exportEntries(start: day, end: day, viewerTimeZone: 'Europe/Madrid');
    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await target.seedDefaults();
    await CsvInterchangeService(
      PlannerRepository(target),
    ).importEntries(csv, defaultTimeZone: 'Europe/Madrid');

    final imported = (await target.watchEntriesBetween(day, day, 'Europe/Madrid').first).map(
      (item) => item.entry,
    );
    expect(imported.firstWhere((entry) => entry.title == 'Clock in').timing, EntryTiming.clockIn);
    expect(imported.firstWhere((entry) => entry.title == 'Deadline').timing, EntryTiming.deadline);
    expect(imported.firstWhere((entry) => entry.title == 'Anytime').timing, EntryTiming.anytime);
  });

  test('re-importing the same entry CSV deduplicates', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveEntry(
      Entry(
        id: 'bins',
        spaceId: 'home',
        title: 'Bins',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final csv = await CsvInterchangeService(repository).exportEntries(
      start: LocalDate.parse('2026-11-09'),
      end: LocalDate.parse('2026-11-09'),
      viewerTimeZone: 'Europe/Madrid',
    );

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await target.seedDefaults();
    final targetService = CsvInterchangeService(PlannerRepository(target));
    final first = await targetService.importEntries(csv, defaultTimeZone: 'Europe/Madrid');
    final second = await targetService.importEntries(csv, defaultTimeZone: 'Europe/Madrid');
    expect(first.imported, 1);
    expect(second.imported, 0);
    expect(second.duplicates, 1);
  });

  test('re-importing an exported CSV into the same plan does not duplicate entries', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveEntry(
      Entry(
        id: 'bins',
        spaceId: 'home',
        title: 'Bins',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.saveEntry(
      Entry(
        id: 'standup',
        spaceId: 'work',
        title: 'Standup',
        date: LocalDate.parse('2026-11-09'),
        startMinute: 9 * 60,
        endMinute: 9 * 60 + 30,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final start = LocalDate.parse('2026-11-09');
    final service = CsvInterchangeService(repository);
    final csv = await service.exportEntries(start: start, end: start, viewerTimeZone: 'Europe/Madrid');
    final before = await database.watchEntriesBetween(start, start, 'Europe/Madrid').first;

    final report = await service.importEntries(csv, defaultTimeZone: 'Europe/Madrid');
    final after = await database.watchEntriesBetween(start, start, 'Europe/Madrid').first;

    expect(report.imported, 0);
    expect(report.duplicates, before.length);
    expect(after.length, before.length);
  });

  test('shopping and inventory CSV round-trip and dedupe', () async {
    await database.saveHomeItem(
      const HomeItem(
        id: 'rice',
        name: 'Rice',
        category: 'Pantry',
        location: 'Kitchen',
        quantity: 2,
        unit: 'kg',
        reorderLevel: 1,
      ),
    );
    await database.saveShoppingItem(
      const ShoppingItem(
        id: 'rice-buy',
        name: 'Rice',
        quantity: 3,
        unit: 'kg',
        note: 'Basmati',
        homeItemId: 'rice',
      ),
    );
    final service = CsvInterchangeService(repository);
    final shoppingCsv = await service.exportShopping();
    final inventoryCsv = await service.exportInventory();
    expect(shoppingCsv, contains('Basmati'));

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await target.seedDefaults();
    final targetService = CsvInterchangeService(PlannerRepository(target));
    final inventoryReport = await targetService.importInventory(inventoryCsv);
    expect(inventoryReport.imported, 1);
    final shoppingReport = await targetService.importShopping(shoppingCsv);
    expect(shoppingReport.imported, 1);

    final shopping = (await target.watchShoppingItems().first).single;
    final home = (await target.watchHomeItems().first).single;
    expect(shopping.name, 'Rice');
    expect(shopping.quantity, 3);
    expect(shopping.homeItemId, home.id);
    expect(home.category, 'Pantry');

    final duplicate = await targetService.importInventory(inventoryCsv);
    expect(duplicate.duplicates, 1);
  });
}
