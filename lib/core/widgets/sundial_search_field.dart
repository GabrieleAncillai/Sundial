import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';
import '../icons/aero_glyph.dart';
import 'sundial_field_clear.dart';

class SundialSearchField extends StatelessWidget {
  const SundialSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final shape = BorderRadius.circular(SundialRadii.pill);
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: style.hasFieldGradient ? null : c.surface,
        gradient: style.fieldGradient,
        borderRadius: shape,
        border: Border.all(color: style.hasFieldGradient ? style.rim : c.border),
        boxShadow: style.hasFieldGradient ? style.chromeShadows.take(1).toList() : null,
      ),
      foregroundDecoration: style.hasFieldGradient && style.gloss
          ? BoxDecoration(borderRadius: shape, gradient: style.glossGradient)
          : null,
      child: Row(
        children: [
          AeroGlyph(icon: Icons.search, size: 18, color: c.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: SundialType.body(14, color: c.text),
              cursorColor: c.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: SundialType.body(14, color: c.textTertiary),
              ),
            ),
          ),
          SundialTextClear(
            controller: controller,
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            onCleared: () => onChanged(''),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
