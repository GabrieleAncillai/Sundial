import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';

/// Transparent room around the Aero surface so its rim and glow stay visible
/// when the menu is clamped against a screen edge.
const double _menuEdgeInset = 20;

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
/// Classic keeps the stock [PopupMenuButton] route. Aero and any future style
/// with a surface gradient use a [MenuAnchor] panel instead, because the stock
/// popup Material only accepts a flat colour and cannot carry the gloss and
/// gradient that make Aero read as Aero.
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
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final style = context.style;
    if (style.hasSurfaceGradient) {
      return _AeroMenuButton<T>(
        actions: actions,
        onSelected: onSelected,
        tooltip: tooltip,
        headerTitle: headerTitle,
        headerCaption: headerCaption,
        icon: icon,
        iconColor: iconColor,
        iconSize: iconSize,
        offset: offset,
        position: position,
        enabled: enabled,
        constraints: constraints,
      );
    }
    return _buildClassic(context);
  }

  Widget _buildClassic(BuildContext context) {
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
      itemBuilder: _buildClassicEntries,
    );
  }

  List<PopupMenuEntry<T>> _buildClassicEntries(BuildContext context) {
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

class _AeroMenuButton<T> extends StatefulWidget {
  const _AeroMenuButton({
    required this.actions,
    required this.onSelected,
    required this.tooltip,
    required this.headerTitle,
    required this.headerCaption,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.offset,
    required this.position,
    required this.enabled,
    required this.constraints,
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
  final BoxConstraints constraints;

  @override
  State<_AeroMenuButton<T>> createState() => _AeroMenuButtonState<T>();
}

class _AeroMenuButtonState<T> extends State<_AeroMenuButton<T>> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    // Keep the content-sized feel of the stock popup: a short menu stays near
    // the 216 dp floor, while a long label can grow to 288 dp. The invisible
    // edge inset keeps the rounded rim and glow inside the screen when
    // MenuAnchor clamps the panel against the right edge.
    final available = math.max(0.0, MediaQuery.sizeOf(context).width - 32);
    final maxVisibleWidth = math.min(widget.constraints.maxWidth, 288.0);
    final maxPanelWidth = math.min(maxVisibleWidth + _menuEdgeInset * 2, available);
    final minPanelWidth = math.min(216.0 + _menuEdgeInset * 2, maxPanelWidth);
    final shape = SundialShapes.rounded(radius: SundialRadii.md);
    return MenuAnchor(
      childFocusNode: _focusNode,
      alignmentOffset: widget.offset,
      crossAxisUnconstrained: false,
      clipBehavior: Clip.none,
      consumeOutsideTap: true,
      style: MenuStyle(
        alignment: widget.position == PopupMenuPosition.under
            ? AlignmentDirectional.bottomStart
            : AlignmentDirectional.topStart,
        backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: WidgetStatePropertyAll(shape),
      ),
      menuChildren: [
        _AeroMenuPanel<T>(
          minWidth: minPanelWidth,
          maxWidth: maxPanelWidth,
          shape: shape,
          headerTitle: widget.headerTitle,
          headerCaption: widget.headerCaption,
          actions: widget.actions,
          onSelected: widget.onSelected,
        ),
      ],
      builder: (context, controller, child) {
        // PopupMenu gets back-button handling from its modal route. Keep the
        // same behaviour here so Android back or an iOS edge swipe closes the
        // menu instead of leaving the screen underneath.
        final isOpen = MenuController.maybeIsOpenOf(context) ?? false;
        return PopScope(
          canPop: !isOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && controller.isOpen) controller.close();
          },
          child: IconButton(
            tooltip: widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
            focusNode: _focusNode,
            icon: Icon(widget.icon, size: widget.iconSize, color: widget.iconColor ?? c.textTertiary),
            onPressed: widget.enabled
                ? () => controller.isOpen ? controller.close() : controller.open()
                : null,
          ),
        );
      },
    );
  }
}

/// The pearl, gloss and cyan-rim surface that the stock popup cannot paint.
class _AeroMenuPanel<T> extends StatelessWidget {
  const _AeroMenuPanel({
    required this.minWidth,
    required this.maxWidth,
    required this.shape,
    required this.headerTitle,
    required this.headerCaption,
    required this.actions,
    required this.onSelected,
  });

  final double minWidth;
  final double maxWidth;
  final OutlinedBorder shape;
  final String? headerTitle;
  final String? headerCaption;
  final List<SundialMenuAction<T>> actions;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    return ConstrainedBox(
      key: const ValueKey('sundial-aero-menu-frame'),
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _menuEdgeInset),
        child: DecoratedBox(
          key: const ValueKey('sundial-aero-menu-surface'),
          decoration: ShapeDecoration(
            shape: shape,
            gradient:
                style.chromeGradient ??
                style.surfaceGradient ??
                LinearGradient(colors: [c.surface, c.surfaceAlt]),
            shadows: style.chromeShadows,
          ),
          child: Container(
            key: const ValueKey('sundial-aero-menu-panel'),
            foregroundDecoration: ShapeDecoration(
              shape: shape.copyWith(side: BorderSide(color: c.accent.withValues(alpha: 0.45))),
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.of(context)),
              child: Stack(
                children: [
                  if (style.gloss && style.glossGradient != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          key: const ValueKey('sundial-aero-menu-gloss'),
                          decoration: BoxDecoration(gradient: style.glossGradient),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (headerTitle != null)
                          _SundialMenuHeaderContent(title: headerTitle!, caption: headerCaption),
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0 && actions[i].dividerBefore)
                            Divider(height: 9, thickness: 1, indent: 12, endIndent: 12, color: c.border),
                          _AeroMenuAction<T>(action: actions[i], onSelected: onSelected),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AeroMenuAction<T> extends StatelessWidget {
  const _AeroMenuAction({required this.action, required this.onSelected});

  final SundialMenuAction<T> action;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return MenuItemButton(
      onPressed: action.enabled ? () => onSelected(action.value) : null,
      clipBehavior: Clip.antiAlias,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        animationDuration: const Duration(milliseconds: 140),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return c.accentSoft.withValues(alpha: 0.55);
          }
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
            return c.accent.withValues(alpha: 0.10);
          }
          return null;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(SundialRadii.sm)),
        ),
      ),
      child: _SundialMenuActionRow<T>(action: action),
    );
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

/// A non-interactive context line at the top of a Classic popup.
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
    return Semantics(
      header: true,
      child: _SundialMenuHeaderContent(title: widget.title, caption: widget.caption),
    );
  }
}

class _SundialMenuHeaderContent extends StatelessWidget {
  const _SundialMenuHeaderContent({required this.title, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      constraints: BoxConstraints(minHeight: caption == null ? 46 : 58),
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
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SundialType.title(13.5, weight: FontWeight.w800, color: c.text),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SundialType.body(11.5, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
