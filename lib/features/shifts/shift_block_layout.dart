/// A shift's visible extent on one displayed day, in minutes from midnight.
class ShiftBlockSpan {
  const ShiftBlockSpan({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;
}

/// A valid span after ordering, with its position in the caller's list.
class ShiftBlock {
  const ShiftBlock({required this.index, required this.startMinute, required this.endMinute});

  final int index;
  final int startMinute;
  final int endMinute;
}

/// Drops empty spans and orders the rest so the earliest shift is painted
/// first. An overlapping shift that starts later then blends over the one
/// beneath it instead of cutting the column in two. Ties keep the caller's
/// order, with the longer shift painted first so a shorter one stays on top.
List<ShiftBlock> orderShiftBlocks(List<ShiftBlockSpan> spans) {
  final blocks = <ShiftBlock>[
    for (var index = 0; index < spans.length; index++)
      if (spans[index].endMinute > spans[index].startMinute)
        ShiftBlock(index: index, startMinute: spans[index].startMinute, endMinute: spans[index].endMinute),
  ];
  blocks.sort((a, b) {
    final byStart = a.startMinute.compareTo(b.startMinute);
    if (byStart != 0) return byStart;
    final byEnd = b.endMinute.compareTo(a.endMinute);
    if (byEnd != 0) return byEnd;
    return a.index.compareTo(b.index);
  });
  return blocks;
}

/// Vertical offsets, in minutes, that keep shift labels readable when blocks
/// start close together. A label is pushed below the one before it when the
/// two would share pixels; the blocks themselves never move.
List<int> shiftLabelOffsets(List<ShiftBlock> blocks, {required int labelMinuteHeight}) {
  assert(labelMinuteHeight > 0);
  final placed = <int>[];
  final offsets = <int>[];
  for (final block in blocks) {
    var top = block.startMinute;
    var moved = true;
    while (moved) {
      moved = false;
      for (final placedTop in placed) {
        if (top < placedTop + labelMinuteHeight && top + labelMinuteHeight > placedTop) {
          top = placedTop + labelMinuteHeight;
          moved = true;
        }
      }
    }
    placed.add(top);
    offsets.add(top - block.startMinute);
  }
  return offsets;
}
