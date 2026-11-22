import 'dart:math' as math;

/// A hybrid logical clock value: `(physicalMillis, counter, nodeId)`.
///
/// The encoded form is fixed-width so plain string comparison has the same
/// ordering on every device and in SQLite. The node id is the final tie-break.
class SyncHlc implements Comparable<SyncHlc> {
  const SyncHlc({required this.millis, required this.counter, required this.nodeId});

  final int millis;
  final int counter;
  final String nodeId;

  static final _pattern = RegExp(r'^(\d{16}):(\d{8}):([A-Za-z0-9_-]{1,64})$');

  String encode() => '${millis.toString().padLeft(16, '0')}:${counter.toString().padLeft(8, '0')}:$nodeId';

  static SyncHlc? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    return SyncHlc(
      millis: int.parse(match.group(1)!),
      counter: int.parse(match.group(2)!),
      nodeId: match.group(3)!,
    );
  }

  static SyncHlc parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) throw FormatException('Invalid sync version', value);
    return parsed;
  }

  static int compare(String first, String second) => first.compareTo(second);

  @override
  int compareTo(SyncHlc other) {
    final byMillis = millis.compareTo(other.millis);
    if (byMillis != 0) return byMillis;
    final byCounter = counter.compareTo(other.counter);
    if (byCounter != 0) return byCounter;
    return nodeId.compareTo(other.nodeId);
  }

  @override
  String toString() => encode();

  @override
  bool operator ==(Object other) => other is SyncHlc && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(millis, counter, nodeId);
}

/// Mutable clock for one device. Call [next] for a local write and [observe]
/// for every incoming version, then persist the result with the device state.
class SyncHlcClock {
  SyncHlcClock({required this.nodeId, required this.millis, required this.counter});

  final String nodeId;
  int millis;
  int counter;

  SyncHlc get current => SyncHlc(millis: millis, counter: counter, nodeId: nodeId);

  SyncHlc next(DateTime now) {
    final physical = now.toUtc().millisecondsSinceEpoch;
    if (physical > millis) {
      millis = physical;
      counter = 0;
    } else {
      counter++;
    }
    return current;
  }

  /// Advances the local clock past [remote]. A wildly future peer wins until
  /// real time catches up; that only affects conflict ordering.
  void observe(SyncHlc remote, DateTime now) {
    final physical = now.toUtc().millisecondsSinceEpoch;
    final highest = math.max(physical, math.max(millis, remote.millis));
    if (highest == millis && highest == remote.millis) {
      counter = math.max(counter, remote.counter) + 1;
    } else if (highest == millis) {
      counter++;
    } else if (highest == remote.millis) {
      counter = remote.counter + 1;
    } else {
      counter = 0;
    }
    millis = highest;
  }
}
