import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show Variable, driftRuntimeOptions;
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

  late AppDatabase desktop;
  late AppDatabase phone;
  late SyncStore desktopStore;
  late SyncStore phoneStore;
  late SyncEngine desktopEngine;
  late SyncEngine phoneEngine;
  late _FakeTransport desktopFromPhone;
  late _FakeTransport phoneFromDesktop;
  late Directory desktopMedia;
  late Directory phoneMedia;
  late Directory pictures;

  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 8);
  final desktopPeer = _peer('desktop', 'Desktop');
  final phonePeer = _peer('phone', 'Phone');

  setUp(() async {
    desktopMedia = await Directory.systemTemp.createTemp('sundial-desktop-media');
    phoneMedia = await Directory.systemTemp.createTemp('sundial-phone-media');
    pictures = await Directory.systemTemp.createTemp('sundial-pictures');
    desktop = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: desktopMedia),
    );
    phone = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: phoneMedia),
    );
    await desktop.seedDefaults();
    await phone.seedDefaults();
    desktopStore = SyncStore(desktop);
    phoneStore = SyncStore(phone);
    desktopFromPhone = _FakeTransport(phoneStore);
    phoneFromDesktop = _FakeTransport(desktopStore);
    desktopEngine = SyncEngine(
      store: desktopStore,
      transport: desktopFromPhone,
      snapshotPageSize: 3,
      changesPageSize: 2,
    );
    phoneEngine = SyncEngine(
      store: phoneStore,
      transport: phoneFromDesktop,
      snapshotPageSize: 3,
      changesPageSize: 2,
    );
  });

  tearDown(() async {
    await desktop.close();
    await phone.close();
    for (final directory in [desktopMedia, phoneMedia, pictures]) {
      if (directory.existsSync()) await directory.delete(recursive: true);
    }
  });

  Future<void> seedDesktopEntry({String title = 'Dentist'}) async {
    await desktop.saveEntry(
      Entry(
        id: 'dentist',
        spaceId: 'personal',
        title: title,
        notes: 'Bring card',
        date: day,
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> adoptDataset(AppDatabase target, AppDatabase source) async {
    final state = await source.syncDeviceState();
    await target.customStatement("UPDATE sync_device_state_records SET dataset_id = ? WHERE id = 'local'", [
      state.datasetId,
    ]);
  }

  Future<List<Entry>> visibleEntries(AppDatabase database) async => [
    for (final occurrence in await database.watchEntriesBetween(day, day, 'Europe/Madrid').first)
      occurrence.entry,
  ];

  test('pulls a paged snapshot and records the peer cursor', () async {
    await seedDesktopEntry();
    await adoptDataset(phone, desktop);

    final result = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(result.didSnapshot, isTrue);
    expect(result.pages, greaterThan(1));
    expect(result.result.applied, greaterThan(0));
    expect((await visibleEntries(phone)).single.title, 'Dentist');
    final peerState = await phoneStore.readPeerState('desktop');
    expect(peerState, isNotNull);
    expect(peerState!.datasetId, (await desktop.syncDeviceState()).datasetId);
  });

  test('a second pull with no changes is a no-op', () async {
    await seedDesktopEntry();
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    final again = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(again.didSnapshot, isFalse);
    expect(again.changed, isFalse);
    expect(again.result.applied, 0);
    expect(again.result.deleted, 0);
  });

  test('deltas carry offline edits in both directions', () async {
    await seedDesktopEntry();
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');

    final onDesktop = (await visibleEntries(desktop)).single;
    final onPhone = (await visibleEntries(phone)).single;
    await desktop.saveEntry(onDesktop.copyWith(title: 'Dentist, 4pm'));
    await phone.saveEntry(onPhone.copyWith(notes: 'Bring the insurance card'));

    final toPhone = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    final toDesktop = await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');

    expect(toPhone.didSnapshot, isFalse);
    expect(toDesktop.didSnapshot, isFalse);
    for (final database in [desktop, phone]) {
      final entry = (await visibleEntries(database)).single;
      expect(entry.title, 'Dentist, 4pm');
      expect(entry.notes, 'Bring the insurance card');
    }
  });

  test('a peer epoch change falls back to a fresh snapshot', () async {
    await seedDesktopEntry();
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    final before = await phoneStore.readPeerState('desktop');
    expect(before, isNotNull);

    await desktop.resetSyncState(newDataset: false);
    await desktop.seedSyncFieldVersionsForAll();
    await seedDesktopEntry(title: 'Dentist after reset');

    final result = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(result.didSnapshot, isTrue);
    expect((await visibleEntries(phone)).single.title, 'Dentist after reset');
    final after = await phoneStore.readPeerState('desktop');
    expect(after!.peerEpoch, (await desktop.syncDeviceState()).epoch);
  });

  test('a dataset mismatch is reported without touching the local plan', () async {
    await seedDesktopEntry();

    await expectLater(
      phoneEngine.pull(desktopPeer, localDeviceId: 'phone'),
      throwsA(isA<SyncDatasetMismatchException>()),
    );
    expect(await visibleEntries(phone), isEmpty);
  });

  test('a delete propagates and a newer edit resurrects it', () async {
    await seedDesktopEntry();
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');

    await desktop.softDeleteEntry('dentist');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final onPhone = (await visibleEntries(phone)).single;
    await phone.saveEntry(onPhone.copyWith(notes: 'Still happening'));

    await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    for (final database in [desktop, phone]) {
      expect((await visibleEntries(database)).single.notes, 'Still happening');
    }
  });

  test('the entry timing group merges as a whole', () async {
    await desktop.saveEntry(
      Entry(
        id: 'timed',
        spaceId: 'personal',
        title: 'Timed task',
        date: day,
        startMinute: 9 * 60,
        endMinute: 12 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');

    final onDesktop = (await visibleEntries(desktop)).single;
    final onPhone = (await visibleEntries(phone)).single;
    await desktop.saveEntry(onDesktop.copyWith(startMinute: 10 * 60));
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await phone.saveEntry(onPhone.copyWith(endMinute: 11 * 60 + 30));

    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');

    final desktopEntry = (await visibleEntries(desktop)).single;
    final phoneEntry = (await visibleEntries(phone)).single;
    expect(desktopEntry.startMinute, phoneEntry.startMinute);
    expect(desktopEntry.endMinute, phoneEntry.endMinute);
    // The newer timing group wins whole: start and end are never mixed.
    expect(desktopEntry.startMinute, 9 * 60);
    expect(desktopEntry.endMinute, 11 * 60 + 30);
  });

  test('completing the same occurrence on both devices keeps one row', () async {
    await desktop.saveEntry(
      Entry(
        id: 'bins',
        spaceId: 'home',
        title: 'Take the bins out',
        date: day,
        allDay: true,
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly, weekdays: {1}),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    await phone.setOccurrenceCompleted('bins', day, completed: true);
    await desktop.setOccurrenceCompleted('bins', day, completed: true);

    await desktopEngine.pull(phonePeer, localDeviceId: 'desktop');
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    for (final database in [desktop, phone]) {
      final occurrences = await database.watchEntriesBetween(day, day, 'Europe/Madrid').first;
      expect(occurrences.single.completed, isTrue);
      final rows = await database
          .customSelect('SELECT COUNT(*) AS count FROM completion_records')
          .getSingle();
      expect(rows.read<int>('count'), 1);
    }
  });

  // ---------------------------------------------------------------------------
  // Media

  Future<PlannerContext> saveDesktopContext({String? imagePath}) async {
    final context = PlannerContext(
      id: 'house',
      spaceId: 'home',
      name: 'House',
      colorValue: 0xFF5B7F6B,
      icon: 'home',
      imagePath: imagePath,
    );
    await desktop.saveContext(context);
    return context;
  }

  Future<PlannerContext> phoneContext() async => (await phone.watchContexts().first).single;

  Future<String?> mediaIdOf(AppDatabase database, String id) async {
    final row = await database
        .customSelect(
          'SELECT image_media_id FROM context_records WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row?.readNullable<String>('image_media_id');
  }

  test('an image reaches the other device with its own local path', () async {
    final file = await writePng(pictures, 'house.png', tinyPng);
    await saveDesktopContext(imagePath: file.path);
    await adoptDataset(phone, desktop);

    final pulled = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(pulled.mediaError, isNull);
    final context = await phoneContext();
    expect(context.imagePath, isNotNull);
    expect(context.imagePath, isNot(file.path));
    expect(File(context.imagePath!).readAsBytesSync(), tinyPng);
    expect(await mediaIdOf(phone, 'house'), MediaStore.hashBytes(tinyPng));

    // The desktop keeps its own display file; the image path is device-local.
    final onDesktop = (await desktop.watchContexts().first).single;
    expect(onDesktop.imagePath, file.path);
  });

  test('replacing an image updates the peer to the new bytes', () async {
    final first = await writePng(pictures, 'first.png', tinyPng);
    await saveDesktopContext(imagePath: first.path);
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    expect(File((await phoneContext()).imagePath!).readAsBytesSync(), tinyPng);

    final second = await writePng(pictures, 'second.png', secondPng);
    await saveDesktopContext(imagePath: second.path);

    // The phone was "offline" between the change and this pull.
    final pulled = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(pulled.didSnapshot, isFalse);
    expect(pulled.mediaError, isNull);
    final context = await phoneContext();
    expect(File(context.imagePath!).readAsBytesSync(), secondPng);
    expect(await mediaIdOf(phone, 'house'), MediaStore.hashBytes(secondPng));
  });

  test('removing an image clears the peer path', () async {
    final file = await writePng(pictures, 'house.png', tinyPng);
    await saveDesktopContext(imagePath: file.path);
    await adoptDataset(phone, desktop);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');
    expect((await phoneContext()).imagePath, isNotNull);

    await saveDesktopContext(imagePath: null);
    await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    final context = await phoneContext();
    expect(context.imagePath, isNull);
    expect(await mediaIdOf(phone, 'house'), isNull);
  });

  test('a media failure leaves the row applied and retries on the next pull', () async {
    final file = await writePng(pictures, 'house.png', tinyPng);
    await saveDesktopContext(imagePath: file.path);
    await adoptDataset(phone, desktop);

    final emissions = <PlannerContext>[];
    final subscription = phone.watchContexts().listen((items) => emissions.addAll(items));
    addTearDown(subscription.cancel);
    await Future<void>.delayed(Duration.zero);

    phoneFromDesktop.failMedia = true;
    final failed = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(failed.result.applied, greaterThan(0));
    expect(failed.mediaError, isNotNull);
    expect(failed.result.missingMediaIds, {MediaStore.hashBytes(tinyPng)});
    expect(await mediaIdOf(phone, 'house'), MediaStore.hashBytes(tinyPng));
    expect((await phoneContext()).imagePath, isNull);

    phoneFromDesktop.failMedia = false;
    final retried = await phoneEngine.pull(desktopPeer, localDeviceId: 'phone');

    expect(retried.mediaError, isNull);
    expect(retried.changed, isFalse);
    expect((await phoneContext()).imagePath, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // The query stream refreshed when the local path was linked.
    expect(emissions.last.imagePath, isNotNull);
  });
}

PairedDevice _peer(String id, String name) {
  final now = DateTime.utc(2026, 11, 9, 8);
  return PairedDevice(
    id: id,
    name: name,
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
