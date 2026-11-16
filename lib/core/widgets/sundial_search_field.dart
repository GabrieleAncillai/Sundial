import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
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
    return Container(
      height: 50,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: c.textTertiary),
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
