import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/sync/sync_clock.dart';

void main() {
  test('a local HLC is monotonic when the wall clock moves backward', () {
    final clock = SyncHlcClock(nodeId: 'node-a', millis: 1000, counter: 0);
    final first = clock.next(DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true));
    expect(first.millis, 2000);
    expect(first.counter, 0);

    final second = clock.next(DateTime.fromMillisecondsSinceEpoch(1500, isUtc: true));
    expect(second.millis, 2000);
    expect(second.counter, 1);
    expect(second.compareTo(first), greaterThan(0));
  });

  test('a remote version ahead of the local clock is adopted', () {
    final clock = SyncHlcClock(nodeId: 'node-a', millis: 1000, counter: 0);
    clock.observe(
      const SyncHlc(millis: 9000, counter: 4, nodeId: 'node-b'),
      DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true),
    );
    final next = clock.next(DateTime.fromMillisecondsSinceEpoch(2000, isUtc: true));
    expect(next.millis, 9000);
    expect(next.counter, 6);
    expect(next.nodeId, 'node-a');
  });

  test('the node id breaks exact ties deterministically', () {
    const first = SyncHlc(millis: 5000, counter: 2, nodeId: 'node-a');
    const second = SyncHlc(millis: 5000, counter: 2, nodeId: 'node-b');
    expect(first.compareTo(second), lessThan(0));
    expect(second.compareTo(first), greaterThan(0));
    expect(first.encode().compareTo(second.encode()), lessThan(0));
  });

  test('the encoded form preserves ordering and round-trips', () {
    const version = SyncHlc(millis: 1762704000000, counter: 12, nodeId: 'node-a');
    final encoded = version.encode();
    final parsed = SyncHlc.parse(encoded);
    expect(parsed.millis, version.millis);
    expect(parsed.counter, version.counter);
    expect(parsed.nodeId, version.nodeId);
    expect(parsed.encode(), encoded);
    expect(encoded.length, greaterThan(25));
  });

  test('a five-minute clock skew keeps remote edits ordered without rejection', () {
    final local = SyncHlcClock(nodeId: 'node-a', millis: 10000, counter: 0);
    final now = DateTime.fromMillisecondsSinceEpoch(10000, isUtc: true);
    final future = SyncHlc(millis: 10000 + 5 * 60 * 1000, counter: 0, nodeId: 'node-b');
    local.observe(future, now);
    final next = local.next(now);
    expect(next.compareTo(future), greaterThan(0));
    expect(next.millis, future.millis);
  });
}
