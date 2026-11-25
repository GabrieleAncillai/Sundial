import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';
import '../icons/aero_glyph.dart';
import 'pressable.dart';
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
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

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
          if (trailing != null) ...[const SizedBox(width: 4), trailing!],
        ],
      ),
    );
  }
}

/// A round action for the trailing edge of a [SundialSearchField].
///
/// Unlike [GlassIconButton], this action stays flat inside the field's frame so
/// the search stays one control instead of a field with a second raised button
/// stuck to it. [selected] marks an active filter; [badge] carries its count.
class SundialSearchAction extends StatelessWidget {
  const SundialSearchAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.badge,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final aero = style.hasFieldGradient;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        semanticButton: true,
        semanticLabel: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? (style.hasSelectedGradient ? null : c.accentSoft)
                : (aero ? c.surfaceHigh.withValues(alpha: 0.55) : c.surface),
            gradient: selected ? style.selectedGradient : null,
            border: Border.all(
              color: selected
                  ? c.accent.withValues(alpha: 0.45)
                  : (aero ? c.border.withValues(alpha: 0.7) : c.border),
            ),
          ),
          foregroundDecoration: selected && style.hasSelectedGradient && style.gloss
              ? BoxDecoration(shape: BoxShape.circle, gradient: style.glossGradient)
              : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AeroGlyph(icon: icon, size: 18, color: selected ? c.accent : c.textSecondary),
              if (badge != null) Positioned(top: 2, right: 2, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}
