import 'dart:math' as math;

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

/// The app mark. Classic keeps the flat accent tile; Aero renders an original
/// glossy sundial orb rather than borrowing an OS asset.
class SundialLogo extends StatelessWidget {
  const SundialLogo({super.key, this.size = 38});

  final double size;

  @override
  Widget build(BuildContext context) {
    final style = context.style;
    final c = style.colors;
    if (style.brandMark == SundialBrandMark.tile) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(SundialRadii.sm)),
        child: Icon(Icons.event_note, size: size * 0.55, color: c.onAccent),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.38, -0.46),
          radius: 0.92,
          colors: style.brightness == Brightness.dark
              ? const [Color(0xFFBFF4FF), Color(0xFF2B9CC8), Color(0xFF093B57)]
              : const [Color(0xFFD9FBFF), Color(0xFF36B6E0), Color(0xFF0B5E86)],
          stops: const [0, 0.58, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 1.2),
        boxShadow: style.performanceMode
            ? null
            : [
                BoxShadow(
                  color: c.accent.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: CustomPaint(
        painter: _SundialMarkPainter(
          ink: style.brightness == Brightness.dark ? const Color(0xFF03212E) : const Color(0xFF083247),
          sun: const Color(0xFFFFE08A),
          gloss: style.gloss,
        ),
      ),
    );
  }
}

class _SundialMarkPainter extends CustomPainter {
  _SundialMarkPainter({required this.ink, required this.sun, required this.gloss});

  final Color ink;
  final Color sun;
  final bool gloss;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide;

    // The dial face.
    canvas.drawCircle(
      center.translate(0, radius * 0.04),
      radius * 0.30,
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center.translate(0, radius * 0.04),
      radius * 0.30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, radius * 0.035)
        ..color = Colors.white.withValues(alpha: 0.52),
    );

    // The gnomon: an original wedge, not an OS icon.
    final shadow = Path()
      ..moveTo(center.dx, center.dy - radius * 0.20)
      ..lineTo(center.dx + radius * 0.20, center.dy + radius * 0.15)
      ..lineTo(center.dx - radius * 0.02, center.dy + radius * 0.15)
      ..close();
    canvas.drawPath(shadow, Paint()..color = ink.withValues(alpha: 0.58));

    // The sun.
    final sunCenter = center.translate(-radius * 0.08, -radius * 0.09);
    canvas.drawCircle(
      sunCenter,
      radius * 0.105,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [Colors.white, sun, const Color(0xFFF2A93B)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: radius * 0.105)),
    );

    if (gloss) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.34, size.height * 0.24),
          width: size.width * 0.36,
          height: size.height * 0.16,
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.44),
      );
    }
  }

  @override
  bool shouldRepaint(_SundialMarkPainter oldDelegate) =>
      oldDelegate.ink != ink || oldDelegate.sun != sun || oldDelegate.gloss != gloss;
}
