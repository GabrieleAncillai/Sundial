import 'package:flutter/material.dart';

import 'sundial_field_clear.dart';

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SundialFieldClearSlot(visible: onClear != null, onPressed: onClear, tooltip: clearTooltip),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
        child: Text(valueLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
