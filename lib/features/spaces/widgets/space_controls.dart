import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';

/// The first twelve entries are the original palette and keep their order so
/// the defaults picked by [spacePalette.first] and friends stay stable.
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
  // Greens.
  0xFF2E6B45,
  0xFF3E8E59,
  0xFF6E9E3E,
  // Teals and cyans.
  0xFF1E8C7E,
  0xFF0F7E92,
  0xFF2BA8AD,
  0xFF4C9E9E,
  // Blues.
  0xFF1F5FA8,
  0xFF3F8FCC,
  0xFF5B79C9,
  0xFF2B6F8A,
  // Violet.
  0xFF8A63D2,
  0xFF5A4FA3,
  0xFF9E5FC4,
  0xFF6E6BC4,
  // Pinks.
  0xFFD2658F,
  0xFFC2456B,
  0xFFB85C9E,
  // Reds.
  0xFFD14B4B,
  0xFFA83A3A,
  // Oranges and browns.
  0xFFE07B39,
  0xFFB5762E,
  0xFF8A6248,
  // Neutrals.
  0xFF7C8794,
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
    final shape = radius != null ? BorderRadius.circular(radius!) : SundialShapes.icon(size);
    final file = imagePath == null ? null : File(imagePath!);
    if (file != null && file.existsSync()) {
      // A real logo reads better without the tinted plate and border, which
      // would otherwise crop into images that have transparent corners.
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: shape,
          child: Image.file(file, fit: BoxFit.cover, cacheWidth: (size * 3).round()),
        ),
      );
    }
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
        child: Icon(SundialIcons.resolve(icon), size: size * 0.46, color: color),
      ),
    );
  }
}

/// The avatar doubles as the appearance trigger: tapping it opens the icon
/// picker, so editors do not need a separate icon row.
class ContextAvatarButton extends StatelessWidget {
  const ContextAvatarButton({
    super.key,
    required this.icon,
    required this.colorValue,
    required this.tooltip,
    required this.onTap,
    this.imagePath,
    this.size = 58,
    this.radius,
  });

  final String icon;
  final int colorValue;
  final String tooltip;
  final VoidCallback onTap;
  final String? imagePath;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final badge = size * 0.36;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        semanticButton: true,
        semanticLabel: tooltip,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ContextAvatar(
              icon: icon,
              colorValue: colorValue,
              imagePath: imagePath,
              size: size,
              radius: radius,
            ),
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
                child: Icon(Icons.edit, size: badge * 0.55, color: c.onAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The shared appearance block for space editors.
///
/// Icon, image and colour are one identity, so they live in a single card with
/// two anchored rows instead of loose buttons that wrap differently on phone
/// and desktop.
class SpaceAppearanceCard extends StatelessWidget {
  const SpaceAppearanceCard({
    super.key,
    required this.icon,
    required this.colorValue,
    required this.imagePath,
    required this.onChooseIcon,
    required this.onChooseImage,
    required this.onRemoveImage,
    required this.onChooseColor,
    this.busy = false,
  });

  final String icon;
  final int colorValue;
  final String? imagePath;
  final VoidCallback onChooseIcon;
  final VoidCallback onChooseImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onChooseColor;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final accent = Color(colorValue);
    final hasImage = imagePath != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(l10n.appearanceSection),
        SoftCard(
          padding: EdgeInsets.zero,
          color: c.surfaceAlt,
          clip: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 13),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 400;
                    final changeTooltip = hasImage ? l10n.changeImage : l10n.chooseImage;
                    return Row(
                      children: [
                        ContextAvatarButton(
                          icon: icon,
                          colorValue: colorValue,
                          imagePath: imagePath,
                          size: 54,
                          tooltip: l10n.chooseIcon,
                          onTap: onChooseIcon,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.image,
                                style: SundialType.body(13, weight: FontWeight.w700, color: c.text),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasImage ? l10n.imageHintSet : l10n.imageHintEmpty,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: SundialType.body(11.5, color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (compact) ...[
                          _RoundAction(
                            icon: Icons.add_photo_alternate_outlined,
                            tooltip: changeTooltip,
                            loading: busy,
                            onTap: busy ? null : onChooseImage,
                          ),
                          if (hasImage) ...[
                            const SizedBox(width: 8),
                            _RoundAction(
                              icon: Icons.delete_outline_rounded,
                              tooltip: l10n.removeImage,
                              danger: true,
                              onTap: busy ? null : onRemoveImage,
                            ),
                          ],
                        ] else ...[
                          _AppearanceAction(
                            icon: Icons.add_photo_alternate_outlined,
                            label: hasImage ? l10n.changeImage : l10n.chooseImage,
                            loading: busy,
                            onTap: busy ? null : onChooseImage,
                          ),
                          if (hasImage) ...[
                            const SizedBox(width: 8),
                            _RoundAction(
                              icon: Icons.delete_outline_rounded,
                              tooltip: l10n.removeImage,
                              danger: true,
                              onTap: busy ? null : onRemoveImage,
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ),
              Divider(height: 1, thickness: 1, color: c.border),
              Pressable(
                onTap: busy ? null : onChooseColor,
                semanticButton: true,
                semanticLabel: l10n.color,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(SundialRadii.xs),
                        ),
                        child: Icon(Icons.palette_outlined, size: 18, color: c.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.color,
                          style: SundialType.body(13.5, weight: FontWeight.w700, color: c.text),
                        ),
                      ),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 2),
                          boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded, size: 20, color: c.textTertiary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceAction extends StatelessWidget {
  const _AppearanceAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: loading
          ? SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))
          : Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        disabledForegroundColor: c.textTertiary,
        backgroundColor: c.surface,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        side: const BorderSide(color: Colors.transparent),
        shape: const StadiumBorder(),
        textStyle: SundialType.body(12.5, weight: FontWeight.w700),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.danger = false,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final foreground = danger ? c.danger : c.text;
    return IconButton.outlined(
      onPressed: onTap,
      tooltip: tooltip,
      icon: loading
          ? SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
            )
          : Icon(icon, size: 18),
      style: IconButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: c.textTertiary,
        backgroundColor: c.surface,
        side: BorderSide(
          color: onTap == null
              ? c.border
              : danger
              ? c.danger.withValues(alpha: 0.32)
              : c.border,
        ),
        fixedSize: const Size(40, 40),
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
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
    final matches = SundialIcons.search(_query);
    final suggested = _query.isEmpty
        ? widget.recommended.where(SundialIcons.all.containsKey).toList()
        : const <String>[];

    return AppSheet(
      title: l10n.chooseIcon,
      children: [
        SundialSearchField(
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
                  child: Text(l10n.noIconsFound, style: SundialType.body(13, color: c.textSecondary)),
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
                          borderRadius: BorderRadius.circular(SundialRadii.sm),
                          border: Border.all(color: selected ? c.accent : c.border),
                        ),
                        child: Icon(
                          SundialIcons.resolve(name),
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
                borderRadius: BorderRadius.circular(SundialRadii.sm),
                border: Border.all(color: name == selected ? c.accent : c.border),
              ),
              child: Icon(
                SundialIcons.resolve(name),
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
                      width: value == selected ? 2.5 : 1,
                    ),
                  ),
                  child: value == selected
                      ? Icon(
                          Icons.check,
                          size: 22,
                          color: Color(value).computeLuminance() > 0.4 ? Colors.black87 : Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
