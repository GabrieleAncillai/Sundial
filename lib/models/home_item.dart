import 'dart:math' as math;

import 'package:sundial_core/sundial_core.dart';

/// One stock variant of a household product.
///
/// A product can have several variants that share [groupId] but use different
/// pack sizes or units, for example a 5-gallon water bottle and a 5-litre
/// bottle. Quantity, expiry, minimum stock and locations belong to the variant;
/// name, description, art and category belong to the product.
class HomeItem {
  const HomeItem({
    required this.id,
    this.contextId,
    this.groupId,
    required this.name,
    this.description = '',
    this.icon = 'inventory',
    this.colorValue,
    this.catalogId,
    this.category = '',
    this.categoryId,
    this.location = '',
    this.locationIds = const <String>[],
    this.quantity = 0,
    this.unit = '',
    this.unitId,
    this.packSize = '',
    this.minQuantity,
    this.reorderLevel,
    this.expiresAt,
    this.notes = '',
    this.lastPurchasedAt,
  });

  static const _unset = Object();

  final String id;
  final String? contextId;

  /// Product identity shared by every variant of the same household item.
  /// Null on legacy rows; [productGroupId] falls back to [id].
  final String? groupId;

  final String name;
  final String description;

  /// A `SundialIcons` key used as the product art.
  final String icon;
  final int? colorValue;
  final String? catalogId;

  /// Legacy/display copy of the category name. New writes keep it in sync with
  /// [categoryId] so search, CSV and older snapshots keep working.
  final String category;
  final String? categoryId;

  /// Legacy/display copy of the joined location names.
  final String location;
  final List<String> locationIds;

  final double quantity;
  final String unit;
  final String? unitId;

  /// Human-readable pack size, for example `5 gal` or `pack of 6`.
  final String packSize;

  /// Minimum stock at or below which the item is considered low. Replaces the
  /// old reorder level.
  final double? minQuantity;

  /// Legacy alias kept for older backups and CSV files.
  final double? reorderLevel;

  final LocalDate? expiresAt;
  final String notes;
  final DateTime? lastPurchasedAt;

  String get productGroupId => groupId ?? id;

  double? get minimumStock => minQuantity ?? reorderLevel;

  bool get hasMinimum => minimumStock != null;

  bool get isLowStock => minimumStock != null && quantity <= minimumStock!;

  bool get isOutOfStock => quantity <= 0;

  bool isExpiredOn(LocalDate today) => expiresAt != null && expiresAt!.isBefore(today);

  bool expiresWithin(LocalDate today, int days) {
    final expires = expiresAt;
    if (expires == null) return false;
    return !expires.isBefore(today) && expires.isBefore(today.addDays(days + 1));
  }

  /// Enough to get comfortably above the minimum, with a floor of one unit.
  double get suggestedPurchase {
    final minimum = minimumStock;
    if (minimum == null) return quantity <= 0 ? 1 : 0;
    final target = (minimum * 2) - quantity;
    return math.max(1, target);
  }

  HomeItem copyWith({
    String? contextId,
    bool clearContext = false,
    Object? groupId = _unset,
    String? name,
    String? description,
    String? icon,
    Object? colorValue = _unset,
    Object? catalogId = _unset,
    String? category,
    Object? categoryId = _unset,
    String? location,
    List<String>? locationIds,
    double? quantity,
    String? unit,
    Object? unitId = _unset,
    String? packSize,
    Object? minQuantity = _unset,
    Object? reorderLevel = _unset,
    Object? expiresAt = _unset,
    String? notes,
    DateTime? lastPurchasedAt,
  }) => HomeItem(
    id: id,
    contextId: clearContext ? null : (contextId ?? this.contextId),
    groupId: identical(groupId, _unset) ? this.groupId : groupId as String?,
    name: name ?? this.name,
    description: description ?? this.description,
    icon: icon ?? this.icon,
    colorValue: identical(colorValue, _unset) ? this.colorValue : colorValue as int?,
    catalogId: identical(catalogId, _unset) ? this.catalogId : catalogId as String?,
    category: category ?? this.category,
    categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as String?,
    location: location ?? this.location,
    locationIds: locationIds ?? this.locationIds,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    unitId: identical(unitId, _unset) ? this.unitId : unitId as String?,
    packSize: packSize ?? this.packSize,
    minQuantity: identical(minQuantity, _unset) ? this.minQuantity : minQuantity as double?,
    reorderLevel: identical(reorderLevel, _unset) ? this.reorderLevel : reorderLevel as double?,
    expiresAt: identical(expiresAt, _unset) ? this.expiresAt : expiresAt as LocalDate?,
    notes: notes ?? this.notes,
    lastPurchasedAt: lastPurchasedAt ?? this.lastPurchasedAt,
  );
}

/// A product card groups every stock variant that shares [HomeItem.groupId].
class HomeProductGroup {
  const HomeProductGroup({required this.id, required this.variants});

  final String id;
  final List<HomeItem> variants;

  HomeItem get lead => variants.first;

  String get name => lead.name;

  String get description => lead.description;

  String get icon => lead.icon;

  int? get colorValue => lead.colorValue;

  String get category => lead.category;

  String? get categoryId => lead.categoryId;

  String? get catalogId => lead.catalogId;

  bool get isLowStock => variants.any((variant) => variant.isLowStock);

  bool get hasOutOfStock => variants.any((variant) => variant.isOutOfStock);
}

/// Groups variants by [HomeItem.productGroupId], preserving catalog order when
/// possible and falling back to the product name.
List<HomeProductGroup> groupHomeProducts(Iterable<HomeItem> items) {
  final groups = <String, List<HomeItem>>{};
  for (final item in items) {
    (groups[item.productGroupId] ??= <HomeItem>[]).add(item);
  }
  final result =
      [
        for (final entry in groups.entries)
          HomeProductGroup(
            id: entry.key,
            variants: entry.value
              ..sort((a, b) {
                final byPack = a.packSize.toLowerCase().compareTo(b.packSize.toLowerCase());
                return byPack != 0 ? byPack : a.id.compareTo(b.id);
              }),
          ),
      ]..sort((a, b) {
        final byCategory = a.category.toLowerCase().compareTo(b.category.toLowerCase());
        if (byCategory != 0) return byCategory;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  return result;
}
