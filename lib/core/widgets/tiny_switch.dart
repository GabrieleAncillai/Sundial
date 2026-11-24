import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/sundial_style.dart';

/// The reference switch: a small track with a sliding thumb, not a Material
/// switch. Aero adds a glossy aqua track and a pearl thumb with a specular
/// highlight.
class TinySwitch extends StatelessWidget {
  const TinySwitch({super.key, required this.value, this.onChanged, this.semanticLabel});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final aero = style.hasControlGradient;
    final enabled = onChanged != null;
    final shape = BorderRadius.circular(SundialRadii.pill);

    final control = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? (aero ? null : c.accent) : c.surfaceHigh,
        gradient: aero && value ? style.controlGradient : null,
        borderRadius: shape,
        border: Border.all(
          color: value ? (aero ? c.accent.withValues(alpha: 0.55) : c.accent) : (aero ? style.rim : c.border),
        ),
        boxShadow: aero && value && !style.performanceMode
            ? [BoxShadow(color: c.accent.withValues(alpha: 0.20), blurRadius: 10, offset: const Offset(0, 3))]
            : null,
      ),
      foregroundDecoration: aero && style.gloss
          ? BoxDecoration(borderRadius: shape, gradient: style.glossGradient)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: aero ? null : (value ? c.onAccent : c.textTertiary),
          gradient: aero
              ? RadialGradient(
                  center: const Alignment(-0.38, -0.48),
                  colors: [Colors.white, Color.lerp(style.colors.surface, style.colors.accentSoft, 0.35)!],
                  stops: const [0, 1],
                )
              : null,
          border: aero ? Border.all(color: Colors.white.withValues(alpha: 0.72)) : null,
          boxShadow: aero
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: style.brightness == Brightness.dark ? 0.35 : 0.16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Opacity(opacity: enabled ? 1 : 0.45, child: control),
      ),
    );
  }
}
