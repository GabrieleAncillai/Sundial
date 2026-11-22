import '../../models/paired_device.dart';

/// Lifecycle of a pairing request. A request is created by the device that
/// wants to pair and approved locally on the other device with its PIN.
enum PairingRequestStatus { pending, approved, rejected, expired, completed }

/// A request received from another device. It exists only while the app is
/// running; nothing here is written to the database.
class PairingRequest {
  const PairingRequest({
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
    required this.status,
  });

  final String id;

  /// One-time six-digit code. Both devices show it so the user can compare
  /// after approving.
  final String code;

  final String username;
  final String deviceId;
  final String deviceName;
  final String certificateFingerprint;
  final String host;
  final int port;
  final String datasetId;
  final bool hasUserData;

  /// Whether the requesting device holds the same plan as this device.
  final bool datasetMatches;

  final DateTime receivedAt;
  final DateTime expiresAt;
  final PairingRequestStatus status;

  bool get pending => status == PairingRequestStatus.pending;

  String get displayCode => '${code.substring(0, 3)} ${code.substring(3)}';

  PairingRequest copyWith({PairingRequestStatus? status}) => PairingRequest(
    id: id,
    code: code,
    username: username,
    deviceId: deviceId,
    deviceName: deviceName,
    certificateFingerprint: certificateFingerprint,
    host: host,
    port: port,
    datasetId: datasetId,
    hasUserData: hasUserData,
    datasetMatches: datasetMatches,
    receivedAt: receivedAt,
    expiresAt: expiresAt,
    status: status ?? this.status,
  );
}

/// A pairing request this device sent to a peer. The service polls the peer
/// until it is approved, rejected or expired.
class OutgoingPairingRequest {
  const OutgoingPairingRequest({
    required this.id,
    required this.code,
    required this.displayName,
    required this.host,
    required this.port,
    required this.certificateFingerprint,
    required this.expiresAt,
  });

  final String id;
  final String code;

  /// Name from discovery, or the manual address until the peer identifies
  /// itself after approval.
  final String displayName;

  final String host;
  final int port;
  final String certificateFingerprint;
  final DateTime expiresAt;

  String get displayCode => '${code.substring(0, 3)} ${code.substring(3)}';
}

/// The peer's answer to [LanClient.readPairRequest].
class PairingStatus {
  const PairingStatus({
    required this.status,
    this.approvalToken,
    this.deviceId,
    this.deviceName,
    this.username,
    this.fingerprint,
    this.port,
    this.datasetId,
    this.hasUserData,
  });

  final PairingRequestStatus status;
  final String? approvalToken;
  final String? deviceId;
  final String? deviceName;
  final String? username;
  final String? fingerprint;
  final int? port;
  final String? datasetId;
  final bool? hasUserData;
}

/// A completed pairing, with enough plan metadata to warn about a mismatch
/// before full sync starts using it.
class PairingResult {
  const PairingResult({required this.device, required this.datasetId, required this.hasUserData});

  final PairedDevice device;
  final String datasetId;
  final bool hasUserData;
}
