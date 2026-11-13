import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/mane_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

const spacePalette = <int>[
  0xFF4F6D5A,
  0xFF2F7ED8,
  0xFF0A8FCF,
  0xFF2FA98F,
  0xFF4FB56B,
  0xFFB07D5C,
  0xFFC25B3F,
  0xFFD39A2E,
  0xFF6E52D8,
  0xFFB04A7A,
  0xFF3D8B8B,
  0xFF5A6470,
];

class ContextAvatar extends StatelessWidget {
  const ContextAvatar({
    super.key,
    required this.icon,
    required this.colorValue,
    this.imagePath,
    this.size = 46,
    this.radius,
  });

  final String icon;
  final int colorValue;
  final String? imagePath;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final color = Color(colorValue);
    final shape = BorderRadius.circular(radius ?? size * 0.32);
    final file = imagePath == null ? null : File(imagePath!);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: shape,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: file != null && file.existsSync()
            ? Image.file(file, fit: BoxFit.cover, cacheWidth: (size * 3).round())
            : Icon(ManeIcons.resolve(icon), size: size * 0.46, color: color),
      ),
    );
  }
}

Future<String?> showIconPicker(
  BuildContext context, {
  required String selected,
  List<String> recommended = const <String>[],
}) {
  return showAppSheet<String>(
    context: context,
    builder: (context) => _IconPickerSheet(selected: selected, recommended: recommended),
  );
}

class _IconPickerSheet extends StatefulWidget {
  const _IconPickerSheet({required this.selected, required this.recommended});

  final String selected;
  final List<String> recommended;

  @override
  State<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends State<_IconPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final matches = ManeIcons.search(_query);
    final suggested = _query.isEmpty
        ? widget.recommended.where(ManeIcons.all.containsKey).toList()
        : const <String>[];

    return AppSheet(
      title: l10n.chooseIcon,
      children: [
        ManeSearchField(
          controller: _controller,
          hint: l10n.searchIcons,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        if (suggested.isNotEmpty) ...[
          SectionLabel(l10n.recommendedIcons),
          const SizedBox(height: 8),
          _IconGrid(
            names: suggested,
            selected: widget.selected,
            onTap: (name) => Navigator.of(context).pop(name),
          ),
          const SizedBox(height: 16),
          SectionLabel(l10n.allIcons),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 320,
          child: matches.isEmpty
              ? Center(
                  child: Text(l10n.noIconsFound, style: ManeType.body(13, color: c.textSecondary)),
                )
              : GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final name = matches[index];
                    final selected = name == widget.selected;
                    return Pressable(
                      onTap: () => Navigator.of(context).pop(name),
                      semanticButton: true,
                      semanticLabel: name,
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? c.accentSoft : c.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? c.accent : c.border),
                        ),
                        child: Icon(
                          ManeIcons.resolve(name),
                          size: 22,
                          color: selected ? c.accent : c.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.names, required this.selected, required this.onTap});

  final List<String> names;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in names)
          Pressable(
            onTap: () => onTap(name),
            semanticButton: true,
            semanticLabel: name,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: name == selected ? c.accentSoft : c.surfaceAlt,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: name == selected ? c.accent : c.border),
              ),
              child: Icon(
                ManeIcons.resolve(name),
                size: 22,
                color: name == selected ? c.accent : c.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

Future<int?> showColorPicker(BuildContext context, {required int selected, required String title}) {
  return showAppSheet<int>(
    context: context,
    builder: (context) => AppSheet(
      title: title,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final value in spacePalette)
              Pressable(
                onTap: () => Navigator.of(context).pop(value),
                semanticButton: true,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Color(value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: value == selected ? context.mc.text : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: value == selected ? const Icon(Icons.check, size: 22, color: Colors.white) : null,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
