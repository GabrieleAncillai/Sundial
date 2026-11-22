import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../models/local_identity.dart';
import '../../models/paired_device.dart';
import '../../services/planner_repository.dart';
import 'pairing_crypto.dart';
import 'pairing_request.dart';
import 'sync_engine.dart';
import 'sync_models.dart';

class RemoteInfo {
  const RemoteInfo({required this.fingerprint, required this.port, required this.protocol});

  final String fingerprint;
  final int port;
  final int protocol;
}

class LanClientException implements Exception {
  const LanClientException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pinned HTTPS client for pairing and querying a peer.
class LanClient implements SyncTransport {
  LanClient(this._repository, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static const _timeout = Duration(seconds: 12);

  final PlannerRepository _repository;
  final DateTime Function() _clock;

  Future<RemoteInfo> fetchInfo({required String host, required int port}) async {
    final captured = <String>[];
    final client = _client(allowAny: true, captured: captured);
    try {
      final response = await _get(client, host, port, '/sundial/v1/info').timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw LanClientException('The device did not answer (${response.statusCode})');
      }
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic> || json['app'] != 'sundial') {
        throw const LanClientException('That address is not a Sundial device');
      }
      if (captured.isEmpty) throw const LanClientException('No certificate was presented');
      final info = RemoteInfo(
        fingerprint: captured.last,
        port: json['port'] is int ? json['port'] as int : port,
        protocol: json['protocol'] is int ? json['protocol'] as int : 0,
      );
      if (info.fingerprint != '${json['fingerprint']}') {
        throw const LanClientException('The certificate fingerprint did not match');
      }
      return info;
    } on TimeoutException {
      throw const LanClientException('The device did not answer in time');
    } on SocketException {
      throw const LanClientException('Could not reach the device on this network');
    } finally {
      client.close(force: true);
    }
  }

  /// Sends a pairing request to a peer. The peer must approve it locally with
  /// its PIN before [completePairing] can finish the key exchange.
  Future<OutgoingPairingRequest> requestPairing({
    required LocalIdentity identity,
    required String myFingerprint,
    required String host,
    required int port,
    required int myServerPort,
    required String datasetId,
    required bool hasUserData,
    String? displayName,
  }) async {
    final info = await fetchInfo(host: host, port: port);
    if (info.protocol < 4) {
      throw const LanClientException('The other device needs a Sundial update before it can pair');
    }

    final requestId = PairingCrypto.randomBase64Url(24);
    final code = PairingCrypto.newPairingCode();
    final client = _client(allowAny: false, pinnedFingerprint: info.fingerprint);
    try {
      final request = await client
          .postUrl(Uri(scheme: 'https', host: host, port: port, path: '/sundial/v1/pair/request'))
          .timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'requestId': requestId,
          'code': code,
          'username': identity.username,
          'deviceId': identity.deviceId,
          'deviceName': identity.deviceName,
          'fingerprint': myFingerprint,
          'port': myServerPort,
          'datasetId': datasetId,
          'hasUserData': hasUserData,
        }),
      );
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join();
      Map<String, dynamic>? errorBody;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) errorBody = decoded;
      } on FormatException {
        errorBody = null;
      }
      if (response.statusCode == HttpStatus.tooManyRequests) {
        throw const LanClientException('The other device is already handling a pairing request');
      }
      if (response.statusCode != HttpStatus.ok) {
        if (errorBody?['error'] == 'username_mismatch') {
          throw const LanClientException('Both devices must use the same username');
        }
        throw const LanClientException('The pairing request was not accepted');
      }
      final json = errorBody;
      if (json is! Map<String, dynamic> || json['ok'] != true || json['requestId'] != requestId) {
        throw const LanClientException('Unexpected answer from the device');
      }
      final expiresAt = DateTime.tryParse('${json['expiresAt']}')?.toUtc();
      if (expiresAt == null) {
        throw const LanClientException('Unexpected answer from the device');
      }
      return OutgoingPairingRequest(
        id: requestId,
        code: code,
        displayName: displayName?.trim().isNotEmpty == true ? displayName!.trim() : host,
        host: host,
        port: port,
        certificateFingerprint: info.fingerprint,
        expiresAt: expiresAt,
      );
    } on TimeoutException {
      throw const LanClientException('The device did not answer in time');
    } on SocketException {
      throw const LanClientException('Could not reach the device on this network');
    } on HandshakeException {
      throw const LanClientException('The device certificate changed');
    } finally {
      client.close(force: true);
    }
  }

  /// Reads the peer's decision for an outgoing request.
  Future<PairingStatus> readPairRequest({
    required String requestId,
    required String host,
    required int port,
    required String pinnedFingerprint,
  }) async {
    final client = _client(allowAny: false, pinnedFingerprint: pinnedFingerprint);
    try {
      final path = '/sundial/v1/pair/request/${Uri.encodeComponent(requestId)}';
      final request = await client.getUrl(Uri(scheme: 'https', host: host, port: port, path: path));
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.notFound) {
        return const PairingStatus(status: PairingRequestStatus.expired);
      }
      if (response.statusCode != HttpStatus.ok) {
        throw LanClientException('The device returned ${response.statusCode}');
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const LanClientException('Unexpected answer from the device');
      }
      final statusName = json['status'];
      PairingRequestStatus? status;
      for (final value in PairingRequestStatus.values) {
        if (value.name == statusName) {
          status = value;
          break;
        }
      }
      if (status == null) {
        throw const LanClientException('Unexpected answer from the device');
      }
      return PairingStatus(
        status: status,
        approvalToken: json['approvalToken'] is String ? json['approvalToken'] as String : null,
        deviceId: json['deviceId'] is String ? json['deviceId'] as String : null,
        deviceName: json['deviceName'] is String ? json['deviceName'] as String : null,
        username: json['username'] is String ? json['username'] as String : null,
        fingerprint: json['fingerprint'] is String ? json['fingerprint'] as String : null,
        port: json['port'] is int ? json['port'] as int : null,
        datasetId: json['datasetId'] is String ? json['datasetId'] as String : null,
        hasUserData: json['hasUserData'] is bool ? json['hasUserData'] as bool : null,
      );
    } on TimeoutException {
      throw const LanClientException('The device did not answer in time');
    } on SocketException {
      throw const LanClientException('The device is offline');
    } on HandshakeException {
      throw const LanClientException('The device certificate did not match the pinned one');
    } finally {
      client.close(force: true);
    }
  }

  Future<PairingResult> completePairing({
    required LocalIdentity identity,
    required String myFingerprint,
    required String host,
    required int port,
    required String code,
    required String requestId,
    required String approvalToken,
    required String expectedFingerprint,
    required int myServerPort,
  }) async {
    final info = await fetchInfo(host: host, port: port);
    if (info.fingerprint != expectedFingerprint) {
      throw const LanClientException('The device certificate changed during pairing');
    }

    final pairingKey = await PairingCrypto.derivePairingKey(
      code: code,
      hostFingerprint: info.fingerprint,
      guestFingerprint: myFingerprint,
      username: identity.username,
    );
    final sharedKey = PairingCrypto.newSharedKey();
    final encrypted = await PairingCrypto.encryptSharedKey(
      pairingKeyBase64: pairingKey,
      sharedKeyBase64: sharedKey,
    );
    final message = PairingCrypto.pairRequestMessage(
      hostFingerprint: info.fingerprint,
      guestFingerprint: myFingerprint,
      username: identity.username,
      guestDeviceId: identity.deviceId,
    );
    final mac = await PairingCrypto.hmacBase64(pairingKey, message);

    final client = _client(allowAny: false, pinnedFingerprint: info.fingerprint);
    try {
      final request = await client
          .postUrl(Uri(scheme: 'https', host: host, port: port, path: '/sundial/v1/pair'))
          .timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'requestId': requestId,
          'approvalToken': approvalToken,
          'username': identity.username,
          'deviceId': identity.deviceId,
          'deviceName': identity.deviceName,
          'fingerprint': myFingerprint,
          'port': myServerPort,
          'key': encrypted.toJson(),
          'mac': mac,
        }),
      );
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.forbidden) {
        throw const LanClientException('The pairing request was not approved');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw const LanClientException('The code was not accepted');
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic> || json['ok'] != true) {
        throw const LanClientException('The code was not accepted');
      }
      final hostDeviceId = json['deviceId'];
      final hostDeviceName = json['deviceName'];
      final hostUsername = json['username'];
      if (hostDeviceId is! String || hostDeviceName is! String || hostUsername is! String) {
        throw const LanClientException('The device did not identify itself after pairing');
      }
      if (hostDeviceId == identity.deviceId) {
        throw const LanClientException('That is this device');
      }
      if ('${json['fingerprint']}' != info.fingerprint) {
        throw const LanClientException('The device certificate changed during pairing');
      }
      final expectedAck = await PairingCrypto.hmacBase64(
        sharedKey,
        PairingCrypto.pairAckMessage(hostFingerprint: info.fingerprint, guestFingerprint: myFingerprint),
      );
      if (!PairingCrypto.constantTimeEquals(base64Decode(expectedAck), base64Decode('${json['mac']}'))) {
        throw const LanClientException('The device could not prove it stored the key');
      }
      final now = _clock().toUtc();
      final paired = PairedDevice(
        id: hostDeviceId,
        name: hostDeviceName,
        username: hostUsername,
        certificateFingerprint: info.fingerprint,
        sharedKey: sharedKey,
        host: host,
        port: port,
        lastSeenAt: now,
        createdAt: now,
        updatedAt: now,
      );
      await _repository.savePairedDevice(paired);
      return PairingResult(
        device: paired,
        datasetId: json['datasetId'] is String ? json['datasetId'] as String : '',
        hasUserData: json['hasUserData'] is bool && json['hasUserData'] as bool,
      );
    } on TimeoutException {
      throw const LanClientException('The device did not answer in time');
    } on SocketException {
      throw const LanClientException('Could not reach the device on this network');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, Object?>> summary(PairedDevice device, {required String localDeviceId}) async {
    final data = await query(device, localDeviceId: localDeviceId, resource: 'summary');
    return data is Map<String, Object?> ? data : <String, Object?>{};
  }

  Future<Map<String, Object?>> snapshot(PairedDevice device, {required String localDeviceId}) async {
    final data = await query(device, localDeviceId: localDeviceId, resource: 'snapshot');
    return data is Map<String, Object?> ? data : <String, Object?>{};
  }

  @override
  Future<SyncSnapshotPage> fetchSnapshot(
    PairedDevice device, {
    required String localDeviceId,
    String? cursor,
    int limit = 500,
  }) async {
    final json = await _postSigned(
      device,
      localDeviceId: localDeviceId,
      path: '/sundial/v1/sync/snapshot',
      body: {'cursor': ?cursor, 'limit': limit},
    );
    try {
      return SyncSnapshotPage.fromJson(json);
    } on SyncProtocolException catch (error) {
      throw LanClientException('The device sent an invalid snapshot: ${error.message}');
    } on FormatException {
      throw const LanClientException('The device sent an invalid snapshot');
    }
  }

  @override
  Future<SyncChangesPage> fetchChanges(
    PairedDevice device, {
    required String localDeviceId,
    required int since,
    int limit = 200,
  }) async {
    final json = await _postSigned(
      device,
      localDeviceId: localDeviceId,
      path: '/sundial/v1/sync/changes',
      body: {'since': since, 'limit': limit},
    );
    try {
      return SyncChangesPage.fromJson(json);
    } on SyncProtocolException catch (error) {
      throw LanClientException('The device sent invalid changes: ${error.message}');
    } on FormatException {
      throw const LanClientException('The device sent invalid changes');
    }
  }

  @override
  Future<SyncMediaResponse> fetchMedia(
    PairedDevice device, {
    required String localDeviceId,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return const SyncMediaResponse();
    final json = await _postSigned(
      device,
      localDeviceId: localDeviceId,
      path: '/sundial/v1/sync/media',
      body: {'ids': ids},
    );
    try {
      return SyncMediaResponse.fromJson(json);
    } on SyncProtocolException catch (error) {
      throw LanClientException('The device sent invalid media: ${error.message}');
    } on FormatException {
      throw const LanClientException('The device sent invalid media');
    }
  }

  Future<Map<String, Object?>> _postSigned(
    PairedDevice device, {
    required String localDeviceId,
    required String path,
    required Map<String, Object?> body,
  }) async {
    if (device.host.isEmpty || device.port <= 0) {
      throw const LanClientException('No known address for this device');
    }
    final payload = jsonEncode(body);
    final timestamp = _clock().toUtc().millisecondsSinceEpoch ~/ 1000;
    final nonce = PairingCrypto.randomBase64(18);
    final signature = await PairingCrypto.signRequest(
      sharedKeyBase64: device.sharedKey,
      method: 'POST',
      path: path,
      timestamp: timestamp,
      nonce: nonce,
      body: payload,
    );

    final client = _client(allowAny: false, pinnedFingerprint: device.certificateFingerprint);
    try {
      final request = await client
          .postUrl(Uri(scheme: 'https', host: device.host, port: device.port, path: path))
          .timeout(_timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-sundial-device', localDeviceId);
      request.headers.set('x-sundial-timestamp', '$timestamp');
      request.headers.set('x-sundial-nonce', nonce);
      request.headers.set('x-sundial-signature', signature);
      request.write(payload);
      final response = await request.close().timeout(_timeout);
      final responseBody = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.unauthorized) {
        throw const LanClientException('The pairing is no longer valid');
      }
      if (response.statusCode == HttpStatus.badRequest) {
        throw const LanClientException('The device rejected the sync request');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw LanClientException('The device returned ${response.statusCode}');
      }
      final json = jsonDecode(responseBody);
      if (json is! Map<String, dynamic>) {
        throw const LanClientException('Unexpected answer from the device');
      }
      return json;
    } on TimeoutException {
      throw const LanClientException('The device did not answer in time');
    } on SocketException {
      throw const LanClientException('The device is offline');
    } on HandshakeException {
      throw const LanClientException('The device certificate did not match the pinned one');
    } finally {
      client.close(force: true);
    }
  }

  Future<Object?> query(
    PairedDevice device, {
    required String localDeviceId,
    required String resource,
    LocalDate? start,
    LocalDate? end,
    String? timeZone,
  }) async {
    if (device.host.isEmpty || device.port <= 0) {
      throw const LanClientException('No known address for this device');
    }
    final query = <String, String>{
      'resource': resource,
      if (start != null) 'start': start.iso,
      if (end != null) 'end': end.iso,
      'timeZone': ?timeZone,
    };
    final path = Uri(path: '/sundial/v1/query', queryParameters: query).toString();
    final timestamp = _clock().toUtc().millisecondsSinceEpoch ~/ 1000;
    final nonce = PairingCrypto.randomBase64(18);
    final signature = await PairingCrypto.signRequest(
      sharedKeyBase64: device.sharedKey,
      method: 'GET',
      path: path,
      timestamp: timestamp,
      nonce: nonce,
      body: '',
    );

    final client = _client(allowAny: false, pinnedFingerprint: device.certificateFingerprint);
    try {
      final request = await client
          .getUrl(
            Uri(
              scheme: 'https',
              host: device.host,
              port: device.port,
              path: '/sundial/v1/query',
              queryParameters: query,
            ),
          )
          .timeout(_timeout);
      request.headers.set('x-sundial-device', localDeviceId);
      request.headers.set('x-sundial-timestamp', '$timestamp');
      request.headers.set('x-sundial-nonce', nonce);
      request.headers.set('x-sundial-signature', signature);
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode == HttpStatus.unauthorized) {
        throw const LanClientException('The pairing is no longer valid');
      }
      if (response.statusCode != HttpStatus.ok) {
        throw LanClientException('The device returned ${response.statusCode}');
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const LanClientException('Unexpected answer from the device');
      }
      return json['data'];
    } on TimeoutException {
      throw const LanClientException('The device did not answer in time');
    } on SocketException {
      throw const LanClientException('The device is offline');
    } on HandshakeException {
      throw const LanClientException('The device certificate did not match the pinned one');
    } finally {
      client.close(force: true);
    }
  }

  HttpClient _client({required bool allowAny, List<String>? captured, String? pinnedFingerprint}) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..idleTimeout = const Duration(seconds: 2);
    client.badCertificateCallback = (certificate, host, port) {
      final fingerprint = sha256.convert(certificate.der).toString();
      captured?.add(fingerprint);
      if (allowAny) return true;
      return fingerprint == pinnedFingerprint;
    };
    return client;
  }

  Future<HttpClientResponse> _get(HttpClient client, String host, int port, String path) async {
    final request = await client.getUrl(Uri(scheme: 'https', host: host, port: port, path: path));
    return request.close();
  }
}
