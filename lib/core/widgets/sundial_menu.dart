import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';

/// One action in a [SundialMenuButton].
///
/// [dividerBefore] starts a new section; the divider is skipped when the
/// action is the first visible one, so optional actions can be omitted without
/// leaving a stray line.
@immutable
class SundialMenuAction<T> {
  const SundialMenuAction({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
    this.enabled = true,
    this.selected = false,
    this.dividerBefore = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool destructive;
  final bool enabled;
  final bool selected;
  final bool dividerBefore;
}

/// The shared overflow and context menu.
///
/// The stock Material popup is kept for focus, keyboard and route semantics;
/// this widget supplies the Sundial recipe: a tinted icon tile per row, grouped
/// sections, a destructive treatment and an optional target header.
class SundialMenuButton<T> extends StatelessWidget {
  const SundialMenuButton({
    super.key,
    required this.actions,
    required this.onSelected,
    this.tooltip,
    this.headerTitle,
    this.headerCaption,
    this.icon = Icons.more_horiz,
    this.iconColor,
    this.iconSize = 22,
    this.offset = const Offset(0, 4),
    this.position = PopupMenuPosition.under,
    this.enabled = true,
    this.onCanceled,
    this.constraints = const BoxConstraints(minWidth: 216, maxWidth: 336),
  });

  final List<SundialMenuAction<T>> actions;
  final ValueChanged<T> onSelected;
  final String? tooltip;
  final String? headerTitle;
  final String? headerCaption;
  final IconData icon;
  final Color? iconColor;
  final double iconSize;
  final Offset offset;
  final PopupMenuPosition position;
  final bool enabled;
  final VoidCallback? onCanceled;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return PopupMenuButton<T>(
      tooltip: tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
      icon: Icon(icon, size: iconSize, color: iconColor ?? c.textTertiary),
      iconSize: iconSize,
      position: position,
      offset: offset,
      enabled: enabled,
      constraints: constraints,
      elevation: 12,
      shadowColor: c.shadow,
      onSelected: onSelected,
      onCanceled: onCanceled,
      itemBuilder: _buildEntries,
    );
  }

  List<PopupMenuEntry<T>> _buildEntries(BuildContext context) {
    final c = context.mc;
    final entries = <PopupMenuEntry<T>>[];
    if (headerTitle != null) {
      entries.add(_SundialMenuHeader<T>(title: headerTitle!, caption: headerCaption));
    }
    var first = true;
    for (final action in actions) {
      if (!first && action.dividerBefore) {
        entries.add(PopupMenuDivider(height: 9, thickness: 1, indent: 12, endIndent: 12, color: c.border));
      }
      entries.add(
        PopupMenuItem<T>(
          value: action.value,
          enabled: action.enabled,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: _SundialMenuActionRow<T>(action: action),
        ),
      );
      first = false;
    }
    return entries;
  }
}

class _SundialMenuActionRow<T> extends StatelessWidget {
  const _SundialMenuActionRow({required this.action});

  final SundialMenuAction<T> action;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final color = !action.enabled
        ? c.textTertiary
        : action.destructive
        ? c.danger
        : c.text;
    final iconColor = !action.enabled
        ? c.textTertiary
        : action.destructive
        ? c.danger
        : c.accent;
    final tileColor = !action.enabled
        ? c.surfaceAlt
        : action.destructive
        ? c.dangerSoft
        : c.accentSoft;
    return Row(
      children: [
        if (action.icon != null) ...[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(SundialRadii.xs)),
            child: Icon(action.icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            action.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SundialType.body(
              13.5,
              weight: action.selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (action.selected) ...[
          const SizedBox(width: 10),
          Icon(Icons.check_rounded, size: 18, color: c.accent),
        ],
      ],
    );
  }
}

/// A non-interactive context line at the top of a menu.
class _SundialMenuHeader<T> extends PopupMenuEntry<T> {
  const _SundialMenuHeader({required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  double get height => caption == null ? 46 : 58;

  @override
  bool represents(T? value) => false;

  @override
  State<_SundialMenuHeader<T>> createState() => _SundialMenuHeaderState<T>();
}

class _SundialMenuHeaderState<T> extends State<_SundialMenuHeader<T>> {
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Semantics(
      header: true,
      child: Container(
        constraints: BoxConstraints(minHeight: widget.height),
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SundialType.title(13.5, weight: FontWeight.w800, color: c.text),
            ),
            if (widget.caption != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SundialType.body(11.5, color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
