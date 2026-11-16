import 'package:flutter_test/flutter_test.dart';
import 'package:mane/features/shifts/shift_lane_layout.dart';

void main() {
  test('no intervals means no layouts', () {
    expect(layoutShiftLanes(const []), isEmpty);
  });

  test('shifts that only touch stay full width for their whole span', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 10 * 60),
      ShiftLaneInterval(startMinute: 10 * 60, endMinute: 11 * 60),
    ]);

    for (final layout in layouts) {
      expect(layout.segments, hasLength(1));
      expect(layout.segments.single.lane, 0);
      expect(layout.segments.single.laneCount, 1);
      expect(layout.overlaps, isFalse);
    }
  });

  test('a fully shared span gets one lane per shift', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 13 * 60),
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 13 * 60),
    ]);

    expect(layouts.map((layout) => [layout.segments.single.startMinute, layout.segments.single.endMinute]), [
      [9 * 60, 13 * 60],
      [9 * 60, 13 * 60],
    ]);
    expect(layouts.map((layout) => layout.segments.single.lane), [0, 1]);
    expect(layouts.map((layout) => layout.segments.single.laneCount), [2, 2]);
    expect(layouts.every((layout) => layout.overlaps), isTrue);
  });

  test('only the shared slice is split in a partial overlap', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 15 * 60, endMinute: 23 * 60),
      ShiftLaneInterval(startMinute: 15 * 60 + 30, endMinute: 20 * 60),
    ]);

    expect(
      layouts[0].segments.map(
        (segment) => [segment.startMinute, segment.endMinute, segment.lane, segment.laneCount],
      ),
      [
        [15 * 60, 15 * 60 + 30, 0, 1],
        [15 * 60 + 30, 20 * 60, 0, 2],
        [20 * 60, 23 * 60, 0, 1],
      ],
    );
    expect(
      layouts[1].segments.map(
        (segment) => [segment.startMinute, segment.endMinute, segment.lane, segment.laneCount],
      ),
      [
        [15 * 60 + 30, 20 * 60, 1, 2],
      ],
    );
    expect(layouts[0].overlaps, isTrue);
    expect(layouts[1].overlaps, isTrue);
  });

  test('three overlapping shifts use three lanes', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 13 * 60),
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 13 * 60),
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 13 * 60),
    ]);

    expect(layouts.map((layout) => layout.segments.single.lane), [0, 1, 2]);
    expect(layouts.map((layout) => layout.segments.single.laneCount), [3, 3, 3]);
    expect(layouts.every((layout) => layout.overlaps), isTrue);
  });

  test('a transitive cluster splits and re-expands around each neighbour', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 11 * 60),
      ShiftLaneInterval(startMinute: 10 * 60, endMinute: 12 * 60),
      ShiftLaneInterval(startMinute: 11 * 60 + 30, endMinute: 13 * 60),
    ]);

    expect(
      layouts[0].segments.map(
        (segment) => [segment.startMinute, segment.endMinute, segment.lane, segment.laneCount],
      ),
      [
        [9 * 60, 10 * 60, 0, 1],
        [10 * 60, 11 * 60, 0, 2],
      ],
    );
    expect(
      layouts[1].segments.map(
        (segment) => [segment.startMinute, segment.endMinute, segment.lane, segment.laneCount],
      ),
      [
        [10 * 60, 11 * 60, 1, 2],
        [11 * 60, 11 * 60 + 30, 0, 1],
        [11 * 60 + 30, 12 * 60, 0, 2],
      ],
    );
    expect(
      layouts[2].segments.map(
        (segment) => [segment.startMinute, segment.endMinute, segment.lane, segment.laneCount],
      ),
      [
        [11 * 60 + 30, 12 * 60, 1, 2],
        [12 * 60, 13 * 60, 0, 1],
      ],
    );
  });

  test('layouts follow the input order while lanes follow start time', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 10 * 60, endMinute: 11 * 60),
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 12 * 60),
    ]);

    expect(layouts[0].segments.single.lane, 1);
    expect(layouts[0].segments.single.laneCount, 2);
    expect(layouts[1].segments, hasLength(3));
    expect(layouts[1].segments[1].lane, 0);
    expect(layouts[1].segments[1].laneCount, 2);
  });

  test('invalid intervals do not split a valid shift', () {
    final layouts = layoutShiftLanes(const [
      ShiftLaneInterval(startMinute: 10 * 60, endMinute: 10 * 60),
      ShiftLaneInterval(startMinute: 9 * 60, endMinute: 12 * 60),
    ]);

    expect(layouts.first.segments, isEmpty);
    expect(layouts.last.segments, hasLength(1));
    expect(layouts.last.segments.single.laneCount, 1);
    expect(layouts.last.overlaps, isFalse);
  });
}
