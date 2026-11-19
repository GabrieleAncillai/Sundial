import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../spaces/widgets/space_controls.dart';
import '../tag_colors.dart';

Future<void> showTagEditor(BuildContext context, {Tag? tag, required List<Space> spaces}) =>
    showAppSheet<void>(
      context: context,
      builder: (context) => TagEditorSheet(tag: tag, spaces: spaces),
    );

class TagEditorSheet extends ConsumerStatefulWidget {
  const TagEditorSheet({super.key, this.tag, required this.spaces});

  final Tag? tag;
  final List<Space> spaces;

  @override
  ConsumerState<TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends ConsumerState<TagEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String? _spaceId;
  late int _color;
  late String _icon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tag?.name ?? '');
    _spaceId = widget.tag?.spaceId;
    _color = widget.tag?.colorValue ?? tagPalette.first;
    _icon = widget.tag?.icon ?? 'folder';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: widget.tag == null ? l10n.addCategory : l10n.editCategory,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.categoryName),
                validator: (value) => value == null || value.trim().isEmpty ? l10n.tagNameRequired : null,
              ),
              const SizedBox(height: 12),
              SundialSelectField(
                label: l10n.tagSpace,
                valueLabel: _spaceId == null
                    ? l10n.tagSpaceAny
                    : widget.spaces.where((space) => space.id == _spaceId).firstOrNull?.name ??
                          l10n.tagSpaceAny,
                leading: const Icon(Icons.space_dashboard_outlined),
                onTap: () async {
                  final picked = await showSundialSelectSheet<String>(
                    context: context,
                    title: l10n.tagSpace,
                    selected: _spaceId ?? '',
                    options: [
                      SundialSelectOption(value: '', label: l10n.tagSpaceAny),
                      for (final space in widget.spaces)
                        SundialSelectOption(
                          value: space.id,
                          label: space.name,
                          leading: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(color: Color(space.colorValue), shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  );
                  if (picked != null && mounted) {
                    setState(() => _spaceId = picked.isEmpty ? null : picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tagColor(_color).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(SundialRadii.sm),
                    ),
                    child: Icon(SundialIcons.resolve(_icon), size: 20, color: tagColor(_color)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.icon,
                      style: SundialType.body(13, weight: FontWeight.w700, color: c.text),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showIconPicker(
                        context,
                        selected: _icon,
                        recommended: SundialIcons.personalRecommended,
                      );
                      if (picked != null && mounted) setState(() => _icon = picked);
                    },
                    icon: const Icon(Icons.category_outlined, size: 18),
                    label: Text(l10n.chooseIcon),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l10n.tagColor, style: SundialType.label(12.5, color: c.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in tagPalette)
                    Pressable(
                      onTap: () => setState(() => _color = color),
                      scale: 0.9,
                      semanticLabel: l10n.tagColor,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: tagColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == _color ? c.text : c.border,
                            width: color == _color ? 2.5 : 1,
                          ),
                        ),
                        child: color == _color
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: tagColor(color).computeLuminance() > 0.38
                                    ? Colors.black87
                                    : Colors.white,
                              )
                            : null,
                      ),
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
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final existing = widget.tag;
    final tag = Tag(
      id: existing?.id ?? const Uuid().v4(),
      spaceId: _spaceId,
      name: _nameController.text.trim(),
      colorValue: _color,
      icon: _icon,
      position: existing?.position ?? 0,
    );
    try {
      await ref.read(repositoryProvider).saveTag(tag);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
