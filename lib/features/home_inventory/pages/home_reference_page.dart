import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../data/home_reference_defaults.dart';
import '../../../models/home_reference.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../spaces/widgets/space_controls.dart';
import '../../tags/tag_colors.dart';
import '../widgets/home_art.dart';

enum HomeReferenceTab { categories, locations, units }

class HomeReferencePage extends ConsumerStatefulWidget {
  const HomeReferencePage({super.key, this.initialTab = HomeReferenceTab.categories});

  final HomeReferenceTab initialTab;

  @override
  ConsumerState<HomeReferencePage> createState() => _HomeReferencePageState();
}

class _HomeReferencePageState extends ConsumerState<HomeReferencePage> {
  late HomeReferenceTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final categories = ref.watch(homeCategoriesProvider).value ?? const <HomeCategory>[];
    final locations = ref.watch(homeLocationsProvider).value ?? const <HomeLocation>[];
    final units = ref.watch(homeUnitsProvider).value ?? const <HomeUnit>[];
    return SundialPage(
      title: l10n.inventorySetup,
      subtitle: l10n.inventorySetupSubtitle,
      floatingAction: SundialAddButton(
        tooltip: switch (_tab) {
          HomeReferenceTab.categories => l10n.newCategory,
          HomeReferenceTab.locations => l10n.newLocation,
          HomeReferenceTab.units => l10n.newUnit,
        },
        onTap: _createCurrent,
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SundialSegmented<HomeReferenceTab>(
              selected: _tab,
              onChanged: (value) => setState(() => _tab = value),
              segments: [
                SundialSegment(value: HomeReferenceTab.categories, label: l10n.manageCategories),
                SundialSegment(value: HomeReferenceTab.locations, label: l10n.manageLocations),
                SundialSegment(value: HomeReferenceTab.units, label: l10n.manageUnits),
              ],
            ),
          ),
          const SizedBox(height: 16),
          switch (_tab) {
            HomeReferenceTab.categories => _categoryList(l10n, c, categories),
            HomeReferenceTab.locations => _locationList(l10n, c, locations),
            HomeReferenceTab.units => _unitList(l10n, c, units),
          },
        ],
      ),
    );
  }

  Widget _categoryList(AppLocalizations l10n, SundialColors c, List<HomeCategory> categories) {
    if (categories.isEmpty) {
      return AppEmptyState(icon: Icons.category_outlined, title: l10n.noCategories, compact: true);
    }
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          clip: true,
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                if (index > 0) const Divider(height: 1, indent: 54),
                _ReferenceRow(
                  icon: categories[index].icon,
                  colorValue: categories[index].colorValue,
                  title: localizedCategoryName(categories[index], locale),
                  subtitle: l10n.category,
                  onEdit: () => _editCategory(categories[index]),
                  onDelete: () => _deleteCategory(categories[index]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l10n.categoryManagerSubtitle, style: SundialType.body(12, color: c.textTertiary)),
        ),
      ],
    );
  }

  Widget _locationList(AppLocalizations l10n, SundialColors c, List<HomeLocation> locations) {
    if (locations.isEmpty) {
      return AppEmptyState(icon: Icons.place_outlined, title: l10n.noLocations, compact: true);
    }
    final locale = Localizations.localeOf(context);
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      clip: true,
      child: Column(
        children: [
          for (var index = 0; index < locations.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 54),
            _ReferenceRow(
              icon: locations[index].icon,
              colorValue: locations[index].colorValue,
              title: localizedLocationName(locations[index], locale),
              subtitle: l10n.location,
              onEdit: () => _editLocation(locations[index]),
              onDelete: () => _deleteLocation(locations[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _unitList(AppLocalizations l10n, SundialColors c, List<HomeUnit> units) {
    if (units.isEmpty) {
      return AppEmptyState(icon: Icons.straighten_outlined, title: l10n.noUnits, compact: true);
    }
    final locale = Localizations.localeOf(context);
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      clip: true,
      child: Column(
        children: [
          for (var index = 0; index < units.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 54),
            _ReferenceRow(
              icon: 'straighten',
              colorValue: c.home.toARGB32(),
              title: localizedUnitName(units[index], locale),
              subtitle: [
                if (units[index].symbol.isNotEmpty) units[index].symbol,
                _unitKindLabel(l10n, units[index].kind),
              ].join(' · '),
              onEdit: () => _editUnit(units[index]),
              onDelete: () => _deleteUnit(units[index]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createCurrent() {
    return switch (_tab) {
      HomeReferenceTab.categories => _editCategory(null),
      HomeReferenceTab.locations => _editLocation(null),
      HomeReferenceTab.units => _editUnit(null),
    };
  }

  Future<void> _editCategory(HomeCategory? category) => showAppSheet<void>(
    context: context,
    builder: (_) => _CategoryEditor(category: category),
  );

  Future<void> _editLocation(HomeLocation? location) => showAppSheet<void>(
    context: context,
    builder: (_) => _LocationEditor(location: location),
  );

  Future<void> _editUnit(HomeUnit? unit) => showAppSheet<void>(
    context: context,
    builder: (_) => _UnitEditor(unit: unit),
  );

  Future<void> _deleteCategory(HomeCategory category) async {
    final confirmed = await _confirm(
      title: context.l10n.deleteCategoryQuestion,
      body: context.l10n.deleteCategoryBody,
    );
    if (confirmed) await ref.read(repositoryProvider).deleteHomeCategory(category.id);
  }

  Future<void> _deleteLocation(HomeLocation location) async {
    final confirmed = await _confirm(
      title: context.l10n.deleteLocationQuestion,
      body: context.l10n.deleteLocationBody,
    );
    if (confirmed) await ref.read(repositoryProvider).deleteHomeLocation(location.id);
  }

  Future<void> _deleteUnit(HomeUnit unit) async {
    final confirmed = await _confirm(
      title: context.l10n.deleteUnitQuestion,
      body: context.l10n.deleteUnitBody,
    );
    if (confirmed) await ref.read(repositoryProvider).deleteHomeUnit(unit.id);
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    return result == true;
  }
}

String _unitKindLabel(AppLocalizations l10n, HomeUnitKind kind) => switch (kind) {
  HomeUnitKind.count => l10n.unitKindCount,
  HomeUnitKind.weight => l10n.unitKindWeight,
  HomeUnitKind.volume => l10n.unitKindVolume,
  HomeUnitKind.length => l10n.unitKindLength,
  HomeUnitKind.other => l10n.unitKindOther,
};

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({
    required this.icon,
    required this.colorValue,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String icon;
  final int colorValue;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 3, 4, 3),
      child: Row(
        children: [
          HomeArt(icon: icon, colorValue: colorValue, size: 34),
          const SizedBox(width: 11),
          Expanded(
            child: Pressable(
              onTap: onEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                    ),
                    Text(subtitle, style: SundialType.body(11.5, color: c.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: c.textTertiary),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(context.l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({this.category});

  final HomeCategory? category;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late String _icon = widget.category?.icon ?? 'category';
  late int _color = widget.category?.colorValue ?? tagPalette.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheet(
      title: widget.category == null ? l10n.newCategory : l10n.editCategory,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.categoryNameLabel),
        ),
        const SizedBox(height: 14),
        _AppearanceRow(
          icon: _icon,
          color: _color,
          onPickIcon: () async {
            final picked = await showIconPicker(
              context,
              selected: _icon,
              recommended: SundialIcons.homeRecommended,
            );
            if (picked != null && mounted) setState(() => _icon = picked);
          },
        ),
        const SizedBox(height: 14),
        _ColorPicker(selected: _color, onChanged: (value) => setState(() => _color = value)),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final categories = ref.read(homeCategoriesProvider).value ?? const <HomeCategory>[];
    if (categories.any(
      (category) =>
          category.id != widget.category?.id && category.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.duplicateName)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .saveHomeCategory(
            HomeCategory(
              id: widget.category?.id ?? const Uuid().v4(),
              name: name,
              icon: _icon,
              colorValue: _color,
              position: widget.category?.position ?? categories.length,
            ),
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _LocationEditor extends ConsumerStatefulWidget {
  const _LocationEditor({this.location});

  final HomeLocation? location;

  @override
  ConsumerState<_LocationEditor> createState() => _LocationEditorState();
}

class _LocationEditorState extends ConsumerState<_LocationEditor> {
  late final _name = TextEditingController(text: widget.location?.name ?? '');
  late String _icon = widget.location?.icon ?? 'place';
  late int _color = widget.location?.colorValue ?? tagPalette[12];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheet(
      title: widget.location == null ? l10n.newLocation : l10n.editLocation,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.locationName),
        ),
        const SizedBox(height: 14),
        _AppearanceRow(
          icon: _icon,
          color: _color,
          onPickIcon: () async {
            final picked = await showIconPicker(
              context,
              selected: _icon,
              recommended: SundialIcons.homeRecommended,
            );
            if (picked != null && mounted) setState(() => _icon = picked);
          },
        ),
        const SizedBox(height: 14),
        _ColorPicker(selected: _color, onChanged: (value) => setState(() => _color = value)),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final locations = ref.read(homeLocationsProvider).value ?? const <HomeLocation>[];
    if (locations.any(
      (location) =>
          location.id != widget.location?.id && location.name.trim().toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.duplicateName)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .saveHomeLocation(
            HomeLocation(
              id: widget.location?.id ?? const Uuid().v4(),
              name: name,
              icon: _icon,
              colorValue: _color,
              position: widget.location?.position ?? locations.length,
            ),
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _UnitEditor extends ConsumerStatefulWidget {
  const _UnitEditor({this.unit});

  final HomeUnit? unit;

  @override
  ConsumerState<_UnitEditor> createState() => _UnitEditorState();
}

class _UnitEditorState extends ConsumerState<_UnitEditor> {
  late final _name = TextEditingController(text: widget.unit?.name ?? '');
  late final _symbol = TextEditingController(text: widget.unit?.symbol ?? '');
  late HomeUnitKind _kind = widget.unit?.kind ?? HomeUnitKind.count;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _symbol.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheet(
      title: widget.unit == null ? l10n.newUnit : l10n.editUnit,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.unitName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _symbol,
          decoration: InputDecoration(labelText: l10n.unitSymbol),
        ),
        const SizedBox(height: 14),
        Text(l10n.unitKind, style: SundialType.label(12, color: context.mc.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in HomeUnitKind.values)
              _ChoicePill(
                label: _unitKindLabel(l10n, kind),
                selected: kind == _kind,
                onTap: () => setState(() => _kind = kind),
              ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final symbol = _symbol.text.trim();
    if (name.isEmpty) return;
    final units = ref.read(homeUnitsProvider).value ?? const <HomeUnit>[];
    if (units.any(
      (unit) =>
          unit.id != widget.unit?.id &&
          (unit.name.trim().toLowerCase() == name.toLowerCase() ||
              (symbol.isNotEmpty && unit.symbol.trim().toLowerCase() == symbol.toLowerCase())),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.duplicateName)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .saveHomeUnit(
            HomeUnit(
              id: widget.unit?.id ?? const Uuid().v4(),
              name: name,
              symbol: symbol,
              kind: _kind,
              position: widget.unit?.position ?? units.length,
            ),
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }
}

class _AppearanceRow extends StatelessWidget {
  const _AppearanceRow({required this.icon, required this.color, required this.onPickIcon});

  final String icon;
  final int color;
  final VoidCallback onPickIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(
      children: [
        HomeArt(icon: icon, colorValue: color, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.icon,
            style: SundialType.body(13, weight: FontWeight.w700, color: c.text),
          ),
        ),
        TextButton.icon(
          onPressed: onPickIcon,
          icon: const Icon(Icons.category_outlined, size: 18),
          label: Text(context.l10n.chooseIcon),
        ),
      ],
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.tagColor, style: SundialType.label(12.5, color: c.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final color in tagPalette)
              Pressable(
                onTap: () => onChanged(color),
                scale: 0.9,
                semanticLabel: context.l10n.tagColor,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tagColor(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color == selected ? c.text : c.border,
                      width: color == selected ? 2.5 : 1,
                    ),
                  ),
                  child: color == selected
                      ? Icon(
                          Icons.check,
                          size: 17,
                          color: tagColor(color).computeLuminance() > 0.38 ? Colors.black87 : Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surfaceAlt,
          borderRadius: BorderRadius.circular(SundialRadii.pill),
          border: Border.all(color: selected ? c.accent.withValues(alpha: 0.35) : c.border),
        ),
        child: Text(label, style: SundialType.label(12, color: selected ? c.accent : c.textSecondary)),
      ),
    );
  }
}

/// Opens the manager at a specific tab. Used by the item editor.
Future<void> showHomeReferencePage(BuildContext context, HomeReferenceTab tab) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HomeReferencePage(initialTab: tab)));
