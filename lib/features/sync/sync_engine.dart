import 'dart:math' as math;

import '../../models/paired_device.dart';
import '../media/media_store.dart';
import 'sync_models.dart';
import 'sync_store.dart';

/// The transport the engine uses. [LanClient] implements it; tests provide a
/// fake that reads another store directly.
abstract class SyncTransport {
  Future<SyncSnapshotPage> fetchSnapshot(
    PairedDevice device, {
    required String localDeviceId,
    String? cursor,
    int limit,
  });

  Future<SyncChangesPage> fetchChanges(
    PairedDevice device, {
    required String localDeviceId,
    required int since,
    int limit,
  });

  /// Fetches content-addressed images. The default reports every id as missing
  /// so a transport that predates media sync still satisfies the interface.
  Future<SyncMediaResponse> fetchMedia(
    PairedDevice device, {
    required String localDeviceId,
    required List<String> ids,
  }) async => SyncMediaResponse(missing: ids);
}

/// Result of one peer pull.
class SyncPullResult {
  SyncPullResult({
    required this.result,
    required this.pages,
    required this.didSnapshot,
    this.knownDevices = const <SyncKnownDevice>[],
    this.mediaError,
  });

  final SyncApplyResult result;
  final int pages;
  final bool didSnapshot;
  final List<SyncKnownDevice> knownDevices;

  /// Rows applied but whose images could not be fetched. The pull itself is
  /// still successful; the ids stay pending for the next pass.
  final String? mediaError;

  bool get changed => result.applied > 0 || result.deleted > 0;
}

/// Pulls a peer's snapshot and deltas into the local replica.
///
/// Pulls are read-only from the peer's perspective. The engine never writes to
/// the remote database and never merges two different datasets: a mismatch is
/// reported to the caller, which has to ask the user for a source.
class SyncEngine {
  SyncEngine({
    required SyncStore store,
    required SyncTransport transport,
    int snapshotPageSize = SyncStore.defaultSnapshotLimit,
    int changesPageSize = SyncStore.defaultChangesLimit,
  }) : _store = store,
       _transport = transport,
       _snapshotPageSize = snapshotPageSize,
       _changesPageSize = changesPageSize;

  final SyncStore _store;
  final SyncTransport _transport;
  final int _snapshotPageSize;
  final int _changesPageSize;

  /// One page-limit guard so a misbehaving peer cannot keep the pull alive.
  static const _maxPages = 10000;

  /// Counts stay well under the endpoint's 32-id cap, and small batches keep a
  /// response under the 8 MiB raw-byte budget for ordinary stickers.
  static const _mediaBatchSize = 8;

  Future<SyncPullResult> pull(PairedDevice peer, {required String localDeviceId}) async {
    final state = await _store.deviceState();
    final peerState = await _store.readPeerState(peer.id);
    final needsSnapshot = peerState == null || peerState.datasetId != state.datasetId;

    var pages = 0;
    final total = SyncApplyResult();
    final known = <String, SyncKnownDevice>{};
    var didSnapshot = false;

    if (needsSnapshot) {
      final snapshot = await _pullSnapshot(peer, localDeviceId: localDeviceId);
      total.merge(snapshot.result);
      pages += snapshot.pages;
      _mergeKnown(known, snapshot.knownDevices);
      didSnapshot = true;
    }

    try {
      final delta = await _pullChanges(peer, localDeviceId: localDeviceId);
      total.merge(delta.result);
      pages += delta.pages;
      _mergeKnown(known, delta.knownDevices);
    } on SyncEpochChangedException {
      // The peer replaced its log, so the cursor is meaningless. A snapshot is
      // safe and idempotent; then continue from its replay point.
      final snapshot = await _pullSnapshot(peer, localDeviceId: localDeviceId);
      total.merge(snapshot.result);
      pages += snapshot.pages;
      _mergeKnown(known, snapshot.knownDevices);
      didSnapshot = true;
      final delta = await _pullChanges(peer, localDeviceId: localDeviceId);
      total.merge(delta.result);
      pages += delta.pages;
      _mergeKnown(known, delta.knownDevices);
    }

    return SyncPullResult(
      result: total,
      pages: pages,
      didSnapshot: didSnapshot,
      knownDevices: known.values.toList(),
      mediaError: await _pullMedia(peer, localDeviceId: localDeviceId, extraIds: total.missingMediaIds),
    );
  }

  /// Fetches every image the local plan still needs. A row is never failed by
  /// a missing image: failures become a per-peer media error and the ids stay
  /// pending for the next pull.
  Future<String?> _pullMedia(
    PairedDevice peer, {
    required String localDeviceId,
    Iterable<String> extraIds = const [],
  }) async {
    try {
      final pending = <String>{...extraIds, ...await _store.pendingMediaIds()};
      pending.removeWhere((id) => !isMediaId(id));
      if (pending.isEmpty) return null;
      final ordered = pending.toList()..sort();
      for (var start = 0; start < ordered.length; start += _mediaBatchSize) {
        final batch = ordered.sublist(start, math.min(start + _mediaBatchSize, ordered.length));
        await _fetchAndInstall(peer, localDeviceId: localDeviceId, ids: batch);
      }
      return null;
    } catch (_) {
      // Keep the message safe: a file-system error can carry an absolute path.
      return 'Media sync failed; images will retry on the next pull';
    }
  }

  Future<Set<String>> _fetchAndInstall(
    PairedDevice peer, {
    required String localDeviceId,
    required List<String> ids,
  }) async {
    final response = await _transport.fetchMedia(peer, localDeviceId: localDeviceId, ids: ids);
    final wanted = ids.toSet();
    final installed = <String>{};
    for (final item in response.media) {
      if (!wanted.contains(item.id) || item.mime != MediaStore.mime) continue;
      if (item.bytes.length > MediaStore.maxBytes) continue;
      if (await _store.installMedia(item.id, item.bytes)) installed.add(item.id);
    }
    if (installed.isNotEmpty) await _store.linkMediaPaths(installed);
    return installed;
  }

  /// Fetches and verifies every image a staged source plan needs. Called before
  /// a source replacement clears the target, so the replacement either carries
  /// its images or aborts untouched.
  Future<void> stageMedia(
    SyncStagedSnapshot staged,
    PairedDevice peer, {
    required String localDeviceId,
  }) async {
    final required = <String>{};
    for (final row in staged.rows) {
      if (row.isDeleted || (row.entity != 'context' && row.entity != 'project')) continue;
      final mediaId = row.row['image_media_id'];
      if (mediaId is String && isMediaId(mediaId)) required.add(mediaId);
    }
    if (required.isEmpty) return;

    final missing = <String>[];
    for (final mediaId in required) {
      if (!await _verified(mediaId)) missing.add(mediaId);
    }
    if (missing.isNotEmpty) {
      final ordered = missing..sort();
      for (var start = 0; start < ordered.length; start += _mediaBatchSize) {
        final batch = ordered.sublist(start, math.min(start + _mediaBatchSize, ordered.length));
        try {
          await _fetchAndInstall(peer, localDeviceId: localDeviceId, ids: batch);
        } on Object {
          throw const SyncProtocolException('The source plan media could not be fetched');
        }
      }
    }
    for (final mediaId in required) {
      if (!await _verified(mediaId)) {
        throw const SyncProtocolException('The source plan references media this device could not verify');
      }
    }
    await _store.linkMediaPaths(required);
  }

  Future<bool> _verified(String mediaId) async {
    try {
      return await _store.readMedia(mediaId) != null;
    } on MediaTooLargeException {
      return false;
    }
  }

  static void _mergeKnown(Map<String, SyncKnownDevice> target, Iterable<SyncKnownDevice> devices) {
    for (final device in devices) {
      target[device.deviceId] = device;
    }
  }

  /// Downloads every snapshot page into memory so a replacement can validate
  /// the whole plan before it clears anything locally.
  Future<SyncStagedSnapshot> stageSnapshot(PairedDevice peer, {required String localDeviceId}) async {
    final rows = <SyncRowPayload>[];
    String? datasetId;
    String? epoch;
    String? nodeId;
    String? deviceId;
    String? serverHlc;
    int? nextSince;
    var knownDevices = const <SyncKnownDevice>[];
    String? cursor;
    var pages = 0;

    while (true) {
      final page = await _transport.fetchSnapshot(
        peer,
        localDeviceId: localDeviceId,
        cursor: cursor,
        limit: _snapshotPageSize,
      );
      if (datasetId == null) {
        datasetId = page.datasetId;
        epoch = page.epoch;
        nodeId = page.nodeId;
        deviceId = page.deviceId;
        serverHlc = page.serverHlc;
        nextSince = page.nextSince;
        knownDevices = page.knownDevices;
      } else if (page.datasetId != datasetId || page.epoch != epoch || page.nodeId != nodeId) {
        throw const SyncProtocolException('The peer plan changed while the snapshot was staged');
      }
      rows.addAll(page.rows);
      pages++;
      if (page.done || page.cursor == null) break;
      if (pages >= _maxPages) {
        throw const SyncProtocolException('Snapshot exceeded the page limit');
      }
      cursor = page.cursor;
    }

    return SyncStagedSnapshot(
      datasetId: datasetId,
      epoch: epoch!,
      nodeId: nodeId!,
      deviceId: deviceId!,
      serverHlc: serverHlc!,
      nextSince: nextSince!,
      knownDevices: knownDevices,
      rows: rows,
    );
  }

  Future<_PagePull> _pullSnapshot(PairedDevice peer, {required String localDeviceId}) async {
    final total = SyncApplyResult();
    final known = <String, SyncKnownDevice>{};
    String? cursor;
    var pages = 0;
    while (true) {
      final page = await _transport.fetchSnapshot(
        peer,
        localDeviceId: localDeviceId,
        cursor: cursor,
        limit: _snapshotPageSize,
      );
      total.merge(await _store.applySnapshotPage(page, peerDeviceId: peer.id));
      _mergeKnown(known, page.knownDevices);
      pages++;
      if (page.done || page.cursor == null) break;
      if (pages >= _maxPages) {
        throw const SyncProtocolException('Snapshot exceeded the page limit');
      }
      cursor = page.cursor;
    }
    return _PagePull(total, pages, known.values.toList());
  }

  Future<_PagePull> _pullChanges(PairedDevice peer, {required String localDeviceId}) async {
    final total = SyncApplyResult();
    final known = <String, SyncKnownDevice>{};
    var pages = 0;
    while (true) {
      final peerState = await _store.readPeerState(peer.id);
      final since = peerState?.lastPulledSeq ?? 0;
      final page = await _transport.fetchChanges(
        peer,
        localDeviceId: localDeviceId,
        since: since,
        limit: _changesPageSize,
      );
      total.merge(await _store.applyChangesPage(page, peerDeviceId: peer.id));
      _mergeKnown(known, page.knownDevices);
      pages++;
      if (!page.hasMore) break;
      if (pages >= _maxPages) {
        throw const SyncProtocolException('Change feed exceeded the page limit');
      }
      if (page.nextSince <= since) {
        throw const SyncProtocolException('Change feed did not advance');
      }
    }
    return _PagePull(total, pages, known.values.toList());
  }
}

class _PagePull {
  _PagePull(this.result, this.pages, this.knownDevices);

  final SyncApplyResult result;
  final int pages;
  final List<SyncKnownDevice> knownDevices;
}
