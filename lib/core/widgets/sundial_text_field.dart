import 'package:flutter/material.dart';

import 'sundial_field_label.dart';

/// A text input with the same caption-above-control idiom as
/// [SundialSelectField]. The label stays outside the input, so a filled field
/// on a same-coloured surface never shows a punched-out floating-label notch.
class SundialTextField extends StatelessWidget {
  const SundialTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    this.enabled = true,
  }) : assert(controller == null || initialValue == null, 'Use either controller or initialValue.');

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SundialFieldLabel(label),
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            initialValue: initialValue,
            autofocus: autofocus,
            enabled: enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            validator: validator,
            onChanged: onChanged,
            decoration: InputDecoration(hintText: hintText, helperText: helperText),
          ),
        ),
      ],
    );
  }
}
