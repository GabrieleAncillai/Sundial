import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

enum SundialNoticeTone { info, warning, danger }

/// Inline message used for load errors and soft warnings. It is deliberately
/// quieter than a snack bar so a failed background query does not cover the
/// plan.
class SundialNotice extends StatelessWidget {
  const SundialNotice({super.key, required this.text, this.tone = SundialNoticeTone.danger, this.icon});

  final String text;
  final SundialNoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final (color, soft) = switch (tone) {
      SundialNoticeTone.danger => (c.danger, c.dangerSoft),
      SundialNoticeTone.warning => (c.warning, c.warningSoft),
      SundialNoticeTone.info => (c.info, c.accentSoft),
    };
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(SundialRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? (tone == SundialNoticeTone.danger ? Icons.error_outline : Icons.info_outline),
            size: 18,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text, style: SundialType.body(12.5, color: color)),
          ),
        ],
      ),
    );
  }
}
