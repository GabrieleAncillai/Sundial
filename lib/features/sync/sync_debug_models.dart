import 'dart:convert';

/// A read-only view of the local replica bookkeeping for the developer screen.
///
/// The change feed is the outbound queue: every local edit appends one row with
/// the HLC of each changed merge group. Field versions and tombstones are the
/// resulting merge state, and peer cursors show how far each paired device has
/// pulled. Nothing here is written by the debug screen.
class SyncDebugSnapshot {
  const SyncDebugSnapshot({
    required this.device,
    required this.changes,
    required this.fields,
    required this.tombstones,
    required this.peers,
    required this.counts,
  });

  final SyncDebugDevice device;
  final List<SyncDebugChange> changes;
  final List<SyncDebugFieldVersion> fields;
  final List<SyncDebugTombstone> tombstones;
  final List<SyncDebugPeer> peers;
  final SyncDebugCounts counts;

  Map<String, Object?> toJson() => {
    'device': device.toJson(),
    'counts': counts.toJson(),
    'changes': [for (final change in changes) change.toJson()],
    'fields': [for (final field in fields) field.toJson()],
    'tombstones': [for (final tombstone in tombstones) tombstone.toJson()],
    'peers': [for (final peer in peers) peer.toJson()],
  };
}

class SyncDebugDevice {
  const SyncDebugDevice({
    required this.nodeId,
    required this.datasetId,
    required this.epoch,
    required this.hlcMillis,
    required this.hlcCounter,
    required this.createdAt,
    required this.updatedAt,
  });

  final String nodeId;
  final String datasetId;
  final String epoch;
  final int hlcMillis;
  final int hlcCounter;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'nodeId': nodeId,
    'datasetId': datasetId,
    'epoch': epoch,
    'hlcMillis': hlcMillis,
    'hlcCounter': hlcCounter,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class SyncDebugCounts {
  const SyncDebugCounts({required this.changes, required this.fieldVersions, required this.tombstones});

  final int changes;
  final int fieldVersions;
  final int tombstones;

  Map<String, Object?> toJson() => {
    'changes': changes,
    'fieldVersions': fieldVersions,
    'tombstones': tombstones,
  };
}

/// One entry from the local change feed.
class SyncDebugChange {
  const SyncDebugChange({
    required this.seq,
    required this.changeId,
    required this.originNodeId,
    required this.originEpoch,
    required this.originSeq,
    required this.entity,
    required this.rowKey,
    required this.op,
    required this.versions,
    required this.rowJson,
    required this.createdAt,
  });

  final int seq;
  final String changeId;
  final String originNodeId;
  final String originEpoch;
  final int originSeq;
  final String entity;
  final String rowKey;
  final String op;

  /// Merge-field name to encoded HLC. A delete carries `__deleted` instead.
  final Map<String, String> versions;
  final String rowJson;
  final DateTime createdAt;

  bool get isDelete => op == 'delete';

  String? get deletedVersion => versions['__deleted'];

  Map<String, String> get fieldVersions => {
    for (final entry in versions.entries)
      if (entry.key != '__deleted') entry.key: entry.value,
  };

  Map<String, Object?> get row => _decodeRow(rowJson);

  Map<String, Object?> toJson() => {
    'seq': seq,
    'changeId': changeId,
    'originNodeId': originNodeId,
    'originEpoch': originEpoch,
    'originSeq': originSeq,
    'entity': entity,
    'rowKey': rowKey,
    'op': op,
    'versions': versions,
    'createdAt': createdAt.toIso8601String(),
    'row': row,
  };
}

/// The currently accepted HLC for one merge field of one row.
class SyncDebugFieldVersion {
  const SyncDebugFieldVersion({
    required this.entity,
    required this.rowKey,
    required this.field,
    required this.version,
    required this.updatedAt,
  });

  final String entity;
  final String rowKey;
  final String field;
  final String version;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'entity': entity,
    'rowKey': rowKey,
    'field': field,
    'version': version,
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// A delete marker. It keeps the last known row so a peer can still identify
/// what was removed.
class SyncDebugTombstone {
  const SyncDebugTombstone({
    required this.entity,
    required this.rowKey,
    required this.version,
    required this.rowJson,
    required this.updatedAt,
  });

  final String entity;
  final String rowKey;
  final String version;
  final String rowJson;
  final DateTime updatedAt;

  Map<String, Object?> get row => _decodeRow(rowJson);

  Map<String, Object?> toJson() => {
    'entity': entity,
    'rowKey': rowKey,
    'version': version,
    'updatedAt': updatedAt.toIso8601String(),
    'row': row,
  };
}

/// One peer's persisted replication cursor.
class SyncDebugPeer {
  const SyncDebugPeer({
    required this.peerDeviceId,
    required this.datasetId,
    required this.peerEpoch,
    required this.lastPulledSeq,
    required this.lastSyncedAt,
    required this.lastError,
  });

  final String peerDeviceId;
  final String datasetId;
  final String peerEpoch;
  final int lastPulledSeq;
  final DateTime? lastSyncedAt;
  final String? lastError;

  Map<String, Object?> toJson() => {
    'peerDeviceId': peerDeviceId,
    'datasetId': datasetId,
    'peerEpoch': peerEpoch,
    'lastPulledSeq': lastPulledSeq,
    'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    'lastError': lastError,
  };
}

Map<String, Object?> _decodeRow(String raw) {
  if (raw.isEmpty) return const {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return {
      for (final entry in decoded.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  } on FormatException {
    return const {};
  }
}
