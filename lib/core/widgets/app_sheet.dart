import 'dart:math' as math;
import 'dart:ui' show ImageFilter, TileMode;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../theme/sundial_style.dart';

/// The width at which Sundial swaps a phone sheet for a floating desktop dialog.
/// Mirrors the shell breakpoint in `lib/app/app_shell.dart`.
const double appSheetCompactBreakpoint = 900;

const _compactKey = ValueKey<String>('app-sheet-compact');
const _wideKey = ValueKey<String>('app-sheet-wide');

/// Opens the shared modal surface.
///
/// Phones keep the reference bottom sheet (drag, safe area and keyboard
/// behaviour included). Wide layouts get a centred dialog with a blurred
/// backdrop and a fade/scale entrance.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
}) {
  if (MediaQuery.sizeOf(context).width < appSheetCompactBreakpoint) {
    return _showCompactSheet<T>(
      context: context,
      builder: builder,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      useSafeArea: useSafeArea,
    );
  }
  return _showWideDialog<T>(
    context: context,
    builder: builder,
    isDismissible: isDismissible,
    useSafeArea: useSafeArea,
  );
}

Future<T?> _showCompactSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool isScrollControlled,
  required bool isDismissible,
  required bool enableDrag,
  required bool useSafeArea,
}) {
  final c = context.mc;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    showDragHandle: false,
    backgroundColor: c.surface,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    shape: SundialShapes.sheetTop(radius: SundialRadii.xxl),
    builder: (sheetContext) => KeyedSubtree(
      key: _compactKey,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: builder(sheetContext),
      ),
    ),
  );
}

Future<T?> _showWideDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool isDismissible,
  required bool useSafeArea,
}) {
  final navigator = Navigator.of(context);
  final captured = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    _AppSheetDialogRoute<T>(
      builder: (dialogContext) => captured.wrap(builder(dialogContext)),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    ),
  );
}

/// A centred dialog route with a blurred, dimmed barrier. The route uses the
/// same controller/view model as the stock popup routes so [Navigator.pop]
/// results and dismissal semantics are unchanged.
class _AppSheetDialogRoute<T> extends PopupRoute<T> {
  _AppSheetDialogRoute({
    required this.builder,
    required String barrierLabel,
    required this.isDismissible,
    required this.useSafeArea,
    required this.reduceMotion,
  }) : _barrierLabel = barrierLabel;

  final WidgetBuilder builder;
  final String _barrierLabel;
  final bool isDismissible;
  final bool useSafeArea;
  final bool reduceMotion;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.38);

  @override
  bool get barrierDismissible => isDismissible;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => reduceMotion ? Duration.zero : const Duration(milliseconds: 160);

  @override
  Widget buildModalBarrier() {
    void dismiss() => navigator?.maybePop();

    Widget barrier = ColoredBox(color: barrierColor!, child: const SizedBox.expand());
    if (!reduceMotion) {
      barrier = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7, tileMode: TileMode.clamp),
        child: barrier,
      );
    }
    barrier = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDismissible ? dismiss : null,
      child: barrier,
    );
    barrier = FadeTransition(opacity: animation ?? const AlwaysStoppedAnimation<double>(1), child: barrier);
    if (isDismissible) {
      barrier = Semantics(button: true, label: barrierLabel, onTap: dismiss, child: barrier);
    }
    return BlockSemantics(child: barrier);
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final c = context.mc;
    final media = MediaQuery.of(context);
    final insets = media.viewInsets;
    final maxWidth = math.max(0.0, math.min(660.0, media.size.width - 48));
    final maxHeight = math.max(0.0, math.min(780.0, media.size.height - insets.bottom - 48));
    final shape = SundialShapes.rounded(radius: SundialRadii.xl);

    Widget panel = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: c.surface,
          clipBehavior: Clip.antiAlias,
          shape: shape.copyWith(side: BorderSide(color: c.border)),
          child: builder(context),
        ),
      ),
    );
    panel = Container(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [BoxShadow(color: c.shadow, blurRadius: 42, offset: const Offset(0, 18), spreadRadius: -10)],
      ),
      child: panel,
    );

    Widget content = Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + insets.bottom),
      child: Center(
        child: KeyedSubtree(key: _wideKey, child: panel),
      ),
    );
    if (useSafeArea) content = SafeArea(child: content);
    return content;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(curved), child: child),
    );
  }
}

class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.bottom = 24,
    this.top = 10,
    this.scroll = true,
    this.maxHeight = 0.9,
  });

  final List<Widget> children;
  final String? title;
  final String? subtitle;
  final double bottom;
  final double top;
  final bool scroll;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final style = context.style;
    final media = MediaQuery.of(context);
    final wide = media.size.width >= appSheetCompactBreakpoint;
    final aero = style.hasSurfaceGradient;
    final available = math.max(0.0, media.size.height - media.viewInsets.bottom);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!wide) const SheetHandle(),
        if (title != null) ...[
          if (!wide) SizedBox(height: top),
          Text(
            title!,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: SundialType.headline(wide ? 21 : 19, color: c.text),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              textAlign: wide ? TextAlign.start : TextAlign.center,
              style: SundialType.body(13, color: c.textSecondary),
            ),
          ],
        ],
        SizedBox(height: wide ? 18 : (title == null ? top : 16)),
        ...children,
      ],
    );
    return Container(
      constraints: BoxConstraints(maxHeight: available * maxHeight),
      padding: EdgeInsets.fromLTRB(
        wide ? 26 : 20,
        wide ? 26 : 10,
        wide ? 26 : 20,
        (wide ? 26 : bottom) + media.padding.bottom,
      ),
      decoration: ShapeDecoration(
        shape: wide
            ? SundialShapes.rounded(
                radius: SundialRadii.xl,
                side: BorderSide(color: aero ? style.rim : c.border),
              )
            : SundialShapes.sheetTop(
                radius: SundialRadii.xxl,
                side: BorderSide(color: aero ? style.rim : Colors.transparent),
              ),
        color: aero ? null : c.surface,
        gradient: aero ? style.surfaceGradient : null,
        shadows: aero ? style.chromeShadows : null,
      ),
      foregroundDecoration: aero && style.gloss
          ? ShapeDecoration(
              shape: (wide
                  ? SundialShapes.rounded(radius: SundialRadii.xl)
                  : SundialShapes.sheetTop(radius: SundialRadii.xxl)),
              gradient: style.glossGradient,
            )
          : null,
      child: scroll ? SingleChildScrollView(child: content) : content,
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key, this.margin = const EdgeInsets.only(bottom: 2)});

  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: margin,
        decoration: BoxDecoration(
          color: c.borderStrong,
          borderRadius: BorderRadius.circular(SundialRadii.marker),
        ),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: SundialType.headline(20, color: c.text)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: SundialType.body(13, color: c.textSecondary)),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class SheetAction extends StatelessWidget {
  const SheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final color = accent ?? c.accent;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(SundialRadii.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: SundialType.body(14, color: c.text)),
              ),
              if (trailing != null) Icon(trailing, size: 18, color: c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
