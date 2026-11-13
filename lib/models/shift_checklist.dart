/// One checklist line attached to a shift pattern.
class ShiftChecklistItem {
  const ShiftChecklistItem({
    required this.id,
    required this.patternId,
    required this.label,
    this.dayIndex,
    this.position = 0,
  });

  final String id;
  final String patternId;
  final String label;

  /// Cycle day this item belongs to. Null applies to every day.
  final int? dayIndex;
  final int position;

  ShiftChecklistItem copyWith({String? label, Object? dayIndex = _unset, int? position}) =>
      ShiftChecklistItem(
        id: id,
        patternId: patternId,
        label: label ?? this.label,
        dayIndex: identical(dayIndex, _unset) ? this.dayIndex : dayIndex as int?,
        position: position ?? this.position,
      );
}

const _unset = Object();
