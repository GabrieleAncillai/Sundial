import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n.dart';
import '../../../models/home_reference.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../shopping_suggestions.dart';
import 'home_art.dart';

/// The low/expired-stock prompt shared by inventory and shopping. Shopping
/// passes [showActions] so each row can become a line without opening a sheet.
class StockSuggestionCard extends ConsumerWidget {
  const StockSuggestionCard({
    super.key,
    required this.suggestions,
    required this.units,
    this.showActions = false,
  });

  final List<ShoppingSuggestion> suggestions;
  final List<HomeUnit> units;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final pending = suggestions.where((suggestion) => !suggestion.alreadyListed).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
      decoration: BoxDecoration(
        color: c.warningSoft,
        borderRadius: BorderRadius.circular(SundialRadii.lg),
        border: Border.all(color: c.warning.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: c.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.stockSuggestions, style: SundialType.label(13, color: c.warning)),
                    Text(l10n.stockSuggestionsBody, style: SundialType.body(11, color: c.textSecondary)),
                  ],
                ),
              ),
              if (pending > 0)
                TextButton(onPressed: () => _addAll(context, ref), child: Text(l10n.addAllSuggestions)),
            ],
          ),
          const SizedBox(height: 7),
          for (final suggestion in suggestions.take(showActions ? 6 : 4)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  HomeArtForItem(item: suggestion.item, size: 28),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          homeItemDisplayName(suggestion.item, locale),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SundialType.body(12.5, color: c.text),
                        ),
                        Text(
                          suggestion.alreadyListed
                              ? l10n.suggestionAlreadyListed
                              : suggestionReason(context, suggestion, units),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SundialType.body(10.5, color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (showActions && !suggestion.alreadyListed)
                    TextButton(
                      onPressed: () => _addOne(context, ref, suggestion),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(l10n.addSuggestion),
                    )
                  else if (suggestion.alreadyListed)
                    Icon(Icons.check_circle_outline, size: 18, color: c.success),
                ],
              ),
            ),
          ],
          if (suggestions.length > (showActions ? 6 : 4))
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 2),
              child: Text(
                suggestions.length == 1
                    ? l10n.shoppingItemsCountOne
                    : l10n.shoppingItemsCount(suggestions.length),
                style: SundialType.body(11, color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addAll(BuildContext context, WidgetRef ref) async {
    final added = await addShoppingSuggestions(
      ref,
      suggestions.where((suggestion) => !suggestion.alreadyListed),
    );
    if (!context.mounted) return;
    _showAdded(context, added);
  }

  Future<void> _addOne(BuildContext context, WidgetRef ref, ShoppingSuggestion suggestion) async {
    final added = await addShoppingSuggestions(ref, [suggestion]);
    if (!context.mounted) return;
    _showAdded(context, added);
  }

  void _showAdded(BuildContext context, int added) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.shoppingItemsCount(added))));
  }
}

String suggestionReason(BuildContext context, ShoppingSuggestion suggestion, List<HomeUnit> units) {
  final locale = Localizations.localeOf(context);
  return switch (suggestion.reason) {
    ShoppingSuggestionReason.outOfStock => context.l10n.suggestionOutOfStock,
    ShoppingSuggestionReason.expired => context.l10n.suggestionExpired,
    ShoppingSuggestionReason.lowStock => context.l10n.suggestionLowStock(
      variantQuantityLabel(suggestion.item.copyWith(quantity: suggestion.quantity), units, locale),
    ),
  };
}
