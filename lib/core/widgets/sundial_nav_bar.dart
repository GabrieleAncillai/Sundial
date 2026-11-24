import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';
import '../icons/aero_glyph.dart';
import 'pressable.dart';

typedef SundialNavItem = ({IconData icon, IconData selectedIcon, String label});

/// The floating bottom navigation from the reference shell. A soft lens slides
/// between destinations. Aero turns the bar into a glass shelf with a
/// specular top highlight, a cyan rim and a glossy selected pill.
class SundialNavBar extends StatelessWidget {
  const SundialNavBar({super.key, required this.items, required this.index, required this.onSelected});

  /// Fixed bar height. Tall enough for an icon and a label with real padding
  /// above and below, which six destinations need on a phone.
  static const double height = 72;

  /// Gap between the shelf edge and the tab slots. Without it the selected
  /// lens in the first and last slots spills past the shelf's rounded corners.
  static const double shelfPadding = 6;

  /// Below this slot width the bar drops labels and enlarges the icons.
  /// Six labelled tabs need about this much room; at 360 dp a six-tab slot is
  /// only ~55 dp and the longest Spanish label no longer fits its lens.
  static const double iconOnlySlotWidth = 60;

  static const double iconSize = 22;
  static const double iconOnlySize = 26;

  final List<SundialNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final aero = style.hasChromeGradient;
    final reduced = style.performanceMode || MediaQuery.disableAnimationsOf(context);
    final shape = SundialShapes.rounded(
      radius: SundialRadii.xl,
      side: BorderSide(color: aero ? style.rim : c.border, width: aero ? 1.4 : 1),
    );

    Widget surface = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: aero ? null : c.navBg,
        gradient: aero ? style.chromeGradient : null,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final slot = (box.maxWidth - shelfPadding * 2) / items.length;
          final iconOnly = slot < iconOnlySlotWidth;
          return Stack(
            children: [
              if (aero && style.gloss)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: style.glossGradient,
                        borderRadius: BorderRadius.circular(SundialRadii.xl),
                      ),
                    ),
                  ),
                ),
              AnimatedPositioned(
                key: const ValueKey('nav-selected-lens'),
                duration: reduced ? Duration.zero : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: shelfPadding + slot * index,
                top: 6,
                width: slot,
                height: height - 12,
                child: DecoratedBox(
                  decoration: aero
                      ? BoxDecoration(
                          gradient: style.selectedGradient,
                          borderRadius: BorderRadius.circular(SundialRadii.lg),
                          border: Border.all(color: c.accent.withValues(alpha: 0.42)),
                          boxShadow: reduced
                              ? null
                              : [
                                  BoxShadow(
                                    color: c.accent.withValues(alpha: 0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        )
                      : BoxDecoration(
                          color: c.accentSoft,
                          borderRadius: BorderRadius.circular(SundialRadii.lg),
                          border: Border.all(color: c.accent.withValues(alpha: 0.22)),
                        ),
                  child: aero && style.gloss
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(SundialRadii.lg),
                            gradient: style.glossGradient,
                          ),
                        )
                      : null,
                ),
              ),
              if (aero)
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(height: 1, color: style.highlight.withValues(alpha: 0.42)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: shelfPadding),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _NavItem(
                          item: items[i],
                          selected: i == index,
                          onTap: () => onSelected(i),
                          iconOnly: iconOnly,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    if (aero && style.blurChrome) {
      surface = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: surface),
      );
    }

    return Container(
      height: height,
      decoration: ShapeDecoration(
        shape: shape.copyWith(side: BorderSide.none),
        shadows: aero
            ? style.chromeShadows
            : [
                BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                BoxShadow(color: c.shadow.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1)),
              ],
      ),
      child: surface,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.selected, required this.onTap, required this.iconOnly});

  final SundialNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final tint = selected ? c.accent : c.textSecondary;
    final pressable = Pressable(
      onTap: onTap,
      semanticButton: true,
      semanticLabel: item.label,
      scale: 0.94,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AeroGlyph(
              icon: selected ? item.selectedIcon : item.icon,
              size: iconOnly ? SundialNavBar.iconOnlySize : SundialNavBar.iconSize,
              selected: selected,
              color: tint,
            ),
            // A narrow slot keeps the icon and drops the label; the pressable
            // still carries the label for screen readers and a tooltip.
            if (!iconOnly) ...[
              const SizedBox(height: 4),
              // Labels honour accessibility scaling up to a cap, then shrink to
              // the slot rather than truncating a long word such as
              // "Estadísticas" on a six-tab phone bar.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Padding(
                  // Keep the longest label inside the lens' bottom corners.
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: SundialType.label(
                        10.5,
                        color: tint,
                      ).copyWith(fontWeight: selected ? FontWeight.w800 : FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!iconOnly) return pressable;
    return Tooltip(message: item.label, excludeFromSemantics: true, child: pressable);
  }
}
