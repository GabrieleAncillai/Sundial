import 'dart:ffi';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/sync/sync_clock.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
  });

  late AppDatabase database;
  late SyncStore store;
  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
    store = SyncStore(database);
  });

  tearDown(() => database.close());

  Entry entry() => Entry(
    id: 'dentist',
    spaceId: 'personal',
    title: 'Dentist',
    date: day,
    allDay: true,
    createdAt: now,
    updatedAt: now,
  );

  test('the change feed carries the HLC of every changed field group', () async {
    final before = await store.readDebugSnapshot();
    await database.saveEntry(entry());
    final created = await store.readDebugSnapshot();

    expect(created.counts.changes, greaterThan(before.counts.changes));
    final change = created.changes.firstWhere((item) => item.entity == 'entry' && item.rowKey == 'dentist');
    expect(change.isDelete, isFalse);
    expect(change.fieldVersions.keys, containsAll(['title', 'notes', 'timing']));
    for (final version in change.versions.values) {
      expect(SyncHlc.tryParse(version), isNotNull);
    }
    expect(change.row['title'], 'Dentist');

    final state = await database.syncDeviceState();
    expect(created.device.nodeId, state.nodeId);
    expect(created.device.datasetId, state.datasetId);
    expect(created.device.epoch, state.epoch);
  });

  test('an update appends only the changed field and the newest change is first', () async {
    await database.saveEntry(entry());
    await database.saveEntry(
      entry().copyWith(title: 'Dentist moved', updatedAt: now.add(const Duration(minutes: 1))),
    );
    final snapshot = await store.readDebugSnapshot();

    expect(snapshot.changes.length, greaterThanOrEqualTo(2));
    expect(snapshot.changes.first.seq, greaterThan(snapshot.changes.last.seq));
    final titled = snapshot.changes.firstWhere((item) => item.entity == 'entry' && item.rowKey == 'dentist');
    expect(titled.fieldVersions.keys.toSet(), {'title'});
  });

  test('a delete writes a tombstone and a delete change', () async {
    await database.saveEntry(entry());
    await database.softDeleteEntry('dentist');
    final snapshot = await store.readDebugSnapshot();

    final change = snapshot.changes.firstWhere((item) => item.entity == 'entry' && item.rowKey == 'dentist');
    expect(change.isDelete, isTrue);
    expect(SyncHlc.tryParse(change.deletedVersion!), isNotNull);
    expect(snapshot.tombstones.any((item) => item.entity == 'entry' && item.rowKey == 'dentist'), isTrue);
    expect(
      snapshot.fields.any(
        (item) => item.entity == 'entry' && item.rowKey == 'dentist' && item.field == 'title',
      ),
      isTrue,
    );
  });

  test('peer cursors and caps are exposed without changing the feed', () async {
    await database.saveEntry(entry());
    await database.saveEntry(
      Entry(
        id: 'call',
        spaceId: 'personal',
        title: 'Call',
        date: day,
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final state = await database.syncDeviceState();
    await store.recordPeerSuccess(
      peerDeviceId: 'phone',
      datasetId: state.datasetId,
      peerEpoch: 'epoch-1',
      lastPulledSeq: 42,
    );

    final snapshot = await store.readDebugSnapshot(changeLimit: 1);
    expect(snapshot.changes.length, 1);
    expect(snapshot.counts.changes, greaterThanOrEqualTo(2));
    expect(snapshot.peers.single.peerDeviceId, 'phone');
    expect(snapshot.peers.single.lastPulledSeq, 42);
    expect(snapshot.peers.single.datasetId, state.datasetId);
  });

  test('the debug watch starts with a snapshot', () async {
    await database.saveEntry(entry());
    final snapshot = await store.watchDebugSnapshot(changeLimit: 1).first;

    expect(snapshot.device.nodeId, isNotEmpty);
    expect(snapshot.changes.length, 1);
  });
}
