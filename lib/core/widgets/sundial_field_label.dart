import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// The small caption that sits above a control in the settings-style form
/// language. Select, time, date and text fields all use it, so the editor does
/// not mix floating labels with captions on the same surface.
class SundialFieldLabel extends StatelessWidget {
  const SundialFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7),
      child: ExcludeSemantics(
        child: Text(label, style: SundialType.label(11.5, color: c.textTertiary)),
      ),
    );
  }
}
