/// One line on the shopping list. A linked [homeItemId] means checking it off
/// adjusts the household inventory.
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    this.contextId,
    required this.name,
    this.quantity = 1,
    this.unit = '',
    this.checked = false,
    this.note = '',
    this.homeItemId,
    this.position = 0,
  });

  final String id;
  final String? contextId;
  final String name;
  final double quantity;
  final String unit;
  final bool checked;
  final String note;
  final String? homeItemId;

  /// Manual order inside the shopping list. Lower values come first.
  final int position;

  ShoppingItem copyWith({
    String? contextId,
    bool clearContext = false,
    String? name,
    double? quantity,
    String? unit,
    bool? checked,
    String? note,
    String? homeItemId,
    bool clearHomeItem = false,
    int? position,
  }) => ShoppingItem(
    id: id,
    contextId: clearContext ? null : (contextId ?? this.contextId),
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    checked: checked ?? this.checked,
    note: note ?? this.note,
    homeItemId: clearHomeItem ? null : (homeItemId ?? this.homeItemId),
    position: position ?? this.position,
  );
}
