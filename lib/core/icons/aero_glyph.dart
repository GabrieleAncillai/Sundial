import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/sundial_style.dart';

/// A style-aware icon. Classic keeps the outline glyph; Aero applies a soft
/// specular gradient and can place the glyph on a glossy orb tile.
class AeroGlyph extends StatelessWidget {
  const AeroGlyph({
    super.key,
    required this.icon,
    this.size = 22,
    this.selected = false,
    this.tile = false,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final bool selected;
  final bool tile;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final style = context.style;
    final resolved = color ?? (selected ? style.colors.accent : style.colors.textSecondary);
    Widget glyph;
    if (style.iconTreatment == SundialIconTreatment.outline) {
      glyph = Icon(icon, size: size, color: resolved, semanticLabel: semanticLabel);
    } else {
      final colors = selected
          ? [style.colors.accent, style.colors.text]
          : [Color.lerp(resolved, Colors.white, 0.22)!, resolved];
      glyph = ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
        child: Icon(icon, size: size, color: Colors.white, semanticLabel: semanticLabel),
      );
    }
    if (!tile || style.iconTreatment == SundialIconTreatment.outline) return glyph;

    final side = size * 1.8;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.38, -0.48),
              radius: 0.9,
              colors: [
                Color.lerp(Colors.white, style.colors.accentSoft, 0.18)!,
                Color.lerp(style.colors.accentSoft, style.colors.accent, 0.28)!,
                Color.lerp(style.colors.accent, style.colors.surface, 0.25)!,
              ],
              stops: const [0, 0.62, 1],
            ),
            border: Border.all(color: style.highlight.withValues(alpha: 0.72), width: 1.2),
            boxShadow: style.performanceMode
                ? null
                : [
                    BoxShadow(
                      color: style.colors.accent.withValues(alpha: 0.26),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (style.gloss)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.62), Colors.white.withValues(alpha: 0)],
                          stops: const [0, 0.55],
                        ),
                      ),
                    ),
                  ),
                ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [style.colors.text, style.colors.accent],
                ).createShader(rect),
                child: Icon(icon, size: size, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app mark. Uses the shipped launcher artwork for the active visual
/// style, so the in-app logo is the official icon rather than a redrawn mark.
class SundialLogo extends StatelessWidget {
  const SundialLogo({super.key, this.size = 38});

  final double size;

  static const _classicAsset = 'assets/icons/icon_classic.png';
  static const _aeroAsset = 'assets/icons/icon_aero.png';

  @override
  Widget build(BuildContext context) {
    final style = context.style;
    final asset = style.brandMark == SundialBrandMark.orb ? _aeroAsset : _classicAsset;
    return ClipRRect(
      borderRadius: SundialShapes.icon(size),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
