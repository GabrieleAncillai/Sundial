import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/settings_scope.dart';
import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';

/// The calm backdrop from the reference shell. The pattern is a preference:
/// dots, grid, OLED black, plain or a custom colour. Aero adds a glossy sky.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.child,
    this.showDots = true,
    this.style,
    this.customColor,
    this.aero,
    this.performanceMode,
  });

  final Widget? child;
  final bool showDots;
  final SundialBackgroundStyle? style;
  final Color? customColor;
  final bool? aero;
  final bool? performanceMode;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final preferences = AppSettingsScope.maybeOf(context);
    final resolvedStyle = style ?? preferences?.backgroundStyle ?? SundialBackgroundStyle.dots;
    final resolvedAero = aero ?? preferences?.isAero ?? false;
    final reducedMotion = performanceMode ?? preferences?.performanceMode ?? false;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = switch (resolvedStyle) {
      SundialBackgroundStyle.oled => Colors.black,
      SundialBackgroundStyle.custom =>
        customColor ?? Color(preferences?.backgroundCustomColor ?? c.pageBg.toARGB32()),
      _ => resolvedAero ? const Color(0xFFE7F7FF) : c.pageBg,
    };
    final pattern = switch (resolvedStyle) {
      SundialBackgroundStyle.dots => showDots ? _Pattern.dots : _Pattern.none,
      SundialBackgroundStyle.grid => _Pattern.grid,
      _ => _Pattern.none,
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        if (resolvedAero) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8BD6FF).withValues(alpha: 0.55),
                  const Color(0xFFDFF5FF).withValues(alpha: 0.25),
                  base.withValues(alpha: 0),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
          if (!reducedMotion)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.75, -0.92),
                  radius: 0.9,
                  colors: [Colors.white.withValues(alpha: 0.62), Colors.white.withValues(alpha: 0)],
                ),
              ),
            ),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [c.accent.withValues(alpha: 0.055), base.withValues(alpha: 0)]
                    : [c.accent.withValues(alpha: 0.035), base.withValues(alpha: 0)],
                stops: const [0, 0.45],
              ),
            ),
          ),
        if (resolvedAero && !reducedMotion)
          IgnorePointer(
            child: RepaintBoundary(child: CustomPaint(painter: _AeroBubblePainter())),
          ),
        if (pattern != _Pattern.none)
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PatternPainter(
                  pattern: pattern,
                  color: resolvedAero
                      ? Colors.white.withValues(alpha: 0.65)
                      : dark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.black.withValues(alpha: 0.075),
                ),
              ),
            ),
          ),
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}

enum _Pattern { none, dots, grid }

class _AeroBubblePainter extends CustomPainter {
  static const _bubbles = <(double, double, double)>[
    (0.08, 0.18, 38),
    (0.22, 0.42, 18),
    (0.78, 0.12, 54),
    (0.9, 0.38, 24),
    (0.64, 0.55, 14),
    (0.14, 0.72, 26),
    (0.42, 0.84, 44),
    (0.82, 0.78, 32),
    (0.54, 0.24, 10),
    (0.32, 0.6, 8),
    (0.72, 0.9, 12),
    (0.04, 0.52, 12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (x, y, radius) in _bubbles) {
      final center = Offset(size.width * x, size.height * y);
      final circle = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            Colors.white.withValues(alpha: 0.55),
            const Color(0xFF9BDDFF).withValues(alpha: 0.22),
            const Color(0xFF6FC8F5).withValues(alpha: 0.05),
          ],
        ).createShader(circle);
      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.34),
      );
    }
  }

  @override
  bool shouldRepaint(_AeroBubblePainter oldDelegate) => false;
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.pattern, required this.color});

  final _Pattern pattern;
  final Color color;
  static const _gap = 24.0;
  static const _radius = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (pattern == _Pattern.dots) {
      for (double y = _gap; y < size.height; y += _gap) {
        for (double x = _gap; x < size.width; x += _gap) {
          canvas.drawCircle(Offset(x, y), _radius, paint);
        }
      }
      return;
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = _gap; x < size.width; x += _gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = _gap; y < size.height; y += _gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pattern != pattern;
}

/// A frosted surface for the floating shell pieces.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.blur = 18,
    this.tint,
    this.borderColor,
    this.shadows = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final Color? tint;
  final Color? borderColor;
  final bool shadows;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: shadows
            ? [
                BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                BoxShadow(
                  color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint ?? c.glass,
              borderRadius: shape,
              border: Border.all(color: borderColor ?? c.glassEdge),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
