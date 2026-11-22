import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import 'sundial_field_clear.dart';
import 'sundial_field_label.dart';

/// A tappable date value with the shared input decoration.
///
/// The clear action lives in the decoration's suffix slot, so the field keeps
/// its width and the control stays inside the rounded frame. [onClear] is
/// optional: required dates simply omit it.
class SundialDateField extends StatelessWidget {
  const SundialDateField({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.onTap,
    this.icon = Icons.event_outlined,
    this.onClear,
    this.clearTooltip,
  });

  final String label;
  final String valueLabel;
  final VoidCallback onTap;
  final IconData icon;
  final VoidCallback? onClear;
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SundialFieldLabel(label),
        Semantics(
          label: label,
          value: valueLabel,
          button: true,
          onTap: onTap,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(SundialRadii.md),
            child: InputDecorator(
              decoration: InputDecoration(
                prefixIcon: Icon(icon, size: 20),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SundialFieldClearSlot(
                    visible: onClear != null,
                    onPressed: onClear,
                    tooltip: clearTooltip,
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
              child: Text(
                valueLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SundialType.body(14, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
