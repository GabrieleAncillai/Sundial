import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../settings_scope.dart';

/// The reference card surface: raised, quiet, one-pixel edge, no Material
/// elevation. Aero upgrades it to a glossy, frosted pane with a cyan glow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = SundialRadii.lg,
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
    // An explicit colour means the caller has a reason (accent tint, warning),
    // so keep that card flat even in Aero.
    final glass = aero && color == null;
    final gloss = glass && !reduced;
    final shape = SundialShapes.rounded(
      radius: radius,
      side: BorderSide(color: borderColor ?? (glass ? c.glassEdge : c.border)),
    );

    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: ShapeDecoration(
        shape: shape,
        color: glass ? null : (color ?? c.surface),
        gradient: glass
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.surface, c.surfaceAlt],
              )
            : null,
        shadows: glass && !reduced
            ? [
                BoxShadow(color: c.shadow, blurRadius: 22, offset: const Offset(0, 10)),
                BoxShadow(color: c.accent.withValues(alpha: 0.12), blurRadius: 18),
              ]
            : null,
      ),
      // The gloss is painted over the child rather than laid out around it, so
      // padding, hit testing and card height stay untouched.
      foregroundDecoration: gloss
          ? ShapeDecoration(
              shape: shape.copyWith(side: BorderSide.none),
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
