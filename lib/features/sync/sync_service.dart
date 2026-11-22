import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/local_identity.dart';
import '../../models/paired_device.dart';
import '../../models/remote_snapshot.dart';
import '../../services/planner_repository.dart';
import 'device_certificate.dart';
import 'identity_service.dart';
import 'lan_client.dart';
import 'lan_server.dart';
import 'pairing_request.dart';
import 'peer_discovery.dart';
import 'sync_engine.dart';
import 'sync_models.dart';
import 'sync_store.dart';

/// One peer's replicated-sync status, independent of the transitional
/// read-only snapshot card.
class PeerSyncState {
  const PeerSyncState({
    this.lastPullAt,
    this.lastError,
    this.pulling = false,
    this.replacing = false,
    this.needsSource = false,
    this.remoteDatasetId,
    this.remoteEpoch,
    this.lastPulledSeq,
  });

  final DateTime? lastPullAt;
  final String? lastError;
  final bool pulling;
  final bool replacing;

  /// The peer belongs to a different plan. The user has to choose a source.
  final bool needsSource;
  final String? remoteDatasetId;
  final String? remoteEpoch;
  final int? lastPulledSeq;

  PeerSyncState copyWith({
    DateTime? lastPullAt,
    Object? lastError = _unset,
    bool? pulling,
    bool? replacing,
    bool? needsSource,
    Object? remoteDatasetId = _unset,
    Object? remoteEpoch = _unset,
    int? lastPulledSeq,
  }) => PeerSyncState(
    lastPullAt: lastPullAt ?? this.lastPullAt,
    lastError: identical(lastError, _unset) ? this.lastError : lastError as String?,
    pulling: pulling ?? this.pulling,
    replacing: replacing ?? this.replacing,
    needsSource: needsSource ?? this.needsSource,
    remoteDatasetId: identical(remoteDatasetId, _unset) ? this.remoteDatasetId : remoteDatasetId as String?,
    remoteEpoch: identical(remoteEpoch, _unset) ? this.remoteEpoch : remoteEpoch as String?,
    lastPulledSeq: lastPulledSeq ?? this.lastPulledSeq,
  );
}

const _unset = Object();

class PairingState {
  const PairingState({
    this.incoming,
    this.outgoing,
    this.error,
    this.lastPairedDeviceName,
    this.lastPairedDatasetMatches,
  });

  final PairingRequest? incoming;
  final OutgoingPairingRequest? outgoing;
  final String? error;
  final String? lastPairedDeviceName;

  /// Whether the last completed pairing shared this device's plan. Null when
  /// the information was unavailable.
  final bool? lastPairedDatasetMatches;
}

class SyncState {
  const SyncState({
    this.running = false,
    this.discoveryAvailable = false,
    this.port = 0,
    this.lastRefresh,
    this.error,
    this.snapshots = const <String, RemoteSnapshot>{},
    this.deviceErrors = const <String, String>{},
    this.peers = const <String, PeerSyncState>{},
    this.roster = const <String, SyncKnownDevice>{},
    this.replacing = false,
    this.discovered = const <DiscoveredPeer>[],
    this.pairing = const PairingState(),
  });

  final bool running;
  final bool discoveryAvailable;
  final int port;
  final DateTime? lastRefresh;
  final String? error;
  final Map<String, RemoteSnapshot> snapshots;
  final Map<String, String> deviceErrors;
  final Map<String, PeerSyncState> peers;

  /// Public device cards learned from peers. The roster is advisory: a device
  /// still has to be paired directly before its changes arrive.
  final Map<String, SyncKnownDevice> roster;
  final bool replacing;
  final List<DiscoveredPeer> discovered;
  final PairingState pairing;
}

/// Starts the LAN server, advertises over mDNS, discovers peers and refreshes
/// read-only snapshots. A failure never touches the local plan.
class SyncService {
  SyncService({
    required PlannerRepository repository,
    required IdentityService identityService,
    required LanClient client,
    required LanServer server,
    required PeerDiscovery discovery,
    required SyncStore store,
    required SyncEngine engine,
    Future<void> Function()? backupBeforeReplace,
    DateTime Function()? clock,
    Duration pairingPollInterval = const Duration(seconds: 2),
  }) : _repository = repository,
       _identityService = identityService,
       _client = client,
       _server = server,
       _discovery = discovery,
       _store = store,
       _engine = engine,
       _backupBeforeReplace = backupBeforeReplace,
       _clock = clock ?? DateTime.now,
       _pairingPollInterval = pairingPollInterval;

  final PlannerRepository _repository;
  final IdentityService _identityService;
  final LanClient _client;
  final LanServer _server;
  final PeerDiscovery _discovery;
  final SyncStore _store;
  final SyncEngine _engine;
  final Future<void> Function()? _backupBeforeReplace;
  final DateTime Function() _clock;
  final Duration _pairingPollInterval;

  final ValueNotifier<SyncState> state = ValueNotifier(const SyncState());
  final _pairedEvents = StreamController<PairedDevice>.broadcast();

  LocalIdentity? _identity;
  bool _running = false;
  bool _discoveryAvailable = false;
  int _port = 0;
  DateTime? _lastRefresh;
  String? _error;
  final Map<String, RemoteSnapshot> _snapshots = {};
  final Map<String, PeerSyncState> _peers = {};
  final Map<String, SyncKnownDevice> _roster = {};
  final Map<String, Future<void>> _devicePulls = {};
  final Map<String, DateTime> _lastQueried = {};
  List<DiscoveredPeer> _discovered = const [];
  final _applied = StreamController<SyncApplyResult>.broadcast();
  bool _replacing = false;
  Timer? _timer;

  /// Batched side effects after a remote apply: the app shell listens and
  /// rebuilds reminders, reloads `weekStart` and refreshes the home widget.
  Stream<SyncApplyResult> get applyEvents => _applied.stream;

  PairingRequest? _incomingPairingRequest;
  OutgoingPairingRequest? _outgoingPairingRequest;
  String? _pairingError;
  String? _lastPairedDeviceName;
  bool? _lastPairedDatasetMatches;
  Timer? _pairPollTimer;
  bool _polling = false;
  int _pollFailures = 0;

  StreamSubscription<DiscoveredPeer>? _peerSubscription;
  StreamSubscription<PairedDevice>? _pairedSubscription;
  StreamSubscription<PairingRequest>? _incomingSubscription;

  LocalIdentity? get identity => _identity;

  /// Pairing requests that arrive while the server is running. The shell shows
  /// an approval card for each one.
  Stream<PairingRequest> get incomingPairingRequests => _server.incomingRequests;

  /// Completed pairings, from either side.
  Stream<PairedDevice> get pairedEvents => _pairedEvents.stream;

  Future<void> start() async {
    if (_running) return;
    await _restoreLocalState();
    final identity = await _identityService.read();
    _identity = identity;
    if (identity == null) {
      _error = 'identity_required';
      _emit();
      return;
    }
    try {
      _port = await _server.start(identity: identity);
      _running = true;
      _error = null;
      _listenToServer();
      _emit();
      await _startDiscovery(identity);
      await refresh();
      _timer ??= Timer.periodic(const Duration(minutes: 5), (_) => refresh());
    } catch (error) {
      _running = false;
      _error = '$error';
      _emit();
    }
  }

  void _listenToServer() {
    _pairedSubscription ??= _server.pairedDevices.listen(_onPaired);
    _incomingSubscription ??= _server.incomingRequests.listen(_onIncomingPairingRequest);
  }

  Future<void> _startDiscovery(LocalIdentity identity) async {
    try {
      await _discovery.start(identity: identity, port: _port, host: _server.address);
      _discoveryAvailable = true;
      _peerSubscription = _discovery.peers.listen(_onPeer);
    } catch (error) {
      _discoveryAvailable = false;
      _error = 'Discovery unavailable: $error';
    }
    _emit();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _pairPollTimer?.cancel();
    _pairPollTimer = null;
    _outgoingPairingRequest = null;
    _incomingPairingRequest = null;
    _lastPairedDeviceName = null;
    _lastPairedDatasetMatches = null;
    _pairingError = null;
    await _peerSubscription?.cancel();
    _peerSubscription = null;
    await _pairedSubscription?.cancel();
    _pairedSubscription = null;
    await _incomingSubscription?.cancel();
    _incomingSubscription = null;
    try {
      await _discovery.stop();
    } catch (_) {
      // The platform daemon may already be gone; stopping is best effort.
    }
    await _server.stop();
    _running = false;
    _discovered = const [];
    _emit();
  }

  Future<void> restart() async {
    await stop();
    await start();
  }

  Future<void> refresh() async {
    final devices = await _repository.readPairedDevices();
    for (final device in devices) {
      await _refreshDevice(device);
    }
    _lastRefresh = _clock().toUtc();
    _emit();
  }

  Future<void> refreshDevice(String id) async {
    final devices = await _repository.readPairedDevices();
    for (final device in devices) {
      if (device.id == id) {
        await _refreshDevice(device);
        _emit();
        return;
      }
    }
  }

  Future<void> _refreshDevice(PairedDevice device) {
    if (_replacing) return Future.value();
    // Serialize pulls per peer; a manual refresh joins the one already running
    // instead of creating a second write stream.
    final pending = _devicePulls[device.id];
    if (pending != null) return pending;
    final future = _pullDevice(device);
    _devicePulls[device.id] = future;
    return future.whenComplete(() {
      if (identical(_devicePulls[device.id], future)) _devicePulls.remove(device.id);
    });
  }

  Future<void> _pullDevice(PairedDevice device) async {
    final identity = _identity;
    if (identity == null) {
      await _setPeerError(device.id, 'identity_required');
      return;
    }
    if (device.host.isEmpty || device.port <= 0) {
      await _setPeerError(device.id, 'No address yet');
      return;
    }
    _updatePeer(device.id, (peer) => peer.copyWith(pulling: true, lastError: null));
    _emit();
    try {
      final pulled = await _engine.pull(device, localDeviceId: identity.deviceId);
      final stored = await _store.readPeerState(device.id);
      final fetchedAt = _clock().toUtc();
      _updatePeer(
        device.id,
        (_) => PeerSyncState(
          lastPullAt: fetchedAt,
          remoteDatasetId: stored?.datasetId,
          remoteEpoch: stored?.peerEpoch,
          lastPulledSeq: stored?.lastPulledSeq,
          lastError: pulled.mediaError,
        ),
      );
      if (pulled.mediaError != null) {
        await _store.recordPeerError(peerDeviceId: device.id, error: pulled.mediaError!);
      }
      _lastQueried[device.id] = fetchedAt;
      await _repository.updatePairedDevicePresence(
        device.id,
        host: device.host,
        port: device.port,
        seenAt: fetchedAt,
      );
      if (pulled.changed) _applied.add(pulled.result);
      _mergeRoster(pulled.knownDevices, identity.deviceId);
    } on SyncDatasetMismatchException catch (error) {
      // A different plan is not an error: it is the signal for the source
      // choice on the Devices page. Keep the transitional preview working.
      _updatePeer(
        device.id,
        (peer) => PeerSyncState(
          lastPullAt: peer.lastPullAt,
          remoteDatasetId: error.remoteDatasetId,
          remoteEpoch: peer.remoteEpoch,
          lastPulledSeq: peer.lastPulledSeq,
          needsSource: true,
        ),
      );
      await _store.recordPeerMismatch(peerDeviceId: device.id, datasetId: error.remoteDatasetId);
      await _refreshLegacySnapshot(device, identity);
    } catch (error) {
      await _setPeerError(device.id, '$error');
      await _store.recordPeerError(peerDeviceId: device.id, error: '$error');
      await _refreshLegacySnapshot(device, identity);
    }
    _emit();
  }

  /// Transitional read-only preview shown while the sync UI is replaced.
  Future<void> _refreshLegacySnapshot(PairedDevice device, LocalIdentity identity) async {
    try {
      final data = await _client.snapshot(device, localDeviceId: identity.deviceId);
      final fetchedAt = _clock().toUtc();
      final snapshot = RemoteSnapshot.fromPayload(
        deviceId: device.id,
        deviceName: device.name,
        fetchedAt: fetchedAt,
        data: data,
      );
      _snapshots[device.id] = snapshot;
      await _repository.saveRemoteSnapshot(snapshot);
      await _repository.updatePairedDevicePresence(
        device.id,
        host: device.host,
        port: device.port,
        seenAt: fetchedAt,
      );
      _lastQueried[device.id] = fetchedAt;
    } catch (error) {
      await _setPeerError(device.id, '$error');
    }
  }

  void _updatePeer(String id, PeerSyncState Function(PeerSyncState current) update) {
    _peers[id] = update(_peers[id] ?? const PeerSyncState());
  }

  Future<void> _setPeerError(String id, String error) async {
    _updatePeer(id, (peer) => peer.copyWith(lastError: error));
  }

  void _mergeRoster(Iterable<SyncKnownDevice> devices, String localDeviceId) {
    for (final device in devices) {
      if (device.deviceId == localDeviceId) continue;
      _roster[device.deviceId] = device;
    }
  }

  Future<void> _onPaired(PairedDevice device) async {
    _lastPairedDeviceName = device.name;
    _pairedEvents.add(device);
    await _refreshDevice(device);
    _emit();
  }

  /// Replaces this device's plan with [deviceId]'s staged snapshot.
  ///
  /// The local PIN authorizes the destructive action. When this device has user
  /// data, [backupBeforeReplace] must write a backup before anything is cleared;
  /// its failure aborts the replacement. The apply itself is transactional, so
  /// a staging or validation failure leaves the local plan intact.
  Future<void> replaceFromPeer(String deviceId, String pin) async {
    if (_replacing) throw const LanClientException('A replacement is already running');
    final identity = await _ensureIdentity();
    if (!await _identityService.verifyPin(identity, pin)) {
      throw const IdentityException('The PIN is not correct');
    }

    PairedDevice? peer;
    for (final device in await _repository.readPairedDevices()) {
      if (device.id == deviceId) {
        peer = device;
        break;
      }
    }
    if (peer == null) throw const LanClientException('That device is not paired');
    if (peer.host.isEmpty || peer.port <= 0) {
      throw const LanClientException('No known address for this device');
    }

    _replacing = true;
    _updatePeer(deviceId, (state) => state.copyWith(replacing: true, lastError: null));
    _emit();

    // Let a pull that already started finish before the plan is replaced; new
    // pulls are refused while `_replacing` is set.
    try {
      await Future.wait(_devicePulls.values.toList());
    } catch (_) {
      // A pull reports its own error through the peer state.
    }

    final wasRunning = _running;
    final wasServing = _port != 0;
    _timer?.cancel();
    _timer = null;
    try {
      if (wasServing) {
        await _peerSubscription?.cancel();
        _peerSubscription = null;
        try {
          await _discovery.stop();
        } catch (_) {
          // The platform daemon may already be gone.
        }
        await _server.stop();
        _running = false;
        _port = 0;
        _emit();
      }

      if (await _repository.hasUserData()) {
        final backup = _backupBeforeReplace;
        if (backup == null) {
          throw const LanClientException('A backup is required before replacing this plan');
        }
        await backup();
      }

      final staged = await _engine.stageSnapshot(peer, localDeviceId: identity.deviceId);
      // Images are staged before the target is cleared: a replacement either
      // carries its pictures or aborts with the old plan intact.
      await _engine.stageMedia(staged, peer, localDeviceId: identity.deviceId);
      final result = await _store.applyReplacement(staged, peerDeviceId: peer.id);
      _snapshots.clear();
      _updatePeer(
        deviceId,
        (_) => PeerSyncState(
          lastPullAt: _clock().toUtc(),
          remoteDatasetId: staged.datasetId,
          remoteEpoch: staged.epoch,
          lastPulledSeq: staged.nextSince,
        ),
      );
      _lastRefresh = _clock().toUtc();
      _mergeRoster(staged.knownDevices, identity.deviceId);
      for (final id in _peers.keys.toList()) {
        if (id != deviceId) _peers[id] = const PeerSyncState();
      }
      _applied.add(result);
    } finally {
      _replacing = false;
      _updatePeer(deviceId, (state) => state.copyWith(replacing: false));
      if (wasServing) {
        try {
          _port = await _server.start(identity: identity);
          _running = true;
          _listenToServer();
          await _startDiscovery(identity);
          _timer ??= Timer.periodic(const Duration(minutes: 5), (_) => refresh());
        } catch (error) {
          _error = '$error';
        }
      }
      _emit();
    }

    if (wasRunning) await refresh();
  }

  void _onIncomingPairingRequest(PairingRequest request) {
    _incomingPairingRequest = request.pending ? request : null;
    if (!request.pending && request.status != PairingRequestStatus.approved) {
      _pairingError = null;
    }
    _emit();
  }

  Future<void> _onPeer(DiscoveredPeer peer) async {
    _discovered = [
      for (final existing in _discovered)
        if (existing.fingerprint != peer.fingerprint) existing,
      peer,
    ];
    _emit();

    // Discovery advertises only the pinned certificate fingerprint, so that is
    // what identifies a peer after its IP address changes.
    final devices = await _repository.readPairedDevices();
    PairedDevice? paired;
    for (final device in devices) {
      if (device.certificateFingerprint == peer.fingerprint) {
        paired = device;
        break;
      }
    }
    if (paired == null) return;

    final now = _clock().toUtc();
    await _repository.updatePairedDevicePresence(paired.id, host: peer.host, port: peer.port, seenAt: now);
    final last = _lastQueried[paired.id];
    if (last != null && now.difference(last) < const Duration(seconds: 20)) return;
    await _refreshDevice(paired.copyWith(host: peer.host, port: peer.port));
    _emit();
  }

  /// Sends a pairing request. The peer shows an approval card and asks for its
  /// local PIN; this device polls until the request is answered.
  Future<OutgoingPairingRequest> requestPairing({
    required String host,
    required int port,
    String? displayName,
  }) async {
    final identity = await _ensureIdentity();
    await _ensureServer(identity);
    final fingerprint = await fingerprintOfCertificatePem(identity.certificatePem);
    final datasetId = await _repository.ensureSyncDatasetId();
    final hasUserData = await _repository.hasUserData();
    _pairingError = null;
    _lastPairedDeviceName = null;
    _lastPairedDatasetMatches = null;
    _emit();
    try {
      final request = await _client.requestPairing(
        identity: identity,
        myFingerprint: fingerprint,
        host: host,
        port: port,
        myServerPort: _port,
        datasetId: datasetId,
        hasUserData: hasUserData,
        displayName: displayName,
      );
      _outgoingPairingRequest = request;
      _emit();
      _startPairPolling(request, identity);
      return request;
    } catch (error) {
      _pairingError = '$error';
      _outgoingPairingRequest = null;
      _emit();
      rethrow;
    }
  }

  /// Approves an incoming request after checking the local PIN. The PIN never
  /// leaves this device.
  Future<PairingRequest> approvePairingRequest(String id, String pin) async {
    final identity = await _ensureIdentity();
    if (!await _identityService.verifyPin(identity, pin)) {
      throw const IdentityException('The PIN is not correct');
    }
    final approved = _server.approvePairingRequest(id);
    if (approved == null) {
      throw const IdentityException('The pairing request is no longer available');
    }
    return approved;
  }

  void rejectPairingRequest(String id) => _server.rejectPairingRequest(id);

  void cancelOutgoingPairing() {
    _pairPollTimer?.cancel();
    _pairPollTimer = null;
    _outgoingPairingRequest = null;
    _pairingError = null;
    _emit();
  }

  /// Clears the success card after the user acknowledges a completed pairing.
  void clearPairingResult() {
    _lastPairedDeviceName = null;
    _lastPairedDatasetMatches = null;
    _pairingError = null;
    _emit();
  }

  void _startPairPolling(OutgoingPairingRequest request, LocalIdentity identity) {
    _pairPollTimer?.cancel();
    _pollFailures = 0;
    _pairPollTimer = Timer.periodic(_pairingPollInterval, (_) => unawaited(_pollPairing(request, identity)));
    unawaited(_pollPairing(request, identity));
  }

  Future<void> _pollPairing(OutgoingPairingRequest request, LocalIdentity identity) async {
    if (_polling || _outgoingPairingRequest?.id != request.id) return;
    _polling = true;
    try {
      final status = await _client.readPairRequest(
        requestId: request.id,
        host: request.host,
        port: request.port,
        pinnedFingerprint: request.certificateFingerprint,
      );
      switch (status.status) {
        case PairingRequestStatus.pending:
          if (_clock().toUtc().isAfter(request.expiresAt)) {
            _failPairing('pairing_expired');
          }
        case PairingRequestStatus.approved:
          final token = status.approvalToken;
          if (token == null) {
            _failPairing('pairing_failed');
            break;
          }
          final myFingerprint = await fingerprintOfCertificatePem(identity.certificatePem);
          final result = await _client.completePairing(
            identity: identity,
            myFingerprint: myFingerprint,
            host: request.host,
            port: request.port,
            code: request.code,
            requestId: request.id,
            approvalToken: token,
            expectedFingerprint: request.certificateFingerprint,
            myServerPort: _port,
          );
          _pairPollTimer?.cancel();
          _pairPollTimer = null;
          final localDataset = await _repository.ensureSyncDatasetId();
          _lastPairedDatasetMatches = result.datasetId.isEmpty ? null : result.datasetId == localDataset;
          _lastPairedDeviceName = result.device.name;
          _outgoingPairingRequest = null;
          _pairingError = null;
          _pairedEvents.add(result.device);
          _emit();
          await _refreshDevice(result.device);
          _emit();
        case PairingRequestStatus.rejected:
          _failPairing('pairing_rejected');
        case PairingRequestStatus.expired:
          _failPairing('pairing_expired');
        case PairingRequestStatus.completed:
          _failPairing('pairing_already_completed');
      }
      _pollFailures = 0;
    } catch (error) {
      _pollFailures++;
      if (_pollFailures >= 5) {
        _failPairing('$error');
      }
    } finally {
      _polling = false;
    }
  }

  void _failPairing(String message) {
    _pairPollTimer?.cancel();
    _pairPollTimer = null;
    _outgoingPairingRequest = null;
    _pairingError = message;
    _emit();
  }

  Future<void> unpair(String id) async {
    await _repository.removePairedDevice(id);
    await _repository.deleteRemoteSnapshot(id);
    await _store.clearPeerState(id);
    _snapshots.remove(id);
    _peers.remove(id);
    _lastQueried.remove(id);
    _emit();
  }

  /// Restores the last peer cursors and the transitional read-only snapshots.
  /// A peer that serves a different dataset is marked for a source choice.
  Future<void> _restoreLocalState() async {
    try {
      final devices = await _repository.readPairedDevices();
      final ids = {for (final device in devices) device.id};
      await _repository.pruneRemoteSnapshots(ids);
      final stored = await _repository.readRemoteSnapshots();
      _snapshots
        ..clear()
        ..addEntries(stored.map((snapshot) => MapEntry(snapshot.deviceId, snapshot)));

      final local = await _store.deviceState();
      final peerStates = await _store.readPeerStates();
      _peers.clear();
      for (final row in peerStates) {
        if (!ids.contains(row.peerDeviceId)) continue;
        final datasetId = row.datasetId.isEmpty ? null : row.datasetId;
        _peers[row.peerDeviceId] = PeerSyncState(
          lastPullAt: row.lastSyncedAt,
          lastError: row.lastError,
          remoteDatasetId: datasetId,
          remoteEpoch: row.peerEpoch.isEmpty ? null : row.peerEpoch,
          lastPulledSeq: row.lastPulledSeq,
          needsSource: datasetId != null && datasetId != local.datasetId,
        );
      }
      _emit();
    } catch (_) {
      // Peer status is display data; a failure must not block LAN startup.
    }
  }

  Future<LocalIdentity> _ensureIdentity() async {
    final identity = _identity ?? await _identityService.read();
    if (identity == null) throw const IdentityException('Set a username and PIN first');
    _identity = identity;
    return identity;
  }

  Future<void> _ensureServer(LocalIdentity identity) async {
    if (_port == 0) {
      _port = await _server.start(identity: identity);
      _running = true;
      _listenToServer();
      _emit();
    }
  }

  void dispose() {
    unawaited(close());
  }

  Future<void> close() async {
    await stop();
    await _server.dispose();
    await _applied.close();
    await _pairedEvents.close();
    state.dispose();
  }

  void _emit() {
    state.value = SyncState(
      running: _running,
      discoveryAvailable: _discoveryAvailable,
      port: _port,
      lastRefresh: _lastRefresh,
      error: _error,
      snapshots: Map.unmodifiable(_snapshots),
      deviceErrors: {
        for (final entry in _peers.entries)
          if (entry.value.lastError != null) entry.key: entry.value.lastError!,
      },
      peers: Map.unmodifiable(_peers),
      roster: Map.unmodifiable(_roster),
      replacing: _replacing,
      discovered: List.unmodifiable(_discovered),
      pairing: PairingState(
        incoming: _incomingPairingRequest,
        outgoing: _outgoingPairingRequest,
        error: _pairingError,
        lastPairedDeviceName: _lastPairedDeviceName,
        lastPairedDatasetMatches: _lastPairedDatasetMatches,
      ),
    );
  }
}
