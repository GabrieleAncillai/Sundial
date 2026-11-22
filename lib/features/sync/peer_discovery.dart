import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import '../../models/local_identity.dart';
import 'device_certificate.dart';

class DiscoveredPeer {
  const DiscoveredPeer({
    required this.deviceName,
    required this.fingerprint,
    required this.host,
    required this.port,
  });

  final String deviceName;

  /// Pinned certificate fingerprint. This is the only stable peer identifier
  /// advertised before pairing, so discovery must match on it.
  final String fingerprint;
  final String host;
  final int port;
}

abstract class PeerDiscovery {
  Stream<DiscoveredPeer> get peers;

  Future<void> start({required LocalIdentity identity, required int port, required String host});

  Future<void> stop();

  Future<void> dispose();
}

/// mDNS/DNS-SD advertisement and discovery through Bonsoir.
///
/// The plugin uses Android NSD, Apple Bonjour, Windows DNS-SD and Avahi on
/// Linux. Discovery is best effort: manual host and port pairing stays
/// available when the platform daemon is missing.
class BonsoirPeerDiscovery implements PeerDiscovery {
  static const serviceType = '_sundial._tcp';

  final _peers = StreamController<DiscoveredPeer>.broadcast();
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;
  String? _selfFingerprint;

  @override
  Stream<DiscoveredPeer> get peers => _peers.stream;

  @override
  Future<void> start({required LocalIdentity identity, required int port, required String host}) async {
    final fingerprint = await fingerprintOfCertificatePem(identity.certificatePem);
    _selfFingerprint = fingerprint;
    // The TXT address is the IPv4 the HTTPS server actually bound. Avahi on
    // Linux may resolve to an IPv6 link-local address first, which an
    // IPv4-only listener cannot answer.
    final service = BonsoirService(
      name: identity.deviceName,
      type: serviceType,
      port: port,
      attributes: {'fp': fingerprint, if (host.isNotEmpty) 'ip4': host},
    );

    final broadcast = BonsoirBroadcast(service: service, printLogs: false);
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;

    final discovery = BonsoirDiscovery(type: serviceType, printLogs: false);
    await discovery.initialize();
    _subscription = discovery.eventStream?.listen(_onEvent);
    await discovery.start();
    _discovery = discovery;
  }

  void _onEvent(BonsoirDiscoveryEvent event) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      final discovery = _discovery;
      if (discovery == null) return;
      unawaited(discovery.serviceResolver.resolveService(event.service).catchError((Object _) {}));
      return;
    }
    if (event is! BonsoirDiscoveryServiceResolvedEvent) return;
    final service = event.service;
    final fingerprint = service.attributes['fp'];
    final host = resolvedHost(service);
    if (fingerprint == null || fingerprint == _selfFingerprint || host == null || host.isEmpty) return;
    _peers.add(
      DiscoveredPeer(deviceName: service.name, fingerprint: fingerprint, host: host, port: service.port),
    );
  }

  /// Prefer the IPv4 address advertised in the TXT record. Avahi can resolve a
  /// dual-stack host to an IPv6 link-local address that an IPv4-only listener
  /// cannot answer.
  static String? resolvedHost(BonsoirService service) => service.attributes['ip4'] ?? service.host;

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _discovery?.stop();
    _discovery = null;
    await _broadcast?.stop();
    _broadcast = null;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _peers.close();
  }
}
