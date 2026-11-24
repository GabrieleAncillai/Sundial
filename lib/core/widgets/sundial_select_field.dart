import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';
import 'app_sheet.dart';
import 'sundial_field_clear.dart';
import 'sundial_field_label.dart';
import 'sundial_search_field.dart';
import 'pressable.dart';

/// One row in a [SundialSelectField]'s option sheet.
@immutable
class SundialSelectOption<T> {
  const SundialSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool enabled;
}

/// A settings-style select control. The caller supplies the copy and owns the
/// tap handler, so this widget stays free of feature-specific strings.
class SundialSelectField extends StatelessWidget {
  const SundialSelectField({
    super.key,
    required this.label,
    required this.valueLabel,
    this.leading,
    this.onTap,
    this.enabled = true,
    this.onClear,
    this.clearTooltip,
  });

  final String label;
  final String valueLabel;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool enabled;

  /// Adds a clear action inside the field's own frame. The action expands from
  /// the trailing edge so the field keeps its width instead of shifting the
  /// surrounding layout.
  final VoidCallback? onClear;

  /// Tooltip and screen-reader label for [onClear].
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final active = enabled && onTap != null;
    final canClear = active && onClear != null;
    final shape = BorderRadius.circular(SundialRadii.md);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SundialFieldLabel(label),
        Semantics(
          enabled: active,
          child: Pressable(
            onTap: active ? onTap : null,
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
              decoration: BoxDecoration(
                color: style.hasFieldGradient ? null : c.surfaceAlt,
                gradient: style.fieldGradient,
                borderRadius: shape,
                border: Border.all(color: style.hasFieldGradient ? style.rim : c.border),
              ),
              foregroundDecoration: style.hasFieldGradient && style.gloss
                  ? BoxDecoration(borderRadius: shape, gradient: style.glossGradient)
                  : null,
              child: Row(
                children: [
                  if (leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(color: active ? c.textSecondary : c.textTertiary, size: 19),
                      child: leading!,
                    ),
                    const SizedBox(width: 11),
                  ],
                  Expanded(
                    child: Semantics(
                      label: label,
                      value: valueLabel,
                      button: true,
                      enabled: active,
                      onTap: active ? onTap : null,
                      excludeSemantics: true,
                      child: Text(
                        valueLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SundialType.body(
                          14,
                          weight: FontWeight.w700,
                          color: active ? c.text : c.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  SundialFieldClearSlot(visible: canClear, onPressed: onClear, tooltip: clearTooltip),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: c.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the shared option sheet for a [SundialSelectField].
///
/// [searchHint] turns on filtering; it matches labels and subtitles
/// case-insensitively. [emptyText] is shown when nothing matches.
Future<T?> showSundialSelectSheet<T>({
  required BuildContext context,
  required String title,
  String? searchHint,
  required T? selected,
  required List<SundialSelectOption<T>> options,
  String? emptyText,
}) {
  return showAppSheet<T>(
    context: context,
    builder: (_) => _SundialSelectSheet<T>(
      title: title,
      searchHint: searchHint,
      selected: selected,
      options: options,
      emptyText: emptyText,
    ),
  );
}

class _SundialSelectSheet<T> extends StatefulWidget {
  const _SundialSelectSheet({
    required this.title,
    required this.searchHint,
    required this.selected,
    required this.options,
    required this.emptyText,
  });

  final String title;
  final String? searchHint;
  final T? selected;
  final List<SundialSelectOption<T>> options;
  final String? emptyText;

  @override
  State<_SundialSelectSheet<T>> createState() => _SundialSelectSheetState<T>();
}

class _SundialSelectSheetState<T> extends State<_SundialSelectSheet<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(SundialSelectOption<T> option) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (option.label.toLowerCase().contains(query)) return true;
    return option.subtitle?.toLowerCase().contains(query) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final searchHint = widget.searchHint;
    final visible = widget.options.where(_matches).toList(growable: false);

    final rows = <Widget>[];
    if (visible.isEmpty) {
      if (widget.emptyText != null) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              widget.emptyText!,
              textAlign: TextAlign.center,
              style: SundialType.body(13, color: c.textTertiary),
            ),
          ),
        );
      }
    } else {
      for (final option in visible) {
        rows.add(_SundialSelectOptionRow<T>(option: option, selected: option.value == widget.selected));
      }
    }

    return AppSheet(
      key: const ValueKey<String>('sundial-select-sheet'),
      title: widget.title,
      children: [
        if (searchHint != null) ...[
          SundialSearchField(
            controller: _controller,
            hint: searchHint,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
        ],
        ...rows,
      ],
    );
  }
}

class _SundialSelectOptionRow<T> extends StatelessWidget {
  const _SundialSelectOptionRow({required this.option, required this.selected});

  final SundialSelectOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: option.enabled ? () => Navigator.of(context).pop(option.value) : null,
      semanticLabel: option.label,
      semanticButton: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(SundialRadii.md),
        ),
        child: Row(
          children: [
            if (option.leading != null) ...[
              SizedBox(width: 28, child: Center(child: option.leading!)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: SundialType.body(
                      14,
                      weight: FontWeight.w700,
                      color: option.enabled ? (selected ? c.accent : c.text) : c.textTertiary,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      option.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(11.5, color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (selected) ...[const SizedBox(width: 8), Icon(Icons.check_rounded, size: 19, color: c.accent)],
          ],
        ),
      ),
    );
  }
}
