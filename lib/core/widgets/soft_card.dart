import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/sundial_style.dart';

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
    final style = context.style;
    // An explicit colour means the caller has a reason (accent tint, warning),
    // so keep that card flat even in Aero.
    final glass = style.hasSurfaceGradient && color == null;
    final shape = SundialShapes.rounded(
      radius: radius,
      side: BorderSide(color: borderColor ?? (glass ? style.rim : c.border)),
    );

    return Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: ShapeDecoration(
        shape: shape,
        color: glass ? null : (color ?? c.surface),
        gradient: glass ? style.surfaceGradient : null,
        shadows: glass && style.cardShadows.isNotEmpty ? style.cardShadows : null,
      ),
      // The gloss is painted over the child rather than laid out around it, so
      // padding, hit testing and card height stay untouched.
      foregroundDecoration: glass && style.gloss
          ? ShapeDecoration(
              shape: shape.copyWith(side: BorderSide.none),
              gradient: style.glossGradient,
            )
          : null,
      child: child,
    );
  }
}
