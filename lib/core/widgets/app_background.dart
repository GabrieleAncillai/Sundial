import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/settings_scope.dart';
import '../../models/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/sundial_style.dart';

/// The backdrop from the reference shell. Classic keeps the calm pattern
/// preference; Aero paints a procedural sky, horizon and slow glass bubbles.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    this.child,
    this.showDots = true,
    this.style,
    this.customColor,
    this.performanceMode,
  });

  final Widget? child;
  final bool showDots;
  final SundialBackgroundStyle? style;
  final Color? customColor;
  final bool? performanceMode;

  @override
  Widget build(BuildContext context) {
    final appStyle = context.style;
    final preferences = AppSettingsScope.maybeOf(context);
    final resolvedStyle = style ?? preferences?.backgroundStyle ?? SundialBackgroundStyle.dots;
    final reduced = performanceMode ?? preferences?.performanceMode ?? false;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final aero =
        appStyle.environment == SundialEnvironment.aero &&
        resolvedStyle != SundialBackgroundStyle.oled &&
        resolvedStyle != SundialBackgroundStyle.custom;
    final base = switch (resolvedStyle) {
      SundialBackgroundStyle.oled => Colors.black,
      SundialBackgroundStyle.custom =>
        customColor ?? Color(preferences?.backgroundCustomColor ?? appStyle.colors.pageBg.toARGB32()),
      _ => appStyle.colors.pageBg,
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
        if (aero)
          AeroEnvironment(style: appStyle, animate: !reduced)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [appStyle.colors.accent.withValues(alpha: 0.055), base.withValues(alpha: 0)]
                    : [appStyle.colors.accent.withValues(alpha: 0.035), base.withValues(alpha: 0)],
                stops: const [0, 0.45],
              ),
            ),
          ),
        if (pattern != _Pattern.none)
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _PatternPainter(
                  pattern: pattern,
                  color: aero
                      ? Colors.white.withValues(alpha: dark ? 0.05 : 0.10)
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

/// The animated Aero environment. It is a single custom paint layer, isolated
/// in a RepaintBoundary, and it stops moving entirely in performance mode.
class AeroEnvironment extends StatefulWidget {
  const AeroEnvironment({super.key, required this.style, required this.animate});

  final SundialStyle style;
  final bool animate;

  @override
  State<AeroEnvironment> createState() => _AeroEnvironmentState();
}

class _AeroEnvironmentState extends State<AeroEnvironment> with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: AeroMotion.loop);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AeroEnvironment oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final animate = widget.animate && !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (animate == _running) return;
    _running = animate;
    if (animate) {
      _drift.repeat();
    } else {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AeroEnvironmentPainter(style: widget.style, animation: _drift),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// The motion math behind the Aero environment.
///
/// The controller repeats from 0 to 1, so every time-based term must complete
/// a whole number of cycles across that range. A fractional cycle leaves the
/// animation at a different pose when it wraps and the background visibly
/// jumps. Keep new motion in these helpers so the seam test covers it.
class AeroMotion {
  const AeroMotion._();

  /// One seamless loop of the ambient sky and glass.
  static const Duration loop = Duration(seconds: 256);

  static const int _waveCycles = 1;
  static const int _bubbleDriftXCycles = 4;
  static const int _bubbleDriftYCycles = 5;

  static double _turns(double progress) => progress * math.pi * 2;

  static double wavePhase(double progress, int layer) => _turns(progress * _waveCycles) + layer * 1.35;

  static Offset bubbleDrift(double progress, double phase, Size size) => Offset(
    math.sin(_turns(progress * _bubbleDriftXCycles) + phase) * size.width * 0.008,
    math.cos(_turns(progress * _bubbleDriftYCycles) + phase) * size.height * 0.018,
  );
}

class _AeroEnvironmentPainter extends CustomPainter {
  _AeroEnvironmentPainter({required this.style, required this.animation}) : super(repaint: animation);

  final SundialStyle style;
  final Animation<double> animation;

  static const _bubbles = <(double, double, double, double)>[
    (0.08, 0.16, 0.040, 0.0),
    (0.21, 0.38, 0.018, 1.2),
    (0.79, 0.11, 0.052, 2.1),
    (0.91, 0.34, 0.024, 0.4),
    (0.65, 0.56, 0.014, 3.0),
    (0.13, 0.72, 0.026, 1.8),
    (0.43, 0.84, 0.042, 5.1),
    (0.83, 0.77, 0.032, 4.0),
    (0.54, 0.23, 0.010, 2.6),
    (0.32, 0.60, 0.008, 0.9),
    (0.72, 0.91, 0.012, 3.7),
    (0.04, 0.50, 0.012, 5.7),
    (0.58, 0.44, 0.020, 4.8),
    (0.95, 0.60, 0.016, 1.5),
    (0.38, 0.08, 0.016, 2.9),
    (0.88, 0.95, 0.022, 0.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    final dark = style.brightness == Brightness.dark;
    final sky = style.skyGradient;
    if (sky != null) {
      canvas.drawRect(rect, Paint()..shader = sky.createShader(rect));
    }

    // The light source sits top-left, matching every other Aero surface.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.72, -0.95),
          radius: 0.92,
          colors: [
            Colors.white.withValues(alpha: dark ? 0.15 : 0.58),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.25, 1.20),
          radius: 0.95,
          colors: [style.horizonGlow, style.horizonGlow.withValues(alpha: 0)],
        ).createShader(rect),
    );

    _paintWaves(canvas, size, dark);
    _paintBubbles(canvas, size, dark);
  }

  void _paintWaves(Canvas canvas, Size size, bool dark) {
    final tint = Color.lerp(style.colors.accent, style.colors.surface, dark ? 0.45 : 0.55)!;
    for (var layer = 0; layer < 3; layer++) {
      final baseY = size.height * (0.74 + layer * 0.07);
      final amplitude = size.height * (0.010 + layer * 0.003);
      final path = Path()..moveTo(0, baseY);
      const steps = 10;
      for (var step = 0; step <= steps; step++) {
        final x = size.width * step / steps;
        final wave =
            math.sin((step / steps) * math.pi * 2 + AeroMotion.wavePhase(animation.value, layer)) * amplitude;
        path.lineTo(x, baseY + wave);
      }
      path
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = tint.withValues(alpha: dark ? 0.045 + layer * 0.018 : 0.035 + layer * 0.016),
      );
    }
  }

  void _paintBubbles(Canvas canvas, Size size, bool dark) {
    final highlight = style.highlight;
    for (final (x, y, radius, phase) in _bubbles) {
      final r = size.shortestSide * radius;
      final drift = AeroMotion.bubbleDrift(animation.value, phase, size);
      final center = Offset(size.width * x + drift.dx, size.height * y + drift.dy);
      final circle = Rect.fromCircle(center: center, radius: r);

      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.36, -0.44),
            radius: 0.96,
            colors: [
              Colors.white.withValues(alpha: dark ? 0.34 : 0.60),
              style.colors.accent.withValues(alpha: dark ? 0.30 : 0.26),
              style.colors.accent.withValues(alpha: 0.05),
            ],
            stops: const [0, 0.68, 1],
          ).createShader(circle),
      );
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.7, r * 0.045)
          ..color = highlight.withValues(alpha: dark ? 0.28 : 0.38),
      );
      canvas.drawCircle(
        center.translate(-r * 0.32, -r * 0.38),
        math.max(1.2, r * 0.15),
        Paint()..color = Colors.white.withValues(alpha: dark ? 0.36 : 0.58),
      );
    }
  }

  @override
  bool shouldRepaint(_AeroEnvironmentPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.animation != animation;
}

enum _Pattern { none, dots, grid }

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
    this.radius = SundialRadii.xl,
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
    final style = context.style;
    final shape = SundialShapes.rounded(
      radius: radius,
      side: BorderSide(color: borderColor ?? (style.hasChromeGradient ? style.rim : c.glassEdge)),
    );
    final decoration = ShapeDecoration(
      shape: shape.copyWith(side: BorderSide.none),
      shadows: shadows
          ? style.hasChromeGradient
                ? style.chromeShadows
                : [
                    BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10)),
                    BoxShadow(
                      color: (style.brightness == Brightness.dark ? Colors.white : Colors.black).withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
          : null,
    );
    Widget surface = Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: tint ?? (style.hasChromeGradient ? null : c.glass),
        gradient: style.chromeGradient,
        shape: shape,
      ),
      child: child,
    );
    if (style.glassChrome && style.blurChrome) {
      surface = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      );
    }
    return DecoratedBox(decoration: decoration, child: surface);
  }
}
