import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../data/household_catalog.dart';
import '../../../models/home_item.dart';
import '../../../models/home_reference.dart';
import '../../../models/household_catalog_item.dart';
import '../../../models/shopping_item.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../pages/home_reference_page.dart';
import 'home_art.dart';

Future<void> showShoppingItemSheet(
  BuildContext context, {
  ShoppingItem? item,
  String? contextId,
  HouseholdCatalogItem? catalog,
  HomeItem? homeItem,
}) => showAppSheet<void>(
  context: context,
  builder: (_) => ShoppingItemSheet(item: item, contextId: contextId, catalog: catalog, homeItem: homeItem),
);

class ShoppingItemSheet extends ConsumerStatefulWidget {
  const ShoppingItemSheet({super.key, this.item, this.contextId, this.catalog, this.homeItem});

  final ShoppingItem? item;
  final String? contextId;
  final HouseholdCatalogItem? catalog;
  final HomeItem? homeItem;

  @override
  ConsumerState<ShoppingItemSheet> createState() => _ShoppingItemSheetState();
}

class _ShoppingItemSheetState extends ConsumerState<ShoppingItemSheet> {
  final _name = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _packSize = TextEditingController();
  final _note = TextEditingController();
  String? _homeItemId;
  String? _catalogId;
  String? _categoryId;
  String? _unitId;
  String _icon = 'shopping_basket';
  int? _color;
  bool _saving = false;
  bool _seededLocale = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final home = widget.homeItem;
    final catalog = widget.catalog;
    _homeItemId = item?.homeItemId ?? home?.id;
    _catalogId = item?.catalogId ?? home?.catalogId ?? catalog?.id;
    _categoryId = item?.categoryId ?? home?.categoryId ?? catalog?.categoryId;
    _unitId = home?.unitId ?? catalog?.unitId;
    if (_unitId == null && item != null && item.unit.isNotEmpty) {
      final units = ref.read(homeUnitsProvider).value ?? const <HomeUnit>[];
      for (final unit in units) {
        if (unit.name.toLowerCase() == item.unit.toLowerCase() ||
            unit.symbol.toLowerCase() == item.unit.toLowerCase()) {
          _unitId = unit.id;
          break;
        }
      }
    }
    _icon = item?.icon ?? home?.icon ?? catalog?.icon ?? 'shopping_basket';
    _color = item?.colorValue ?? home?.colorValue ?? catalog?.colorValue;
    _name.text = item?.name ?? home?.name ?? catalog?.name ?? '';
    _quantity.text = _number(item?.quantity ?? home?.suggestedPurchase ?? 1);
    _packSize.text = item?.packSize ?? home?.packSize ?? catalog?.defaultPackSize ?? '';
    _note.text = item?.note ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededLocale) return;
    _seededLocale = true;
    final locale = Localizations.localeOf(context);
    final catalog = widget.catalog ?? householdCatalogItemById(_catalogId);
    final home = widget.homeItem;
    if (catalog != null && (widget.item == null || widget.item!.name == catalog.name)) {
      _name.text = catalog.displayName(locale);
    } else if (home != null) {
      _name.text = homeItemDisplayName(home, locale);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _packSize.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context);
    final categories = ref.watch(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final units = ref.watch(homeUnitsProvider).value ?? const <HomeUnit>[];
    final homeItems = ref.watch(homeItemsProvider).value ?? const <HomeItem>[];
    final linked = homeItems.where((item) => item.id == _homeItemId).firstOrNull;
    final category = homeCategoryFor(_categoryId, categories);
    final unit = _unitById(units, _unitId);
    final linkedLocked = linked != null;
    return AppSheet(
      title: widget.item == null ? l10n.addShoppingItem : l10n.editShoppingItem,
      subtitle: linked == null ? null : l10n.linkedTo(homeItemDisplayName(linked, locale)),
      children: [
        Row(
          children: [
            HomeArt(icon: _icon, colorValue: _color, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                linked == null ? l10n.shoppingOneOffHint : l10n.linkedInventory,
                style: SundialType.body(11.5, color: c.textTertiary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _name,
          autofocus: widget.item == null && widget.homeItem == null && widget.catalog == null,
          readOnly: linkedLocked,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.itemName),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.shoppingItemQuantity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _packSize,
                readOnly: linkedLocked,
                decoration: InputDecoration(labelText: l10n.shoppingItemPack),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SelectWithAction(
          field: SundialSelectField(
            label: l10n.shoppingItemUnit,
            valueLabel: unit == null ? l10n.noLink : localizedUnitName(unit, locale),
            leading: const Icon(Icons.straighten),
            onTap: linkedLocked || units.isEmpty
                ? null
                : () async {
                    final picked = await showSundialSelectSheet<String>(
                      context: context,
                      title: l10n.shoppingItemUnit,
                      selected: _unitId ?? '',
                      options: [
                        SundialSelectOption(value: '', label: l10n.noLink),
                        for (final option in units)
                          SundialSelectOption(
                            value: option.id,
                            label: localizedUnitName(option, locale),
                            subtitle: option.symbol,
                          ),
                      ],
                    );
                    if (picked != null && mounted) {
                      setState(() => _unitId = picked.isEmpty ? null : picked);
                    }
                  },
            onClear: linkedLocked || _unitId == null ? null : () => setState(() => _unitId = null),
            clearTooltip: l10n.clearText,
          ),
          actionTooltip: l10n.manageUnits,
          icon: Icons.straighten,
          onAction: () => showHomeReferencePage(context, HomeReferenceTab.units),
        ),
        const SizedBox(height: 12),
        _SelectWithAction(
          field: SundialSelectField(
            label: l10n.shoppingItemCategory,
            valueLabel: category == null ? l10n.noLink : localizedCategoryName(category, locale),
            leading: category == null
                ? const Icon(Icons.category_outlined)
                : Icon(SundialIcons.resolve(category.icon), color: Color(category.colorValue)),
            onTap: linkedLocked || categories.isEmpty
                ? null
                : () async {
                    final picked = await showSundialSelectSheet<String>(
                      context: context,
                      title: l10n.shoppingItemCategory,
                      selected: _categoryId ?? '',
                      options: [
                        SundialSelectOption(value: '', label: l10n.noLink),
                        for (final option in categories)
                          SundialSelectOption(
                            value: option.id,
                            label: localizedCategoryName(option, locale),
                            leading: Icon(
                              SundialIcons.resolve(option.icon),
                              size: 19,
                              color: Color(option.colorValue),
                            ),
                          ),
                      ],
                    );
                    if (picked != null && mounted) {
                      setState(() => _categoryId = picked.isEmpty ? null : picked);
                    }
                  },
            onClear: linkedLocked || _categoryId == null ? null : () => setState(() => _categoryId = null),
            clearTooltip: l10n.clearText,
          ),
          actionTooltip: l10n.manageCategories,
          icon: Icons.tune,
          onAction: () => showHomeReferencePage(context, HomeReferenceTab.categories),
        ),
        const SizedBox(height: 12),
        SundialSelectField(
          label: l10n.linkedInventory,
          valueLabel: linked == null
              ? l10n.noLink
              : '${homeItemDisplayName(linked, locale)} · ${variantQuantityLabel(linked, units, locale)}',
          leading: const Icon(Icons.inventory_2_outlined),
          onTap: homeItems.isEmpty ? null : () => _pickLinkedItem(homeItems, units),
          onClear: _homeItemId == null ? null : () => setState(() => _homeItemId = null),
          clearTooltip: l10n.clearText,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.note),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _pickLinkedItem(List<HomeItem> homeItems, List<HomeUnit> units) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final picked = await showSundialSelectSheet<String>(
      context: context,
      title: l10n.linkedInventory,
      searchHint: l10n.inventorySearch,
      selected: _homeItemId ?? '',
      options: [
        SundialSelectOption(value: '', label: l10n.noLink),
        for (final item in homeItems)
          SundialSelectOption(
            value: item.id,
            label: homeItemDisplayName(item, locale),
            subtitle: variantQuantityLabel(item, units, locale),
            leading: HomeArtForItem(item: item, size: 30),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    HomeItem? selected;
    for (final item in homeItems) {
      if (item.id == picked) {
        selected = item;
        break;
      }
    }
    setState(() {
      _homeItemId = selected?.id;
      if (selected == null) return;
      _name.text = homeItemDisplayName(selected, locale);
      _quantity.text = _number(selected.suggestedPurchase <= 0 ? 1 : selected.suggestedPurchase);
      _packSize.text = selected.packSize;
      _catalogId = selected.catalogId;
      _categoryId = selected.categoryId;
      _unitId = selected.unitId;
      _icon = selected.icon;
      _color = selected.colorValue;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final locale = Localizations.localeOf(context);
    final categories = ref.read(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final units = ref.read(homeUnitsProvider).value ?? const <HomeUnit>[];
    final homeItems = ref.read(homeItemsProvider).value ?? const <HomeItem>[];
    final linked = homeItems.where((item) => item.id == _homeItemId).firstOrNull;
    final catalog = widget.catalog ?? householdCatalogItemById(_catalogId);
    final canonicalName = catalog != null && name == catalog.displayName(locale) ? catalog.name : name;
    final category = homeCategoryFor(_categoryId, categories);
    final unit = _unitById(units, _unitId);
    final existing = widget.item;
    final item = ShoppingItem(
      id: existing?.id ?? const Uuid().v4(),
      contextId: existing?.contextId ?? linked?.contextId ?? widget.contextId,
      name: canonicalName,
      quantity: _parse(_quantity.text),
      unit: unit?.name ?? linked?.unit ?? '',
      packSize: _packSize.text.trim(),
      checked: existing?.checked ?? false,
      note: _note.text.trim(),
      homeItemId: linked?.id,
      catalogId: _catalogId,
      category: category == null ? '' : category.name,
      categoryId: category?.id,
      icon: _icon,
      colorValue: _color,
      position: existing?.position ?? 0,
    );
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveShoppingItem(item);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (!mounted) return;
    playUiSound(context, UiSound.confirm);
    Navigator.of(context).pop();
  }

  static double _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    return parsed == null || parsed <= 0 ? 1 : parsed;
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  static HomeUnit? _unitById(List<HomeUnit> units, String? id) {
    if (id == null) return null;
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }
}

class _SelectWithAction extends StatelessWidget {
  const _SelectWithAction({
    required this.field,
    required this.actionTooltip,
    required this.icon,
    required this.onAction,
  });

  final Widget field;
  final String actionTooltip;
  final IconData icon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: field),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: IconButton(tooltip: actionTooltip, icon: Icon(icon), onPressed: onAction),
        ),
      ],
    );
  }
}
