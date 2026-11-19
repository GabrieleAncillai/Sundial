/// One line on the shopping list. A linked [homeItemId] means checking it off
/// adjusts that inventory variant.
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    this.contextId,
    required this.name,
    this.quantity = 1,
    this.unit = '',
    this.packSize = '',
    this.checked = false,
    this.note = '',
    this.homeItemId,
    this.catalogId,
    this.category = '',
    this.categoryId,
    this.icon = 'shopping_basket',
    this.colorValue,
    this.position = 0,
  });

  final String id;
  final String? contextId;
  final String name;
  final double quantity;
  final String unit;

  /// Size or pack description carried over from the inventory variant.
  final String packSize;

  final bool checked;
  final String note;

  /// Inventory variant this line restocks.
  final String? homeItemId;
  final String? catalogId;

  /// Legacy/display category copy plus the reference id.
  final String category;
  final String? categoryId;

  final String icon;
  final int? colorValue;

  /// Manual order inside the shopping list. Lower values come first.
  final int position;

  ShoppingItem copyWith({
    String? contextId,
    bool clearContext = false,
    String? name,
    double? quantity,
    String? unit,
    String? packSize,
    bool? checked,
    String? note,
    String? homeItemId,
    bool clearHomeItem = false,
    String? catalogId,
    bool clearCatalog = false,
    String? category,
    String? categoryId,
    bool clearCategory = false,
    String? icon,
    int? colorValue,
    bool clearColor = false,
    int? position,
  }) => ShoppingItem(
    id: id,
    contextId: clearContext ? null : (contextId ?? this.contextId),
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    packSize: packSize ?? this.packSize,
    checked: checked ?? this.checked,
    note: note ?? this.note,
    homeItemId: clearHomeItem ? null : (homeItemId ?? this.homeItemId),
    catalogId: clearCatalog ? null : (catalogId ?? this.catalogId),
    category: category ?? this.category,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    icon: icon ?? this.icon,
    colorValue: clearColor ? null : (colorValue ?? this.colorValue),
    position: position ?? this.position,
  );
}
