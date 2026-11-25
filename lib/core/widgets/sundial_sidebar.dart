import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';
import '../icons/aero_glyph.dart';
import '../layout/sundial_layout.dart';
import 'app_background.dart';
import 'pressable.dart';

/// The floating desktop sidebar shared by the main rail and Settings.
///
/// Width, outer inset and the style-driven chrome live here so the two rails
/// cannot drift apart again. Headers, search fields and footers stay with the
/// screen that owns them.
class SundialSidebar extends StatelessWidget {
  const SundialSidebar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: kSidebarWidth,
        child: GlassSurface(
          radius: SundialRadii.xl,
          tint: style.hasChromeGradient ? null : c.navBg,
          child: child,
        ),
      ),
    );
  }
}

/// The standard list body inside a [SundialSidebar].
///
/// Rows sit 10 px from the sidebar edge while the search field sits 12 px in,
/// so the row capsules just overhang the field by 2 px on each side, as on the
/// main rail. Keeping the inset here stops the two rails from drifting again.
class SundialSidebarList extends StatelessWidget {
  const SundialSidebarList({super.key, required this.children, this.bottom = 0});

  final List<Widget> children;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: EdgeInsets.fromLTRB(10, 0, 10, bottom), children: children);
  }
}

/// A row in a [SundialSidebar].
///
/// The main rail and the settings menu share the selected treatment, glyph,
/// radius and type so moving between them reads as one surface.
class SundialSidebarItem extends StatelessWidget {
  const SundialSidebarItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selectedIcon,
    this.subtitle,
    this.value,
    this.selected = false,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String title;
  final String? subtitle;
  final String? value;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final twoLines = subtitle != null;
    final label = semanticLabel ?? [title, ?subtitle, ?value].join(', ');
    return Semantics(
      selected: selected,
      child: Pressable(
        onTap: onTap,
        semanticButton: true,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: twoLines ? 8 : 10),
          decoration: BoxDecoration(
            color: selected && !style.hasSelectedGradient ? c.accentSoft : Colors.transparent,
            gradient: selected ? style.selectedGradient : null,
            borderRadius: BorderRadius.circular(SundialRadii.md),
            border: selected
                ? Border.all(
                    color: style.hasSelectedGradient
                        ? c.accent.withValues(alpha: 0.42)
                        : c.accent.withValues(alpha: 0.2),
                  )
                : null,
            boxShadow: selected && style.hasSelectedGradient && !style.performanceMode
                ? [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          foregroundDecoration: selected && style.hasSelectedGradient && style.gloss
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(SundialRadii.md),
                  gradient: style.glossGradient,
                )
              : null,
          child: Row(
            children: [
              AeroGlyph(
                icon: selected ? (selectedIcon ?? icon) : icon,
                size: 20,
                selected: selected,
                color: selected ? c.accent : c.textSecondary,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(
                        13,
                        weight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? c.accent : c.textSecondary,
                      ),
                    ),
                    if (twoLines) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SundialType.body(10.5, color: c.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(value!, style: SundialType.label(10.5, color: c.textTertiary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
