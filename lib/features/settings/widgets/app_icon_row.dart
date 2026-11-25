import 'package:flutter/material.dart';

import '../../../core/sound/sound_service.dart';
import '../../../core/widgets/pressable.dart';
import '../../../models/app_icon_style.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/sundial_style.dart';
import 'settings_rows.dart';

/// Launcher icon picker. The previews are the same PNGs shown in the app, so
/// the choice reads before the launcher has refreshed.
class SettingsAppIconRow extends StatelessWidget implements SettingsTitledRow {
  const SettingsAppIconRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.classicLabel,
    required this.aeroLabel,
    required this.selected,
    required this.onChanged,
  });

  @override
  final String title;
  final String subtitle;
  final String hint;
  final String classicLabel;
  final String aeroLabel;
  final AppIconStyle selected;
  final ValueChanged<AppIconStyle> onChanged;

  static const _previews = {
    AppIconStyle.classic: 'assets/icons/icon_classic.png',
    AppIconStyle.aero: 'assets/icons/icon_aero.png',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SettingsIcon(icon: Icons.apps_rounded),
              const SizedBox(width: 13),
              Expanded(
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
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _IconChoice(
                  label: classicLabel,
                  asset: _previews[AppIconStyle.classic]!,
                  style: AppIconStyle.classic,
                  selected: selected,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _IconChoice(
                  label: aeroLabel,
                  asset: _previews[AppIconStyle.aero]!,
                  style: AppIconStyle.aero,
                  selected: selected,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: c.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(hint, style: SundialType.body(11, color: c.textTertiary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.label,
    required this.asset,
    required this.style,
    required this.selected,
    required this.onChanged,
  });

  static const _previewSize = 76.0;

  final String label;
  final String asset;
  final AppIconStyle style;
  final AppIconStyle selected;
  final ValueChanged<AppIconStyle> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final visual = context.style;
    final isSelected = style == selected;
    final radius = BorderRadius.circular(SundialRadii.md);
    return Pressable(
      key: ValueKey('appIconChoice-${style.name}'),
      onTap: () {
        if (isSelected) return;
        playUiSound(context, UiSound.select);
        onChanged(style);
      },
      semanticLabel: label,
      semanticButton: true,
      semanticSelected: isSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(10, 11, 10, 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (visual.hasSelectedGradient ? null : c.accentSoft)
              : (visual.hasChromeGradient ? null : c.surfaceAlt),
          gradient: isSelected ? visual.selectedGradient : visual.chromeGradient,
          borderRadius: radius,
          border: Border.all(
            color: isSelected
                ? c.accent.withValues(alpha: 0.55)
                : (visual.hasChromeGradient ? visual.rim : c.border),
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected && !visual.performanceMode
              ? [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        foregroundDecoration: isSelected && visual.hasSelectedGradient && visual.gloss
            ? BoxDecoration(borderRadius: radius, gradient: visual.glossGradient)
            : null,
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: SundialShapes.icon(_previewSize),
                  child: Image.asset(
                    asset,
                    width: _previewSize,
                    height: _previewSize,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stack) => Container(
                      width: _previewSize,
                      height: _previewSize,
                      color: c.surfaceAlt,
                      child: Icon(Icons.apps_rounded, size: 32, color: c.textTertiary),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.surface, width: 1.5),
                      ),
                      child: Icon(Icons.check_rounded, size: 13, color: c.onAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SundialType.label(12, color: isSelected ? c.text : c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
