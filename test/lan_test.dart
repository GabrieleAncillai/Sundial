import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value, Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/media/media_store.dart';
import 'package:sundial/features/sync/device_certificate.dart';
import 'package:sundial/features/sync/lan_client.dart';
import 'package:sundial/features/sync/lan_server.dart';
import 'package:sundial/features/sync/pairing_crypto.dart';
import 'package:sundial/features/sync/sync_models.dart';
import 'package:sundial/features/sync/sync_store.dart';
import 'package:sundial/features/sync/pairing_request.dart';
import 'package:sundial/models/local_identity.dart';
import 'package:sundial/models/paired_device.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/services/planner_repository.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

import 'support/media_fixture.dart';

void main() {
  late LocalIdentity hostIdentity;
  late LocalIdentity guestIdentity;
  late DateTime now;
  late AppDatabase hostDb;
  late AppDatabase guestDb;
  late LanServer server;
  late LanClient client;
  late Directory hostMedia;
  late Directory guestMedia;

  setUpAll(() async {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    hostIdentity = await _identity('host', 'Host', 'tester');
    guestIdentity = await _identity('guest', 'Phone', 'tester');
  });

  setUp(() async {
    now = DateTime.utc(2026, 11, 9, 12);
    hostMedia = await Directory.systemTemp.createTemp('sundial-host-media');
    guestMedia = await Directory.systemTemp.createTemp('sundial-guest-media');
    hostDb = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: hostMedia),
    );
    guestDb = AppDatabase(
      NativeDatabase.memory(),
      defaultTimeZone: 'Europe/Madrid',
      mediaStore: MediaStore(directory: guestMedia),
    );
    await hostDb.seedDefaults();
    await hostDb.saveEntry(
      Entry(
        id: 'passport',
        spaceId: 'personal',
        title: 'Renew passport',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    server = LanServer(
      repository: PlannerRepository(hostDb),
      syncStore: SyncStore(hostDb),
      deviceTimeZone: () => 'Europe/Madrid',
      clock: () => now,
    );
    await server.start(identity: hostIdentity, address: InternetAddress.loopbackIPv4);
    client = LanClient(PlannerRepository(guestDb), clock: () => now);
  });

  tearDown(() async {
    await server.dispose();
    await hostDb.close();
    await guestDb.close();
    for (final directory in [hostMedia, guestMedia]) {
      if (directory.existsSync()) await directory.delete(recursive: true);
    }
  });

  Future<OutgoingPairingRequest> requestPairing({
    bool approve = false,
    String datasetId = 'dataset-guest',
  }) async {
    final request = await client.requestPairing(
      identity: guestIdentity,
      myFingerprint: fingerprintOfPemSync(guestIdentity.certificatePem),
      host: '127.0.0.1',
      port: server.port,
      myServerPort: 0,
      datasetId: datasetId,
      hasUserData: false,
      displayName: 'Host',
    );
    if (approve) {
      expect(server.approvePairingRequest(request.id), isNotNull);
    }
    return request;
  }

  Future<PairingStatus> readStatus(OutgoingPairingRequest request) => client.readPairRequest(
    requestId: request.id,
    host: '127.0.0.1',
    port: server.port,
    pinnedFingerprint: request.certificateFingerprint,
  );

  Future<PairingResult> complete(OutgoingPairingRequest request, {String? approvalToken}) async {
    final status = approvalToken == null ? await readStatus(request) : null;
    final token = approvalToken ?? status!.approvalToken;
    if (token == null) throw const LanClientException('The pairing request was not approved');
    return client.completePairing(
      identity: guestIdentity,
      myFingerprint: fingerprintOfPemSync(guestIdentity.certificatePem),
      host: '127.0.0.1',
      port: server.port,
      code: request.code,
      requestId: request.id,
      approvalToken: token,
      expectedFingerprint: request.certificateFingerprint,
      myServerPort: 0,
    );
  }

  Future<PairedDevice> pairHost() async {
    final request = await requestPairing(approve: true);
    final result = await complete(request);
    return result.device;
  }

  test('the unauthenticated info endpoint does not leak identity', () async {
    final http = HttpClient()..badCertificateCallback = (_, _, _) => true;
    try {
      final request = await http.getUrl(
        Uri(scheme: 'https', host: '127.0.0.1', port: server.port, path: '/sundial/v1/info'),
      );
      final response = await request.close();
      final body = jsonDecode(await utf8.decoder.bind(response).join()) as Map<String, dynamic>;
      expect(body['app'], 'sundial');
      expect(body['protocol'], 4);
      expect(body.containsKey('deviceId'), isFalse);
      expect(body.containsKey('deviceName'), isFalse);
      expect(body.containsKey('username'), isFalse);
      expect(body['fingerprint'], isNotEmpty);
    } finally {
      http.close(force: true);
    }
  });

  test('pairs two devices and answers an authenticated summary', () async {
    final host = await pairHost();
    expect(host.name, 'Host');
    expect(host.host, '127.0.0.1');
    expect(host.port, server.port);

    final hostSide = (await hostDb.readPairedDevices()).single;
    expect(hostSide.id, 'guest');
    expect(hostSide.certificateFingerprint, fingerprintOfPemSync(guestIdentity.certificatePem));
    expect(hostSide.sharedKey, host.sharedKey);

    final summary = await client.summary(host, localDeviceId: guestIdentity.deviceId);
    expect(summary['date'], '2026-11-09');
    final today = Map<String, Object?>.from(summary['today'] as Map);
    final entries = (today['entries'] as List).cast<Map<String, Object?>>();
    expect(entries.single['entry'], isA<Map>());
    expect((entries.single['entry'] as Map)['title'], 'Renew passport');
    expect(summary['openShopping'], 0);
  });

  test('serves signed sync snapshot and change pages after pairing', () async {
    final host = await pairHost();

    final rows = <SyncRowPayload>[];
    String? cursor;
    do {
      final page = await client.fetchSnapshot(
        host,
        localDeviceId: guestIdentity.deviceId,
        cursor: cursor,
        limit: 2,
      );
      expect(page.datasetId, isNotEmpty);
      expect(page.epoch, isNotEmpty);
      rows.addAll(page.rows);
      cursor = page.cursor;
    } while (cursor != null);

    expect(rows.any((row) => row.entity == 'entry' && row.key == 'passport'), isTrue);

    final changes = await client.fetchChanges(
      host,
      localDeviceId: guestIdentity.deviceId,
      since: 0,
      limit: 10,
    );
    expect(changes.changes, isNotEmpty);
    expect(changes.nextSince, greaterThan(0));
  });

  test('a pairing request must be approved before the key exchange', () async {
    final request = await requestPairing();
    final pending = await readStatus(request);
    expect(pending.status, PairingRequestStatus.pending);
    expect(pending.approvalToken, isNull);
    await expectLater(complete(request), throwsA(isA<LanClientException>()));
    expect(await hostDb.readPairedDevices(), isEmpty);
    expect(await guestDb.readPairedDevices(), isEmpty);
  });

  test('rejects a pairing request without side effects', () async {
    final request = await requestPairing();
    expect(server.rejectPairingRequest(request.id), isNotNull);
    final status = await readStatus(request);
    expect(status.status, PairingRequestStatus.rejected);
    expect(status.approvalToken, isNull);
    await expectLater(complete(request), throwsA(isA<LanClientException>()));
    expect(await hostDb.readPairedDevices(), isEmpty);
  });

  test('expires a pairing request after five minutes', () async {
    final request = await requestPairing();
    now = now.add(const Duration(minutes: 6));
    final status = await readStatus(request);
    expect(status.status, PairingRequestStatus.expired);
    expect(server.pendingPairingRequest, isNull);
    await expectLater(complete(request), throwsA(isA<LanClientException>()));
  });

  test('holds one pending request at a time', () async {
    await requestPairing();
    await expectLater(
      client.requestPairing(
        identity: guestIdentity,
        myFingerprint: fingerprintOfPemSync(guestIdentity.certificatePem),
        host: '127.0.0.1',
        port: server.port,
        myServerPort: 0,
        datasetId: 'dataset-guest',
        hasUserData: false,
      ),
      throwsA(isA<LanClientException>()),
    );
  });

  test('reports whether the requesting device shares the plan', () async {
    final hostDataset = await hostDb.ensureSyncDatasetId();
    await requestPairing();
    expect(server.pendingPairingRequest!.datasetMatches, isFalse);
    server.rejectPairingRequest(server.pendingPairingRequest!.id);
    await requestPairing(datasetId: hostDataset);
    expect(server.pendingPairingRequest!.datasetMatches, isTrue);
  });

  test('refuses a request from a different username', () async {
    final other = await _identity('other', 'Other', 'somebody');
    await expectLater(
      client.requestPairing(
        identity: other,
        myFingerprint: fingerprintOfPemSync(other.certificatePem),
        host: '127.0.0.1',
        port: server.port,
        myServerPort: 0,
        datasetId: 'dataset-other',
        hasUserData: false,
      ),
      throwsA(isA<LanClientException>()),
    );
    expect(server.pendingPairingRequest, isNull);
  });

  test('rate limits repeated pairing requests', () async {
    for (var index = 0; index < 5; index++) {
      final request = await requestPairing();
      server.rejectPairingRequest(request.id);
    }
    await expectLater(requestPairing(), throwsA(isA<LanClientException>()));
  });

  test('refuses to pair with a protocol-3 peer', () async {
    final context = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(hostIdentity.certificatePem))
      ..usePrivateKeyBytes(utf8.encode(hostIdentity.privateKeyPem));
    final old = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
    addTearDown(() => old.close(force: true));
    old.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'app': 'sundial',
          'protocol': 3,
          'fingerprint': fingerprintOfPemSync(hostIdentity.certificatePem),
          'port': old.port,
        }),
      );
      await request.response.close();
    });

    await expectLater(
      client.requestPairing(
        identity: guestIdentity,
        myFingerprint: fingerprintOfPemSync(guestIdentity.certificatePem),
        host: '127.0.0.1',
        port: old.port,
        myServerPort: 0,
        datasetId: 'dataset-guest',
        hasUserData: false,
      ),
      throwsA(isA<LanClientException>().having((error) => error.message, 'message', contains('update'))),
    );
  });

  test('pairs after approval and records the peer', () async {
    final host = await pairHost();
    expect(host.name, 'Host');
    expect(host.host, '127.0.0.1');
    expect(host.port, server.port);
    final hostSide = (await hostDb.readPairedDevices()).single;
    expect(hostSide.id, 'guest');
    expect(hostSide.certificateFingerprint, fingerprintOfPemSync(guestIdentity.certificatePem));
    expect(hostSide.sharedKey, host.sharedKey);
    expect(server.pendingPairingRequest, isNull);
  });

  test('answers each signed request once and rejects a replay', () async {
    final host = await pairHost();
    final path = Uri(path: '/sundial/v1/query', queryParameters: {'resource': 'summary'}).toString();
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    const nonce = 'replay-test-nonce';
    final signature = await PairingCrypto.signRequest(
      sharedKeyBase64: host.sharedKey,
      method: 'GET',
      path: path,
      timestamp: timestamp,
      nonce: nonce,
      body: '',
    );

    Future<int> send() async {
      final raw = HttpClient()..badCertificateCallback = (certificate, host, port) => true;
      try {
        final request = await raw.getUrl(
          Uri(
            scheme: 'https',
            host: '127.0.0.1',
            port: server.port,
            path: '/sundial/v1/query',
            queryParameters: {'resource': 'summary'},
          ),
        );
        request.headers.set('x-sundial-device', guestIdentity.deviceId);
        request.headers.set('x-sundial-timestamp', '$timestamp');
        request.headers.set('x-sundial-nonce', nonce);
        request.headers.set('x-sundial-signature', signature);
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        raw.close(force: true);
      }
    }

    expect(await send(), HttpStatus.ok);
    expect(await send(), HttpStatus.unauthorized);
  });

  test('rejects a query signed with another key', () async {
    final host = await pairHost();
    final tampered = host.copyWith(sharedKey: PairingCrypto.randomBase64(32));
    await expectLater(
      client.summary(tampered, localDeviceId: guestIdentity.deviceId),
      throwsA(isA<LanClientException>()),
    );
  });

  test('pins the certificate and refuses a different one', () async {
    final host = await pairHost();
    final tampered = host.copyWith(certificateFingerprint: '0' * 64);
    await expectLater(
      client.summary(tampered, localDeviceId: guestIdentity.deviceId),
      throwsA(isA<LanClientException>()),
    );
  });

  test('reports an offline device without touching local data', () async {
    final host = (await pairHost()).copyWith(port: 1);
    await expectLater(
      client.summary(host, localDeviceId: guestIdentity.deviceId),
      throwsA(isA<LanClientException>()),
    );
    final local = await hostDb
        .watchEntriesBetween(LocalDate.parse('2026-11-09'), LocalDate.parse('2026-11-09'), 'Europe/Madrid')
        .first;
    expect(local.single.entry.title, 'Renew passport');
  });

  // ---------------------------------------------------------------------------
  // Media endpoint

  Future<({String mediaId, String path})> seedHostImage() async {
    final pictures = await Directory.systemTemp.createTemp('sundial-lan-pictures');
    addTearDown(() async {
      if (pictures.existsSync()) await pictures.delete(recursive: true);
    });
    final file = await writePng(pictures, 'cafe.png', tinyPng);
    await hostDb.saveContext(
      PlannerContext(id: 'cafe', spaceId: 'work', name: 'Cafe', colorValue: 0xFF2F7ED8, imagePath: file.path),
    );
    final row = await hostDb
        .customSelect(
          'SELECT image_media_id FROM context_records WHERE id = ?',
          variables: [Variable.withString('cafe')],
        )
        .getSingle();
    return (mediaId: row.read<String>('image_media_id'), path: file.path);
  }

  Future<String> registerRawMedia(Uint8List bytes) async {
    final id = MediaStore.hashBytes(bytes);
    final cache = Directory('${hostMedia.path}/cache');
    if (!cache.existsSync()) await cache.create(recursive: true);
    final file = File('${cache.path}/$id.png');
    await file.writeAsBytes(bytes, flush: true);
    await hostDb
        .into(hostDb.mediaCacheRecords)
        .insert(
          MediaCacheRecordsCompanion(
            mediaId: Value(id),
            path: Value(file.path),
            mime: Value(MediaStore.mime),
            byteSize: Value(bytes.length),
            createdAt: Value(now),
          ),
        );
    return id;
  }

  test('serves a paired signed media fetch by content address', () async {
    final host = await pairHost();
    final seeded = await seedHostImage();

    final response = await client.fetchMedia(
      host,
      localDeviceId: guestIdentity.deviceId,
      ids: [seeded.mediaId],
    );

    expect(response.missing, isEmpty);
    final item = response.media.single;
    expect(item.id, seeded.mediaId);
    expect(item.mime, MediaStore.mime);
    expect(item.bytes, tinyPng);
    expect(item.byteSize, tinyPng.length);
    final wire = jsonEncode(response.toJson());
    expect(wire, isNot(contains('path')));
    expect(wire, isNot(contains(hostMedia.path)));
    expect(wire, isNot(contains(seeded.path)));
  });

  test('reports unknown ids as missing', () async {
    final host = await pairHost();
    final unknown = 'a' * 64;

    final response = await client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: [unknown]);

    expect(response.media, isEmpty);
    expect(response.missing, [unknown]);
  });

  test('rejects paths, malformed ids and too many ids', () async {
    final host = await pairHost();

    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: ['../../etc/passwd']),
      throwsA(isA<LanClientException>()),
    );
    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: ['A' * 64]),
      throwsA(isA<LanClientException>()),
    );
    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: ['a' * 65]),
      throwsA(isA<LanClientException>()),
    );
    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: ['../media/cache']),
      throwsA(isA<LanClientException>()),
    );
    final tooMany = List.generate(33, (index) => index.toRadixString(16).padLeft(64, '0'));
    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: tooMany),
      throwsA(isA<LanClientException>()),
    );
  });

  test('refuses media for an unpaired or tampered device', () async {
    final host = await pairHost();
    final seeded = await seedHostImage();

    await expectLater(
      client.fetchMedia(
        host.copyWith(sharedKey: PairingCrypto.randomBase64(32)),
        localDeviceId: guestIdentity.deviceId,
        ids: [seeded.mediaId],
      ),
      throwsA(isA<LanClientException>()),
    );
    await expectLater(
      client.fetchMedia(host, localDeviceId: 'stranger', ids: [seeded.mediaId]),
      throwsA(isA<LanClientException>()),
    );
  });

  test('rejects a replayed media request', () async {
    final host = await pairHost();
    final seeded = await seedHostImage();
    final body = jsonEncode({
      'ids': [seeded.mediaId],
    });
    final timestamp = now.millisecondsSinceEpoch ~/ 1000;
    const nonce = 'media-replay-nonce';
    final signature = await PairingCrypto.signRequest(
      sharedKeyBase64: host.sharedKey,
      method: 'POST',
      path: '/sundial/v1/sync/media',
      timestamp: timestamp,
      nonce: nonce,
      body: body,
    );

    Future<int> send() async {
      final raw = HttpClient()..badCertificateCallback = (certificate, host, port) => true;
      try {
        final request = await raw.postUrl(
          Uri(scheme: 'https', host: '127.0.0.1', port: server.port, path: '/sundial/v1/sync/media'),
        );
        request.headers.contentType = ContentType.json;
        request.headers.set('x-sundial-device', guestIdentity.deviceId);
        request.headers.set('x-sundial-timestamp', '$timestamp');
        request.headers.set('x-sundial-nonce', nonce);
        request.headers.set('x-sundial-signature', signature);
        request.write(body);
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        raw.close(force: true);
      }
    }

    expect(await send(), HttpStatus.ok);
    expect(await send(), HttpStatus.unauthorized);
  });

  test('rejects an oversized image and an oversized response', () async {
    final host = await pairHost();
    final oversized = Uint8List(MediaStore.maxBytes + 1)
      ..[0] = 0x89
      ..[1] = 0x50
      ..[2] = 0x4e
      ..[3] = 0x47
      ..[4] = 0x0d
      ..[5] = 0x0a
      ..[6] = 0x1a
      ..[7] = 0x0a;
    final oversizedId = await registerRawMedia(oversized);
    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: [oversizedId]),
      throwsA(isA<LanClientException>()),
    );

    final first = Uint8List(MediaStore.maxBytes)
      ..[0] = 0x89
      ..[1] = 0x50
      ..[2] = 0x4e
      ..[3] = 0x47
      ..[4] = 0x0d
      ..[5] = 0x0a
      ..[6] = 0x1a
      ..[7] = 0x0a;
    final second = Uint8List.fromList(first)..[64] = 1;
    final firstId = await registerRawMedia(first);
    final secondId = await registerRawMedia(second);
    await expectLater(
      client.fetchMedia(host, localDeviceId: guestIdentity.deviceId, ids: [firstId, secondId, oversizedId]),
      throwsA(isA<LanClientException>()),
    );
  });

  test('a snapshot never carries an image path', () async {
    final host = await pairHost();
    final seeded = await seedHostImage();

    final page = await client.fetchSnapshot(host, localDeviceId: guestIdentity.deviceId, limit: 500);
    final wire = jsonEncode(page.toJson());

    expect(wire, contains(seeded.mediaId));
    expect(wire, isNot(contains(seeded.path)));
    expect(wire, isNot(contains(hostMedia.path)));
    expect(wire, isNot(contains('image_path')));
  });
}

Future<LocalIdentity> _identity(String id, String name, String username) async {
  final certificate = await generateDeviceCertificate(deviceId: id);
  final now = DateTime.utc(2026, 11, 9, 8);
  return LocalIdentity(
    deviceId: id,
    deviceName: name,
    username: username,
    pinSalt: 'c2FsdA==',
    pinHash: 'aGFzaA==',
    certificatePem: certificate.certificatePem,
    privateKeyPem: certificate.privateKeyPem,
    mcpToken: 'token-$id',
    createdAt: now,
    updatedAt: now,
  );
}
