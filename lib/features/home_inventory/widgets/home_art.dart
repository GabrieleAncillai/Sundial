import 'package:flutter/material.dart';

import '../../../core/icons/sundial_icons.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../data/household_catalog.dart';
import '../../../models/home_item.dart';
import '../../../models/home_reference.dart';
import '../../../models/household_catalog_item.dart';
import '../../../models/shopping_item.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';

/// Resolves the localized catalog name while keeping user renames intact.
String homeItemDisplayName(HomeItem item, Locale locale) {
  final catalog = householdCatalogItemById(item.catalogId);
  if (catalog == null || item.name != catalog.name) return item.name;
  return catalog.displayName(locale);
}

String homeItemDisplayDescription(HomeItem item, Locale locale) {
  final catalog = householdCatalogItemById(item.catalogId);
  if (catalog == null || item.description != catalog.description) return item.description;
  return catalog.displayDescription(locale);
}

String shoppingItemDisplayName(ShoppingItem item, Locale locale) {
  final catalog = householdCatalogItemById(item.catalogId);
  if (catalog == null || item.name != catalog.name) return item.name;
  return catalog.displayName(locale);
}

HouseholdCatalogItem? homeItemCatalog(HomeItem item) => householdCatalogItemById(item.catalogId);

String homeItemIcon(HomeItem item) {
  if (item.icon.isNotEmpty && item.icon != 'inventory') return item.icon;
  return homeItemCatalog(item)?.icon ?? item.icon;
}

int? homeItemColorValue(HomeItem item) => item.colorValue ?? homeItemCatalog(item)?.colorValue;

String shoppingItemIcon(ShoppingItem item) {
  if (item.icon.isNotEmpty && item.icon != 'shopping_basket') return item.icon;
  return householdCatalogItemById(item.catalogId)?.icon ?? item.icon;
}

int? shoppingItemColorValue(ShoppingItem item) => item.colorValue;

HomeCategory? homeCategoryFor(String? categoryId, List<HomeCategory> categories) {
  if (categoryId == null) return null;
  for (final category in categories) {
    if (category.id == categoryId) return category;
  }
  return null;
}

String homeCategoryLabel(String? categoryId, String fallback, List<HomeCategory> categories, Locale locale) {
  final category = homeCategoryFor(categoryId, categories);
  if (category == null) return fallback;
  return localizedCategoryName(category, locale);
}

String homeLocationsLabel(HomeItem item, List<HomeLocation> locations, Locale locale) {
  if (item.locationIds.isEmpty) return item.location;
  final names = <String>[];
  for (final id in item.locationIds) {
    for (final location in locations) {
      if (location.id != id) continue;
      names.add(localizedLocationName(location, locale));
      break;
    }
  }
  return names.isEmpty ? item.location : names.join(', ');
}

/// A tinted art tile that stands in for a product photo. Catalog icons are
/// chosen per item, so the inventory reads at a glance without network images.
class HomeArt extends StatelessWidget {
  const HomeArt({
    super.key,
    required this.icon,
    this.colorValue,
    this.size = 48,
    this.radius = SundialRadii.md,
  });

  final String icon;
  final int? colorValue;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final tint = colorValue == null ? c.home : Color(colorValue!);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.22), tint.withValues(alpha: 0.06)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tint.withValues(alpha: 0.18)),
      ),
      child: Icon(SundialIcons.resolve(icon), size: size * 0.5, color: tint),
    );
  }
}

class HomeArtForItem extends StatelessWidget {
  const HomeArtForItem({super.key, required this.item, this.size = 48});

  final HomeItem item;
  final double size;

  @override
  Widget build(BuildContext context) =>
      HomeArt(icon: homeItemIcon(item), colorValue: homeItemColorValue(item), size: size);
}

String formatHomeQuantity(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);

HomeUnit? homeUnitFor(String? unitId, List<HomeUnit> units) {
  if (unitId == null) return null;
  for (final unit in units) {
    if (unit.id == unitId) return unit;
  }
  return null;
}

HomeUnit? homeUnitByName(String name, List<HomeUnit> units) {
  final query = name.trim().toLowerCase();
  if (query.isEmpty) return null;
  for (final unit in units) {
    if (unit.name.toLowerCase() == query || unit.symbol.toLowerCase() == query) return unit;
  }
  return null;
}

/// `3 Bottle · 5 gal`: the quantity is a count of the unit, and the pack size
/// describes which size that count refers to. It is never a multiplier.
String quantityWithPack(double quantity, String unitLabel, String packSize) {
  final number = formatHomeQuantity(quantity);
  final base = unitLabel.isEmpty ? number : '$number $unitLabel';
  final pack = packSize.trim();
  return pack.isEmpty ? base : '$base · $pack';
}

String _unitLabel(HomeUnit? unit, String fallback, Locale locale) {
  // The reference defaults carry Spanish names in the data layer. User-created
  // units keep the name they were given.
  return unit == null ? fallback : localizedUnitName(unit, locale);
}

String variantQuantityLabel(HomeItem item, List<HomeUnit> units, Locale locale) => quantityWithPack(
  item.quantity,
  _unitLabel(homeUnitFor(item.unitId, units), item.unit, locale),
  item.packSize,
);

/// Quantity and unit only, for thresholds where repeating the pack size is noise.
String variantUnitQuantityLabel(HomeItem item, double quantity, List<HomeUnit> units, Locale locale) {
  final number = formatHomeQuantity(quantity);
  final label = _unitLabel(homeUnitFor(item.unitId, units), item.unit, locale);
  return label.isEmpty ? number : '$number $label';
}

String shoppingQuantityLabel(ShoppingItem item, HomeItem? linked, List<HomeUnit> units, Locale locale) {
  if (linked != null) {
    return quantityWithPack(
      item.quantity,
      _unitLabel(homeUnitFor(linked.unitId, units), linked.unit, locale),
      linked.packSize,
    );
  }
  return quantityWithPack(
    item.quantity,
    _unitLabel(homeUnitByName(item.unit, units), item.unit, locale),
    item.packSize,
  );
}
