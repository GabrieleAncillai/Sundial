import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../models/home_item.dart';
import '../../../models/home_purchase.dart';
import '../../../models/home_reference.dart';
import '../../../models/shopping_item.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/sundial_style.dart';
import '../home_scope.dart';
import '../pages/home_reference_page.dart';
import '../pages/household_catalog_page.dart';
import '../shopping_suggestions.dart';
import '../widgets/home_art.dart';
import '../widgets/home_item_sheet.dart';
import '../widgets/stock_suggestion_card.dart';

enum _InventoryFilter { all, low, expiring }

class HomeInventoryPage extends ConsumerStatefulWidget {
  const HomeInventoryPage({super.key, this.contextId});

  final String? contextId;

  @override
  ConsumerState<HomeInventoryPage> createState() => _HomeInventoryPageState();
}

class _HomeInventoryPageState extends ConsumerState<HomeInventoryPage> {
  final _search = TextEditingController();
  String _query = '';
  _InventoryFilter _filter = _InventoryFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final today = localDateAt(ref.watch(nowProvider), ref.watch(deviceTimeZoneProvider));
    final itemsState = ref.watch(homeItemsProvider);
    final allItems = itemsState.value ?? const <HomeItem>[];
    final items = widget.contextId == null
        ? allItems
        : allItems.where((item) => item.contextId == widget.contextId).toList();
    final categories = ref.watch(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final locations = ref.watch(homeLocationsProvider).value ?? const <HomeLocation>[];
    final units = ref.watch(homeUnitsProvider).value ?? const <HomeUnit>[];
    final shopping = ref.watch(shoppingItemsProvider).value ?? const <ShoppingItem>[];
    final suggestions = buildShoppingSuggestions(items: items, shopping: shopping, today: today);
    final groups = groupHomeProducts(items);
    final visible = groups
        .where((group) => _matches(group, today, locale, locations, categories, units))
        .toList();
    final grouped = <String?, List<HomeProductGroup>>{};
    for (final group in visible) {
      final text = group.category.trim();
      final key = group.categoryId ?? (text.isEmpty ? null : 'text:$text');
      (grouped[key] ??= <HomeProductGroup>[]).add(group);
    }
    final categoryOrder = {
      for (var index = 0; index < categories.length; index++) categories[index].id: index,
    };
    final groupKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aIndex = a == null ? null : categoryOrder[a];
        final bIndex = b == null ? null : categoryOrder[b];
        if (aIndex != null && bIndex != null) return aIndex.compareTo(bIndex);
        if (aIndex != null) return -1;
        if (bIndex != null) return 1;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    return SundialPage(
      title: l10n.homeInventory,
      subtitle: items.isEmpty
          ? l10n.homeInventorySubtitle
          : (groups.length == 1 ? l10n.productsCountOne : l10n.productsCount(groups.length)),
      actions: [
        IconButton(
          tooltip: l10n.manageInventorySetup,
          icon: const Icon(Icons.tune),
          onPressed: () => showHomeReferencePage(context, HomeReferenceTab.categories),
        ),
      ],
      floatingAction: items.isEmpty
          ? null
          : SundialAddButton(
              tooltip: l10n.addInventoryItem,
              icon: Icons.add,
              onTap: () => _openCatalog(context, ref),
            ),
      child: items.isEmpty
          ? ListView(
              children: [
                if (itemsState.hasError) SundialNotice(text: l10n.couldNotLoadHome('${itemsState.error}')),
                AppEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.homeInventoryEmpty,
                  message: l10n.homeInventoryEmptyBody,
                  action: FilledButton.tonalIcon(
                    onPressed: () => _openCatalog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.browseHouseholdCatalog),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (itemsState.hasError) SundialNotice(text: l10n.couldNotLoadHome('${itemsState.error}')),
                if (suggestions.isNotEmpty) StockSuggestionCard(suggestions: suggestions, units: units),
                SundialSearchField(
                  controller: _search,
                  hint: l10n.inventorySearch,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterPill(
                        label: l10n.inventoryFilterAll,
                        selected: _filter == _InventoryFilter.all,
                        onTap: () => setState(() => _filter = _InventoryFilter.all),
                      ),
                      const SizedBox(width: 7),
                      _FilterPill(
                        label: l10n.inventoryFilterLow,
                        selected: _filter == _InventoryFilter.low,
                        onTap: () => setState(() => _filter = _InventoryFilter.low),
                      ),
                      const SizedBox(width: 7),
                      _FilterPill(
                        label: l10n.inventoryFilterExpiring,
                        selected: _filter == _InventoryFilter.expiring,
                        onTap: () => setState(() => _filter = _InventoryFilter.expiring),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  AppEmptyState(
                    icon: Icons.search_off_outlined,
                    title: l10n.inventoryNoMatches,
                    compact: true,
                  )
                else ...[
                  for (final key in groupKeys) ...[
                    SectionLabel(
                      key == null
                          ? l10n.uncategorized
                          : key.startsWith('text:')
                          ? key.substring(5)
                          : (homeCategoryFor(key, categories) == null
                                ? l10n.uncategorized
                                : localizedCategoryName(homeCategoryFor(key, categories)!, locale)),
                    ),
                    for (final group in grouped[key]!) ...[
                      _ProductCard(
                        group: group,
                        categories: categories,
                        locations: locations,
                        units: units,
                        today: today,
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                  ],
                ],
              ],
            ),
    );
  }

  bool _matches(
    HomeProductGroup group,
    LocalDate today,
    Locale locale,
    List<HomeLocation> locations,
    List<HomeCategory> categories,
    List<HomeUnit> units,
  ) {
    if (_filter == _InventoryFilter.low && !group.isLowStock && !group.hasOutOfStock) return false;
    if (_filter == _InventoryFilter.expiring) {
      final expiring = group.variants.any(
        (variant) => variant.isExpiredOn(today) || variant.expiresWithin(today, 30),
      );
      if (!expiring) return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (group.name.toLowerCase().contains(query)) return true;
    if (group.description.toLowerCase().contains(query)) return true;
    if (group.category.toLowerCase().contains(query)) return true;
    if (homeCategoryLabel(
      group.categoryId,
      group.category,
      categories,
      locale,
    ).toLowerCase().contains(query)) {
      return true;
    }
    for (final variant in group.variants) {
      if (variant.notes.toLowerCase().contains(query)) return true;
      if (variant.packSize.toLowerCase().contains(query)) return true;
      if (homeItemDisplayName(variant, locale).toLowerCase().contains(query)) return true;
      if (homeItemDisplayDescription(variant, locale).toLowerCase().contains(query)) return true;
      if (variantQuantityLabel(variant, units, locale).toLowerCase().contains(query)) return true;
      if (homeLocationsLabel(variant, locations, locale).toLowerCase().contains(query)) return true;
    }
    return false;
  }

  Future<void> _openCatalog(BuildContext context, WidgetRef ref) async {
    final homeId = await chooseHomeScope(context, ref, contextId: widget.contextId);
    if (homeId == null || !context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => HouseholdCatalogPage(homeId: homeId)));
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.group,
    required this.categories,
    required this.locations,
    required this.units,
    required this.today,
  });

  final HomeProductGroup group;
  final List<HomeCategory> categories;
  final List<HomeLocation> locations;
  final List<HomeUnit> units;
  final LocalDate today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final locationsText = {
      for (final variant in group.variants) homeLocationsLabel(variant, locations, locale),
    }.where((text) => text.isNotEmpty).join(', ');
    final categoryText = homeCategoryLabel(group.categoryId, group.category, categories, locale);
    final low = group.isLowStock || group.hasOutOfStock;
    final expiring = group.variants.any(
      (variant) => variant.isExpiredOn(today) || variant.expiresWithin(today, 30),
    );
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Pressable(
                  onTap: () => showHomeItemSheet(context, item: group.lead, updateGroup: true),
                  child: Row(
                    children: [
                      HomeArt(
                        icon: homeItemIcon(group.lead),
                        colorValue: homeItemColorValue(group.lead),
                        size: 44,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    homeItemDisplayName(group.lead, locale),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: SundialType.body(14.5, weight: FontWeight.w700, color: c.text),
                                  ),
                                ),
                                if (low) ...[
                                  const SizedBox(width: 7),
                                  _Badge(label: l10n.lowStockItems, color: c.danger, soft: c.dangerSoft),
                                ] else if (expiring) ...[
                                  const SizedBox(width: 7),
                                  _Badge(label: l10n.expiringItems, color: c.warning, soft: c.warningSoft),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (categoryText.isNotEmpty) categoryText,
                                if (locationsText.isNotEmpty) locationsText,
                                group.variants.length == 1
                                    ? l10n.variantsCountOne
                                    : l10n.variantsCount(group.variants.length),
                              ].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SundialType.body(11.5, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SundialMenuButton<String>(
                tooltip: l10n.moreActions,
                headerTitle: homeItemDisplayName(group.lead, locale),
                headerCaption: categoryText.isEmpty ? null : categoryText,
                onSelected: (value) async {
                  switch (value) {
                    case 'variant':
                      await showHomeItemSheet(context, variantOf: group.lead);
                    case 'history':
                      await showAppSheet<void>(
                        context: context,
                        builder: (_) => _PurchaseHistorySheet(group: group),
                      );
                    case 'archive':
                      await _archive(context, ref);
                    default:
                      await showHomeItemSheet(context, item: group.lead, updateGroup: true);
                  }
                },
                actions: [
                  SundialMenuAction(value: 'edit', label: l10n.editProduct, icon: Icons.edit_outlined),
                  SundialMenuAction(
                    value: 'variant',
                    label: l10n.addAnotherSize,
                    icon: Icons.add_box_outlined,
                  ),
                  SundialMenuAction(
                    value: 'history',
                    label: l10n.purchaseHistory,
                    icon: Icons.history_rounded,
                  ),
                  SundialMenuAction(
                    value: 'archive',
                    label: l10n.remove,
                    icon: Icons.archive_outlined,
                    dividerBefore: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var index = 0; index < group.variants.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 38),
            _VariantRow(
              variant: group.variants[index],
              units: units,
              locations: locations,
              today: today,
              groupSize: group.variants.length,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveProductQuestion),
        content: Text(l10n.archiveProductBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(repositoryProvider).archiveHomeGroup(group.id);
      if (context.mounted) playUiSound(context, UiSound.remove);
    }
  }
}

class _VariantRow extends ConsumerWidget {
  const _VariantRow({
    required this.variant,
    required this.units,
    required this.locations,
    required this.today,
    required this.groupSize,
  });

  final HomeItem variant;
  final List<HomeUnit> units;
  final List<HomeLocation> locations;
  final LocalDate today;
  final int groupSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final expiry = variant.expiresAt;
    final expiryLabel = expiry == null
        ? null
        : expiry.isBefore(today)
        ? l10n.expiredOn(formatShortDate(context, expiry.toDateTime()))
        : expiry == today
        ? l10n.expiresToday
        : expiry.isBefore(today.addDays(31))
        ? l10n.expiresOn(formatShortDate(context, expiry.toDateTime()))
        : null;
    final locationText = homeLocationsLabel(variant, locations, locale);
    final details = [
      variantQuantityLabel(variant, units, locale),
      if (locationText.isNotEmpty) locationText,
      ?expiryLabel,
      if (variant.minimumStock != null)
        l10n.minStockValue(variantUnitQuantityLabel(variant, variant.minimumStock!, units, locale)),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 1, 0, 1),
      child: Row(
        children: [
          HomeArt(icon: homeItemIcon(variant), colorValue: homeItemColorValue(variant), size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Pressable(
              onTap: () => showHomeItemSheet(context, item: variant),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SundialType.body(
                    11.5,
                    color: expiry != null && !expiry.isAfter(today) ? c.danger : c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          _QtyButton(
            icon: Icons.remove,
            tooltip: l10n.decreaseQuantity,
            onTap: () {
              playUiSound(context, UiSound.toggleOff);
              ref.read(repositoryProvider).adjustHomeQuantity(variant.id, -1);
            },
          ),
          _QtyButton(
            icon: Icons.add,
            tooltip: l10n.increaseQuantity,
            onTap: () {
              playUiSound(context, UiSound.toggleOn);
              ref.read(repositoryProvider).adjustHomeQuantity(variant.id, 1);
            },
          ),
          SundialMenuButton<String>(
            tooltip: l10n.moreActions,
            headerTitle: homeItemDisplayName(variant, locale),
            onSelected: (value) async {
              if (value == 'edit') {
                await showHomeItemSheet(context, item: variant);
                return;
              }
              if (value == 'archive') {
                await _archive(context, ref);
                return;
              }
              await showAppSheet<void>(
                context: context,
                builder: (_) => _PurchaseHistorySheet(
                  group: HomeProductGroup(id: variant.productGroupId, variants: [variant]),
                ),
              );
            },
            actions: [
              SundialMenuAction(value: 'edit', label: l10n.edit, icon: Icons.edit_outlined),
              SundialMenuAction(value: 'history', label: l10n.purchaseHistory, icon: Icons.history_rounded),
              SundialMenuAction(
                value: 'archive',
                label: l10n.remove,
                icon: Icons.archive_outlined,
                dividerBefore: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final product = groupSize > 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product ? l10n.archiveVariantQuestion : l10n.archiveProductQuestion),
        content: Text(product ? l10n.archiveVariantBody : l10n.archiveProductBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (confirmed != true) return;
    if (product) {
      await ref.read(repositoryProvider).archiveHomeItem(variant.id);
    } else {
      await ref.read(repositoryProvider).archiveHomeGroup(variant.productGroupId);
    }
    if (context.mounted) playUiSound(context, UiSound.remove);
  }
}

class _PurchaseHistorySheet extends ConsumerWidget {
  const _PurchaseHistorySheet({required this.group});

  final HomeProductGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final units = ref.watch(homeUnitsProvider).value ?? const <HomeUnit>[];
    return AppSheet(
      title: l10n.purchaseHistory,
      subtitle: homeItemDisplayName(group.lead, locale),
      children: [
        for (final variant in group.variants) ...[
          if (group.variants.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                variantQuantityLabel(variant, units, locale),
                style: SundialType.label(11.5, color: c.textSecondary),
              ),
            ),
          FutureBuilder<List<HomePurchase>>(
            future: ref.read(repositoryProvider).readPurchaseHistory(variant.id),
            builder: (context, snapshot) {
              final purchases = snapshot.data ?? const <HomePurchase>[];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (purchases.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(l10n.purchaseHistoryEmpty, style: SundialType.body(13, color: c.textSecondary)),
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < purchases.length; index++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 18, color: c.home),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              variantQuantityLabel(
                                variant.copyWith(quantity: purchases[index].quantity),
                                units,
                                locale,
                              ),
                              style: SundialType.body(13, weight: FontWeight.w700, color: c.text),
                            ),
                          ),
                          Text(
                            formatFullDate(context, purchases[index].purchasedAt.toLocal()),
                            style: SundialType.body(11.5, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (index < purchases.length - 1) const Divider(height: 1, indent: 28),
                  ],
                ],
              );
            },
          ),
          if (group.variants.length > 1) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (style.hasSelectedGradient ? null : c.accentSoft)
              : (style.hasSelectedGradient ? null : c.surfaceAlt),
          gradient: style.hasSelectedGradient
              ? (selected ? style.selectedGradient : style.fieldGradient)
              : null,
          borderRadius: BorderRadius.circular(SundialRadii.pill),
          border: Border.all(
            color: selected
                ? c.accent.withValues(alpha: style.hasSelectedGradient ? 0.42 : 0.35)
                : (style.hasSelectedGradient ? style.rim : c.border),
          ),
          boxShadow: selected && style.hasSelectedGradient ? style.cardShadows.take(1).toList() : null,
        ),
        foregroundDecoration: selected && style.hasSelectedGradient && style.gloss
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(SundialRadii.pill),
                gradient: style.glossGradient,
              )
            : null,
        child: Text(label, style: SundialType.label(12, color: selected ? c.accent : c.textSecondary)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.soft});

  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(SundialRadii.pill)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SundialType.label(9, color: color),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SundialRadii.xs),
          child: SizedBox(width: 48, height: 48, child: Icon(icon, size: 18, color: c.textSecondary)),
        ),
      ),
    );
  }
}
