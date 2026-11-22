import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/media/media_store.dart';
import 'package:sundial/features/sync/sync_engine.dart';
import 'package:sundial/features/sync/sync_models.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

import 'support/media_fixture.dart';

class _FakeTransport extends SyncTransport {
  _FakeTransport(this.store);

  final SyncStore store;
  bool failMedia = false;

  @override
  Future<SyncSnapshotPage> fetchSnapshot(
    PairedDevice device, {
    required String localDeviceId,
    String? cursor,
    int limit = 500,
  }) => store.snapshotPage(cursor: cursor, limit: limit);

  @override
  Future<SyncChangesPage> fetchChanges(
    PairedDevice device, {
    required String localDeviceId,
    required int since,
    int limit = 200,
  }) => store.changesPage(since: since, limit: limit);

  @override
  Future<SyncMediaResponse> fetchMedia(
    PairedDevice device, {
    required String localDeviceId,
    required List<String> ids,
  }) async {
    if (failMedia) throw StateError('media transport is offline');
    final media = <SyncMediaItem>[];
    final missing = <String>[];
    for (final id in ids) {
      final blob = await store.readMedia(id);
      if (blob == null) {
        missing.add(id);
      } else {
        media.add(SyncMediaItem(id: blob.id, mime: blob.mime, byteSize: blob.byteSize, bytes: blob.bytes));
      }
    }
    return SyncMediaResponse(media: media, missing: missing);
  }
}

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 8);

  Future<AppDatabase> openDatabase() async {
    final media = await Directory.systemTemp.createTemp('sundial-mesh-media');
    addTearDown(() async {
      if (media.existsSync()) await media.delete(recursive: true);
    });
    final database = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: media),
    );
    await database.seedDefaults();
    return database;
  }

  Future<void> adopt(AppDatabase target, AppDatabase source) async {
    final state = await source.syncDeviceState();
    await target.customStatement("UPDATE sync_device_state_records SET dataset_id = ? WHERE id = 'local'", [
      state.datasetId,
    ]);
  }

  Future<void> sync(
    AppDatabase from,
    AppDatabase to,
    String fromId,
    String toId, {
    bool failMedia = false,
  }) async {
    final engine = SyncEngine(
      store: SyncStore(to),
      transport: _FakeTransport(SyncStore(from))..failMedia = failMedia,
      snapshotPageSize: 5,
      changesPageSize: 3,
    );
    await engine.pull(_peer(fromId), localDeviceId: toId);
  }

  Future<void> fullMesh(List<AppDatabase> databases) async {
    for (var from = 0; from < databases.length; from++) {
      for (var to = 0; to < databases.length; to++) {
        if (from == to) continue;
        await sync(databases[from], databases[to], 'device-$from', 'device-$to');
      }
    }
  }

  Future<void> addEntry(AppDatabase database, String id) async {
    await database.saveEntry(
      Entry(id: id, spaceId: 'personal', title: id, date: day, allDay: true, createdAt: now, updatedAt: now),
    );
  }

  Future<Set<String>> entryIds(AppDatabase database) async => {
    for (final occurrence in await database.watchEntriesBetween(day, day, 'Europe/Madrid').first)
      occurrence.entry.id,
  };

  test('three fully paired devices converge in one mesh round', () async {
    final first = await openDatabase();
    final second = await openDatabase();
    final third = await openDatabase();
    addTearDown(() async {
      await first.close();
      await second.close();
      await third.close();
    });
    await adopt(second, first);
    await adopt(third, first);
    await addEntry(first, 'from-first');

    await fullMesh([first, second, third]);
    expect(await entryIds(first), {'from-first'});
    expect(await entryIds(second), {'from-first'});
    expect(await entryIds(third), {'from-first'});

    await addEntry(second, 'from-second');
    await fullMesh([first, second, third]);
    for (final database in [first, second, third]) {
      expect(await entryIds(database), {'from-first', 'from-second'});
    }
  });

  test('four fully paired devices converge in one mesh round', () async {
    final databases = [
      await openDatabase(),
      await openDatabase(),
      await openDatabase(),
      await openDatabase(),
    ];
    addTearDown(() async {
      for (final database in databases) {
        await database.close();
      }
    });
    for (final database in databases.skip(1)) {
      await adopt(database, databases.first);
    }
    await addEntry(databases.first, 'from-first');
    await fullMesh(databases);
    for (final database in databases) {
      expect(await entryIds(database), {'from-first'});
    }

    await addEntry(databases[3], 'from-fourth');
    await fullMesh(databases);
    for (final database in databases) {
      expect(await entryIds(database), {'from-first', 'from-fourth'});
    }
  });

  test('a missing direct link is not bridged by a third device', () async {
    final first = await openDatabase();
    final second = await openDatabase();
    final third = await openDatabase();
    addTearDown(() async {
      await first.close();
      await second.close();
      await third.close();
    });
    await adopt(second, first);
    await adopt(third, first);
    await addEntry(first, 'initial');
    await fullMesh([first, second, third]);

    // A and C are not paired. A -> B is paired, and B -> C is paired, but a
    // pull-only peer serves only its own changes, so B does not relay A's edit.
    await addEntry(first, 'only-on-first');
    await sync(first, second, 'device-0', 'device-1');
    await sync(second, third, 'device-1', 'device-2');
    await sync(third, second, 'device-2', 'device-1');

    expect(await entryIds(second), contains('only-on-first'));
    expect(await entryIds(third), isNot(contains('only-on-first')));

    // Pairing A and C closes the meshes and restores the update.
    await sync(first, third, 'device-0', 'device-2');
    expect(await entryIds(third), contains('only-on-first'));
  });

  test('a snapshot page split does not break foreign keys', () async {
    final first = await openDatabase();
    final second = await openDatabase();
    addTearDown(() async {
      await first.close();
      await second.close();
    });
    await adopt(second, first);
    await first.saveEntry(
      Entry(
        id: 'tagged',
        spaceId: 'personal',
        title: 'Tagged',
        date: day,
        allDay: true,
        tagIds: const {'seed-health'},
        createdAt: now,
        updatedAt: now,
      ),
    );

    // A page size of one forces entries, tags and membership rows onto
    // separate pages, each applied in isolation.
    final engine = SyncEngine(
      store: SyncStore(second),
      transport: _FakeTransport(SyncStore(first)),
      snapshotPageSize: 1,
      changesPageSize: 1,
    );
    final result = await engine.pull(_peer('device-0'), localDeviceId: 'device-1');

    expect(result.pages, greaterThan(1));
    final occurrences = await second.watchEntriesBetween(day, day, 'Europe/Madrid').first;
    expect(occurrences.single.entry.tagIds, {'seed-health'});
  });

  test('a 3-device full mesh converges images', () async {
    final databases = [await openDatabase(), await openDatabase(), await openDatabase()];
    addTearDown(() async {
      for (final database in databases) {
        await database.close();
      }
    });
    for (final database in databases.skip(1)) {
      await adopt(database, databases.first);
    }
    final pictures = await Directory.systemTemp.createTemp('sundial-mesh-pictures');
    addTearDown(() async {
      if (pictures.existsSync()) await pictures.delete(recursive: true);
    });
    final image = await writePng(pictures, 'house.png', tinyPng);
    await databases.first.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: image.path,
      ),
    );

    await fullMesh(databases);

    for (final database in databases) {
      final context = (await database.watchContexts().first).single;
      expect(context.imagePath, isNotNull);
      expect(File(context.imagePath!).readAsBytesSync(), tinyPng);
    }
  });

  test('media is served only from the peer\'s own cache, not relayed', () async {
    final first = await openDatabase();
    final second = await openDatabase();
    final third = await openDatabase();
    addTearDown(() async {
      await first.close();
      await second.close();
      await third.close();
    });
    await adopt(second, first);
    await adopt(third, first);
    final pictures = await Directory.systemTemp.createTemp('sundial-mesh-pictures');
    addTearDown(() async {
      if (pictures.existsSync()) await pictures.delete(recursive: true);
    });
    final image = await writePng(pictures, 'house.png', tinyPng);
    await first.saveContext(
      PlannerContext(
        id: 'house',
        spaceId: 'home',
        name: 'House',
        colorValue: 0xFF5B7F6B,
        imagePath: image.path,
      ),
    );

    // The second device gets the row but not the bytes.
    await sync(first, second, 'device-0', 'device-1', failMedia: true);
    expect((await second.watchContexts().first).single.imagePath, isNull);

    // The third device pulls the row from the second, which cannot relay the
    // bytes it never received from the first.
    await sync(second, third, 'device-1', 'device-2');
    expect((await third.watchContexts().first).single.id, 'house');
    expect((await third.watchContexts().first).single.imagePath, isNull);

    // Once the second owns a verified copy, the third can fetch that copy.
    await sync(first, second, 'device-0', 'device-1');
    expect((await second.watchContexts().first).single.imagePath, isNotNull);
    await sync(second, third, 'device-1', 'device-2');
    final thirdContext = (await third.watchContexts().first).single;
    expect(thirdContext.imagePath, isNotNull);
    expect(File(thirdContext.imagePath!).readAsBytesSync(), tinyPng);
  });
}

PairedDevice _peer(String id) {
  final now = DateTime.utc(2026, 11, 9, 8);
  return PairedDevice(
    id: id,
    name: id,
    username: 'tester',
    certificateFingerprint: 'f' * 64,
    sharedKey: 'c2hhcmVkLXNlY3JldA==',
    host: '127.0.0.1',
    port: 8766,
    lastSeenAt: now,
    createdAt: now,
    updatedAt: now,
  );
}
