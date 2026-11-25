import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../models/home_item.dart';
import '../../../models/home_reference.dart';
import '../../../models/household_catalog_item.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../spaces/widgets/space_controls.dart';
import '../../tags/tag_colors.dart';
import '../pages/home_reference_page.dart';
import 'home_art.dart';

Future<void> showHomeItemSheet(
  BuildContext context, {
  HomeItem? item,
  String? contextId,
  HouseholdCatalogItem? catalog,
  HomeItem? variantOf,
  bool updateGroup = false,
}) => showAppSheet<void>(
  context: context,
  builder: (_) => HomeItemSheet(
    item: item,
    contextId: contextId,
    catalog: catalog,
    variantOf: variantOf,
    updateGroup: updateGroup,
  ),
);

class HomeItemSheet extends ConsumerStatefulWidget {
  const HomeItemSheet({
    super.key,
    this.item,
    this.contextId,
    this.catalog,
    this.variantOf,
    this.updateGroup = false,
  });

  final HomeItem? item;
  final String? contextId;
  final HouseholdCatalogItem? catalog;
  final HomeItem? variantOf;
  final bool updateGroup;

  @override
  ConsumerState<HomeItemSheet> createState() => _HomeItemSheetState();
}

class _HomeItemSheetState extends ConsumerState<HomeItemSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _quantity = TextEditingController(text: '0');
  final _minimum = TextEditingController();
  final _packSize = TextEditingController();
  final _notes = TextEditingController();

  late final String _itemId;
  late final String _groupId;
  late final String _contextId;
  String? _catalogId;
  String? _categoryId;
  String? _unitId;
  final Set<String> _locationIds = {};
  LocalDate? _expiresAt;
  String _icon = 'inventory';
  int? _color;
  bool _saving = false;
  bool _seededLocale = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final source = item ?? widget.variantOf;
    final catalog = widget.catalog ?? (source == null ? null : homeItemCatalog(source));
    final today = localDateAt(ref.read(nowProvider), ref.read(deviceTimeZoneProvider));
    _itemId = item?.id ?? const Uuid().v4();
    _groupId = item?.productGroupId ?? widget.variantOf?.productGroupId ?? const Uuid().v4();
    _contextId = item?.contextId ?? widget.variantOf?.contextId ?? widget.contextId ?? '';
    _catalogId = item?.catalogId ?? widget.variantOf?.catalogId ?? catalog?.id;
    _categoryId = item?.categoryId ?? widget.variantOf?.categoryId ?? catalog?.categoryId;
    _unitId = item?.unitId ?? widget.variantOf?.unitId ?? catalog?.unitId;
    _locationIds.addAll(item?.locationIds ?? widget.variantOf?.locationIds ?? const <String>[]);
    _expiresAt = item?.expiresAt;
    if (item == null) {
      _expiresAt = catalog?.shelfLifeDays == null ? null : today.addDays(catalog!.shelfLifeDays!);
    }
    _icon = item?.icon ?? widget.variantOf?.icon ?? catalog?.icon ?? 'inventory';
    _color = item?.colorValue ?? widget.variantOf?.colorValue ?? catalog?.colorValue;
    _name.text = source?.name ?? catalog?.name ?? '';
    _description.text = source?.description ?? catalog?.description ?? '';
    _packSize.text = item?.packSize ?? (widget.variantOf != null ? '' : (catalog?.defaultPackSize ?? ''));
    _quantity.text = _number(item?.quantity ?? 0);
    final minimum =
        item?.minimumStock ?? widget.variantOf?.minimumStock ?? (catalog?.defaultMinQuantity ?? 0);
    _minimum.text = minimum > 0 ? _number(minimum) : '';
    _notes.text = item?.notes ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededLocale) return;
    _seededLocale = true;
    final locale = Localizations.localeOf(context);
    final item = widget.item;
    final catalog = widget.catalog ?? (item == null ? null : homeItemCatalog(item));
    if (widget.variantOf != null) {
      _name.text = homeItemDisplayName(widget.variantOf!, locale);
      _description.text = homeItemDisplayDescription(widget.variantOf!, locale);
    } else if (catalog != null) {
      if (item == null || item.name == catalog.name) _name.text = catalog.displayName(locale);
      if (item == null || item.description == catalog.description) {
        _description.text = catalog.displayDescription(locale);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _quantity.dispose();
    _minimum.dispose();
    _packSize.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _editing => widget.item != null;

  bool get _newVariant => widget.item == null && widget.variantOf != null;

  /// Name and art belong to the product, not to one size. The product overflow
  /// action is the place to rename every variant at once.
  bool get _productFieldsLocked => _newVariant || (_editing && !widget.updateGroup);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final categories = ref.watch(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final locations = ref.watch(homeLocationsProvider).value ?? const <HomeLocation>[];
    final units = ref.watch(homeUnitsProvider).value ?? const <HomeUnit>[];
    final locale = Localizations.localeOf(context);
    final title = _editing
        ? (widget.updateGroup ? l10n.editProduct : l10n.editHomeItem)
        : (_newVariant ? l10n.addAnotherSize : l10n.addHomeItem);
    final category = homeCategoryFor(_categoryId, categories);
    final unit = _unitById(units, _unitId);
    final locationNames = _locationNames(locations, _locationIds, locale);
    final groupVariants =
        ref.watch(homeItemsProvider).value?.where((item) => item.productGroupId == _groupId).length ?? 0;
    return AppSheet(
      title: title,
      subtitle: widget.catalog?.displayName(locale),
      children: [
        Row(
          children: [
            HomeArt(icon: _icon, colorValue: _color, size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _catalogId == null ? l10n.createCustomItem : l10n.householdCatalog,
                    style: SundialType.body(11.5, color: c.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _name.text.trim().isEmpty ? l10n.itemName : _name.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SundialType.body(16, weight: FontWeight.w700, color: c.text),
                  ),
                ],
              ),
            ),
            if (!_productFieldsLocked)
              SundialMenuButton<String>(
                tooltip: l10n.edit,
                icon: Icons.palette_outlined,
                iconColor: c.textSecondary,
                onSelected: (value) async {
                  if (value == 'icon') {
                    final picked = await showIconPicker(
                      context,
                      selected: _icon,
                      recommended: SundialIcons.homeRecommended,
                    );
                    if (picked != null && mounted) setState(() => _icon = picked);
                    return;
                  }
                  await _pickColor();
                },
                actions: [
                  SundialMenuAction(
                    value: 'icon',
                    label: l10n.chooseIcon,
                    icon: Icons.emoji_emotions_outlined,
                  ),
                  SundialMenuAction(value: 'color', label: l10n.tagColor, icon: Icons.palette_outlined),
                ],
              ),
          ],
        ),
        if ((_editing || _newVariant) && !widget.updateGroup) ...[
          const SizedBox(height: 8),
          Text(l10n.variantEditHint, style: SundialType.body(11.5, color: c.textTertiary)),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          autofocus: widget.catalog == null && !_editing && !_newVariant,
          readOnly: _productFieldsLocked,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.itemName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          minLines: 1,
          maxLines: 3,
          readOnly: _productFieldsLocked,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.description),
        ),
        const SizedBox(height: 14),
        _SelectWithAction(
          field: SundialSelectField(
            label: l10n.category,
            valueLabel: category == null
                ? (categories.isEmpty ? l10n.noCategories : l10n.noLink)
                : localizedCategoryName(category, locale),
            leading: category == null
                ? const Icon(Icons.category_outlined)
                : Icon(SundialIcons.resolve(category.icon), color: Color(category.colorValue)),
            onTap: _productFieldsLocked || categories.isEmpty
                ? null
                : () async {
                    final picked = await showSundialSelectSheet<String>(
                      context: context,
                      title: l10n.category,
                      selected: _categoryId ?? '',
                      options: [
                        SundialSelectOption(value: '', label: l10n.noLink),
                        for (final option in categories)
                          SundialSelectOption(
                            value: option.id,
                            label: localizedCategoryName(option, locale),
                            leading: Icon(
                              SundialIcons.resolve(option.icon),
                              color: Color(option.colorValue),
                              size: 19,
                            ),
                          ),
                      ],
                    );
                    if (picked != null && mounted) {
                      setState(() => _categoryId = picked.isEmpty ? null : picked);
                    }
                  },
            onClear: _productFieldsLocked || _categoryId == null
                ? null
                : () => setState(() => _categoryId = null),
            clearTooltip: l10n.clearText,
          ),
          actionTooltip: l10n.manageCategories,
          icon: Icons.tune,
          onAction: () => showHomeReferencePage(context, HomeReferenceTab.categories),
        ),
        const SizedBox(height: 12),
        _SelectWithAction(
          field: SundialSelectField(
            label: l10n.unit,
            valueLabel: unit == null ? l10n.noLink : localizedUnitName(unit, locale),
            leading: const Icon(Icons.straighten),
            onTap: units.isEmpty
                ? null
                : () async {
                    final picked = await showSundialSelectSheet<String>(
                      context: context,
                      title: l10n.unit,
                      selected: _unitId ?? '',
                      options: [
                        SundialSelectOption(value: '', label: l10n.noLink),
                        for (final option in units)
                          SundialSelectOption(
                            value: option.id,
                            label: localizedUnitName(option, locale),
                            subtitle: [
                              option.symbol,
                              option.name,
                            ].where((part) => part.isNotEmpty).join(' · '),
                          ),
                      ],
                    );
                    if (picked != null && mounted) {
                      setState(() => _unitId = picked.isEmpty ? null : picked);
                    }
                  },
            onClear: _unitId == null ? null : () => setState(() => _unitId = null),
            clearTooltip: l10n.clearText,
          ),
          actionTooltip: l10n.manageUnits,
          icon: Icons.straighten,
          onAction: () => showHomeReferencePage(context, HomeReferenceTab.units),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.quantity),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _packSize,
                decoration: InputDecoration(labelText: l10n.packSize, hintText: l10n.packSizeHint),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _minimum,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.minimumStock),
        ),
        const SizedBox(height: 12),
        SundialDateField(
          label: l10n.expiresAtLabel,
          valueLabel: _expiresAt == null ? l10n.noExpiry : formatFullDate(context, _expiresAt!.toDateTime()),
          onTap: _pickExpiry,
          onClear: _expiresAt == null ? null : () => setState(() => _expiresAt = null),
          clearTooltip: l10n.clearDate,
        ),
        const SizedBox(height: 12),
        _SelectWithAction(
          field: SundialSelectField(
            label: l10n.locations,
            valueLabel: _locationIds.isEmpty ? l10n.noLink : locationNames,
            leading: const Icon(Icons.place_outlined),
            onTap: () => _pickLocations(locations),
            onClear: _locationIds.isEmpty ? null : () => setState(_locationIds.clear),
            clearTooltip: l10n.clearText,
          ),
          actionTooltip: l10n.manageLocations,
          icon: Icons.place_outlined,
          onAction: () => showHomeReferencePage(context, HomeReferenceTab.locations),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.note),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.save),
        ),
        if (_editing) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: _saving ? null : _archive,
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(groupVariants > 1 ? l10n.archiveVariantQuestion : l10n.archiveProductQuestion),
          ),
        ],
      ],
    );
  }

  Future<void> _pickColor() async {
    await showAppSheet<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: context.l10n.tagColor,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in tagPalette)
                Pressable(
                  onTap: () {
                    setState(() => _color = color);
                    Navigator.of(sheetContext).pop();
                  },
                  scale: 0.9,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tagColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == _color ? context.mc.text : context.mc.border,
                        width: color == _color ? 2.5 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final now = localDateAt(ref.read(nowProvider), ref.read(deviceTimeZoneProvider));
    final picked = await showDatePicker(
      context: context,
      initialDate: (_expiresAt ?? now).toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _expiresAt = LocalDate.fromDateTime(picked));
  }

  Future<void> _pickLocations(List<HomeLocation> locations) async {
    if (locations.isEmpty) {
      await showHomeReferencePage(context, HomeReferenceTab.locations);
      return;
    }
    final picked = await showAppSheet<Set<String>>(
      context: context,
      builder: (_) => _LocationPickerSheet(locations: locations, selected: _locationIds),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _locationIds
        ..clear()
        ..addAll(picked);
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (_newVariant && _packSize.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.packSizeRequired)));
      return;
    }
    final categories = ref.read(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final units = ref.read(homeUnitsProvider).value ?? const <HomeUnit>[];
    final locations = ref.read(homeLocationsProvider).value ?? const <HomeLocation>[];
    final catalog =
        widget.catalog ??
        (widget.item == null ? null : homeItemCatalog(widget.item!)) ??
        (widget.variantOf == null ? null : homeItemCatalog(widget.variantOf!));
    final canonicalName = catalog != null && name == catalog.displayName(locale) ? catalog.name : name;
    final canonicalDescription =
        catalog != null && _description.text.trim() == catalog.displayDescription(locale)
        ? catalog.description
        : _description.text.trim();
    final category = homeCategoryFor(_categoryId, categories);
    final unit = _unitById(units, _unitId);
    final existing = widget.item;
    final item = HomeItem(
      id: _itemId,
      contextId: _contextId.isEmpty ? null : _contextId,
      groupId: _groupId,
      name: canonicalName,
      description: canonicalDescription,
      icon: _icon,
      colorValue: _color,
      catalogId: _catalogId,
      category: category == null ? '' : localizedCategoryName(category, Locale('en')),
      categoryId: category?.id,
      location: _locationNames(locations, _locationIds, locale),
      locationIds: _locationIds.toList(),
      quantity: _nonNegative(_quantity.text),
      unit: unit == null ? '' : unit.name,
      unitId: unit?.id,
      packSize: _packSize.text.trim(),
      minQuantity: _minimum.text.trim().isEmpty ? null : _nonNegative(_minimum.text),
      expiresAt: _expiresAt,
      notes: _notes.text.trim(),
      lastPurchasedAt: existing?.lastPurchasedAt,
    );
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).saveHomeItem(item, updateGroup: widget.updateGroup);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotSave('$error'))));
      return;
    }
    if (!mounted) return;
    playUiSound(context, UiSound.confirm);
    Navigator.of(context).pop();
  }

  Future<void> _archive() async {
    final l10n = context.l10n;
    final groupVariants =
        ref.read(homeItemsProvider).value?.where((item) => item.productGroupId == _groupId).length ?? 1;
    final product = groupVariants > 1 || widget.updateGroup;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product ? l10n.archiveProductQuestion : l10n.archiveVariantQuestion),
        content: Text(product ? l10n.archiveProductBody : l10n.archiveVariantBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    if (product) {
      await ref.read(repositoryProvider).archiveHomeGroup(_groupId);
    } else {
      await ref.read(repositoryProvider).archiveHomeItem(_itemId);
    }
    if (!mounted) return;
    playUiSound(context, UiSound.remove);
    Navigator.of(context).pop();
  }

  static double _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  static double _nonNegative(String value) => _parse(value).clamp(0.0, double.infinity).toDouble();

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  static HomeUnit? _unitById(List<HomeUnit> units, String? id) {
    if (id == null) return null;
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  static String _locationNames(List<HomeLocation> locations, Set<String> ids, Locale locale) {
    final names = <String>[];
    for (final id in ids) {
      for (final location in locations) {
        if (location.id != id) continue;
        names.add(localizedLocationName(location, locale));
        break;
      }
    }
    return names.join(', ');
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

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.locations, required this.selected});

  final List<HomeLocation> locations;
  final Set<String> selected;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    return AppSheet(
      title: l10n.locations,
      children: [
        for (final location in widget.locations)
          CheckboxListTile(
            value: _selected.contains(location.id),
            onChanged: (value) => setState(() {
              if (value == true) {
                _selected.add(location.id);
              } else {
                _selected.remove(location.id);
              }
            }),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(localizedLocationName(location, locale)),
            secondary: Icon(SundialIcons.resolve(location.icon), size: 20, color: Color(location.colorValue)),
          ),
        const SizedBox(height: 10),
        FilledButton(onPressed: () => Navigator.of(context).pop(_selected), child: Text(l10n.save)),
      ],
    );
  }
}
