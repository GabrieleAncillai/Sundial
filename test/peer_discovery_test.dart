import 'package:bonsoir/bonsoir.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/sync/peer_discovery.dart';

void main() {
  BonsoirService service({String? host, Map<String, String> attributes = const {}}) => BonsoirService(
    name: 'Desktop',
    type: BonsoirPeerDiscovery.serviceType,
    host: host,
    port: 1234,
    attributes: {'fp': 'a' * 64, ...attributes},
  );

  test('prefers the advertised IPv4 over an IPv6 service host', () {
    final resolved = BonsoirPeerDiscovery.resolvedHost(
      service(host: 'fe80::dc4d:462a:dd62:f88d', attributes: {'ip4': '192.168.0.110'}),
    );
    expect(resolved, '192.168.0.110');
  });

  test('falls back to the resolved service host', () {
    final resolved = BonsoirPeerDiscovery.resolvedHost(service(host: '192.168.0.103'));
    expect(resolved, '192.168.0.103');
  });
}
