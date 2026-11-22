import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/sync/device_certificate.dart';
import 'package:sundial/features/sync/identity_service.dart';
import 'package:sundial/features/sync/lan_client.dart';
import 'package:sundial/features/sync/lan_server.dart';
import 'package:sundial/features/sync/pairing_crypto.dart';
import 'package:sundial/features/sync/peer_discovery.dart';
import 'package:sundial/features/sync/sync_engine.dart';
import 'package:sundial/features/sync/sync_service.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/services/planner_repository.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  late LocalIdentity hostIdentity;
  late LocalIdentity guestIdentity;
  late AppDatabase hostDb;
  late AppDatabase guestDb;
  late LanServer hostServer;
  late SyncService service;
  late _FakeDiscovery discovery;
  var backupCalls = 0;
  var backupFails = false;
  final now = DateTime.utc(2026, 11, 9, 12);

  setUpAll(() async {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    hostIdentity = await _identity('host', 'Host');
    guestIdentity = await _identity('guest', 'Phone');
  });

  setUp(() async {
    backupCalls = 0;
    backupFails = false;
    hostDb = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    guestDb = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await hostDb.seedDefaults();
    await guestDb.seedDefaults();
    await guestDb.saveIdentity(guestIdentity);
    await guestDb.saveEntry(
      Entry(
        id: 'local',
        spaceId: 'home',
        title: 'Local plan',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await hostDb.saveEntry(
      Entry(
        id: 'remote',
        spaceId: 'personal',
        title: 'Remote plan',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final sharedKey = PairingCrypto.newSharedKey();
    hostServer = LanServer(
      repository: PlannerRepository(hostDb),
      syncStore: SyncStore(hostDb),
      deviceTimeZone: () => 'Europe/Madrid',
      clock: () => now,
    );
    await hostServer.start(identity: hostIdentity, address: InternetAddress.loopbackIPv4);
    await hostDb.savePairedDevice(
      PairedDevice(
        id: guestIdentity.deviceId,
        name: guestIdentity.deviceName,
        username: guestIdentity.username,
        certificateFingerprint: fingerprintOfPemSync(guestIdentity.certificatePem),
        sharedKey: sharedKey,
        host: '127.0.0.1',
        port: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await guestDb.savePairedDevice(
      PairedDevice(
        id: hostIdentity.deviceId,
        name: hostIdentity.deviceName,
        username: hostIdentity.username,
        certificateFingerprint: fingerprintOfPemSync(hostIdentity.certificatePem),
        sharedKey: sharedKey,
        host: '127.0.0.1',
        port: hostServer.port,
        lastSeenAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );

    discovery = _FakeDiscovery();
    service = SyncService(
      repository: PlannerRepository(guestDb),
      identityService: IdentityService(PlannerRepository(guestDb)),
      client: LanClient(PlannerRepository(guestDb), clock: () => now),
      server: LanServer(
        repository: PlannerRepository(guestDb),
        syncStore: SyncStore(guestDb),
        deviceTimeZone: () => 'Europe/Madrid',
        clock: () => now,
      ),
      discovery: discovery,
      store: SyncStore(guestDb),
      engine: SyncEngine(
        store: SyncStore(guestDb),
        transport: LanClient(PlannerRepository(guestDb), clock: () => now),
      ),
      backupBeforeReplace: () async {
        backupCalls++;
        if (backupFails) throw StateError('no space for a backup');
      },
      clock: () => now,
      pairingPollInterval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await service.close();
    await hostServer.dispose();
    await hostDb.close();
    await guestDb.close();
  });

  test('starts the server, discovers a peer and refreshes its snapshot', () async {
    await service.start();
    expect(service.state.value.running, isTrue);
    expect(service.state.value.port, greaterThan(0));
    expect(discovery.started, isTrue);
    expect(service.state.value.snapshots[hostIdentity.deviceId]!.todayEntries, contains('Remote plan'));
    expect(service.state.value.snapshots[hostIdentity.deviceId]!.payload['spaces'], isNotEmpty);

    discovery.emit(
      DiscoveredPeer(
        deviceName: hostIdentity.deviceName,
        fingerprint: fingerprintOfPemSync(hostIdentity.certificatePem),
        host: '127.0.0.1',
        port: hostServer.port,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      service.state.value.discovered.map((peer) => peer.fingerprint),
      contains(fingerprintOfPemSync(hostIdentity.certificatePem)),
    );

    await service.stop();
    expect(service.state.value.running, isFalse);
    expect(discovery.stopped, isTrue);
  });

  test('requests pairing, waits for approval and completes the key exchange', () async {
    await guestDb.removePairedDevice(hostIdentity.deviceId);
    await service.start();

    await service.requestPairing(host: '127.0.0.1', port: hostServer.port, displayName: 'Host');
    expect(service.state.value.pairing.outgoing, isNotNull);

    final incoming = hostServer.pendingPairingRequest;
    expect(incoming, isNotNull);
    expect(incoming!.deviceId, guestIdentity.deviceId);
    expect(incoming.datasetMatches, isFalse);
    hostServer.approvePairingRequest(incoming.id);

    for (var index = 0; index < 500; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (service.state.value.pairing.lastPairedDeviceName != null) break;
    }

    expect(service.state.value.pairing.error, isNull, reason: service.state.value.pairing.error);
    expect(service.state.value.pairing.lastPairedDeviceName, 'Host');
    expect(service.state.value.pairing.outgoing, isNull);
    expect(service.state.value.pairing.lastPairedDatasetMatches, isFalse);
    final devices = await guestDb.readPairedDevices();
    expect(devices.single.id, hostIdentity.deviceId);
    for (var index = 0; index < 500; index++) {
      if (service.state.value.snapshots.containsKey(hostIdentity.deviceId)) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final deviceError = service.state.value.deviceErrors[hostIdentity.deviceId];
    expect(deviceError, isNull, reason: deviceError);
    expect(service.state.value.snapshots[hostIdentity.deviceId], isNotNull);
    expect(service.state.value.snapshots[hostIdentity.deviceId]!.todayEntries, contains('Remote plan'));
  });

  test('pulls and merges a real replica when the dataset matches', () async {
    final hostState = await hostDb.syncDeviceState();
    await guestDb.customStatement("UPDATE sync_device_state_records SET dataset_id = ? WHERE id = 'local'", [
      hostState.datasetId,
    ]);

    await service.start();

    final day = LocalDate.parse('2026-11-09');
    final entries = await guestDb.watchEntriesBetween(day, day, 'Europe/Madrid').first;
    expect(entries.map((entry) => entry.entry.id), containsAll(['local', 'remote']));
    final peer = service.state.value.peers[hostIdentity.deviceId];
    expect(peer, isNotNull);
    expect(peer!.needsSource, isFalse);
    expect(peer.lastError, isNull);
    expect(service.state.value.deviceErrors, isEmpty);

    final remote = (await hostDb.readEntry('remote'))!;
    await hostDb.saveEntry(remote.copyWith(title: 'Remote plan updated'));
    await service.refresh();

    expect((await guestDb.readEntry('remote'))!.title, 'Remote plan updated');
  });

  test('replaces this device from a chosen source after a backup', () async {
    await service.start();

    await service.replaceFromPeer(hostIdentity.deviceId, '4821');

    expect(backupCalls, 1);
    final day = LocalDate.parse('2026-11-09');
    final entries = await guestDb.watchEntriesBetween(day, day, 'Europe/Madrid').first;
    expect(entries.map((entry) => entry.entry.id), ['remote']);
    expect(await guestDb.readIdentity(), isNotNull);
    expect((await guestDb.readPairedDevices()).single.id, hostIdentity.deviceId);
    expect(service.state.value.replacing, isFalse);
    final peer = service.state.value.peers[hostIdentity.deviceId]!;
    expect(peer.needsSource, isFalse);
    expect(peer.lastError, isNull);
  });

  test('aborts a replacement when the backup fails', () async {
    await service.start();
    backupFails = true;

    await expectLater(service.replaceFromPeer(hostIdentity.deviceId, '4821'), throwsA(isA<StateError>()));

    expect(backupCalls, 1);
    final day = LocalDate.parse('2026-11-09');
    final entries = await guestDb.watchEntriesBetween(day, day, 'Europe/Madrid').first;
    expect(entries.single.entry.id, 'local');
    expect(service.state.value.replacing, isFalse);
  });

  test('requires the local PIN before replacing', () async {
    await service.start();

    await expectLater(
      service.replaceFromPeer(hostIdentity.deviceId, '0000'),
      throwsA(isA<IdentityException>()),
    );

    expect(backupCalls, 0);
    final day = LocalDate.parse('2026-11-09');
    final entries = await guestDb.watchEntriesBetween(day, day, 'Europe/Madrid').first;
    expect(entries.single.entry.id, 'local');
  });

  test('keeps the last read-only snapshot across a restart', () async {
    await service.start();
    expect(service.state.value.snapshots[hostIdentity.deviceId], isNotNull);
    await service.stop();
    await hostServer.stop();

    final restarted = SyncService(
      repository: PlannerRepository(guestDb),
      identityService: IdentityService(PlannerRepository(guestDb)),
      client: LanClient(PlannerRepository(guestDb), clock: () => now),
      server: LanServer(
        repository: PlannerRepository(guestDb),
        syncStore: SyncStore(guestDb),
        deviceTimeZone: () => 'Europe/Madrid',
        clock: () => now,
      ),
      discovery: _FakeDiscovery(),
      store: SyncStore(guestDb),
      engine: SyncEngine(
        store: SyncStore(guestDb),
        transport: LanClient(PlannerRepository(guestDb), clock: () => now),
      ),
      clock: () => now,
    );
    addTearDown(restarted.close);
    await restarted.start();

    final snapshot = restarted.state.value.snapshots[hostIdentity.deviceId];
    expect(snapshot, isNotNull);
    expect(snapshot!.todayEntries, contains('Remote plan'));
    expect(snapshot.payload['range'], isNotNull);
    expect(restarted.state.value.deviceErrors[hostIdentity.deviceId], isNotNull);
  });

  test('keeps the local plan when the peer is offline', () async {
    await service.start();
    await hostServer.stop();
    await service.refresh();
    expect(service.state.value.deviceErrors[hostIdentity.deviceId], isNotNull);
    final local = await guestDb
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(local.single.entry.title, 'Local plan');
  });

  test('reports a missing identity without failing', () async {
    await guestDb.customSelect('DELETE FROM identity_records').get();
    final empty = SyncService(
      repository: PlannerRepository(guestDb),
      identityService: IdentityService(PlannerRepository(guestDb)),
      client: LanClient(PlannerRepository(guestDb), clock: () => now),
      server: LanServer(
        repository: PlannerRepository(guestDb),
        syncStore: SyncStore(guestDb),
        deviceTimeZone: () => 'Europe/Madrid',
        clock: () => now,
      ),
      discovery: _FakeDiscovery(),
      store: SyncStore(guestDb),
      engine: SyncEngine(
        store: SyncStore(guestDb),
        transport: LanClient(PlannerRepository(guestDb), clock: () => now),
      ),
      clock: () => now,
    );
    await empty.start();
    expect(empty.state.value.running, isFalse);
    expect(empty.state.value.error, 'identity_required');
    await empty.close();
  });
}

class _FakeDiscovery implements PeerDiscovery {
  final _peers = StreamController<DiscoveredPeer>.broadcast();
  bool started = false;
  bool stopped = false;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start({required LocalIdentity identity, required int port, required String host}) async {
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> dispose() => _peers.close();

  void emit(DiscoveredPeer peer) => _peers.add(peer);
}

Future<LocalIdentity> _identity(String id, String name) async {
  final certificate = await generateDeviceCertificate(deviceId: id);
  final now = DateTime.utc(2026, 11, 9, 8);
  final salt = PairingCrypto.newPinSalt();
  final hash = await PairingCrypto.hashPin('4821', saltBase64: salt);
  return LocalIdentity(
    deviceId: id,
    deviceName: name,
    username: 'tester',
    pinSalt: salt,
    pinHash: hash,
    certificatePem: certificate.certificatePem,
    privateKeyPem: certificate.privateKeyPem,
    mcpToken: 'token-$id',
    createdAt: now,
    updatedAt: now,
  );
}
