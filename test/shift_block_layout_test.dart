import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/features/shifts/shift_block_layout.dart';

void main() {
  test('no spans means no blocks', () {
    expect(orderShiftBlocks(const []), isEmpty);
  });

  test('empty and inverted spans are dropped', () {
    final blocks = orderShiftBlocks(const [
      ShiftBlockSpan(startMinute: 10 * 60, endMinute: 10 * 60),
      ShiftBlockSpan(startMinute: 12 * 60, endMinute: 11 * 60),
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 12 * 60),
    ]);

    expect(blocks.map((block) => block.index), [2]);
  });

  test('blocks are ordered by start so the later shift blends on top', () {
    final blocks = orderShiftBlocks(const [
      ShiftBlockSpan(startMinute: 15 * 60, endMinute: 23 * 60),
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 13 * 60),
    ]);

    expect(blocks.map((block) => block.index), [1, 0]);
  });

  test('the longer shift is painted first when two start together', () {
    final blocks = orderShiftBlocks(const [
      ShiftBlockSpan(startMinute: 10 * 60, endMinute: 11 * 60),
      ShiftBlockSpan(startMinute: 10 * 60, endMinute: 12 * 60),
    ]);

    expect(blocks.map((block) => block.index), [1, 0]);
  });

  test('identical spans keep the caller order', () {
    final blocks = orderShiftBlocks(const [
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 13 * 60),
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 13 * 60),
    ]);

    expect(blocks.map((block) => block.index), [0, 1]);
  });

  test('labels that would share pixels move down one line at a time', () {
    final blocks = orderShiftBlocks(const [
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 13 * 60),
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 10 * 60),
      ShiftBlockSpan(startMinute: 9 * 60 + 5, endMinute: 10 * 60),
    ]);

    expect(shiftLabelOffsets(blocks, labelMinuteHeight: 15), [0, 15, 25]);
  });

  test('labels far enough apart stay at their block start', () {
    final blocks = orderShiftBlocks(const [
      ShiftBlockSpan(startMinute: 9 * 60, endMinute: 10 * 60),
      ShiftBlockSpan(startMinute: 10 * 60, endMinute: 11 * 60),
    ]);

    expect(shiftLabelOffsets(blocks, labelMinuteHeight: 15), [0, 0]);
  });
}
