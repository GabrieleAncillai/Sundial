import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../models/home_item.dart';
import '../../models/shopping_item.dart';
import '../../state/providers.dart';

enum ShoppingSuggestionReason { outOfStock, lowStock, expired }

class ShoppingSuggestion {
  const ShoppingSuggestion({
    required this.item,
    required this.reason,
    required this.quantity,
    required this.alreadyListed,
  });

  final HomeItem item;
  final ShoppingSuggestionReason reason;
  final double quantity;
  final bool alreadyListed;
}

/// Items that deserve a shopping line: out of stock first, then low stock,
/// then expired stock that needs replacing. A line already on the list is kept
/// in the result so the card can explain why it will not be duplicated.
List<ShoppingSuggestion> buildShoppingSuggestions({
  required Iterable<HomeItem> items,
  required Iterable<ShoppingItem> shopping,
  required LocalDate today,
}) {
  final listed = {
    for (final line in shopping)
      if (!line.checked && line.homeItemId != null) line.homeItemId!,
  };
  final suggestions = <ShoppingSuggestion>[];
  for (final item in items) {
    final ShoppingSuggestionReason? reason;
    if (item.isOutOfStock) {
      reason = ShoppingSuggestionReason.outOfStock;
    } else if (item.isLowStock) {
      reason = ShoppingSuggestionReason.lowStock;
    } else if (item.isExpiredOn(today)) {
      reason = ShoppingSuggestionReason.expired;
    } else {
      reason = null;
    }
    if (reason == null) continue;
    suggestions.add(
      ShoppingSuggestion(
        item: item,
        reason: reason,
        quantity: math.max(1, item.suggestedPurchase),
        alreadyListed: listed.contains(item.id),
      ),
    );
  }
  suggestions.sort((a, b) {
    final byReason = a.reason.index.compareTo(b.reason.index);
    if (byReason != 0) return byReason;
    return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  });
  return suggestions;
}

/// Adds every suggestion that is not already on the list. Returns the number of
/// new lines.
Future<int> addShoppingSuggestions(WidgetRef ref, Iterable<ShoppingSuggestion> suggestions) async {
  final repository = ref.read(repositoryProvider);
  var added = 0;
  for (final suggestion in suggestions) {
    if (suggestion.alreadyListed) continue;
    final item = suggestion.item;
    await repository.saveShoppingItem(
      ShoppingItem(
        id: const Uuid().v4(),
        contextId: item.contextId,
        name: item.name,
        quantity: suggestion.quantity,
        unit: item.unit,
        packSize: item.packSize,
        homeItemId: item.id,
        catalogId: item.catalogId,
        category: item.category,
        categoryId: item.categoryId,
        icon: item.icon,
        colorValue: item.colorValue,
      ),
    );
    added++;
  }
  return added;
}
