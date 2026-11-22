import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/media/media_store.dart';
import 'package:sundial/features/sync/sync_clock.dart';
import 'package:sundial/features/sync/sync_engine.dart';
import 'package:sundial/features/sync/sync_models.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

import 'support/media_fixture.dart';

class _FakeTransport extends SyncTransport {
  _FakeTransport(this.store);

  final SyncStore store;

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

  late AppDatabase source;
  late AppDatabase target;
  late SyncStore sourceStore;
  late SyncStore targetStore;
  late SyncEngine targetEngine;
  late Directory sourceMedia;
  late Directory targetMedia;
  late Directory pictures;

  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 8);
  final sourcePeer = _peer('source', 'Desktop');

  setUp(() async {
    sourceMedia = await Directory.systemTemp.createTemp('sundial-source-media');
    targetMedia = await Directory.systemTemp.createTemp('sundial-target-media');
    pictures = await Directory.systemTemp.createTemp('sundial-replace-pictures');
    source = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: sourceMedia),
    );
    target = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: targetMedia),
    );
    await source.seedDefaults();
    await target.seedDefaults();
    sourceStore = SyncStore(source);
    targetStore = SyncStore(target);
    targetEngine = SyncEngine(
      store: targetStore,
      transport: _FakeTransport(sourceStore),
      snapshotPageSize: 3,
      changesPageSize: 2,
    );
  });

  tearDown(() async {
    await source.close();
    await target.close();
    for (final directory in [sourceMedia, targetMedia, pictures]) {
      if (directory.existsSync()) await directory.delete(recursive: true);
    }
  });

  Future<void> seedSource() async {
    await source.writeSetting('weekStart', '1');
    await source.saveEntry(
      Entry(
        id: 'source-entry',
        spaceId: 'personal',
        title: 'Source appointment',
        notes: 'Keep me',
        date: day,
        allDay: true,
        tagIds: const {'seed-health'},
        createdAt: now,
        updatedAt: now,
      ),
    );
    await source.saveShiftPattern(
      ShiftPattern(
        id: 'source-shift',
        spaceId: 'work',
        name: 'Opening',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: day,
        slots: const [ShiftSlot(dayIndex: 0, label: 'Open', startMinute: 540, endMinute: 780)],
      ),
    );
  }

  Future<void> seedTarget() async {
    await target.writeSetting('weekStart', '0');
    await target.writeSetting('themeMode', 'dark');
    await target.saveEntry(
      Entry(
        id: 'target-entry',
        spaceId: 'home',
        title: 'Target task',
        date: day,
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await target.saveIdentity(
      LocalIdentity(
        deviceId: 'target',
        deviceName: 'Phone',
        username: 'tester',
        pinSalt: 'c2FsdA==',
        pinHash: 'aGFzaA==',
        certificatePem: 'cert',
        privateKeyPem: 'key',
        mcpToken: 'token',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await target.savePairedDevice(sourcePeer);
  }

  Future<List<Entry>> entries(AppDatabase database) async => [
    for (final occurrence in await database.watchEntriesBetween(day, day, 'Europe/Madrid').first)
      occurrence.entry,
  ];

  test('a staged source replaces the plan and keeps device-local data', () async {
    await seedSource();
    await seedTarget();
    final sourceState = await source.syncDeviceState();

    final staged = await targetEngine.stageSnapshot(sourcePeer, localDeviceId: 'target');
    expect(staged.rows, isNotEmpty);
    final serverHlc = SyncHlc.parse(staged.serverHlc);

    final result = await targetStore.applyReplacement(staged, peerDeviceId: 'source');
    expect(result.applied, greaterThan(0));

    final targetState = await target.syncDeviceState();
    expect(targetState.datasetId, sourceState.datasetId);
    expect(targetState.nodeId, isNot(sourceState.nodeId));
    expect(targetState.epoch, isNot(sourceState.epoch));
    expect(targetState.hlcMillis, greaterThan(serverHlc.millis));

    final visible = await entries(target);
    expect(visible.map((entry) => entry.id), ['source-entry']);
    expect(visible.single.tagIds, {'seed-health'});
    expect((await target.watchShiftPatterns().first).single.name, 'Opening');

    final settings = await target.readSettings();
    expect(settings['weekStart'], '1');
    expect(settings['themeMode'], 'dark');
    expect(settings['defaultCategoriesSeeded'], 'true');
    expect(settings['homeReferenceSeeded'], 'true');

    expect(await target.readIdentity(), isNotNull);
    expect((await target.readPairedDevices()).single.id, 'source');

    final peerState = await targetStore.readPeerState('source');
    expect(peerState!.datasetId, staged.datasetId);
    expect(peerState.peerEpoch, staged.epoch);
    expect(peerState.lastPulledSeq, staged.nextSince);

    final changes = await target
        .customSelect('SELECT COUNT(*) AS count FROM sync_change_records')
        .getSingle();
    expect(changes.read<int>('count'), 0);

    final oldRows = await target
        .customSelect("SELECT COUNT(*) AS count FROM entry_records WHERE id = 'target-entry'")
        .getSingle();
    expect(oldRows.read<int>('count'), 0);
  });

  test('a malformed stage leaves the target untouched', () async {
    await seedSource();
    await seedTarget();
    final staged = await targetEngine.stageSnapshot(sourcePeer, localDeviceId: 'target');
    final before = await target.syncDeviceState();
    final broken = SyncStagedSnapshot(
      datasetId: staged.datasetId,
      epoch: staged.epoch,
      nodeId: staged.nodeId,
      deviceId: staged.deviceId,
      serverHlc: staged.serverHlc,
      nextSince: staged.nextSince,
      knownDevices: staged.knownDevices,
      rows: [
        ...staged.rows,
        const SyncRowPayload(
          entity: 'notAnEntity',
          key: 'broken',
          row: {'id': 'broken'},
          versions: {'present': '0000000000001000:00000000:node'},
        ),
      ],
    );

    await expectLater(
      targetStore.applyReplacement(broken, peerDeviceId: 'source'),
      throwsA(isA<SyncProtocolException>()),
    );

    final after = await target.syncDeviceState();
    expect(after.datasetId, before.datasetId);
    expect(after.nodeId, before.nodeId);
    expect((await entries(target)).single.id, 'target-entry');
    expect((await target.readSettings())['weekStart'], '0');
  });

  test('deltas continue from the replacement cursor', () async {
    await seedSource();
    await seedTarget();
    final staged = await targetEngine.stageSnapshot(sourcePeer, localDeviceId: 'target');
    await targetStore.applyReplacement(staged, peerDeviceId: 'source');

    await source.saveEntry(
      Entry(
        id: 'after-replace',
        spaceId: 'personal',
        title: 'After replacement',
        date: day,
        allDay: true,
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    final pulled = await targetEngine.pull(sourcePeer, localDeviceId: 'target');
    expect(pulled.didSnapshot, isFalse);
    expect(pulled.changed, isTrue);
    expect((await entries(target)).map((entry) => entry.id), contains('after-replace'));
  });

  test('a replacement carries context and project images', () async {
    await seedSource();
    await seedTarget();
    final contextImage = await writePng(pictures, 'cafe.png', tinyPng);
    final projectImage = await writePng(pictures, 'reno.png', secondPng);
    await source.saveContext(
      PlannerContext(
        id: 'cafe',
        spaceId: 'work',
        name: 'Cafe',
        colorValue: 0xFF2F7ED8,
        icon: 'local_cafe',
        imagePath: contextImage.path,
      ),
    );
    await source.saveProject(
      Project(
        id: 'reno',
        spaceId: 'work',
        contextId: 'cafe',
        name: 'Renovation',
        colorValue: 0xFF2FA98F,
        imagePath: projectImage.path,
      ),
    );

    // The target already owns a cached image; a replacement must keep the
    // local cache so delayed peers and the new rows can still resolve it.
    final oldImage = await writePng(pictures, 'old.png', secondPng);
    await target.saveContext(
      PlannerContext(
        id: 'old-target',
        spaceId: 'home',
        name: 'Old target',
        colorValue: 0xFF5B7F6B,
        imagePath: oldImage.path,
      ),
    );

    final staged = await targetEngine.stageSnapshot(sourcePeer, localDeviceId: 'target');
    await targetEngine.stageMedia(staged, sourcePeer, localDeviceId: 'target');
    await targetStore.applyReplacement(staged, peerDeviceId: 'source');

    final context = (await target.watchContexts().first).single;
    expect(context.id, 'cafe');
    expect(context.imagePath, isNotNull);
    expect(File(context.imagePath!).readAsBytesSync(), tinyPng);
    final project = (await target.watchProjects().first).single;
    expect(project.id, 'reno');
    expect(project.imagePath, isNotNull);
    expect(File(project.imagePath!).readAsBytesSync(), secondPng);

    final cached = await target.select(target.mediaCacheRecords).get();
    expect(cached.map((row) => row.mediaId).toSet(), {
      MediaStore.hashBytes(tinyPng),
      MediaStore.hashBytes(secondPng),
    });
    for (final row in cached) {
      expect(File(row.path).existsSync(), isTrue);
    }

    expect(await target.readIdentity(), isNotNull);
    expect((await target.readPairedDevices()).single.id, 'source');
  });

  test('a replacement aborts when staged media cannot be verified', () async {
    await seedSource();
    await seedTarget();
    final image = await writePng(pictures, 'cafe.png', tinyPng);
    await source.saveContext(
      PlannerContext(
        id: 'cafe',
        spaceId: 'work',
        name: 'Cafe',
        colorValue: 0xFF2F7ED8,
        imagePath: image.path,
      ),
    );

    final staged = await targetEngine.stageSnapshot(sourcePeer, localDeviceId: 'target');
    final before = await target.syncDeviceState();

    // The source lost its bytes after the snapshot was taken.
    final cache = Directory('${sourceMedia.path}/cache');
    if (cache.existsSync()) await cache.delete(recursive: true);
    await source.customStatement('DELETE FROM media_cache_records');

    await expectLater(
      targetEngine.stageMedia(staged, sourcePeer, localDeviceId: 'target'),
      throwsA(isA<SyncProtocolException>()),
    );

    final after = await target.syncDeviceState();
    expect(after.nodeId, before.nodeId);
    expect(after.epoch, before.epoch);
    expect((await entries(target)).single.id, 'target-entry');
    expect(await target.watchContexts().first, isEmpty);
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
