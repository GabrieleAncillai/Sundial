import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../models/home_item.dart';
import '../../../models/home_reference.dart';
import '../../../models/shopping_item.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../home_scope.dart';
import '../pages/household_catalog_page.dart';
import '../shopping_suggestions.dart';
import '../widgets/home_art.dart';
import '../widgets/shopping_item_sheet.dart';
import '../widgets/stock_suggestion_card.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key, this.contextId});

  final String? contextId;

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final today = localDateAt(ref.watch(nowProvider), ref.watch(deviceTimeZoneProvider));
    final shoppingState = ref.watch(shoppingItemsProvider);
    final allShopping = shoppingState.value ?? const <ShoppingItem>[];
    final items = widget.contextId == null
        ? allShopping
        : allShopping.where((item) => item.contextId == widget.contextId).toList();
    final allHome = ref.watch(homeItemsProvider).value ?? const <HomeItem>[];
    final homeItems = widget.contextId == null
        ? allHome
        : allHome.where((item) => item.contextId == widget.contextId).toList();
    final homeById = {for (final item in homeItems) item.id: item};
    final categories = ref.watch(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final units = ref.watch(homeUnitsProvider).value ?? const <HomeUnit>[];
    final suggestions = buildShoppingSuggestions(items: homeItems, shopping: items, today: today);
    final available = items.where((item) => !item.checked).toList();
    final allBought = items.where((item) => item.checked).toList();
    final filtered = available.where((item) => _matches(item, homeById, categories, units, locale)).toList();
    final bought = allBought.where((item) => _matches(item, homeById, categories, units, locale)).toList();
    final groups = _groupItems(filtered, homeById, categories, locale, l10n.shoppingOther);
    final done = allBought.length;

    return SundialPage(
      title: l10n.shoppingList,
      subtitle: items.isEmpty ? l10n.shoppingListSubtitle : l10n.shoppingProgress(done, items.length),
      floatingAction: items.isEmpty
          ? null
          : SundialAddButton(tooltip: l10n.addShoppingItem, onTap: () => _openCatalog(context, ref)),
      child: items.isEmpty && suggestions.isEmpty && !shoppingState.hasError
          ? AppEmptyState(
              icon: Icons.shopping_basket_outlined,
              title: l10n.shoppingListEmpty,
              message: l10n.shoppingListEmptyBody,
              action: FilledButton.tonalIcon(
                onPressed: () => _openCatalog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addShoppingItem),
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (shoppingState.hasError)
                  SundialNotice(text: l10n.couldNotLoadHome('${shoppingState.error}')),
                if (items.isEmpty && suggestions.isEmpty)
                  AppEmptyState(
                    icon: Icons.shopping_basket_outlined,
                    title: l10n.shoppingListEmpty,
                    message: l10n.shoppingListEmptyBody,
                    action: FilledButton.tonalIcon(
                      onPressed: () => _openCatalog(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.addShoppingItem),
                    ),
                  ),
                if (suggestions.isNotEmpty)
                  StockSuggestionCard(suggestions: suggestions, units: units, showActions: true),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Center(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _addOneOff(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.shoppingOneOff),
                      ),
                    ),
                  ),
                if (items.isNotEmpty) ...[
                  SundialSearchField(
                    controller: _search,
                    hint: l10n.shoppingSearch,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 14),
                ],
                if (groups.isNotEmpty) ...[
                  SectionLabel(l10n.shoppingToBuy),
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 2, 10, 7),
                      child: Row(
                        children: [
                          if (group.icon != null) ...[
                            Icon(SundialIcons.resolve(group.icon!), size: 15, color: group.color),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(group.label, style: SundialType.label(12, color: c.textSecondary)),
                          ),
                          Text(
                            group.items.length == 1
                                ? l10n.shoppingItemsCountOne
                                : l10n.shoppingItemsCount(group.items.length),
                            style: SundialType.body(10.5, color: c.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    SoftCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      clip: true,
                      child: Column(
                        children: [
                          for (var index = 0; index < group.items.length; index++) ...[
                            if (index > 0) const Divider(height: 1, indent: 50),
                            _ShoppingRow(
                              item: group.items[index],
                              linked: homeById[group.items[index].homeItemId],
                              units: units,
                              onChecked: (value) =>
                                  _setChecked(context, ref, group.items[index], homeById, units, value),
                              onEdit: () => showShoppingItemSheet(
                                context,
                                item: group.items[index],
                                contextId: widget.contextId,
                              ),
                              onDelete: () =>
                                  ref.read(repositoryProvider).deleteShoppingItem(group.items[index].id),
                              onMoveUp: () =>
                                  ref.read(repositoryProvider).moveShoppingItem(group.items[index].id, -1),
                              onMoveDown: () =>
                                  ref.read(repositoryProvider).moveShoppingItem(group.items[index].id, 1),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                if (filtered.isEmpty && available.isNotEmpty)
                  AppEmptyState(
                    icon: Icons.search_off_outlined,
                    title: l10n.inventoryNoMatches,
                    compact: true,
                  ),
                if (bought.isNotEmpty) ...[
                  SectionLabel(
                    l10n.shoppingBought,
                    trailing: TextButton(
                      onPressed: () => _clearBought(context, ref),
                      child: Text(l10n.clearChecked),
                    ),
                  ),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    clip: true,
                    child: Column(
                      children: [
                        for (var index = 0; index < bought.length; index++) ...[
                          if (index > 0) const Divider(height: 1, indent: 50),
                          _ShoppingRow(
                            item: bought[index],
                            linked: homeById[bought[index].homeItemId],
                            units: units,
                            onChecked: (value) =>
                                _setChecked(context, ref, bought[index], homeById, units, value),
                            onEdit: () => showShoppingItemSheet(
                              context,
                              item: bought[index],
                              contextId: widget.contextId,
                            ),
                            onDelete: () => ref.read(repositoryProvider).deleteShoppingItem(bought[index].id),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(l10n.shoppingListSubtitle, style: SundialType.body(12, color: c.textTertiary)),
                ),
              ],
            ),
    );
  }

  bool _matches(
    ShoppingItem item,
    Map<String, HomeItem> homeById,
    List<HomeCategory> categories,
    List<HomeUnit> units,
    Locale locale,
  ) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final linked = homeById[item.homeItemId];
    final category = homeCategoryLabel(
      item.categoryId ?? linked?.categoryId,
      item.category.isEmpty ? (linked?.category ?? '') : item.category,
      categories,
      locale,
    );
    return item.name.toLowerCase().contains(query) ||
        item.note.toLowerCase().contains(query) ||
        item.packSize.toLowerCase().contains(query) ||
        category.toLowerCase().contains(query) ||
        shoppingQuantityLabel(item, linked, units, locale).toLowerCase().contains(query) ||
        (linked != null && homeItemDisplayName(linked, locale).toLowerCase().contains(query));
  }

  static List<_ShoppingGroup> _groupItems(
    List<ShoppingItem> items,
    Map<String, HomeItem> homeById,
    List<HomeCategory> categories,
    Locale locale,
    String otherLabel,
  ) {
    final groups = <String, _ShoppingGroup>{};
    for (final item in items) {
      final linked = homeById[item.homeItemId];
      final categoryId = item.categoryId ?? linked?.categoryId;
      final category = homeCategoryFor(categoryId, categories);
      final label = category == null
          ? (item.category.isNotEmpty
                ? item.category
                : (linked?.category.isNotEmpty == true ? linked!.category : otherLabel))
          : localizedCategoryName(category, locale);
      final key = category?.id ?? label;
      final group = groups[key] ??= _ShoppingGroup(
        key: key,
        label: label,
        icon: category?.icon,
        color: category == null ? null : Color(category.colorValue),
        items: <ShoppingItem>[],
      );
      group.items.add(item);
    }
    final categoryOrder = {
      for (var index = 0; index < categories.length; index++) categories[index].id: index,
    };
    final ordered = groups.values.toList()
      ..sort((a, b) {
        final aIndex = categoryOrder[a.key];
        final bIndex = categoryOrder[b.key];
        if (aIndex != null && bIndex != null) return aIndex.compareTo(bIndex);
        if (aIndex != null) return -1;
        if (bIndex != null) return 1;
        if (a.label == otherLabel) return 1;
        if (b.label == otherLabel) return -1;
        return a.label.compareTo(b.label);
      });
    return ordered;
  }

  Future<void> _setChecked(
    BuildContext context,
    WidgetRef ref,
    ShoppingItem item,
    Map<String, HomeItem> homeById,
    List<HomeUnit> units,
    bool checked,
  ) async {
    await ref.read(repositoryProvider).setShoppingChecked(item.id, checked);
    if (!context.mounted) return;
    final linked = homeById[item.homeItemId];
    if (checked && linked != null) {
      final locale = Localizations.localeOf(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.addedToInventory(
              variantQuantityLabel(linked.copyWith(quantity: item.quantity), units, locale),
              homeItemDisplayName(linked, locale),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _openCatalog(BuildContext context, WidgetRef ref) async {
    final homeId = await chooseHomeScope(context, ref, contextId: widget.contextId);
    if (homeId == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HouseholdCatalogPage(homeId: homeId, mode: CatalogPickerMode.shopping),
      ),
    );
  }

  Future<void> _addOneOff(BuildContext context, WidgetRef ref) async {
    final homeId = await chooseHomeScope(context, ref, contextId: widget.contextId);
    if (homeId == null || !context.mounted) return;
    await showShoppingItemSheet(context, contextId: homeId);
  }

  Future<void> _clearBought(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearChecked),
        content: Text(l10n.clearCheckedBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.clearChecked),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(repositoryProvider).clearCheckedShopping(contextId: widget.contextId);
    }
  }
}

class _ShoppingGroup {
  _ShoppingGroup({required this.key, required this.label, required this.items, this.icon, this.color});

  final String key;
  final String label;
  final List<ShoppingItem> items;
  final String? icon;
  final Color? color;
}

class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.linked,
    required this.units,
    required this.onChecked,
    required this.onEdit,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final ShoppingItem item;
  final HomeItem? linked;
  final List<HomeUnit> units;
  final ValueChanged<bool> onChecked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final name = linked == null
        ? shoppingItemDisplayName(item, locale)
        : homeItemDisplayName(linked!, locale);
    final quantityLabel = shoppingQuantityLabel(item, linked, units, locale);
    final details = [
      quantityLabel,
      if (linked != null) l10n.restocksInventory,
      if (item.note.isNotEmpty) item.note,
    ].where((part) => part.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 4, 2),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Semantics(
              label: name,
              child: Checkbox(
                value: item.checked,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (value) => onChecked(value == true),
              ),
            ),
          ),
          HomeArt(
            icon: linked == null ? shoppingItemIcon(item) : homeItemIcon(linked!),
            colorValue: linked == null ? shoppingItemColorValue(item) : homeItemColorValue(linked!),
            size: 30,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Pressable(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(
                        14,
                        weight: FontWeight.w700,
                        color: item.checked ? c.textTertiary : c.text,
                      ).copyWith(decoration: item.checked ? TextDecoration.lineThrough : null),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SundialType.body(11.5, color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: c.textTertiary),
            onSelected: (value) => switch (value) {
              'up' => onMoveUp?.call(),
              'down' => onMoveDown?.call(),
              'edit' => onEdit(),
              _ => onDelete(),
            },
            itemBuilder: (context) => [
              if (onMoveUp != null) PopupMenuItem(value: 'up', child: Text(l10n.moveUp)),
              if (onMoveDown != null) PopupMenuItem(value: 'down', child: Text(l10n.moveDown)),
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }
}
