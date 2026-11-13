import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../settings_scope.dart';

/// The reference card surface: raised, quiet, one-pixel edge, no Material
/// elevation. Aero upgrades it to a glossy, frosted pane with a cyan glow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.color,
    this.borderColor,
    this.clip = false,
    this.margin,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool clip;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final settings = AppSettingsScope.maybeOf(context);
    final aero = settings?.isAero ?? false;
    final reduced = settings?.performanceMode ?? false;
    final shape = BorderRadius.circular(radius);
    // An explicit colour means the caller has a reason (accent tint, warning),
    // so keep that card flat even in Aero.
    final glass = aero && color == null;
    final gloss = glass && !reduced;

    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: glass
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.surface, c.surfaceAlt],
              ),
              border: Border.all(color: borderColor ?? c.glassEdge),
              borderRadius: shape,
              boxShadow: reduced
                  ? null
                  : [
                      BoxShadow(color: c.shadow, blurRadius: 22, offset: const Offset(0, 10)),
                      BoxShadow(color: c.accent.withValues(alpha: 0.12), blurRadius: 18),
                    ],
            )
          : BoxDecoration(
              color: color ?? c.surface,
              border: Border.all(color: borderColor ?? c.border),
              borderRadius: shape,
            ),
      // The gloss is painted over the child rather than laid out around it, so
      // padding, hit testing and card height stay untouched.
      foregroundDecoration: gloss
          ? BoxDecoration(
              borderRadius: shape,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)],
                stops: const [0, 0.42],
              ),
            )
          : null,
      child: child,
    );
  }
}
