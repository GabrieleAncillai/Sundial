import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/media/media_store.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/models/remote_snapshot.dart';
import 'package:sundial/models/reminder.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

import 'support/media_fixture.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
  });

  test('migrates real v1 data to the current schema without losing anything', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);

    raw.execute(File('test/fixtures/schema_v1.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['home', 'Home', 0xFF5B7F6B, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['work', 'Work', 0xFF4A6FA5, 1, createdAt, createdAt],
    );

    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, start_minute, end_minute, all_day, status, '
      'recurrence_json, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'standup',
        'work',
        'Standup',
        'task',
        20261109,
        540,
        570,
        0,
        'open',
        '{"frequency":"weekly","interval":1,"weekdays":[1]}',
        createdAt,
        createdAt,
      ],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bins', 'home', 'Bins', 'task', 20261109, 1, 'open', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['implicit', 'home', 'Old date-only row', 'task', 20261110, 0, 'open', createdAt, createdAt],
    );
    raw.execute('INSERT INTO completion_records (entry_id, date_key, created_at) VALUES (?, ?, ?)', [
      'standup',
      20261109,
      createdAt,
    ]);

    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, name, cycle_days, anchor_date_key, slots_json, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'bank',
        'work',
        'Bank',
        7,
        20261109,
        '[{"dayIndex":0,"label":"Open","startMinute":540,"endMinute":780},'
            '{"dayIndex":0,"label":"Close","startMinute":960,"endMinute":1200}]',
        1,
        createdAt,
        createdAt,
      ],
    );
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final spaces = await database.watchSpaces().first;
    expect(spaces.map((space) => space.id), ['personal', 'work', 'home']);
    expect(spaces.first.name, 'Personal');

    final entries = await database
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-15'), 'Europe/Madrid')
        .first;

    final standup = entries.firstWhere((item) => item.entry.id == 'standup');
    expect(standup.entry.timeZone, 'Europe/Madrid');
    expect(standup.entry.startAt, DateTime.utc(2026, 11, 9, 8));
    expect(standup.entry.endAt, DateTime.utc(2026, 11, 9, 8, 30));
    expect(standup.entry.allDay, isFalse);
    expect(standup.completed, isTrue);

    final bins = entries.firstWhere((item) => item.entry.id == 'bins');
    expect(bins.entry.allDay, isTrue);
    expect(bins.entry.timeZone, isNull);
    expect(bins.entry.startAt, isNull);

    final implicit = entries.firstWhere((item) => item.entry.id == 'implicit');
    expect(implicit.entry.allDay, isTrue);

    final shifts = await database
        .watchShiftsBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(shifts, hasLength(2));
    expect(shifts.map((item) => item.slot.label), ['Open', 'Close']);
    expect(shifts.first.startAt, DateTime.utc(2026, 11, 9, 8));
    expect(shifts.first.pattern.timeZone, 'Europe/Madrid');

    final columns = await database.customSelect('PRAGMA table_info(shift_pattern_records)').get();
    expect(columns.map((row) => row.data['name']), isNot(contains('slots_json')));
    expect(columns.map((row) => row.data['name']), contains('time_zone'));

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v2 data and keeps tags usable', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v2');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v2.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['personal', 'Personal', 0xFFB07D5C, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['taxes', 'personal', 'Taxes', 'deadline', 20261115, 1, 'open', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, name, time_zone, cycle_days, anchor_date_key, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bank', 'personal', 'Bank', 'Europe/Madrid', 7, 20261109, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_slot_records (pattern_id, day_index, label, start_minute, end_minute) '
      'VALUES (?, ?, ?, ?, ?)',
      ['bank', 0, 'Open', 540, 900],
    );
    raw.execute('INSERT INTO setting_records (key, value) VALUES (?, ?)', ['themeMode', 'dark']);
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final entries = await database
        .watchEntriesBetween(LocalDate.parse('2026-11-15'), LocalDate.parse('2026-11-15'), 'Europe/Madrid')
        .first;
    expect(entries.single.entry.title, 'Taxes');
    expect(entries.single.entry.tagIds, isEmpty);

    final shifts = await database
        .watchShiftsBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(shifts.single.slot.label, 'Open');

    await database.saveTag(const Tag(id: 'tax', name: 'Tax', colorValue: 0xFFB07D5C, position: 0));
    final entry = entries.single.entry.copyWith(tagIds: {'tax'});
    await database.saveEntry(entry);
    final tagged = await database
        .watchEntriesBetween(LocalDate.parse('2026-11-15'), LocalDate.parse('2026-11-15'), 'Europe/Madrid')
        .first;
    expect(tagged.single.entry.tagIds, {'tax'});
    expect((await database.watchTags().first).single.name, 'Tax');

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v3 data and exposes the v0.3 tables', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v3');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v3.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['home', 'Home', 0xFF5B7F6B, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bins', 'home', 'Bins', 'task', 20261109, 1, 'open', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO tag_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['house', 'House', 0xFF5B7F6B, 0, createdAt, createdAt],
    );
    raw.execute('INSERT INTO entry_tag_records (entry_id, tag_id) VALUES (?, ?)', ['bins', 'house']);
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final entries = await database
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(entries.single.entry.tagIds, {'house'});
    expect(entries.single.entry.source, isNull);
    expect(entries.single.entry.readOnly, isFalse);
    expect(entries.single.entry.repeatAfterCompletionDays, isNull);

    await database.saveHomeItem(const HomeItem(id: 'rice', name: 'Rice', quantity: 1, reorderLevel: 2));
    await database.saveShoppingItem(
      const ShoppingItem(id: 'buy-rice', name: 'Rice', quantity: 3, homeItemId: 'rice'),
    );
    await database.setShoppingChecked('buy-rice', true);
    final home = await database.watchHomeItems().first;
    expect(home.single.quantity, 4);
    expect((await database.watchShoppingItems().first).single.checked, isTrue);

    await database.saveShiftChecklistItems('missing-pattern', const []);
    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v4 data and creates the pairing tables', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v4');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v4.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['personal', 'Personal', 0xFFB07D5C, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['home', 'Home', 0xFF5B7F6B, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['passport', 'personal', 'Renew passport', 'task', 20261109, 1, 'open', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, source, external_id, read_only, '
      'created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'imported',
        'personal',
        'Imported',
        'event',
        20261110,
        1,
        'open',
        'ics',
        'uid:x',
        1,
        createdAt,
        createdAt,
      ],
    );
    raw.execute(
      'INSERT INTO tag_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['admin', 'Admin', 0xFFB07D5C, 0, createdAt, createdAt],
    );
    raw.execute('INSERT INTO entry_tag_records (entry_id, tag_id) VALUES (?, ?)', ['passport', 'admin']);
    raw.execute(
      'INSERT INTO home_item_records '
      '(id, name, quantity, reorder_level, unit, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['coffee', 'Coffee', 100.0, 150.0, 'g', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shopping_item_records '
      '(id, name, quantity, unit, home_item_id, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['buy-coffee', 'Coffee', 250.0, 'g', 'coffee', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, name, time_zone, cycle_days, anchor_date_key, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bar', 'home', 'Bar', 'Europe/Madrid', 7, 20261109, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_slot_records (pattern_id, day_index, label, start_minute, end_minute) '
      'VALUES (?, ?, ?, ?, ?)',
      ['bar', 0, 'Open', 960, 1320],
    );
    raw.execute(
      'INSERT INTO shift_checklist_item_records (id, pattern_id, label, position) VALUES (?, ?, ?, ?)',
      ['count', 'bar', 'Count the drawer', 0],
    );
    raw.execute(
      'INSERT INTO shift_checklist_completion_records (item_id, date_key, created_at) VALUES (?, ?, ?)',
      ['count', 20261109, createdAt],
    );
    raw.execute('INSERT INTO setting_records (key, value) VALUES (?, ?)', ['themeMode', 'dark']);
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final entries = await database
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-10'), 'Europe/Madrid')
        .first;
    final passport = entries.firstWhere((item) => item.entry.id == 'passport');
    expect(passport.entry.tagIds, {'admin'});
    final imported = entries.firstWhere((item) => item.entry.id == 'imported');
    expect(imported.entry.readOnly, isTrue);
    expect(imported.entry.source, 'ics');

    expect((await database.watchHomeItems().first).single.isLowStock, isTrue);
    expect((await database.watchShoppingItems().first).single.homeItemId, 'coffee');
    expect((await database.readShiftChecklistItems('bar')).single.label, 'Count the drawer');
    expect(
      await database.readShiftChecklistCompletions(
        'bar',
        LocalDate.parse('2026-11-09'),
        slotKey: '0:960:1320:Open',
      ),
      {'count'},
    );
    expect(await database.readIdentity(), isNull);
    expect(await database.readPairedDevices(), isEmpty);

    final now = DateTime.utc(2026, 11, 9, 8);
    await database.saveIdentity(
      LocalIdentity(
        deviceId: 'self',
        deviceName: 'Linux',
        username: 'muffin',
        pinSalt: 'c2FsdA==',
        pinHash: 'aGFzaA==',
        certificatePem: 'cert',
        privateKeyPem: 'key',
        mcpToken: 'token',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final identity = await database.readIdentity();
    expect(identity!.deviceId, 'self');
    expect(identity.mcpToken, 'token');

    await database.savePairedDevice(
      PairedDevice(
        id: 'phone',
        name: 'Phone',
        username: 'muffin',
        certificateFingerprint: 'f' * 64,
        sharedKey: 'c2hhcmVk',
        host: '192.168.1.20',
        port: 8766,
        lastSeenAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final paired = (await database.readPairedDevices()).single;
    expect(paired.name, 'Phone');
    expect(paired.host, '192.168.1.20');
    expect(paired.port, 8766);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v5 checklist rows to per-slot keys', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v5');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v5.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['work', 'Work', 0xFF4A6FA5, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO tag_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['pizzeria', 'Pizzeria', 0xFF4A6FA5, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, name, time_zone, cycle_days, anchor_date_key, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bar', 'work', 'Bar', 'Europe/Madrid', 7, 20261109, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_slot_records (pattern_id, day_index, label, start_minute, end_minute) '
      'VALUES (?, ?, ?, ?, ?)',
      ['bar', 0, 'Lunch', 720, 960],
    );
    raw.execute(
      'INSERT INTO shift_slot_records (pattern_id, day_index, label, start_minute, end_minute) '
      'VALUES (?, ?, ?, ?, ?)',
      ['bar', 0, 'Dinner', 1140, 1380],
    );
    raw.execute(
      'INSERT INTO shift_checklist_item_records (id, pattern_id, label, position) VALUES (?, ?, ?, ?)',
      ['count', 'bar', 'Count the drawer', 0],
    );
    raw.execute(
      'INSERT INTO shift_checklist_completion_records (item_id, date_key, created_at) VALUES (?, ?, ?)',
      ['count', 20261109, createdAt],
    );
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final pattern = (await database.watchShiftPatterns().first).single;
    final monday = LocalDate.parse('2026-11-09');
    final slots = pattern.slotsFor(monday);
    expect(slots.map((slot) => slot.label), ['Lunch', 'Dinner']);

    // The legacy tick belongs to the first slot of that date, not both.
    expect(await database.readShiftChecklistCompletions('bar', monday, slotKey: slots.first.key), {'count'});
    expect(await database.readShiftChecklistCompletions('bar', monday, slotKey: slots.last.key), isEmpty);

    await database.saveShiftPattern(
      pattern.copyWith(tagIds: {'pizzeria'}, commuteMinutes: 45, windDownMinutes: 20),
    );
    final saved = (await database.watchShiftPatterns().first).single;
    expect(saved.tagIds, {'pizzeria'});
    expect(saved.commuteMinutes, 45);
    expect(saved.windDownMinutes, 20);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v6 rows to shopping order and purchase history', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v6');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v6.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['home', 'Home', 0xFF5B7F6B, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO home_item_records '
      '(id, name, category, location, quantity, unit, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['rice', 'Rice', 'Pantry', 'Kitchen', 2.0, 'kg', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shopping_item_records '
      '(id, name, quantity, unit, checked, note, home_item_id, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['rice-buy', 'Rice', 3.0, 'kg', 0, '', 'rice', createdAt, createdAt],
    );
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final shopping = (await database.watchShoppingItems().first).single;
    expect(shopping.name, 'Rice');
    expect(shopping.position, 0);

    await database.setShoppingChecked('rice-buy', true);
    var items = await database.watchHomeItems().first;
    expect(items.single.quantity, 5.0);
    expect(await database.readPurchaseHistory('rice'), hasLength(1));

    await database.setShoppingChecked('rice-buy', false);
    items = await database.watchHomeItems().first;
    expect(items.single.quantity, 2.0);
    expect(await database.readPurchaseHistory('rice'), isEmpty);

    await database.adjustHomeQuantity('rice', 1.5, note: 'Shop run');
    items = await database.watchHomeItems().first;
    expect(items.single.quantity, 3.5);
    final history = await database.readPurchaseHistory('rice');
    expect(history.single.quantity, 1.5);
    expect(history.single.note, 'Shop run');

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v7 rows to custom reminder times and remote snapshots', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v7');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v7.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['home', 'Home', 0xFF5B7F6B, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bins', 'home', 'Bins', 'task', 20261109, 1, 'open', createdAt, createdAt],
    );
    raw.execute('INSERT INTO reminder_records (id, entry_id, offset_minutes, enabled) VALUES (?, ?, ?, ?)', [
      'bins:60',
      'bins',
      60,
      1,
    ]);
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final reminders = await database.readRemindersForEntry('bins');
    expect(reminders.single.offsetMinutes, 60);
    expect(reminders.single.timeMinute, isNull);

    await database.saveRemindersForEntry('bins', [
      const Reminder(id: 'bins:at:1080', entryId: 'bins', offsetMinutes: 0, timeMinute: 18 * 60),
    ]);
    final saved = (await database.readRemindersForEntry('bins')).single;
    expect(saved.timeMinute, 18 * 60);

    await database.saveRemoteSnapshot(
      RemoteSnapshot(
        deviceId: 'phone',
        deviceName: 'Phone',
        fetchedAt: DateTime.utc(2026, 11, 9, 12),
        date: LocalDate.parse('2026-11-09'),
        todayEntries: const ['Remote plan'],
        todayShifts: const ['Bar'],
        openShopping: 2,
        payload: const {
          'date': '2026-11-09',
          'today': {
            'entries': [
              {
                'entry': {'title': 'Remote plan'},
              },
            ],
            'shifts': [],
          },
          'openShopping': 2,
        },
      ),
    );
    final snapshots = await database.readRemoteSnapshots();
    expect(snapshots.single.todayEntries, ['Remote plan']);
    expect(snapshots.single.openShopping, 2);
    await database.pruneRemoteSnapshots(const {});
    expect(await database.readRemoteSnapshots(), isEmpty);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates real v8 rows to contexts, projects, habits and tracked tasks', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v8');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v8.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['work', 'Work', 0xFF4A6FA5, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, kind, date_key, all_day, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['shift', 'work', 'Shift note', 'task', 20261109, 1, 'open', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO tag_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['job', 'Job', 0xFF2F7ED8, 0, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, name, time_zone, cycle_days, anchor_date_key, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bar', 'work', 'Bar', 'Europe/Madrid', 7, 20261109, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_checklist_item_records (id, pattern_id, label, position) VALUES (?, ?, ?, ?)',
      ['open', 'bar', 'Open', 0],
    );
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    await database.saveContext(
      const PlannerContext(id: 'cafe', spaceId: 'work', name: 'Cafe', colorValue: 0xFF2F7ED8),
    );
    await database.saveProject(
      const Project(id: 'reno', spaceId: 'work', contextId: 'cafe', name: 'Reno', colorValue: 0xFF2FA98F),
    );
    final entry = await database.readEntry('shift');
    expect(entry!.priority, EntryPriority.none);
    expect(entry.contextId, isNull);
    await database.saveEntry(
      entry.copyWith(
        contextId: 'cafe',
        projectId: 'reno',
        priority: EntryPriority.high,
        updatedAt: DateTime.utc(2026, 11, 9),
      ),
    );
    final saved = await database.readEntry('shift');
    expect(saved!.contextId, 'cafe');
    expect(saved.projectId, 'reno');
    expect(saved.priority, EntryPriority.high);

    final tags = await database.watchTags().first;
    expect(tags.single.icon, 'folder');

    final items = await database.readShiftChecklistItems('bar');
    expect(items.single.dayIndex, isNull);
    await database.saveShiftChecklistItems('bar', [items.single.copyWith(dayIndex: 2)]);
    expect((await database.readShiftChecklistItems('bar')).single.dayIndex, 2);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('repairs a database written by the draft v9 build', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-migration-v9-draft');
    final path = '${directory.path}/sundial.sqlite';
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute(File('test/fixtures/schema_v9_draft.sql').readAsStringSync());
    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['work', 'Work', 0xFF4A6FA5, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO space_unit_records '
      '(id, space_id, name, kind, icon, color, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['pizza', 'work', 'Pida Pizza', 'job', 'store', 0xFF2F7ED8, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO project_records '
      '(id, space_id, space_unit_id, name, color, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['reno', 'work', 'pizza', 'Reno', 0xFF2FA98F, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, space_unit_id, project_id, title, kind, date_key, all_day, status, priority, '
      'estimated_minutes, sort_order, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'shift',
        'work',
        'pizza',
        'reno',
        'Shift note',
        'task',
        20261109,
        1,
        'open',
        2,
        45,
        3,
        createdAt,
        createdAt,
      ],
    );
    raw.execute(
      'INSERT INTO habit_records (id, space_unit_id, name, icon, color, weekdays, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['open-shop', 'pizza', 'Open shop', 'bolt', 0xFF34C759, '1,3,5', createdAt, createdAt],
    );
    raw.execute('INSERT INTO habit_check_records (habit_id, date_key, created_at) VALUES (?, ?, ?)', [
      'open-shop',
      20261109,
      createdAt,
    ]);
    raw.execute(
      'INSERT INTO task_session_records '
      '(id, entry_id, started_at, ended_at, note, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      ['session', 'shift', createdAt, createdAt + 1800, 'Prep', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, space_unit_id, name, time_zone, cycle_days, anchor_date_key, enabled, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['bar', 'work', 'pizza', 'Bar', 'Europe/Madrid', 7, 20261109, 1, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO home_item_records (id, space_unit_id, name, quantity, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['beans', 'pizza', 'Beans', 2, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shopping_item_records (id, space_unit_id, name, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?)',
      ['milk', 'pizza', 'Milk', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO gadget_records (id, space_unit_id, name, interval_days, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['boiler', 'pizza', 'Boiler service', 180, createdAt, createdAt],
    );
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final contexts = await database.watchContexts().first;
    expect(contexts.map((context) => context.id), contains('pizza'));
    expect(contexts.firstWhere((context) => context.id == 'pizza').name, 'Pida Pizza');

    // The repaired tables must accept new rows, not just read old ones.
    await database.saveContext(
      const PlannerContext(id: 'delivery', spaceId: 'work', name: 'Delivery', colorValue: 0xFF2F7ED8),
    );
    expect(
      (await database.watchContexts(spaceId: 'work').first).map((context) => context.id),
      contains('delivery'),
    );
    await database.startTimeEntry(entryId: 'shift', at: DateTime.utc(2026, 11, 1, 2));
    await database.stopTimeEntry('shift', at: DateTime.utc(2026, 11, 1, 2, 15));

    final projects = await database.watchProjects().first;
    expect(projects.single.contextId, 'pizza');

    final entry = await database.readEntry('shift');
    expect(entry!.contextId, 'pizza');
    expect(entry.projectId, 'reno');
    expect(entry.priority, EntryPriority.medium);

    final habit = (await database.watchHabits().first).single;
    expect(habit.spaceId, 'work');
    expect(habit.contextId, 'pizza');
    expect(habit.weekdays, {1, 3, 5}, reason: 'the draft weekday schedule survives the v10 rebuild');
    final completions = await database.watchHabitCompletions().first;
    expect(completions['open-shop']?[LocalDate.parse('2026-11-09')], 1);

    final sessions = await database.readTimeEntriesBetween(
      DateTime.utc(2026, 11, 1),
      DateTime.utc(2026, 11, 2),
    );
    expect(sessions, hasLength(2));
    expect(sessions.first.note, 'Prep');
    expect(sessions.first.endedAt, DateTime.utc(2026, 11, 1, 0, 30));
    expect(sessions.last.endedAt, DateTime.utc(2026, 11, 1, 2, 15));

    final patterns = await database.watchShiftPatterns().first;
    expect(patterns.single.contextId, 'pizza');
    expect((await database.watchHomeItems().first).single.contextId, 'pizza');
    expect((await database.watchShoppingItems().first).single.contextId, 'pizza');

    final entryColumns = await database.customSelect('PRAGMA table_info(entry_records)').get();
    final entryNames = entryColumns.map((row) => row.read<String>('name')).toSet();
    expect(entryNames, containsAll(['context_id', 'completed_at', 'icon']));
    expect(entryNames, isNot(contains('space_unit_id')));

    // The draft gadget table is converted into a Home maintenance entry.
    final gadget = await database.readEntry('gadget-boiler');
    expect(gadget, isNotNull);
    expect(gadget!.spaceId, 'home');
    expect(gadget.contextId, isNull, reason: 'the draft unit belonged to Work');
    expect(gadget.repeatAfterCompletionDays, 180);
    expect(gadget.allDay, isTrue);
    expect(gadget.timing, EntryTiming.anytime);
    expect(gadget.date, LocalDate.parse('2027-04-30'));
    expect(gadget.lastCompletedAt, isNull);
    final remainingGadgets = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'gadget_records'")
        .get();
    expect(remainingGadgets, isEmpty);

    // The converted entry must keep working, not just read back.
    final nextDue = await database.completeMaintenanceEntry('gadget-boiler', LocalDate.parse('2027-05-02'));
    expect(nextDue, LocalDate.parse('2027-10-29'));

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('a v10 database gains habit weekdays and keeps writing', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-v10');
    final path = p.join(directory.path, 'sundial.sqlite');
    addTearDown(() => directory.delete(recursive: true));
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute('''
      CREATE TABLE habit_records (
        id TEXT NOT NULL,
        space_id TEXT NOT NULL,
        context_id TEXT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        color INTEGER NOT NULL,
        icon TEXT NOT NULL DEFAULT 'star',
        target_per_week INTEGER NOT NULL DEFAULT 7,
        position INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL,
        PRIMARY KEY (id)
      )
    ''');
    raw.execute(
      'INSERT INTO habit_records (id, space_id, name, color, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['walk', 'personal', 'Walk', 0xFF00AA00, createdAt, createdAt],
    );
    raw.execute('PRAGMA user_version = 10');
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() => database.close());

    final existing = (await database.watchHabits().first).single;
    expect(existing.weekdays, {1, 2, 3, 4, 5, 6, 7});

    await database.saveHabit(
      Habit(
        id: existing.id,
        spaceId: existing.spaceId,
        name: existing.name,
        colorValue: existing.colorValue,
        targetCount: 3,
        weekdays: const {1, 3, 5},
        createdAt: existing.createdAt,
      ),
    );
    final updated = (await database.watchHabits().first).single;
    expect(updated.weekdays, {1, 3, 5});
    expect(updated.targetCount, 3);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('repairs the draft leftovers a v1.2 build reported as v10', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-broken-v10');
    final path = p.join(directory.path, 'sundial.sqlite');
    addTearDown(() => directory.delete(recursive: true));
    final now = DateTime.utc(2026, 11, 9, 10);

    // Start from a healthy file, then reintroduce the draft-only NOT NULL
    // columns and gadgets exactly as the earlier build left them.
    final first = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    await first.seedDefaults();
    await first.saveContext(
      const PlannerContext(id: 'house', spaceId: 'home', name: 'House', colorValue: 0xFF5B7F6B),
    );
    await first.saveEntry(
      Entry(
        id: 'boiler-task',
        spaceId: 'home',
        title: 'Boiler task',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await first.close();

    final raw = sqlite3.open(path);
    raw.execute("ALTER TABLE context_records ADD COLUMN kind TEXT NOT NULL DEFAULT 'job'");
    raw.execute('ALTER TABLE time_entry_records ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0');
    raw.execute('''
      CREATE TABLE gadget_records (
        id TEXT NOT NULL PRIMARY KEY,
        space_unit_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        icon TEXT NOT NULL DEFAULT '',
        interval_days INTEGER NOT NULL,
        last_serviced_at INTEGER NULL,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute(
      'INSERT INTO gadget_records (id, space_unit_id, name, interval_days, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      [
        'wash',
        'house',
        'Washing machine',
        90,
        now.millisecondsSinceEpoch ~/ 1000,
        now.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    raw.execute('PRAGMA user_version = 10');
    raw.dispose();

    final repaired = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() => repaired.close());

    // The rebuilt tables accept new writes instead of hitting the NOT NULL
    // columns the shipped model never fills.
    await repaired.saveContext(
      const PlannerContext(id: 'flat', spaceId: 'work', name: 'Flat', colorValue: 0xFF2F7ED8),
    );
    await repaired.startTimeEntry(entryId: 'boiler-task', at: DateTime.utc(2026, 11, 9, 11));
    await repaired.stopTimeEntry('boiler-task', at: DateTime.utc(2026, 11, 9, 11, 15));

    // The draft gadget becomes a Home maintenance entry and its table is gone.
    final gadget = await repaired.readEntry('gadget-wash');
    expect(gadget, isNotNull);
    expect(gadget!.spaceId, 'home');
    expect(gadget.contextId, 'house');
    expect(gadget.repeatAfterCompletionDays, 90);
    expect(gadget.title, 'Washing machine');
    final draftTable = await repaired
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'gadget_records'")
        .get();
    expect(draftTable, isEmpty);

    final version = await repaired.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });

  test('migrates v12 inventory text into variants and reference rows', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-v12-home');
    final path = p.join(directory.path, 'sundial.sqlite');
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;

    final raw = sqlite3.open(path);
    raw.execute('CREATE TABLE setting_records (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');
    raw.execute('CREATE TABLE entry_records (id TEXT NOT NULL PRIMARY KEY)');
    raw.execute('''
      CREATE TABLE home_item_records (
        id TEXT NOT NULL PRIMARY KEY,
        context_id TEXT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        location TEXT NOT NULL DEFAULT '',
        quantity REAL NOT NULL DEFAULT 0,
        reorder_level REAL NULL,
        unit TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        last_purchased_at INTEGER NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE shopping_item_records (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 1,
        unit TEXT NOT NULL DEFAULT '',
        checked INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        home_item_id TEXT NULL,
        context_id TEXT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute(
      'INSERT INTO home_item_records '
      '(id, name, category, location, quantity, reorder_level, unit, notes, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['rice', 'Rice', 'Food & pantry', 'Kitchen', 2.0, 1.0, 'kg', '', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shopping_item_records '
      '(id, name, quantity, unit, checked, note, home_item_id, position, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['buy-rice', 'Rice', 3.0, 'kg', 0, '', 'rice', 0, createdAt, createdAt],
    );
    raw.execute('PRAGMA user_version = 12');
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    final item = (await database.watchHomeItems().first).single;
    expect(item.groupId, 'rice');
    expect(item.categoryId, 'home-food');
    expect(item.unitId, 'home-unit-kg');
    expect(item.locationIds, ['home-loc-kitchen']);
    expect(item.minimumStock, 1);
    expect(item.expiresAt, isNull);

    final shopping = (await database.watchShoppingItems().first).single;
    expect(shopping.categoryId, 'home-food');
    expect(shopping.icon, 'restaurant');
    expect((await database.watchHomeCategories().first), isNotEmpty);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });
  test('a v13 database gains sync ids, field versions and tombstones', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-v14-sync');
    final path = p.join(directory.path, 'sundial.sqlite');
    addTearDown(() => directory.delete(recursive: true));
    final createdAt = DateTime.utc(2026, 11, 1).millisecondsSinceEpoch ~/ 1000;
    final deletedAt = createdAt + 100;

    final raw = sqlite3.open(path);
    raw.execute('''
      CREATE TABLE space_records (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE tag_records (
        id TEXT NOT NULL PRIMARY KEY,
        space_id TEXT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL DEFAULT 'folder',
        position INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE entry_records (
        id TEXT NOT NULL PRIMARY KEY,
        space_id TEXT NOT NULL,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        kind TEXT NOT NULL,
        date_key INTEGER NULL,
        end_date_key INTEGER NULL,
        start_minute INTEGER NULL,
        end_minute INTEGER NULL,
        time_zone TEXT NULL,
        context_id TEXT NULL,
        project_id TEXT NULL,
        icon TEXT NOT NULL DEFAULT '',
        priority TEXT NOT NULL DEFAULT 'none',
        start_at INTEGER NULL,
        end_at INTEGER NULL,
        all_day INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        recurrence_json TEXT NULL,
        source TEXT NULL,
        external_id TEXT NULL,
        read_only INTEGER NOT NULL DEFAULT 0,
        last_completed_at INTEGER NULL,
        repeat_after_completion_days INTEGER NULL,
        completed_at INTEGER NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE entry_tag_records (
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (entry_id, tag_id)
      )
    ''');
    raw.execute('''
      CREATE TABLE home_item_records (
        id TEXT NOT NULL PRIMARY KEY,
        context_id TEXT NULL,
        group_id TEXT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        icon TEXT NOT NULL DEFAULT 'inventory',
        color INTEGER NULL,
        catalog_id TEXT NULL,
        category TEXT NOT NULL DEFAULT '',
        category_id TEXT NULL,
        location TEXT NOT NULL DEFAULT '',
        quantity REAL NOT NULL DEFAULT 0,
        min_quantity REAL NULL,
        reorder_level REAL NULL,
        unit TEXT NOT NULL DEFAULT '',
        unit_id TEXT NULL,
        pack_size TEXT NOT NULL DEFAULT '',
        expires_date_key INTEGER NULL,
        notes TEXT NOT NULL DEFAULT '',
        last_purchased_at INTEGER NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE home_item_location_records (
        home_item_id TEXT NOT NULL,
        location_id TEXT NOT NULL,
        PRIMARY KEY (home_item_id, location_id)
      )
    ''');
    raw.execute('''
      CREATE TABLE shift_pattern_records (
        id TEXT NOT NULL PRIMARY KEY,
        space_id TEXT NOT NULL,
        name TEXT NOT NULL,
        context_id TEXT NULL,
        time_zone TEXT NOT NULL DEFAULT 'UTC',
        cycle_days INTEGER NOT NULL,
        anchor_date_key INTEGER NOT NULL,
        commute_minutes INTEGER NULL,
        wind_down_minutes INTEGER NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE shift_slot_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        pattern_id TEXT NOT NULL,
        day_index INTEGER NOT NULL,
        label TEXT NOT NULL DEFAULT '',
        start_minute INTEGER NOT NULL,
        end_minute INTEGER NOT NULL
      )
    ''');
    raw.execute('''
      CREATE TABLE shift_exception_records (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        pattern_id TEXT NOT NULL,
        date_key INTEGER NOT NULL,
        type TEXT NOT NULL,
        start_minute INTEGER NULL,
        end_minute INTEGER NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
    raw.execute('CREATE TABLE setting_records (key TEXT NOT NULL PRIMARY KEY, value TEXT NOT NULL)');

    raw.execute(
      'INSERT INTO space_records (id, name, color, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)',
      ['personal', 'Personal', 0xFFB07D5C, 0, createdAt, createdAt],
    );
    raw.execute('INSERT INTO tag_records (id, name, color, created_at, updated_at) VALUES (?, ?, ?, ?, ?)', [
      'seed-health',
      'Health',
      0xFF34C759,
      createdAt,
      createdAt,
    ]);
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, notes, kind, date_key, icon, priority, all_day, status, read_only, '
      'created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'live',
        'personal',
        'Renew passport',
        'Portal link',
        'task',
        20261109,
        '',
        'none',
        1,
        'open',
        0,
        createdAt,
        createdAt,
      ],
    );
    raw.execute(
      'INSERT INTO entry_records '
      '(id, space_id, title, notes, kind, date_key, icon, priority, all_day, status, read_only, '
      'created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        'gone',
        'personal',
        'Old task',
        '',
        'task',
        20261110,
        '',
        'none',
        1,
        'open',
        0,
        createdAt,
        createdAt,
        deletedAt,
      ],
    );
    raw.execute('INSERT INTO entry_tag_records (entry_id, tag_id) VALUES (?, ?)', ['live', 'seed-health']);
    raw.execute(
      'INSERT INTO home_item_records '
      '(id, group_id, name, category, location, quantity, min_quantity, unit, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['rice', 'rice', 'Rice', 'Food & pantry', 'Kitchen', 2.0, 1.0, 'kg', createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO home_item_records '
      '(id, group_id, name, category, location, quantity, unit, created_at, updated_at, deleted_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      ['old-oat', 'old-oat', 'Oats', 'Food & pantry', 'Kitchen', 0.0, 'kg', createdAt, createdAt, deletedAt],
    );
    raw.execute(
      'INSERT INTO shift_pattern_records '
      '(id, space_id, name, time_zone, cycle_days, anchor_date_key, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      ['rotation', 'personal', 'Rotation', 'Europe/Madrid', 7, 20261109, createdAt, createdAt],
    );
    raw.execute(
      'INSERT INTO shift_slot_records (pattern_id, day_index, label, start_minute, end_minute) '
      'VALUES (?, ?, ?, ?, ?)',
      ['rotation', 0, 'Opening', 540, 780],
    );
    raw.execute(
      'INSERT INTO shift_slot_records (pattern_id, day_index, label, start_minute, end_minute) '
      'VALUES (?, ?, ?, ?, ?)',
      ['rotation', 1, 'Closing', 900, 1320],
    );
    raw.execute(
      'INSERT INTO shift_exception_records (pattern_id, date_key, type, start_minute, end_minute, note) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['rotation', 20261114, 'free', null, null, 'Swap'],
    );
    raw.execute('INSERT INTO setting_records (key, value) VALUES (?, ?)', ['weekStart', '1']);
    raw.execute('INSERT INTO setting_records (key, value) VALUES (?, ?)', ['themeMode', 'dark']);
    raw.execute('PRAGMA user_version = 13');
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(() async {
      await database.close();
    });

    final state = await database.syncDeviceState();
    expect(state.nodeId, isNotEmpty);
    expect(state.datasetId, isNotEmpty);
    expect(state.epoch, isNotEmpty);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);

    final slots = await database.customSelect('SELECT sync_id FROM shift_slot_records').get();
    expect(slots, hasLength(2));
    final slotIds = slots.map((row) => row.read<String>('sync_id')).toList();
    expect(slotIds, everyElement(isNotEmpty));
    expect(slotIds.toSet(), hasLength(2));

    final exceptions = await database.customSelect('SELECT sync_id FROM shift_exception_records').get();
    expect(exceptions.single.read<String>('sync_id'), isNotEmpty);

    final liveVersions = await database
        .customSelect(
          "SELECT field, version FROM sync_field_version_records WHERE entity = 'entry' AND row_key = 'live'",
        )
        .get();
    expect(liveVersions.map((row) => row.read<String>('field')).toSet(), {
      'title',
      'notes',
      'classification',
      'presentation',
      'timing',
      'recurrence',
      'status',
      'maintenance',
      'source',
    });

    final tombstones = await database
        .customSelect("SELECT row_key, version FROM sync_tombstone_records WHERE entity = 'entry'")
        .get();
    expect(tombstones.map((row) => row.read<String>('row_key')), ['gone']);
    final tombstoneVersion = tombstones.single.read<String>('version');
    final goneVersions = await database
        .customSelect(
          "SELECT version FROM sync_field_version_records WHERE entity = 'entry' AND row_key = 'gone'",
        )
        .get();
    for (final row in goneVersions) {
      expect(tombstoneVersion.compareTo(row.read<String>('version')), greaterThan(0));
    }

    final settingVersions = await database
        .customSelect("SELECT row_key FROM sync_field_version_records WHERE entity = 'setting'")
        .get();
    expect(settingVersions.map((row) => row.read<String>('row_key')), ['weekStart']);

    final changes = await database
        .customSelect('SELECT COUNT(*) AS count FROM sync_change_records')
        .getSingle();
    expect(changes.read<int>('count'), 0);

    expect((await database.readEntry('live'))?.title, 'Renew passport');
    expect((await database.readEntry('gone'))?.deletedAt, isNotNull);
    expect((await database.watchHomeItems().first).single.name, 'Rice');
    expect(slots, hasLength(2));
  });

  test('a v14 database backfills content-addressed media and tolerates bad files', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-v15-media');
    final mediaDir = await Directory.systemTemp.createTemp('sundial-v15-media-cache');
    final pictures = await Directory.systemTemp.createTemp('sundial-v15-pictures');
    addTearDown(() async {
      for (final item in [directory, mediaDir, pictures]) {
        if (item.existsSync()) await item.delete(recursive: true);
      }
    });
    final path = p.join(directory.path, 'sundial.sqlite');
    final image = await writePng(pictures, 'house.png', tinyPng);
    final corrupt = File(p.join(pictures.path, 'corrupt.png'))..writeAsBytesSync([1, 2, 3, 4]);

    final created = AppDatabase(
      NativeDatabase(File(path)),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: mediaDir),
    );
    await created.seedDefaults();
    await created.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: image.path,
      ),
    );
    await created.saveProject(
      Project(
        id: 'reno',
        spaceId: 'home',
        name: 'Renovation',
        colorValue: 0xFF2FA98F,
        imagePath: corrupt.path,
      ),
    );
    await created.saveContext(
      PlannerContext(
        id: 'gone',
        spaceId: 'home',
        name: 'Gone',
        colorValue: 0xFF000000,
        imagePath: p.join(pictures.path, 'missing.png'),
      ),
    );
    await created.close();

    // Rewind the file to the v14 shape: no media id columns, no cache index and
    // no cache files. The display files stay, as they did in the old release.
    final raw = sqlite3.open(path);
    raw.execute('ALTER TABLE context_records DROP COLUMN image_media_id');
    raw.execute('ALTER TABLE project_records DROP COLUMN image_media_id');
    raw.execute('DROP TABLE media_cache_records');
    raw.execute("DELETE FROM sync_field_version_records WHERE field = 'image'");
    raw.execute('PRAGMA user_version = 14');
    raw.dispose();
    final cache = Directory(p.join(mediaDir.path, 'cache'));
    if (cache.existsSync()) await cache.delete(recursive: true);

    final database = AppDatabase(
      NativeDatabase(File(path)),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: mediaDir),
    );
    addTearDown(database.close);

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);

    final rows = await database
        .customSelect('SELECT id, image_media_id FROM context_records ORDER BY id')
        .get();
    final ids = {for (final row in rows) row.read<String>('id'): row.readNullable<String>('image_media_id')};
    expect(ids['house'], MediaStore.hashBytes(tinyPng));
    expect(ids['gone'], isNull);
    final project = await database
        .customSelect(
          'SELECT image_media_id FROM project_records WHERE id = ?',
          variables: [Variable.withString('reno')],
        )
        .getSingle();
    // A corrupt legacy file must not fail the upgrade; it simply has no id.
    expect(project.readNullable<String>('image_media_id'), isNull);

    final cached = await database.select(database.mediaCacheRecords).get();
    expect(cached.single.mediaId, MediaStore.hashBytes(tinyPng));
    expect(File(cached.single.path).readAsBytesSync(), tinyPng);

    final mediaVersions = await database
        .customSelect(
          "SELECT version FROM sync_field_version_records WHERE entity = 'context' AND row_key = 'house' AND field = 'image'",
        )
        .get();
    expect(mediaVersions, hasLength(1));

    expect((await database.watchContexts().first).map((item) => item.id), containsAll(['house', 'gone']));
  });

  test('a v15 database gains monthly habit targets and check-in counts', () async {
    final directory = await Directory.systemTemp.createTemp('sundial-v15-habits');
    final path = p.join(directory.path, 'sundial.sqlite');
    addTearDown(() => directory.delete(recursive: true));

    final created = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    await created.seedDefaults();
    await created.saveHabit(
      const Habit(
        id: 'walk',
        spaceId: 'personal',
        name: 'Walk',
        colorValue: 0xFF00AA00,
        targetCount: 3,
        weekdays: {1, 3, 5},
      ),
    );
    await created.setHabitCompleted('walk', LocalDate.parse('2026-11-09'), completed: true);
    await created.close();

    // Rewind the two habit tables to their v15 shape. Everything else is
    // already v15-compatible, so only the new fields and the new sync field
    // version have to disappear.
    final raw = sqlite3.open(path);
    raw.execute('ALTER TABLE habit_records DROP COLUMN target_period');
    raw.execute('ALTER TABLE habit_completion_records DROP COLUMN check_in_count');
    raw.execute(
      "DELETE FROM sync_field_version_records WHERE entity = 'habitCompletion' AND field = 'count'",
    );
    raw.execute('PRAGMA user_version = 15');
    raw.dispose();

    final database = AppDatabase(NativeDatabase(File(path)), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);

    final habit = (await database.watchHabits().first).single;
    expect(habit.targetPeriod, HabitTargetPeriod.week);
    expect(habit.targetCount, 3);
    expect((await database.watchHabitCompletions().first)['walk']?[LocalDate.parse('2026-11-09')], 1);

    await database.saveHabit(
      Habit(
        id: habit.id,
        spaceId: habit.spaceId,
        name: habit.name,
        colorValue: habit.colorValue,
        targetCount: 7,
        targetPeriod: HabitTargetPeriod.month,
        weekdays: habit.weekdays,
        createdAt: habit.createdAt,
      ),
    );
    final updated = (await database.watchHabits().first).single;
    expect(updated.targetPeriod, HabitTargetPeriod.month);
    expect(updated.targetCount, 7);

    final fields = await database
        .customSelect(
          "SELECT field FROM sync_field_version_records WHERE entity = 'habitCompletion' ORDER BY field",
        )
        .get();
    expect(fields.map((row) => row.read<String>('field')), containsAll(['present', 'count']));

    final version = await database.customSelect('PRAGMA user_version').getSingle();
    expect(version.data.values.single, 16);
  });
}
