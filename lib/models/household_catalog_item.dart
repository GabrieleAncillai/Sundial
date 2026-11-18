import 'package:flutter/widgets.dart';

/// A household item in the built-in catalog.
///
/// Catalog entries are reference data, not inventory rows. Selecting one
/// creates a normal [HomeItem] with sensible defaults and a stable
/// [catalogId], so later language changes can use the localized name without
/// rewriting user data.
class HouseholdCatalogItem {
  const HouseholdCatalogItem({
    required this.id,
    required this.name,
    required this.nameEs,
    required this.description,
    required this.descriptionEs,
    required this.icon,
    required this.colorValue,
    required this.categoryId,
    required this.unitId,
    this.defaultMinQuantity = 1,
    this.defaultPackSize = '',
    this.shelfLifeDays,
    this.keywords = const <String>[],
  });

  final String id;
  final String name;
  final String nameEs;
  final String description;
  final String descriptionEs;

  /// A `SundialIcons` key. The catalog renders it on a tinted art tile.
  final String icon;
  final int colorValue;

  /// Default reference ids. A deleted default falls back to no category or
  /// unit in the editor.
  final String categoryId;
  final String unitId;

  final double defaultMinQuantity;
  final String defaultPackSize;

  /// Optional shelf life used to prefill an expiry date on a new item.
  final int? shelfLifeDays;

  /// Extra search terms, including plurals and common Spanish words.
  final List<String> keywords;

  String displayName(Locale locale) => locale.languageCode == 'es' && nameEs.isNotEmpty ? nameEs : name;

  String displayDescription(Locale locale) =>
      locale.languageCode == 'es' && descriptionEs.isNotEmpty ? descriptionEs : description;

  bool matches(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return true;
    return name.toLowerCase().contains(term) ||
        nameEs.toLowerCase().contains(term) ||
        description.toLowerCase().contains(term) ||
        descriptionEs.toLowerCase().contains(term) ||
        keywords.any((keyword) => keyword.toLowerCase().contains(term));
  }
}
