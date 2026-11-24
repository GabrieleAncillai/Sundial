import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/sundial_style.dart';

/// A progress track with the Aero material: an inset pearl groove and one
/// glossy aqua fill. Classic keeps the flat accent fill.
class SundialProgressBar extends StatelessWidget {
  const SundialProgressBar({super.key, required this.value, this.height = 8, this.color});

  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final fill = color ?? c.accent;
    final aero = style.hasControlGradient;
    final radius = BorderRadius.circular(height / 2);
    final progress = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: aero ? null : c.surfaceHigh,
                gradient: aero
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [c.surfaceHigh, c.surfaceAlt],
                      )
                    : null,
                borderRadius: radius,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: aero ? null : fill,
                    gradient: aero
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.lerp(fill, Colors.white, 0.30)!, fill],
                          )
                        : null,
                    borderRadius: radius,
                  ),
                  child: aero && style.gloss
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.48),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.62],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
