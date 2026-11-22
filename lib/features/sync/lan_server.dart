import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sundial_core/sundial_core.dart';

import '../../app_version.dart';
import '../../models/local_identity.dart';
import '../../models/paired_device.dart';
import '../../services/planner_repository.dart';
import '../media/media_store.dart';
import 'device_certificate.dart';
import 'pairing_crypto.dart';
import 'pairing_request.dart';
import 'remote_payload.dart';
import 'sync_models.dart';
import 'sync_store.dart';

class LanServerException implements Exception {
  const LanServerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A small HTTPS endpoint for pairing and for read-only queries between the
/// user's own devices.
///
/// The certificate is self-signed and pinned by the peer's fingerprint. Every
/// query is signed with the paired device's shared key and a timestamped nonce.
/// The server never merges or writes remote data; it only answers queries over
/// the local repository.
class LanServer {
  LanServer({
    required PlannerRepository repository,
    required SyncStore syncStore,
    required String Function() deviceTimeZone,
    DateTime Function()? clock,
  }) : _repository = repository,
       _syncStore = syncStore,
       _deviceTimeZone = deviceTimeZone,
       _clock = clock ?? DateTime.now;

  /// Protocol 4 adds the content-addressed media endpoint. Pairing requires it:
  /// a protocol-3 peer cannot resolve context or project images.
  static const protocolVersion = 4;
  static const pairRequestTtl = Duration(minutes: 5);
  static const _pairRequestLimit = 5;

  final PlannerRepository _repository;
  final SyncStore _syncStore;
  final String Function() _deviceTimeZone;
  final DateTime Function() _clock;

  HttpServer? _server;
  String _address = '';
  LocalIdentity? _identity;
  String _fingerprint = '';
  _IncomingPairingRequest? _incomingRequest;
  int _pairRequestAttempts = 0;
  DateTime? _pairRequestWindowStart;
  final _pairedEvents = StreamController<PairedDevice>.broadcast();
  final _incomingRequests = StreamController<PairingRequest>.broadcast();
  final Map<String, Map<String, DateTime>> _nonces = {};

  Stream<PairedDevice> get pairedDevices => _pairedEvents.stream;

  /// Requests that arrived while the server was running. Only one request is
  /// held at a time; approving or rejecting it is done by the local user.
  Stream<PairingRequest> get incomingRequests => _incomingRequests.stream;

  PairingRequest? get pendingPairingRequest {
    _expireIncoming();
    final active = _incomingRequest;
    if (active == null || active.status != PairingRequestStatus.pending) return null;
    return _snapshot(active);
  }

  int get port => _server?.port ?? 0;

  /// The private IPv4 address the HTTPS server is bound to. Empty when the
  /// server is stopped.
  String get address => _address;

  Future<int> start({required LocalIdentity identity, int port = 0, InternetAddress? address}) async {
    if (_server != null) return _server!.port;
    _identity = identity;
    _fingerprint = await fingerprintOfCertificatePem(identity.certificatePem);

    final context = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(identity.certificatePem))
      ..usePrivateKeyBytes(utf8.encode(identity.privateKeyPem));
    final bindAddress = address ?? await _privateBindAddress();
    final server = await HttpServer.bindSecure(bindAddress, port, context, shared: false);
    _server = server;
    _address = server.address.address;
    server.listen(_handle, onError: (Object _) {});
    return server.port;
  }

  Future<void> stop() async {
    _incomingRequest = null;
    _pairRequestAttempts = 0;
    _pairRequestWindowStart = null;
    await _server?.close(force: true);
    _server = null;
    _address = '';
  }

  Future<void> dispose() async {
    await stop();
    await _pairedEvents.close();
    await _incomingRequests.close();
  }

  /// Marks a pending request as rejected. Returns null when the id is unknown
  /// or the request is no longer pending.
  PairingRequest? rejectPairingRequest(String id) {
    _expireIncoming();
    final active = _incomingRequest;
    if (active == null || active.id != id || active.status != PairingRequestStatus.pending) {
      return null;
    }
    active.status = PairingRequestStatus.rejected;
    final snapshot = _snapshot(active);
    _incomingRequests.add(snapshot);
    return snapshot;
  }

  /// Marks a pending request as approved. The PIN is verified by the caller
  /// before this point; this method only changes the request state.
  PairingRequest? approvePairingRequest(String id) {
    _expireIncoming();
    final active = _incomingRequest;
    if (active == null || active.id != id || active.status != PairingRequestStatus.pending) {
      return null;
    }
    active.status = PairingRequestStatus.approved;
    active.approvalToken = PairingCrypto.randomBase64Url(24);
    _pairRequestAttempts = 0;
    _pairRequestWindowStart = null;
    final snapshot = _snapshot(active);
    _incomingRequests.add(snapshot);
    return snapshot;
  }

  /// Bind to a private LAN address, never every interface. A device with no
  /// private IPv4 address (for example a VPN-only host) stays on loopback so
  /// the endpoint is not exposed to a public or tethered network.
  Future<InternetAddress> _privateBindAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (_isPrivateAddress(address)) return address;
        }
      }
    } on Object {
      // Fall through to loopback; discovery can still work on localhost.
    }
    return InternetAddress.loopbackIPv4;
  }

  static bool _isPrivateAddress(InternetAddress address) {
    final bytes = address.rawAddress;
    if (bytes.length != 4) return false;
    if (bytes[0] == 10) return true;
    if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) return true;
    if (bytes[0] == 192 && bytes[1] == 168) return true;
    return false;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final remote = request.connectionInfo?.remoteAddress;
      if (remote != null && !remote.isLoopback && !_isPrivateAddress(remote)) {
        await _json(request.response, HttpStatus.forbidden, {'error': 'private_network_only'});
        return;
      }
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/sundial/v1/info') {
        await _handleInfo(request);
        return;
      }
      if (request.method == 'POST' && path == '/sundial/v1/pair/request') {
        await _handlePairRequest(request);
        return;
      }
      if (request.method == 'GET' && path.startsWith('/sundial/v1/pair/request/')) {
        await _handlePairRequestStatus(request, path.substring('/sundial/v1/pair/request/'.length));
        return;
      }
      if (request.method == 'POST' && path == '/sundial/v1/pair') {
        await _handlePair(request);
        return;
      }
      if (request.method == 'POST' && path == '/sundial/v1/sync/snapshot') {
        await _handleSyncSnapshot(request);
        return;
      }
      if (request.method == 'POST' && path == '/sundial/v1/sync/changes') {
        await _handleSyncChanges(request);
        return;
      }
      if (request.method == 'POST' && path == '/sundial/v1/sync/media') {
        await _handleSyncMedia(request);
        return;
      }
      if (request.method == 'GET' && path == '/sundial/v1/query') {
        await _handleQuery(request);
        return;
      }
      await _json(request.response, HttpStatus.notFound, {'error': 'not_found'});
    } catch (_) {
      try {
        await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      } on StateError {
        // The response was already closed; nothing left to send.
      }
    }
  }

  Future<void> _handleInfo(HttpRequest request) async {
    final identity = _identity;
    if (identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }
    // No identity here: this endpoint is reachable before pairing. The
    // certificate fingerprint is public and is checked by the client. Device
    // identity is returned only in the authenticated pair response.
    await _json(request.response, HttpStatus.ok, {
      'app': 'sundial',
      'version': appVersion,
      'protocol': protocolVersion,
      'fingerprint': _fingerprint,
      'pairing': pendingPairingRequest != null,
      'port': port,
    });
  }

  Future<void> _handlePairRequest(HttpRequest request) async {
    final identity = _identity;
    if (identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }

    final now = _clock().toUtc();
    _expireIncoming();
    final active = _incomingRequest;
    if (active != null && active.status == PairingRequestStatus.pending) {
      await _json(request.response, HttpStatus.tooManyRequests, {'error': 'pairing_busy'});
      return;
    }
    if (!_countPairRequest(now)) {
      await _json(request.response, HttpStatus.tooManyRequests, {'error': 'rate_limited'});
      return;
    }

    final body = await _readBody(request);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      return;
    }

    final requestId = decoded['requestId'];
    final code = decoded['code'];
    final username = decoded['username'];
    final deviceId = decoded['deviceId'];
    final deviceName = decoded['deviceName'];
    final guestFingerprint = decoded['fingerprint'];
    final guestPort = decoded['port'];
    final datasetId = decoded['datasetId'];
    final hasUserData = decoded['hasUserData'];
    if (requestId is! String ||
        !_validRequestId(requestId) ||
        code is! String ||
        !RegExp(r'^\d{6}$').hasMatch(code) ||
        username is! String ||
        username.trim().isEmpty ||
        username.length > 64 ||
        deviceId is! String ||
        deviceId.isEmpty ||
        deviceId.length > 128 ||
        deviceId == identity.deviceId ||
        deviceName is! String ||
        deviceName.trim().isEmpty ||
        deviceName.length > 128 ||
        guestFingerprint is! String ||
        !_validFingerprint(guestFingerprint) ||
        guestPort is! int ||
        guestPort < 0 ||
        guestPort > 65535 ||
        datasetId is! String ||
        datasetId.isEmpty ||
        datasetId.length > 128 ||
        hasUserData is! bool) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      return;
    }
    if (username.trim().toLowerCase() != identity.username.toLowerCase()) {
      await _json(request.response, HttpStatus.forbidden, {'error': 'username_mismatch'});
      return;
    }

    final localDatasetId = await _repository.ensureSyncDatasetId();
    final remoteHost = request.connectionInfo?.remoteAddress.address ?? '';
    final incoming = _IncomingPairingRequest(
      id: requestId,
      code: code,
      username: username.trim(),
      deviceId: deviceId,
      deviceName: deviceName.trim(),
      certificateFingerprint: guestFingerprint,
      host: remoteHost,
      port: guestPort,
      datasetId: datasetId,
      hasUserData: hasUserData,
      datasetMatches: datasetId == localDatasetId,
      receivedAt: now,
      expiresAt: now.add(pairRequestTtl),
    );
    _incomingRequest = incoming;
    _incomingRequests.add(_snapshot(incoming));
    await _json(request.response, HttpStatus.ok, {
      'ok': true,
      'requestId': requestId,
      'expiresAt': incoming.expiresAt.toIso8601String(),
    });
  }

  Future<void> _handlePairRequestStatus(HttpRequest request, String rawId) async {
    final identity = _identity;
    if (identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }
    String id;
    try {
      id = Uri.decodeComponent(rawId);
    } on ArgumentError {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      return;
    }
    _expireIncoming();
    final active = _incomingRequest;
    if (active == null || active.id != id) {
      await _json(request.response, HttpStatus.notFound, {'error': 'unknown_request'});
      return;
    }

    final payload = <String, Object?>{
      'status': active.status.name,
      'expiresAt': active.expiresAt.toIso8601String(),
    };
    if (active.status == PairingRequestStatus.approved) {
      payload.addAll({
        'approvalToken': active.approvalToken,
        'deviceId': identity.deviceId,
        'deviceName': identity.deviceName,
        'username': identity.username,
        'fingerprint': _fingerprint,
        'port': port,
        'datasetId': await _repository.ensureSyncDatasetId(),
        'hasUserData': await _repository.hasUserData(),
      });
    }
    await _json(request.response, HttpStatus.ok, payload);
  }

  Future<void> _handlePair(HttpRequest request) async {
    final identity = _identity;
    if (identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }
    _expireIncoming();
    final active = _incomingRequest;
    if (active == null ||
        active.status != PairingRequestStatus.approved ||
        active.approvalToken == null ||
        active.consumed) {
      await _json(request.response, HttpStatus.forbidden, {'error': 'pairing_closed'});
      return;
    }

    final body = await _readBody(request);
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      return;
    }

    final requestId = decoded['requestId'];
    final approvalToken = decoded['approvalToken'];
    final username = decoded['username'];
    final deviceId = decoded['deviceId'];
    final deviceName = decoded['deviceName'];
    final guestFingerprint = decoded['fingerprint'];
    final guestPort = decoded['port'];
    final mac = decoded['mac'];
    final keyData = decoded['key'];
    if (requestId is! String ||
        requestId != active.id ||
        approvalToken is! String ||
        !PairingCrypto.constantTimeStringEquals(approvalToken, active.approvalToken!) ||
        username is! String ||
        username.trim().toLowerCase() != active.username.toLowerCase() ||
        deviceId is! String ||
        deviceId != active.deviceId ||
        deviceName is! String ||
        guestFingerprint is! String ||
        guestFingerprint != active.certificateFingerprint ||
        guestPort is! int ||
        guestPort < 0 ||
        guestPort > 65535 ||
        mac is! String ||
        keyData is! Map) {
      await _json(request.response, HttpStatus.forbidden, {'error': 'pairing_rejected'});
      return;
    }

    final pairingKey = await PairingCrypto.derivePairingKey(
      code: active.code,
      hostFingerprint: _fingerprint,
      guestFingerprint: active.certificateFingerprint,
      username: identity.username,
    );
    final message = PairingCrypto.pairRequestMessage(
      hostFingerprint: _fingerprint,
      guestFingerprint: active.certificateFingerprint,
      username: identity.username,
      guestDeviceId: active.deviceId,
    );
    if (!await PairingCrypto.verifyHmac(pairingKey, message, mac)) {
      await _json(request.response, HttpStatus.forbidden, {'error': 'pairing_rejected'});
      return;
    }

    final String sharedKey;
    try {
      sharedKey = await PairingCrypto.decryptSharedKey(
        pairingKeyBase64: pairingKey,
        payload: EncryptedPayload.fromJson(Map<String, Object?>.from(keyData)),
      );
      if (base64Decode(sharedKey).length != 32) {
        throw const FormatException('Shared key must be 32 bytes');
      }
    } on Object {
      await _json(request.response, HttpStatus.forbidden, {'error': 'pairing_rejected'});
      return;
    }

    final now = _clock().toUtc();
    final paired = PairedDevice(
      id: active.deviceId,
      name: active.deviceName,
      username: active.username,
      certificateFingerprint: active.certificateFingerprint,
      sharedKey: sharedKey,
      host: active.host,
      port: active.port,
      lastSeenAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.savePairedDevice(paired);
    active.consumed = true;
    active.status = PairingRequestStatus.completed;
    active.approvalToken = null;
    _incomingRequests.add(_snapshot(active));

    final ack = await PairingCrypto.hmacBase64(
      sharedKey,
      PairingCrypto.pairAckMessage(
        hostFingerprint: _fingerprint,
        guestFingerprint: active.certificateFingerprint,
      ),
    );
    _pairedEvents.add(paired);
    await _json(request.response, HttpStatus.ok, {
      'ok': true,
      'mac': ack,
      'deviceId': identity.deviceId,
      'deviceName': identity.deviceName,
      'username': identity.username,
      'fingerprint': _fingerprint,
      'port': port,
      'datasetId': await _repository.ensureSyncDatasetId(),
      'hasUserData': await _repository.hasUserData(),
    });
  }

  Future<void> _handleQuery(HttpRequest request) async {
    final identity = _identity;
    if (identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }

    final paired = await _authenticatedDevice(request, body: '');
    if (paired == null) return;

    final now = _clock().toUtc();
    final query = request.uri.queryParameters;
    final timeZone = query['timeZone'] ?? _deviceTimeZone();
    if (!isKnownTimeZone(timeZone)) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_timezone'});
      return;
    }
    final today = localDateAt(now, timeZone);

    try {
      final Object? data = await _resource(query['resource'] ?? 'summary', query, timeZone, today);
      await _json(request.response, HttpStatus.ok, {
        'deviceId': identity.deviceId,
        'deviceName': identity.deviceName,
        'generatedAt': now.toIso8601String(),
        'data': data,
      });
    } on ArgumentError {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
    }
  }

  /// Reads and checks the shared-key signature on a peer request. Returns null
  /// after writing the error response, so the caller only handles success.
  Future<PairedDevice?> _authenticatedDevice(HttpRequest request, {required String body}) async {
    final deviceId = request.headers.value('x-sundial-device');
    final timestampRaw = request.headers.value('x-sundial-timestamp');
    final nonce = request.headers.value('x-sundial-nonce');
    final signature = request.headers.value('x-sundial-signature');
    if (deviceId == null || timestampRaw == null || nonce == null || signature == null) {
      await _json(request.response, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return null;
    }
    final timestamp = int.tryParse(timestampRaw);
    if (timestamp == null) {
      await _json(request.response, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return null;
    }
    final now = _clock().toUtc();
    final requestTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    if (now.difference(requestTime).abs() > const Duration(minutes: 5)) {
      await _json(request.response, HttpStatus.unauthorized, {'error': 'stale'});
      return null;
    }

    final devices = await _repository.readPairedDevices();
    PairedDevice? paired;
    for (final device in devices) {
      if (device.id == deviceId) {
        paired = device;
        break;
      }
    }
    if (paired == null) {
      await _json(request.response, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return null;
    }

    final valid = await PairingCrypto.verifyRequest(
      sharedKeyBase64: paired.sharedKey,
      method: request.method,
      path: _signedPath(request),
      timestamp: timestamp,
      nonce: nonce,
      body: body,
      signatureBase64: signature,
    );
    if (!valid) {
      await _json(request.response, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return null;
    }
    if (!_acceptNonce(deviceId, nonce, now)) {
      await _json(request.response, HttpStatus.unauthorized, {'error': 'replay'});
      return null;
    }
    return paired;
  }

  static String _signedPath(HttpRequest request) {
    final query = request.uri.query;
    return query.isEmpty ? request.uri.path : '${request.uri.path}?$query';
  }

  Future<void> _handleSyncSnapshot(HttpRequest request) async {
    if (_identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }
    final body = await _readBody(request);
    if (await _authenticatedDevice(request, body: body) == null) return;

    final decoded = _decodeSyncBody(body);
    if (decoded == null) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      return;
    }
    final cursor = decoded['cursor'];
    if (cursor != null && cursor is! String) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_cursor'});
      return;
    }
    try {
      final page = await _syncStore.snapshotPage(
        cursor: cursor as String?,
        limit: _syncLimit(decoded['limit'], SyncStore.defaultSnapshotLimit),
      );
      await _json(request.response, HttpStatus.ok, page.toJson());
    } on SyncProtocolException {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_cursor'});
    }
  }

  Future<void> _handleSyncChanges(HttpRequest request) async {
    if (_identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }
    final body = await _readBody(request);
    if (await _authenticatedDevice(request, body: body) == null) return;

    final decoded = _decodeSyncBody(body);
    if (decoded == null) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_request'});
      return;
    }
    final since = decoded['since'];
    if (since is! int || since < 0) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_since'});
      return;
    }
    final page = await _syncStore.changesPage(
      since: since,
      limit: _syncLimit(decoded['limit'], SyncStore.defaultChangesLimit),
    );
    await _json(request.response, HttpStatus.ok, page.toJson());
  }

  /// Serves content-addressed images to a paired device. The request contains
  /// hashes only; the server never accepts a path and never logs bytes or file
  /// systems locations.
  Future<void> _handleSyncMedia(HttpRequest request) async {
    if (_identity == null) {
      await _json(request.response, HttpStatus.serviceUnavailable, {'error': 'not_ready'});
      return;
    }
    final body = await _readBody(request);
    if (await _authenticatedDevice(request, body: body) == null) return;

    final decoded = _decodeSyncBody(body);
    if (decoded == null || decoded['ids'] is! List) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'bad_media_request'});
      return;
    }
    final rawIds = decoded['ids'] as List;
    if (rawIds.length > MediaStore.maxIdsPerRequest) {
      await _json(request.response, HttpStatus.badRequest, {'error': 'too_many_media_ids'});
      return;
    }
    final ids = <String>{};
    for (final raw in rawIds) {
      if (raw is! String || !isMediaId(raw)) {
        await _json(request.response, HttpStatus.badRequest, {'error': 'bad_media_id'});
        return;
      }
      ids.add(raw);
    }

    final media = <Map<String, Object?>>[];
    final missing = <String>[];
    var total = 0;
    for (final id in ids) {
      try {
        final blob = await _syncStore.readMedia(id);
        if (blob == null) {
          missing.add(id);
          continue;
        }
        total += blob.bytes.length;
        if (total > MediaStore.maxResponseBytes) {
          await _json(request.response, HttpStatus.badRequest, {'error': 'media_response_too_large'});
          return;
        }
        media.add(
          SyncMediaItem(
            id: blob.id,
            mime: blob.mime,
            byteSize: blob.bytes.length,
            bytes: blob.bytes,
          ).toJson(),
        );
      } on MediaTooLargeException {
        await _json(request.response, HttpStatus.badRequest, {'error': 'media_too_large'});
        return;
      }
    }
    await _json(request.response, HttpStatus.ok, {'media': media, 'missing': missing});
  }

  Map<String, dynamic>? _decodeSyncBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static int _syncLimit(Object? raw, int fallback) {
    if (raw is! int) return fallback;
    return raw.clamp(1, 2000).toInt();
  }

  Future<Object?> _resource(
    String resource,
    Map<String, String> query,
    String timeZone,
    LocalDate today,
  ) async {
    switch (resource) {
      case 'summary':
        return SyncPayloads.summary(repository: _repository, now: _clock(), timeZone: timeZone);
      case 'snapshot':
        return SyncPayloads.fullSnapshot(repository: _repository, now: _clock(), timeZone: timeZone);
      case 'spaces':
        return [for (final space in await _repository.watchSpaces().first) SyncPayloads.spaceJson(space)];
      case 'tags':
        return [for (final tag in await _repository.watchTags().first) SyncPayloads.tagJson(tag)];
      case 'home':
        return [for (final item in await _repository.watchHomeItems().first) SyncPayloads.homeItemJson(item)];
      case 'shopping':
        return [
          for (final item in await _repository.watchShoppingItems().first)
            SyncPayloads.shoppingItemJson(item),
        ];
      case 'entries':
        final range = _range(query, today);
        final entries = await _repository.loadEntries(range.$1, range.$2, timeZone);
        return [for (final entry in entries) SyncPayloads.occurrenceJson(entry)];
      case 'shifts':
        final range = _range(query, today);
        final shifts = await _repository.watchShifts(range.$1, range.$2, timeZone).first;
        return [for (final shift in shifts) SyncPayloads.shiftJson(shift)];
      default:
        throw ArgumentError.value(resource, 'resource', 'unknown resource');
    }
  }

  (LocalDate, LocalDate) _range(Map<String, String> query, LocalDate today) {
    final start = _dateOrNull(query['start']) ?? today;
    final end = _dateOrNull(query['end']) ?? start;
    if (end.isBefore(start) || end.differenceInDays(start) > 366) {
      throw ArgumentError('Invalid date range');
    }
    return (start, end);
  }

  static LocalDate? _dateOrNull(String? value) {
    if (value == null) return null;
    try {
      return LocalDate.parse(value);
    } on FormatException {
      return null;
    }
  }

  bool _acceptNonce(String deviceId, String nonce, DateTime now) {
    if (nonce.length < 8 || nonce.length > 128) return false;
    final seen = _nonces[deviceId] ??= <String, DateTime>{};
    seen.removeWhere((_, expires) => now.isAfter(expires));
    if (seen.containsKey(nonce)) return false;
    seen[nonce] = now.add(const Duration(minutes: 5));
    return true;
  }

  bool _countPairRequest(DateTime now) {
    final start = _pairRequestWindowStart;
    if (start == null || now.difference(start) > pairRequestTtl) {
      _pairRequestWindowStart = now;
      _pairRequestAttempts = 0;
    }
    _pairRequestAttempts++;
    return _pairRequestAttempts <= _pairRequestLimit;
  }

  void _expireIncoming() {
    final active = _incomingRequest;
    if (active == null || active.status != PairingRequestStatus.pending) return;
    if (_clock().toUtc().isBefore(active.expiresAt)) return;
    active.status = PairingRequestStatus.expired;
    active.approvalToken = null;
    _incomingRequests.add(_snapshot(active));
  }

  PairingRequest _snapshot(_IncomingPairingRequest request) => PairingRequest(
    id: request.id,
    code: request.code,
    username: request.username,
    deviceId: request.deviceId,
    deviceName: request.deviceName,
    certificateFingerprint: request.certificateFingerprint,
    host: request.host,
    port: request.port,
    datasetId: request.datasetId,
    hasUserData: request.hasUserData,
    datasetMatches: request.datasetMatches,
    receivedAt: request.receivedAt,
    expiresAt: request.expiresAt,
    status: request.status,
  );

  static bool _validRequestId(String value) =>
      value.length >= 16 && value.length <= 128 && RegExp(r'^[A-Za-z0-9_\-]+$').hasMatch(value);

  static bool _validFingerprint(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

  Future<String> _readBody(HttpRequest request) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in request) {
      builder.add(chunk);
      if (builder.length > 1024 * 1024) {
        throw const LanServerException('Request too large');
      }
    }
    return utf8.decode(builder.takeBytes());
  }

  Future<void> _json(HttpResponse response, int status, Object body) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}

class _IncomingPairingRequest {
  _IncomingPairingRequest({
    required this.id,
    required this.code,
    required this.username,
    required this.deviceId,
    required this.deviceName,
    required this.certificateFingerprint,
    required this.host,
    required this.port,
    required this.datasetId,
    required this.hasUserData,
    required this.datasetMatches,
    required this.receivedAt,
    required this.expiresAt,
  });

  final String id;
  final String code;
  final String username;
  final String deviceId;
  final String deviceName;
  final String certificateFingerprint;
  final String host;
  final int port;
  final String datasetId;
  final bool hasUserData;
  final bool datasetMatches;
  final DateTime receivedAt;
  final DateTime expiresAt;
  PairingRequestStatus status = PairingRequestStatus.pending;
  String? approvalToken;
  bool consumed = false;
}
