import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/backup/backup_service.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/home_reference.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/models/reminder.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    // The round-trip test deliberately keeps a source and target database.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase source;

  setUp(() async {
    source = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await source.seedDefaults();
  });

  tearDown(() => source.close());

  Future<void> seedRealData(AppDatabase database) async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveTag(const Tag(id: 'job-a', spaceId: 'work', name: 'Job A', colorValue: 0xFF4A6FA5));
    await database.saveTag(const Tag(id: 'old-tag', name: 'Old', colorValue: 0xFF8A5A5A));
    await database.saveContext(
      const PlannerContext(
        id: 'cafe',
        spaceId: 'work',
        name: 'Cafe',
        colorValue: 0xFF2F7ED8,
        icon: 'local_cafe',
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
      const Habit(
        id: 'walk',
        spaceId: 'personal',
        name: 'Walk',
        colorValue: 0xFF00AA00,
        targetPerWeek: 3,
        weekdays: {1, 3, 5},
      ),
    );
    await database.setHabitCompleted('walk', LocalDate.parse('2026-11-09'), completed: true);
    await database.saveEntry(
      Entry(
        id: 'bins',
        spaceId: 'home',
        title: 'Bins',
        notes: 'Tuesday night',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        tagIds: const {'old-tag'},
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly, weekdays: {1}),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.saveEntry(
      Entry(
        id: 'shift',
        spaceId: 'work',
        title: 'Late shift',
        date: LocalDate.parse('2026-11-09'),
        startMinute: 23 * 60,
        endMinute: 24 * 60,
        timeZone: 'America/New_York',
        contextId: 'cafe',
        projectId: 'reno',
        icon: 'water_damage',
        priority: EntryPriority.medium,
        tagIds: const {'job-a'},
        status: EntryStatus.done,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.startTimeEntry(entryId: 'shift', at: now);
    await database.stopTimeEntry('shift', at: now.add(const Duration(minutes: 45)));
    await database.saveEntry(
      Entry(
        id: 'old-entry',
        spaceId: 'personal',
        title: 'Old note',
        date: LocalDate.parse('2026-11-08'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.softDeleteEntry('old-entry');
    await database.softDeleteTag('old-tag');
    await database.setOccurrenceCompleted('bins', LocalDate.parse('2026-11-09'), completed: true);
    await database.saveRemindersForEntry('shift', const [
      Reminder(id: 'shift:15', entryId: 'shift', offsetMinutes: 15),
      Reminder(id: 'shift:60', entryId: 'shift', offsetMinutes: 60),
      Reminder(id: 'shift:at:1200', entryId: 'shift', offsetMinutes: 0, timeMinute: 20 * 60),
    ]);
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'rotation',
        spaceId: 'work',
        name: 'Rotation',
        timeZone: 'Europe/Madrid',
        cycleDays: 14,
        anchorDate: LocalDate.parse('2026-11-09'),
        slots: const [
          ShiftSlot(dayIndex: 0, label: 'Open', startMinute: 540, endMinute: 900),
          ShiftSlot(dayIndex: 5, label: 'Long', startMinute: 600, endMinute: 1380),
        ],
        exceptions: [
          ShiftException(
            date: LocalDate.parse('2026-11-14'),
            type: ShiftExceptionType.override,
            startMinute: 480,
            endMinute: 720,
            note: 'Training',
          ),
        ],
      ),
    );
    await database.writeSetting('themeMode', 'dark');
    await database.writeSetting('locale', 'es');
    await database.writeSetting('weekStart', '7');
    await database.saveHomeItem(
      const HomeItem(
        id: 'rice',
        groupId: 'rice',
        name: 'Rice',
        description: 'Long-grain rice',
        icon: 'rice',
        colorValue: 0xFFB07D5C,
        catalogId: 'catalog-long-grain-rice',
        category: 'Food & pantry',
        categoryId: 'home-food',
        location: 'Kitchen',
        locationIds: ['home-loc-kitchen'],
        quantity: 2,
        unit: 'kg',
        unitId: 'home-unit-kg',
        packSize: '1 kg bag',
        minQuantity: 1,
        expiresAt: LocalDate(2027, 1, 1),
        reorderLevel: 1,
      ),
    );
    await database.saveShoppingItem(
      const ShoppingItem(
        id: 'rice-buy',
        name: 'Rice',
        quantity: 3,
        unit: 'kg',
        homeItemId: 'rice',
        position: 2,
      ),
    );
    await database.adjustHomeQuantity('rice', 2, note: 'Weekend shop');
    await database.saveEntry(
      Entry(
        id: 'boiler',
        spaceId: 'home',
        title: 'Boiler service',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        repeatAfterCompletionDays: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.completeMaintenanceEntry(
      'boiler',
      LocalDate.parse('2026-11-10'),
      note: 'Replaced the filter',
      durationMinutes: 60,
    );
  }

  test('backups exclude the pairing identity, certificates and shared keys', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await source.saveIdentity(
      LocalIdentity(
        deviceId: 'self',
        deviceName: 'Linux',
        username: 'muffin',
        pinSalt: 'c2FsdA==',
        pinHash: 'cGluaGFzaA==',
        certificatePem: '-----BEGIN CERTIFICATE-----\nsecret\n-----END CERTIFICATE-----',
        privateKeyPem: '-----BEGIN PRIVATE KEY-----\nsecret\n-----END PRIVATE KEY-----',
        mcpToken: 'mcp-secret',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.savePairedDevice(
      PairedDevice(
        id: 'phone',
        name: 'Phone',
        username: 'muffin',
        certificateFingerprint: 'a' * 64,
        sharedKey: 'c2hhcmVkLXNlY3JldA==',
        host: '192.168.1.20',
        port: 8766,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final exported = await BackupService(source).exportJson();
    final payload = jsonDecode(exported) as Map<String, dynamic>;
    expect(payload['schemaVersion'], 13);
    expect(payload.containsKey('identity'), isFalse);
    expect(payload.containsKey('pairedDevices'), isFalse);
    expect(exported, isNot(contains('cGluaGFzaA==')));
    expect(exported, isNot(contains('c2hhcmVkLXNlY3JldA==')));
    expect(exported, isNot(contains('BEGIN PRIVATE KEY')));

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await BackupService(target).importJson(exported);
    expect(await target.readIdentity(), isNull);
    expect(await target.readPairedDevices(), isEmpty);
  });

  test('export, clear and import round-trips every table', () async {
    await seedRealData(source);
    final exported = await BackupService(source).exportJson();

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await BackupService(target).importJson(exported);

    final before = Map<String, Object?>.from(jsonDecode(exported) as Map);
    final after = Map<String, Object?>.from(jsonDecode(await BackupService(target).exportJson()) as Map);
    before.remove('exportedAt');
    after.remove('exportedAt');

    expect(after, before);
    expect((await target.watchHabits().first).single.weekdays, {1, 3, 5});
  });

  test('backups embed and restore sticker media', () async {
    final mediaDir = await Directory.systemTemp.createTemp('sundial-media');
    addTearDown(() => mediaDir.delete(recursive: true));
    final sticker = File('${mediaDir.path}/cafe.png')..writeAsBytesSync([1, 2, 3, 4]);
    await source.saveContext(
      PlannerContext(
        id: 'cafe',
        spaceId: 'work',
        name: 'Cafe',
        colorValue: 0xFF2F7ED8,
        imagePath: sticker.path,
      ),
    );

    final exported = await BackupService(source, mediaDirectory: mediaDir).exportJson();
    final payload = jsonDecode(exported) as Map<String, Object?>;
    expect((payload['media'] as Map).keys, contains(sticker.path));

    final restoreDir = await Directory.systemTemp.createTemp('sundial-media-restore');
    addTearDown(() => restoreDir.delete(recursive: true));
    // Media from the plan being replaced must not survive the import.
    final stale = File('${restoreDir.path}/old-sticker.png')..writeAsBytesSync([9, 9]);
    // A file the plan never referenced is not ours to delete.
    final orphan = File('${restoreDir.path}/orphan.png')..writeAsBytesSync([8, 8]);
    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await target.seedDefaults();
    await target.saveContext(
      PlannerContext(id: 'old', spaceId: 'work', name: 'Old', colorValue: 0xFF000000, imagePath: stale.path),
    );
    await BackupService(target, mediaDirectory: restoreDir).importJson(exported);

    final restored = (await target.watchContexts().first).single;
    expect(restored.imagePath, isNotNull);
    expect(restored.imagePath, startsWith(restoreDir.path));
    expect(File(restored.imagePath!).readAsBytesSync(), [1, 2, 3, 4]);
    expect(stale.existsSync(), isFalse);
    expect(orphan.existsSync(), isTrue);
  });

  test('restores over a populated database', () async {
    await seedRealData(source);
    final exported = await BackupService(source).exportJson();

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await target.seedDefaults();
    await target.saveEntry(
      Entry(
        id: 'stale',
        spaceId: 'personal',
        title: 'Stale row',
        date: LocalDate.parse('2026-11-01'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );

    await BackupService(target).importJson(exported);

    expect(await target.readEntry('stale'), isNull);
    final before = Map<String, Object?>.from(jsonDecode(exported) as Map);
    final after = Map<String, Object?>.from(jsonDecode(await BackupService(target).exportJson()) as Map);
    before.remove('exportedAt');
    after.remove('exportedAt');
    expect(after, before);
  });

  test('a restored unit with an unknown kind falls back to other', () async {
    final exported = await BackupService(source).exportJson();
    final payload = jsonDecode(exported) as Map<String, Object?>;
    final units = (payload['homeUnits']! as List<Object?>).cast<Map<String, Object?>>();
    final modifiedId = units.first['id']! as String;
    units.first['kind'] = 'not-a-kind';

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await BackupService(target).importJson(jsonEncode(payload));

    final restored = await target.watchHomeUnits().first;
    expect(restored, isNotEmpty);
    expect(restored.firstWhere((unit) => unit.id == modifiedId).kind, HomeUnitKind.other);
  });

  test('accepts a schema v9 backup', () async {
    await seedRealData(source);
    final payload = jsonDecode(await BackupService(source).exportJson()) as Map<String, Object?>;
    payload['schemaVersion'] = 9;

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await BackupService(target).importJson(jsonEncode(payload));

    expect((await target.watchContexts().first).single.id, 'cafe');
    expect(
      (await target
          .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
          .first),
      isNotEmpty,
    );
  });

  test('rejects a corrupt file without touching existing data', () async {
    await source.saveEntry(
      Entry(
        id: 'keep',
        spaceId: 'home',
        title: 'Keep me',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );

    await expectLater(BackupService(source).importJson('{not json'), throwsA(isA<BackupFormatException>()));

    final entries = await source
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(entries.single.entry.id, 'keep');
  });

  test('rejects a backup missing its required lists without touching existing data', () async {
    await source.saveEntry(
      Entry(
        id: 'keep',
        spaceId: 'home',
        title: 'Keep me',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );
    final payload = jsonDecode(await BackupService(source).exportJson()) as Map<String, Object?>;
    payload.remove('entries');

    await expectLater(
      BackupService(source).importJson(jsonEncode(payload)),
      throwsA(isA<BackupFormatException>()),
    );

    final entries = await source
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(entries.single.entry.id, 'keep');
  });

  test('rejects a future schema version without touching existing data', () async {
    await source.saveEntry(
      Entry(
        id: 'keep',
        spaceId: 'home',
        title: 'Keep me',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );
    final payload = jsonDecode(await BackupService(source).exportJson()) as Map<String, Object?>;
    payload['schemaVersion'] = 999;

    await expectLater(
      BackupService(source).importJson(jsonEncode(payload)),
      throwsA(isA<BackupVersionException>()),
    );

    final entries = await source
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(entries.single.entry.id, 'keep');
  });

  test('rolls back when a row is malformed mid-import', () async {
    await source.saveEntry(
      Entry(
        id: 'keep',
        spaceId: 'home',
        title: 'Keep me',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );
    final payload = jsonDecode(await BackupService(source).exportJson()) as Map<String, Object?>;
    final entries = payload['entries']! as List<Object?>;
    (entries.single! as Map<String, Object?>)['title'] = 42;

    await expectLater(
      BackupService(source).importJson(jsonEncode(payload)),
      throwsA(isA<BackupFormatException>()),
    );

    final loaded = await source
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(loaded.single.entry.id, 'keep');
  });

  test('rejects unknown enum names and recurrence JSON before writing', () async {
    await source.saveEntry(
      Entry(
        id: 'keep',
        spaceId: 'home',
        title: 'Keep me',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );

    for (final mutate in <void Function(Map<String, Object?>)>[
      (row) => row['priority'] = 'urgent',
      (row) => row['kind'] = 'chore',
      (row) => row['status'] = 'pending',
      (row) => row['timeZone'] = 'Mars/Olympus',
      (row) => row['recurrenceJson'] = '{"frequency":"hourly"}',
    ]) {
      final payload = jsonDecode(await BackupService(source).exportJson()) as Map<String, Object?>;
      final entries = payload['entries']! as List<Object?>;
      mutate(entries.single! as Map<String, Object?>);

      await expectLater(
        BackupService(source).importJson(jsonEncode(payload)),
        throwsA(isA<BackupFormatException>()),
      );
      final loaded = await source
          .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
          .first;
      expect(loaded.single.entry.id, 'keep');
      expect(loaded.single.entry.priority, EntryPriority.none);
    }
  });

  test('upgrades a v3 payload and leaves device-local settings behind', () async {
    await source.writeSetting('appLockEnabled', 'true');
    await source.writeSetting('appLockPinSalt', 'c2FsdA==');
    await source.writeSetting('appLockPinHash', 'cGluaGFzaA==');
    final exported = jsonDecode(await BackupService(source).exportJson()) as Map<String, Object?>;
    expect(exported.containsKey('homePurchases'), isTrue);
    expect(jsonEncode(exported), isNot(contains('cGluaGFzaA==')));

    final legacy = <String, Object?>{
      'app': 'sundial',
      'schemaVersion': 3,
      'exportedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
      'spaces': [
        {
          'id': 'personal',
          'name': 'Personal',
          'color': 0xFFB07D5C,
          'position': 0,
          'createdAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
        },
      ],
      'tags': <Object?>[],
      'entries': [
        {
          'id': 'old-v3',
          'spaceId': 'personal',
          'title': 'Imported from v3',
          'notes': '',
          'kind': 'task',
          'dateKey': 20261109,
          'endDateKey': null,
          'startMinute': null,
          'endMinute': null,
          'timeZone': null,
          'startAt': null,
          'endAt': null,
          'allDay': true,
          'status': 'open',
          'recurrenceJson': null,
          'createdAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'deletedAt': null,
        },
      ],
      'entryTags': <Object?>[],
      'completions': <Object?>[],
      'reminders': <Object?>[],
      'shiftPatterns': <Object?>[],
      'shiftSlots': <Object?>[],
      'shiftExceptions': <Object?>[],
      'settings': {
        'themeMode': 'dark',
        'appLockEnabled': 'true',
        'appLockPinSalt': 'c2FsdA==',
        'appLockPinHash': 'cGluaGFzaA==',
      },
    };

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await BackupService(target).importJson(jsonEncode(legacy));

    final entry = await target.readEntry('old-v3');
    expect(entry?.readOnly, isFalse);
    expect(entry?.allDay, isTrue);
    final settings = await target.readSettings();
    expect(settings['themeMode'], 'dark');
    expect(settings.containsKey('appLockPinHash'), isFalse);
    expect(settings.containsKey('appLockEnabled'), isFalse);
  });

  test('upgrades a v4 payload with home items and shopping', () async {
    final legacy = <String, Object?>{
      'app': 'sundial',
      'schemaVersion': 4,
      'exportedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
      'spaces': [
        {
          'id': 'home',
          'name': 'Home',
          'color': 0xFF5B7F6B,
          'position': 0,
          'createdAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
        },
      ],
      'entries': <Object?>[],
      'homeItems': [
        {
          'id': 'soap',
          'name': 'Soap',
          'category': 'Bathroom',
          'location': 'Cabinet',
          'quantity': 4,
          'reorderLevel': 1,
          'unit': 'bars',
          'notes': '',
          'lastPurchasedAt': null,
          'createdAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'deletedAt': null,
        },
      ],
      'shoppingItems': [
        {
          'id': 'soap-buy',
          'name': 'Soap',
          'quantity': 2,
          'unit': 'bars',
          'checked': false,
          'note': '',
          'homeItemId': 'soap',
          'createdAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'updatedAt': DateTime.utc(2026, 11, 1).toIso8601String(),
          'deletedAt': null,
        },
      ],
    };

    final target = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(target.close);
    await BackupService(target).importJson(jsonEncode(legacy));

    final shopping = (await target.watchShoppingItems().first).single;
    expect(shopping.position, 0);
    expect(shopping.homeItemId, 'soap');
    expect(await target.readPurchaseHistory('soap'), isEmpty);
  });

  test('rejects payloads older than the supported upgrade window', () async {
    final legacy = <String, Object?>{'app': 'sundial', 'schemaVersion': 2, 'spaces': <Object?>[]};
    await expectLater(
      BackupService(source).importJson(jsonEncode(legacy)),
      throwsA(isA<BackupFormatException>()),
    );
  });
}
