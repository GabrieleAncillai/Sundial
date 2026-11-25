import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';
import '../sound/sound_service.dart';
import 'app_background.dart';
import 'pressable.dart';
import 'sundial_content_pane.dart';

/// A pushed page with the reference header: round back button, strong title,
/// optional subtitle and glass actions. It replaces stock AppBar scaffolds.
class SundialPage extends StatelessWidget {
  const SundialPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.padding = const EdgeInsets.fromLTRB(20, 4, 20, 28),
    this.floatingAction,
    this.bottomBar,
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final EdgeInsets padding;
  final Widget? floatingAction;
  final Widget? bottomBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: SafeArea(
          bottom: bottomBar == null,
          child: SundialContentPane(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: SundialPageHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    onBack:
                        onBack ??
                        () {
                          playUiSound(context, UiSound.back);
                          Navigator.of(context).maybePop();
                        },
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(padding: padding, child: child),
                      ),
                      if (floatingAction != null) Positioned(right: 20, bottom: 20, child: floatingAction!),
                    ],
                  ),
                ),
                if (bottomBar != null)
                  Container(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + MediaQuery.paddingOf(context).bottom),
                    decoration: BoxDecoration(
                      color: context.style.hasChromeGradient ? null : c.surface,
                      gradient: context.style.chromeGradient,
                      border: Border(
                        top: BorderSide(
                          color: context.style.hasChromeGradient ? context.style.rim : c.border,
                        ),
                      ),
                    ),
                    child: bottomBar,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SundialPageHeader extends StatelessWidget {
  const SundialPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    return Row(
      children: [
        if (onBack != null) ...[
          Pressable(
            onTap: onBack,
            semanticButton: true,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.hasChromeGradient ? null : c.surface,
                gradient: style.chromeGradient,
                border: Border.all(color: style.hasChromeGradient ? style.rim : c.border),
                boxShadow: style.hasChromeGradient ? style.chromeShadows : null,
              ),
              foregroundDecoration: style.hasChromeGradient && style.gloss
                  ? BoxDecoration(shape: BoxShape.circle, gradient: style.glossGradient)
                  : null,
              child: Icon(Icons.chevron_left, size: 22, color: c.text),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SundialType.headline(21, color: c.text),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SundialType.body(12, color: c.textSecondary),
                ),
              ],
            ],
          ),
        ),
        for (final action in actions) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

/// A round filled action used for "add" and primary page actions.
class SundialAddButton extends StatelessWidget {
  const SundialAddButton({
    super.key,
    required this.onTap,
    required this.tooltip,
    this.icon = Icons.add,
    this.size = 54,
  });

  final VoidCallback onTap;
  final String tooltip;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        semanticLabel: tooltip,
        semanticButton: true,
        scale: 0.92,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: style.hasControlGradient ? null : c.accent,
            gradient: style.controlGradient,
            shape: BoxShape.circle,
            border: style.hasControlGradient
                ? Border.all(color: style.highlight.withValues(alpha: 0.45))
                : null,
            boxShadow: style.hasControlGradient
                ? style.chromeShadows
                : [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          foregroundDecoration: style.hasControlGradient && style.gloss
              ? BoxDecoration(shape: BoxShape.circle, gradient: style.glossGradient)
              : null,
          child: Icon(icon, size: size * 0.48, color: c.onAccent),
        ),
      ),
    );
  }
}
