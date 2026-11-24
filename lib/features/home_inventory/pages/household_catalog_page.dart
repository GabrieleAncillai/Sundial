import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../data/household_catalog.dart';
import '../../../models/home_item.dart';
import '../../../models/home_reference.dart';
import '../../../models/household_catalog_item.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/sundial_style.dart';
import '../widgets/home_art.dart';
import '../widgets/home_item_sheet.dart';
import '../widgets/shopping_item_sheet.dart';

enum CatalogPickerMode { inventory, shopping }

class HouseholdCatalogPage extends ConsumerStatefulWidget {
  const HouseholdCatalogPage({super.key, required this.homeId, this.mode = CatalogPickerMode.inventory});

  final String homeId;
  final CatalogPickerMode mode;

  @override
  ConsumerState<HouseholdCatalogPage> createState() => _HouseholdCatalogPageState();
}

class _HouseholdCatalogPageState extends ConsumerState<HouseholdCatalogPage> {
  final _search = TextEditingController();
  String _query = '';
  String? _categoryId;

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
    final categories = ref.watch(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final items = ref.watch(homeItemsProvider).value ?? const <HomeItem>[];
    final homeItems = items.where((item) => item.contextId == widget.homeId).toList();
    final catalogIds = {for (final item in homeItems) item.catalogId};
    final query = _query.trim();
    final visible = householdCatalog
        .where((item) => _categoryId == null || item.categoryId == _categoryId)
        .where((item) => item.matches(query))
        .toList();

    return SundialPage(
      title: l10n.householdCatalog,
      subtitle: l10n.catalogSubtitle,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SundialSearchField(
            controller: _search,
            hint: l10n.catalogSearchHint,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: l10n.inventoryFilterAll,
                  selected: _categoryId == null,
                  onTap: () => setState(() => _categoryId = null),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: 7),
                  _FilterPill(
                    label: localizedCategoryName(category, locale),
                    leading: Icon(
                      SundialIcons.resolve(category.icon),
                      size: 15,
                      color: Color(category.colorValue),
                    ),
                    selected: _categoryId == category.id,
                    onTap: () => setState(() => _categoryId = category.id),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            clip: true,
            child: Pressable(
              onTap: _createCustom,
              child: Row(
                children: [
                  HomeArt(icon: 'inventory', colorValue: c.home.toARGB32(), size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.mode == CatalogPickerMode.shopping
                              ? l10n.shoppingOneOff
                              : l10n.createCustomItem,
                          style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.mode == CatalogPickerMode.shopping
                              ? l10n.shoppingOneOffHint
                              : l10n.createCustomHint,
                          style: SundialType.body(11.5, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_outline, color: c.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            AppEmptyState(icon: Icons.search_off_outlined, title: l10n.catalogNoResults, compact: true)
          else
            for (var index = 0; index < visible.length; index++) ...[
              if (index == 0 || visible[index].categoryId != visible[index - 1].categoryId) ...[
                if (index > 0) const SizedBox(height: 10),
                SectionLabel(homeCategoryLabel(visible[index].categoryId, '', categories, locale)),
              ],
              _CatalogTile(
                item: visible[index],
                alreadyInInventory: catalogIds.contains(visible[index].id),
                onTap: () => _select(visible[index]),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Future<void> _createCustom() {
    if (widget.mode == CatalogPickerMode.shopping) {
      return showShoppingItemSheet(context, contextId: widget.homeId);
    }
    return showHomeItemSheet(context, contextId: widget.homeId);
  }

  Future<void> _select(HouseholdCatalogItem item) async {
    if (widget.mode == CatalogPickerMode.inventory) {
      final existing = (ref.read(homeItemsProvider).value ?? const <HomeItem>[])
          .where(
            (homeItem) =>
                homeItem.contextId == widget.homeId &&
                (homeItem.catalogId == item.id || homeItem.name.toLowerCase() == item.name.toLowerCase()),
          )
          .toList();
      await showHomeItemSheet(
        context,
        contextId: widget.homeId,
        catalog: item,
        variantOf: existing.isEmpty ? null : existing.first,
      );
      return;
    }
    final items = ref.read(homeItemsProvider).value ?? const <HomeItem>[];
    final variants = [
      for (final homeItem in items)
        if (homeItem.contextId == widget.homeId &&
            (homeItem.catalogId == item.id || homeItem.name.toLowerCase() == item.name.toLowerCase()))
          homeItem,
    ];
    if (!mounted) return;
    if (variants.isEmpty) {
      await showShoppingItemSheet(context, contextId: widget.homeId, catalog: item);
      return;
    }
    final choice = await showSundialSelectSheet<String>(
      context: context,
      title: item.displayName(Localizations.localeOf(context)),
      selected: variants.first.id,
      options: [
        for (final variant in variants)
          SundialSelectOption(
            value: variant.id,
            label: homeItemDisplayName(variant, Localizations.localeOf(context)),
            subtitle: variant.packSize.isEmpty ? variant.unit : '${variant.packSize} · ${variant.unit}',
            leading: HomeArtForItem(item: variant, size: 30),
          ),
        SundialSelectOption(
          value: '',
          label: context.l10n.shoppingOneOff,
          subtitle: context.l10n.shoppingOneOffHint,
          leading: const Icon(Icons.shopping_basket_outlined, size: 20),
        ),
      ],
    );
    if (choice == null || !mounted) return;
    final linked = choice.isEmpty ? null : variants.firstWhere((variant) => variant.id == choice);
    await showShoppingItemSheet(context, contextId: widget.homeId, catalog: item, homeItem: linked);
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap, this.leading});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 6)],
            Text(label, style: SundialType.label(12, color: selected ? c.accent : c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.item, required this.alreadyInInventory, required this.onTap});

  final HouseholdCatalogItem item;
  final bool alreadyInInventory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      child: Pressable(
        onTap: onTap,
        child: Row(
          children: [
            HomeArt(icon: item.icon, colorValue: item.colorValue, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.displayName(locale),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                        ),
                      ),
                      if (alreadyInInventory) ...[
                        const SizedBox(width: 8),
                        _TinyBadge(label: l10n.catalogInInventory, color: c.success, soft: c.successSoft),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.displayDescription(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SundialType.body(11.5, color: c.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.defaultPackSize.isEmpty
                        ? item.defaultMinQuantity.toStringAsFixed(0)
                        : item.defaultPackSize,
                    style: SundialType.body(11, color: c.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.add_circle_outline, size: 22, color: c.accent),
          ],
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label, required this.color, required this.soft});

  final String label;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(SundialRadii.pill)),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SundialType.label(9.5, color: color),
      ),
    );
  }
}
