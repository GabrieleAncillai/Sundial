import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/media/media_store.dart';
import 'package:sundial/features/sync/sync_models.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

import 'support/media_fixture.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase first;
  late AppDatabase second;
  late Directory firstMedia;
  late Directory secondMedia;
  late Directory pictures;

  setUp(() async {
    firstMedia = await Directory.systemTemp.createTemp('sundial-first-media');
    secondMedia = await Directory.systemTemp.createTemp('sundial-second-media');
    pictures = await Directory.systemTemp.createTemp('sundial-store-pictures');
    first = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: firstMedia),
    );
    second = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: secondMedia),
    );
    await first.seedDefaults();
    await second.seedDefaults();
  });

  tearDown(() async {
    await first.close();
    await second.close();
    for (final directory in [firstMedia, secondMedia, pictures]) {
      if (directory.existsSync()) await directory.delete(recursive: true);
    }
  });

  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 8);

  Future<Entry> seedEntry(
    AppDatabase database, {
    String id = 'dentist',
    String title = 'Dentist',
    String notes = 'Bring card',
  }) async {
    final entry = Entry(
      id: id,
      spaceId: 'personal',
      title: title,
      notes: notes,
      date: day,
      allDay: true,
      tagIds: const {'seed-health'},
      createdAt: now,
      updatedAt: now,
    );
    await database.saveEntry(entry);
    return entry;
  }

  Future<void> adoptDataset(AppDatabase target, AppDatabase source) async {
    final state = await source.syncDeviceState();
    await target.customStatement("UPDATE sync_device_state_records SET dataset_id = ? WHERE id = 'local'", [
      state.datasetId,
    ]);
  }

  Future<void> pull({
    required AppDatabase from,
    required AppDatabase to,
    required String peerId,
    int snapshotLimit = 3,
    int changesLimit = 2,
  }) async {
    final source = SyncStore(from);
    final target = SyncStore(to);
    final state = await from.syncDeviceState();
    final peer = await target.readPeerState(peerId);
    if (peer != null && peer.datasetId == state.datasetId && peer.peerEpoch == state.epoch) {
      var since = peer.lastPulledSeq;
      while (true) {
        final page = await source.changesPage(since: since, limit: changesLimit);
        await target.applyChangesPage(page, peerDeviceId: peerId);
        if (!page.hasMore) break;
        since = page.nextSince;
      }
      return;
    }

    String? cursor;
    do {
      final page = await source.snapshotPage(cursor: cursor, limit: snapshotLimit);
      await target.applySnapshotPage(page, peerDeviceId: peerId);
      cursor = page.cursor;
    } while (cursor != null);
  }

  Future<List<Entry>> visibleEntries(AppDatabase database) async => [
    for (final occurrence in await database.watchEntriesBetween(day, day, 'Europe/Madrid').first)
      occurrence.entry,
  ];

  test('a paged snapshot transfers entries, tags, inventory, shopping and weekStart', () async {
    await first.writeSetting('weekStart', '1');
    await seedEntry(first);
    await first.saveHomeItem(
      const HomeItem(id: 'rice', name: 'Rice', quantity: 2, unit: 'kg', category: 'Food & pantry'),
    );
    await first.saveShoppingItem(
      const ShoppingItem(id: 'buy-rice', name: 'Rice', quantity: 3, unit: 'kg', homeItemId: 'rice'),
    );
    await first.saveContext(
      const PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        icon: 'home',
        imagePath: '/home/tester/secret-house.png',
      ),
    );
    await adoptDataset(second, first);

    final store = SyncStore(first);
    final firstPage = await store.snapshotPage(limit: 3);
    expect(firstPage.done, isFalse);
    expect(firstPage.cursor, isNotNull);
    expect(firstPage.nextSince, greaterThanOrEqualTo(0));

    await pull(from: first, to: second, peerId: 'device-a');

    final entry = (await visibleEntries(second)).single;
    expect(entry.title, 'Dentist');
    expect(entry.tagIds, {'seed-health'});
    final item = (await second.watchHomeItems().first).single;
    expect(item.name, 'Rice');
    expect(item.quantity, 2);
    final shopping = (await second.watchShoppingItems().first).single;
    expect(shopping.name, 'Rice');
    expect(shopping.homeItemId, 'rice');
    final context = (await second.watchContexts().first).single;
    expect(context.icon, 'home');
    expect(context.colorValue, 0xFF5B7F6B);
    expect(context.imagePath, isNull);
    expect(await second.readSettings(), containsPair('weekStart', '1'));
  });

  test('offline edits on different fields both survive', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    final onFirst = (await visibleEntries(first)).single;
    final onSecond = (await visibleEntries(second)).single;
    await first.saveEntry(onFirst.copyWith(title: 'Dentist, 4pm'));
    await second.saveEntry(onSecond.copyWith(notes: 'Bring the insurance card'));

    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    for (final database in [first, second]) {
      final entry = (await visibleEntries(database)).single;
      expect(entry.title, 'Dentist, 4pm');
      expect(entry.notes, 'Bring the insurance card');
    }
  });

  test('same-field edits converge on one value', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    final onFirst = (await visibleEntries(first)).single;
    final onSecond = (await visibleEntries(second)).single;
    await first.saveEntry(onFirst.copyWith(title: 'From the desktop'));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await second.saveEntry(onSecond.copyWith(title: 'From the phone'));

    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    final firstTitle = (await visibleEntries(first)).single.title;
    final secondTitle = (await visibleEntries(second)).single.title;
    expect(firstTitle, secondTitle);
    expect(firstTitle, 'From the phone');
  });

  test('a newer edit resurrects a deleted row', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    await first.softDeleteEntry('dentist');
    expect(await visibleEntries(first), isEmpty);

    // The phone was offline and edited the appointment after the desktop
    // deleted it, so its field versions are newer than the tombstone.
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final onSecond = (await visibleEntries(second)).single;
    await second.saveEntry(onSecond.copyWith(notes: 'Still happening'));

    await pull(from: second, to: first, peerId: 'device-b');
    await pull(from: first, to: second, peerId: 'device-a');

    for (final database in [first, second]) {
      final entry = (await visibleEntries(database)).single;
      expect(entry.notes, 'Still happening');
    }
  });

  test('a newer delete wins over an older edit', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    final onSecond = (await visibleEntries(second)).single;
    await second.saveEntry(onSecond.copyWith(notes: 'Edited first'));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await first.softDeleteEntry('dentist');

    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    expect(await visibleEntries(first), isEmpty);
    expect(await visibleEntries(second), isEmpty);
  });

  test('re-applying the same page is idempotent', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    final store = SyncStore(first);
    final page = await store.snapshotPage(limit: 500);
    final target = SyncStore(second);

    final applied = await target.applySnapshotPage(page, peerDeviceId: 'device-a');
    expect(applied.applied, greaterThan(0));
    final replay = await target.applySnapshotPage(page, peerDeviceId: 'device-a');
    expect(replay.applied, 0);
    expect(replay.deleted, 0);
    expect(replay.skipped, greaterThan(0));
    expect((await visibleEntries(second)).length, 1);
  });

  test('a malformed page rolls back as a whole', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    final store = SyncStore(first);
    final page = await store.snapshotPage(limit: 500);
    final broken = SyncSnapshotPage(
      datasetId: page.datasetId,
      epoch: page.epoch,
      nodeId: page.nodeId,
      deviceId: page.deviceId,
      generatedAt: page.generatedAt,
      serverHlc: page.serverHlc,
      nextSince: page.nextSince,
      cursor: null,
      done: true,
      knownDevices: page.knownDevices,
      rows: [
        ...page.rows,
        const SyncRowPayload(
          entity: 'notAnEntity',
          key: 'broken',
          row: {'id': 'broken'},
          versions: {'present': '0000000000001000:00000000:node'},
        ),
      ],
    );

    await expectLater(
      SyncStore(second).applySnapshotPage(broken, peerDeviceId: 'device-a'),
      throwsA(isA<SyncProtocolException>()),
    );
    expect(await visibleEntries(second), isEmpty);
    expect(await second.syncDeviceState(), isNotNull);
  });

  test('a different dataset is rejected before writing', () async {
    await seedEntry(first);
    final page = await SyncStore(first).snapshotPage(limit: 500);
    await expectLater(
      SyncStore(second).applySnapshotPage(page, peerDeviceId: 'device-a'),
      throwsA(isA<SyncDatasetMismatchException>()),
    );
    expect(await visibleEntries(second), isEmpty);
  });

  test('a changed peer epoch requires a fresh snapshot', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    await pull(from: first, to: second, peerId: 'device-a');
    final peer = await SyncStore(second).readPeerState('device-a');
    expect(peer, isNotNull);

    final source = SyncStore(first);
    final changes = await source.changesPage(since: 0, limit: 100);
    final altered = SyncChangesPage(
      datasetId: changes.datasetId,
      epoch: 'a-different-epoch',
      nodeId: changes.nodeId,
      nextSince: changes.nextSince,
      hasMore: false,
      knownDevices: changes.knownDevices,
      changes: changes.changes,
    );
    await expectLater(
      SyncStore(second).applyChangesPage(altered, peerDeviceId: 'device-a'),
      throwsA(isA<SyncEpochChangedException>()),
    );
  });

  test('a whole-form save keeps a tag another device added', () async {
    await seedEntry(first);
    await adoptDataset(second, first);
    await pull(from: first, to: second, peerId: 'device-a');
    await pull(from: second, to: first, peerId: 'device-b');

    await first.saveEntryTags('dentist', {'seed-health', 'seed-fitness'});
    await pull(from: first, to: second, peerId: 'device-a');

    final onSecond = (await visibleEntries(second)).single;
    expect(onSecond.tagIds, {'seed-health', 'seed-fitness'});

    // The editor opened before the fitness tag arrived and only knows about
    // the health tag; saving must not remove the concurrent addition.
    await second.saveEntry(onSecond.copyWith(tagIds: const {'seed-health'}), removedTagIds: const {});
    expect((await visibleEntries(second)).single.tagIds, {'seed-health', 'seed-fitness'});

    await pull(from: second, to: first, peerId: 'device-b');
    expect((await visibleEntries(first)).single.tagIds, {'seed-health', 'seed-fitness'});
  });

  test('only weekStart travels with settings', () async {
    await first.writeSetting('weekStart', '1');
    await first.writeSetting('themeMode', 'dark');
    await second.writeSetting('themeMode', 'light');
    await adoptDataset(second, first);

    await pull(from: first, to: second, peerId: 'device-a');

    final settings = await second.readSettings();
    expect(settings['weekStart'], '1');
    expect(settings['themeMode'], 'light');
  });

  test('a snapshot exposes only public device metadata', () async {
    final createdAt = DateTime.utc(2026, 11, 9, 8);
    await first.saveIdentity(
      LocalIdentity(
        deviceId: 'desktop',
        deviceName: 'Desktop',
        username: 'tester',
        pinSalt: 'c2FsdA==',
        pinHash: 'cGluaGFzaA==',
        certificatePem: 'BEGIN CERTIFICATE',
        privateKeyPem: 'BEGIN PRIVATE KEY',
        mcpToken: 'mcp-secret-token',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await first.savePairedDevice(
      PairedDevice(
        id: 'phone',
        name: 'Phone',
        username: 'tester',
        certificateFingerprint: 'f' * 64,
        sharedKey: 'c2hhcmVkLXNlY3JldA==',
        host: '192.168.1.20',
        port: 8766,
        lastSeenAt: createdAt,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await seedEntry(first);

    final page = await SyncStore(first).snapshotPage(limit: 500);
    final payload = jsonEncode(page.toJson());
    expect(payload, contains('Phone'));
    expect(payload, contains('f' * 64));
    expect(payload, isNot(contains('c2hhcmVkLXNlY3JldA==')));
    expect(payload, isNot(contains('cGluaGFzaA==')));
    expect(payload, isNot(contains('BEGIN PRIVATE KEY')));
    expect(payload, isNot(contains('mcp-secret-token')));
    expect(payload, isNot(contains('192.168.1.20')));
  });

  Future<String?> mediaIdOf(AppDatabase database, String id) async {
    final row = await database
        .customSelect(
          'SELECT image_media_id FROM context_records WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row?.readNullable<String>('image_media_id');
  }

  Future<String?> projectMediaIdOf(AppDatabase database, String id) async {
    final row = await database
        .customSelect(
          'SELECT image_media_id FROM project_records WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row?.readNullable<String>('image_media_id');
  }

  test('a context image syncs by id and its local path never travels', () async {
    final file = await writePng(pictures, 'house.png', tinyPng);
    await first.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: file.path,
      ),
    );
    final id = await mediaIdOf(first, 'house');
    expect(id, MediaStore.hashBytes(tinyPng));

    final store = SyncStore(first);
    final snapshot = jsonEncode((await store.snapshotPage(limit: 500)).toJson());
    final changes = jsonEncode((await store.changesPage(since: 0, limit: 100)).toJson());
    for (final payload in [snapshot, changes]) {
      expect(payload, contains(id!));
      expect(payload, isNot(contains(file.path)));
      expect(payload, isNot(contains('image_path')));
    }

    await adoptDataset(second, first);
    await SyncStore(second).applySnapshotPage(await store.snapshotPage(limit: 500), peerDeviceId: 'device-a');
    final onSecond = (await second.watchContexts().first).single;
    expect(await mediaIdOf(second, 'house'), id);
    // The low-level apply does not fetch media; the path stays null until the
    // engine's media step runs.
    expect(onSecond.imagePath, isNull);
  });

  test('clearing an image clears the id but keeps the shared cache', () async {
    final file = await writePng(pictures, 'house.png', tinyPng);
    await first.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: file.path,
      ),
    );
    final id = await mediaIdOf(first, 'house');
    expect(id, isNotNull);

    await first.saveContext(
      const PlannerContext(id: 'house', spaceId: 'home', name: 'House', colorValue: 0xFF5B7F6B),
    );

    expect(await mediaIdOf(first, 'house'), isNull);
    expect((await first.watchContexts().first).single.imagePath, isNull);
    final cached = await first.select(first.mediaCacheRecords).get();
    expect(cached.single.mediaId, id);
    expect(File(cached.single.path).existsSync(), isTrue);
  });

  test('a save with a missing image still succeeds without a media id', () async {
    await first.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: '${pictures.path}/gone.png',
      ),
    );

    expect((await first.watchContexts().first).single.id, 'house');
    expect(await mediaIdOf(first, 'house'), isNull);
    expect(await first.select(first.mediaCacheRecords).get(), isEmpty);
  });

  test('a project image gets and clears its media id', () async {
    final file = await writePng(pictures, 'reno.png', secondPng);
    await first.saveProject(
      Project(id: 'reno', spaceId: 'home', name: 'Renovation', colorValue: 0xFF2FA98F, imagePath: file.path),
    );
    expect(await projectMediaIdOf(first, 'reno'), MediaStore.hashBytes(secondPng));

    await first.saveProject(
      const Project(id: 'reno', spaceId: 'home', name: 'Renovation', colorValue: 0xFF2FA98F),
    );
    expect(await projectMediaIdOf(first, 'reno'), isNull);
    expect((await first.watchProjects().first).single.imagePath, isNull);
  });

  test('clearAllData clears the media index and managed image files', () async {
    final file = await writePng(pictures, 'house.png', tinyPng);
    await first.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: file.path,
      ),
    );
    final cached = (await first.select(first.mediaCacheRecords).get()).single;
    expect(File(cached.path).existsSync(), isTrue);

    await first.clearAllData();

    expect(await first.select(first.mediaCacheRecords).get(), isEmpty);
    expect(File(cached.path).existsSync(), isFalse);
    expect(file.existsSync(), isFalse);
  });
}
