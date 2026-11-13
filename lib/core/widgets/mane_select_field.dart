import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_sheet.dart';
import 'mane_search_field.dart';
import 'pressable.dart';

/// One row in a [ManeSelectField]'s option sheet.
@immutable
class ManeSelectOption<T> {
  const ManeSelectOption({
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
class ManeSelectField extends StatelessWidget {
  const ManeSelectField({
    super.key,
    required this.label,
    required this.valueLabel,
    this.leading,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final String valueLabel;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final active = enabled && onTap != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 7),
          child: Text(label, style: ManeType.label(11.5, color: c.textTertiary)),
        ),
        Semantics(
          enabled: active,
          child: Pressable(
            onTap: active ? onTap : null,
            semanticLabel: label,
            semanticButton: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 11, 11, 11),
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
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
                    child: Text(
                      valueLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ManeType.body(
                        14,
                        weight: FontWeight.w700,
                        color: active ? c.text : c.textTertiary,
                      ),
                    ),
                  ),
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

/// Opens the shared option sheet for a [ManeSelectField].
///
/// [searchHint] turns on filtering; it matches labels and subtitles
/// case-insensitively. [emptyText] is shown when nothing matches.
Future<T?> showManeSelectSheet<T>({
  required BuildContext context,
  required String title,
  String? searchHint,
  required T? selected,
  required List<ManeSelectOption<T>> options,
  String? emptyText,
}) {
  return showAppSheet<T>(
    context: context,
    builder: (_) => _ManeSelectSheet<T>(
      title: title,
      searchHint: searchHint,
      selected: selected,
      options: options,
      emptyText: emptyText,
    ),
  );
}

class _ManeSelectSheet<T> extends StatefulWidget {
  const _ManeSelectSheet({
    required this.title,
    required this.searchHint,
    required this.selected,
    required this.options,
    required this.emptyText,
  });

  final String title;
  final String? searchHint;
  final T? selected;
  final List<ManeSelectOption<T>> options;
  final String? emptyText;

  @override
  State<_ManeSelectSheet<T>> createState() => _ManeSelectSheetState<T>();
}

class _ManeSelectSheetState<T> extends State<_ManeSelectSheet<T>> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(ManeSelectOption<T> option) {
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
              style: ManeType.body(13, color: c.textTertiary),
            ),
          ),
        );
      }
    } else {
      for (final option in visible) {
        rows.add(_ManeSelectOptionRow<T>(option: option, selected: option.value == widget.selected));
      }
    }

    return AppSheet(
      key: const ValueKey<String>('mane-select-sheet'),
      title: widget.title,
      children: [
        if (searchHint != null) ...[
          ManeSearchField(
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

class _ManeSelectOptionRow<T> extends StatelessWidget {
  const _ManeSelectOptionRow({required this.option, required this.selected});

  final ManeSelectOption<T> option;
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
          borderRadius: BorderRadius.circular(14),
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
                    style: ManeType.body(
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
                      style: ManeType.body(11.5, color: c.textSecondary),
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
