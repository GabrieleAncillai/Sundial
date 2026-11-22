import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../settings_scope.dart';
import 'pressable.dart';

typedef SundialNavItem = ({IconData icon, IconData selectedIcon, String label});

/// The floating bottom navigation from the reference shell. A soft lens slides
/// between three destinations; labels stay visible for accessibility. Aero
/// turns the bar into a glass slab with a gloss and a cyan glow.
class SundialNavBar extends StatelessWidget {
  const SundialNavBar({super.key, required this.items, required this.index, required this.onSelected});

  final List<SundialNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final settings = AppSettingsScope.maybeOf(context);
    final aero = settings?.isAero ?? false;
    final reduced = settings?.performanceMode ?? false;
    final glow = aero && !reduced;
    final shape = SundialShapes.rounded(
      radius: SundialRadii.xl,
      side: BorderSide(color: aero ? c.glassEdge : c.border, width: aero ? 1.4 : 1),
    );
    return Container(
      height: 64,
      decoration: ShapeDecoration(
        shape: shape.copyWith(side: BorderSide.none),
        shadows: aero
            ? [
                BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                if (glow) BoxShadow(color: c.accent.withValues(alpha: 0.14), blurRadius: 22),
              ]
            : [
                BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                BoxShadow(color: c.shadow.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1)),
              ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: DecoratedBox(
          decoration: ShapeDecoration(shape: shape, color: aero ? c.glass : c.navBg),
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / items.length;
              return Stack(
                children: [
                  if (aero && !reduced)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.55],
                            ),
                          ),
                        ),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    left: slot * index + 6,
                    top: 6,
                    width: slot - 12,
                    height: 52,
                    child: DecoratedBox(
                      decoration: aero
                          ? BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.92),
                                  c.accent.withValues(alpha: 0.16),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(SundialRadii.md),
                              border: Border.all(color: c.accent.withValues(alpha: 0.32)),
                              boxShadow: glow
                                  ? [
                                      BoxShadow(
                                        color: c.accent.withValues(alpha: 0.16),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            )
                          : BoxDecoration(
                              color: c.accentSoft,
                              borderRadius: BorderRadius.circular(SundialRadii.md),
                              border: Border.all(color: c.accent.withValues(alpha: 0.22)),
                            ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavItem(item: items[i], selected: i == index, onTap: () => onSelected(i)),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.selected, required this.onTap});

  final SundialNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final tint = selected ? c.accent : c.textSecondary;
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      semanticLabel: item.label,
      scale: 0.94,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? item.selectedIcon : item.icon, size: 21, color: tint),
            const SizedBox(height: 3),
            // Labels honour accessibility scaling up to a cap, then shrink to
            // the slot rather than truncating a long word such as
            // "Estadísticas" on a six-tab phone bar.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
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
          ],
        ),
      ),
    );
  }
}
