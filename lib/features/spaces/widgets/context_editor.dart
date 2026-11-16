import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../media/media_store.dart';
import '../../media/sticker_editor.dart';
import 'space_controls.dart';

Future<void> showContextEditor(
  BuildContext context, {
  required String spaceId,
  PlannerContext? existing,
  required String title,
  List<String> recommendedIcons = const <String>[],
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _ContextEditorSheet(
      spaceId: spaceId,
      context: existing,
      title: title,
      recommendedIcons: recommendedIcons,
    ),
  );
}

class _ContextEditorSheet extends ConsumerStatefulWidget {
  const _ContextEditorSheet({
    required this.spaceId,
    required this.title,
    required this.recommendedIcons,
    this.context,
  });

  final String spaceId;
  final String title;
  final List<String> recommendedIcons;
  final PlannerContext? context;

  @override
  ConsumerState<_ContextEditorSheet> createState() => _ContextEditorSheetState();
}

class _ContextEditorSheetState extends ConsumerState<_ContextEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _icon;
  late int _color;
  late String? _imagePath;
  String? _originalImage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final context = widget.context;
    _name = TextEditingController(text: context?.name ?? '');
    _description = TextEditingController(text: context?.description ?? '');
    _icon = context?.icon ?? (widget.recommendedIcons.isEmpty ? 'folder' : widget.recommendedIcons.first);
    _color = context?.colorValue ?? spacePalette.first;
    _imagePath = context?.imagePath;
    _originalImage = context?.imagePath;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: widget.title,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.name),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.descriptionOptional),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ContextAvatarButton(
              icon: _icon,
              colorValue: _color,
              imagePath: _imagePath,
              size: 58,
              radius: 18,
              tooltip: l10n.chooseIcon,
              onTap: _chooseIcon,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.image, style: SundialType.label(12, color: c.textSecondary)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: _busy ? null : _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: Text(_imagePath == null ? l10n.chooseImage : l10n.changeImage),
                      ),
                      if (_imagePath != null)
                        TextButton(
                          onPressed: _busy ? null : () => setState(() => _imagePath = null),
                          style: TextButton.styleFrom(foregroundColor: c.danger),
                          child: Text(l10n.removeImage),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _OptionTile(
              icon: Icons.palette_outlined,
              label: l10n.color,
              color: Color(_color),
              onTap: _chooseColor,
            ),
          ],
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.context == null ? l10n.save : l10n.saveChanges),
          ),
        ),
        if (widget.context != null)
          TextButton(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l10n.delete),
          ),
      ],
    );
  }

  Future<void> _chooseIcon() async {
    final picked = await showIconPicker(context, selected: _icon, recommended: widget.recommendedIcons);
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  Future<void> _chooseColor() async {
    final picked = await showColorPicker(context, selected: _color, title: context.l10n.color);
    if (picked != null && mounted) setState(() => _color = picked);
  }

  Future<void> _pickImage() async {
    setState(() => _busy = true);
    try {
      final bytes = await pickAndEditSticker(
        context,
        StickerEditorLabels(
          title: context.l10n.stickerImage,
          pickImage: context.l10n.pickImage,
          zoomHint: context.l10n.zoomHint,
          tolerance: context.l10n.tolerance,
          outline: context.l10n.outline,
          outlineWidth: context.l10n.outlineWidth,
          reset: context.l10n.reset,
          cancel: context.l10n.cancel,
          useImage: context.l10n.useImage,
          noImage: context.l10n.noImage,
          error: context.l10n.imageError,
        ),
      );
      if (bytes == null || !mounted) return;
      final path = await saveStickerImage(bytes);
      if (mounted) setState(() => _imagePath = path);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.imageError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final existing = widget.context;
    final saved = PlannerContext(
      id: existing?.id ?? const Uuid().v4(),
      spaceId: widget.spaceId,
      name: name,
      description: _description.text.trim(),
      colorValue: _color,
      icon: _icon,
      imagePath: _imagePath,
      position: existing?.position ?? 0,
    );
    try {
      await ref.read(repositoryProvider).saveContext(saved);
      if (_originalImage != null && _originalImage != _imagePath) {
        await deleteStickerImage(_originalImage);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.context;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteContextQuestion(existing.name)),
        content: Text(context.l10n.deleteContextBody),
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
    if (confirmed != true || !mounted) return;
    await ref.read(repositoryProvider).deleteContext(existing.id);
    if (mounted) Navigator.of(context).pop();
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            else
              Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Text(
              label,
              style: SundialType.body(12.5, weight: FontWeight.w700, color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}
