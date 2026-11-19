import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../settings_scope.dart';

class SundialSegment<T> {
  const SundialSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// The reference pill segmented control. It keeps the selected state readable
/// without the heavy Material segment border. Aero gives the thumb a glossy
/// white-to-blue finish and the track a translucent glass tint.
class SundialSegmented<T> extends StatelessWidget {
  const SundialSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  final List<SundialSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final settings = AppSettingsScope.maybeOf(context);
    final aero = settings?.isAero ?? false;
    final reduced = settings?.performanceMode ?? false;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: aero ? c.glass : c.surfaceAlt,
        borderRadius: BorderRadius.circular(SundialRadii.pill),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final segment in segments)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(segment.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 7 : 9),
                decoration: BoxDecoration(
                  color: segment.value == selected && !aero ? c.surface : Colors.transparent,
                  gradient: segment.value == selected && aero
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, c.surfaceAlt],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(SundialRadii.pill),
                  boxShadow: segment.value == selected
                      ? [
                          BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 2)),
                          if (aero && !reduced)
                            BoxShadow(color: c.accent.withValues(alpha: 0.12), blurRadius: 10),
                        ]
                      : null,
                ),
                // Border and inner highlight live in the foreground so they
                // never add decoration padding or shift the label.
                foregroundDecoration: segment.value == selected && aero
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(SundialRadii.pill),
                        border: Border.all(color: c.accent.withValues(alpha: 0.30)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                          stops: const [0, 0.45],
                        ),
                      )
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(
                        segment.icon,
                        size: 15,
                        color: segment.value == selected ? c.accent : c.textSecondary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      segment.label,
                      style: SundialType.label(
                        compact ? 11.5 : 12.5,
                        color: segment.value == selected ? c.text : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
