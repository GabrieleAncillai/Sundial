/// A time interval on one displayed day, in minutes from midnight.
class ShiftLaneInterval {
  const ShiftLaneInterval({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;
}

/// One vertical slice of a shift after the day is cut at every overlap
/// boundary.
class ShiftLaneSegment {
  const ShiftLaneSegment({
    required this.startMinute,
    required this.endMinute,
    required this.lane,
    required this.laneCount,
  });

  final int startMinute;
  final int endMinute;
  final int lane;

  /// Number of shifts active during this slice. A value above one means the
  /// slice is shared and the day is split into this many columns.
  final int laneCount;
}

/// The full-width and shared slices that make up one shift.
class ShiftLaneLayout {
  const ShiftLaneLayout({required this.segments});

  const ShiftLaneLayout.empty() : segments = const <ShiftLaneSegment>[];

  final List<ShiftLaneSegment> segments;

  /// True when any slice is shared with another shift.
  bool get overlaps => segments.any((segment) => segment.laneCount > 1);
}

/// Lays shifts out as full-width blocks, split into lanes only while their
/// times overlap.
///
/// The day is cut at every start and end. Each slice then contains a stable
/// set of active shifts, which are ordered by start time and share the width.
/// Adjacent slices with the same lane and width are merged. The result keeps
/// the input order, so callers can zip it with the original shifts.
List<ShiftLaneLayout> layoutShiftLanes(List<ShiftLaneInterval> intervals) {
  if (intervals.isEmpty) return const <ShiftLaneLayout>[];

  final result = List<List<ShiftLaneSegment>>.generate(intervals.length, (_) => <ShiftLaneSegment>[]);
  final valid = <int>[];
  final boundaries = <int>{};
  for (var index = 0; index < intervals.length; index++) {
    final interval = intervals[index];
    if (interval.endMinute <= interval.startMinute) continue;
    valid.add(index);
    boundaries
      ..add(interval.startMinute)
      ..add(interval.endMinute);
  }
  if (valid.isEmpty) {
    return List<ShiftLaneLayout>.generate(
      intervals.length,
      (_) => const ShiftLaneLayout.empty(),
      growable: false,
    );
  }

  final sorted = boundaries.toList()..sort();
  for (var boundary = 0; boundary < sorted.length - 1; boundary++) {
    final start = sorted[boundary];
    final end = sorted[boundary + 1];
    if (end <= start) continue;

    final active = <int>[
      for (final index in valid)
        if (intervals[index].startMinute <= start && intervals[index].endMinute > start) index,
    ];
    if (active.isEmpty) continue;
    active.sort((a, b) {
      final byStart = intervals[a].startMinute.compareTo(intervals[b].startMinute);
      if (byStart != 0) return byStart;
      final byEnd = intervals[a].endMinute.compareTo(intervals[b].endMinute);
      if (byEnd != 0) return byEnd;
      return a.compareTo(b);
    });

    final laneCount = active.length;
    for (var lane = 0; lane < active.length; lane++) {
      final index = active[lane];
      final segments = result[index];
      final previous = segments.isEmpty ? null : segments.last;
      if (previous != null &&
          previous.endMinute == start &&
          previous.lane == lane &&
          previous.laneCount == laneCount) {
        segments[segments.length - 1] = ShiftLaneSegment(
          startMinute: previous.startMinute,
          endMinute: end,
          lane: lane,
          laneCount: laneCount,
        );
      } else {
        segments.add(ShiftLaneSegment(startMinute: start, endMinute: end, lane: lane, laneCount: laneCount));
      }
    }
  }

  return [
    for (final segments in result) ShiftLaneLayout(segments: List<ShiftLaneSegment>.unmodifiable(segments)),
  ];
}

/// Left edge of [lane] inside [width], with a small gap between shared lanes.
double shiftLaneLeft(double width, int lane, int laneCount, {double gap = 2}) {
  final laneWidth = shiftLaneWidth(width, laneCount, gap: gap);
  return lane * (laneWidth + (laneCount > 1 ? gap : 0));
}

/// Width of one lane inside [width].
double shiftLaneWidth(double width, int laneCount, {double gap = 2}) {
  if (laneCount <= 1) return width;
  final available = width - gap * (laneCount - 1);
  return available <= 0 ? 0 : available / laneCount;
}
