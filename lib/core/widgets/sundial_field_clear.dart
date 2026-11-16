import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A compact clear action that belongs inside a field's frame.
///
/// Fields place this in their trailing slot rather than beside the field, so
/// clearing a value never changes the surrounding layout.
class SundialFieldClearButton extends StatelessWidget {
  const SundialFieldClearButton({super.key, required this.onPressed, this.tooltip});

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.close, size: 16),
      tooltip: tooltip,
      color: c.textTertiary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 26, height: 20),
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}

/// Animates a [SundialFieldClearButton] in and out of a field's trailing edge.
class SundialFieldClearSlot extends StatelessWidget {
  const SundialFieldClearSlot({super.key, required this.visible, this.onPressed, this.tooltip});

  final bool visible;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final show = visible && onPressed != null;
    return AnimatedSize(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: show
          ? SundialFieldClearButton(onPressed: onPressed!, tooltip: tooltip)
          : const SizedBox.shrink(),
    );
  }
}

/// An in-field clear action for a text input, controlled by [controller].
class SundialTextClear extends StatelessWidget {
  const SundialTextClear({
    super.key,
    required this.controller,
    this.tooltip,
    this.onCleared,
    this.padding = const EdgeInsets.only(right: 10),
  });

  final TextEditingController controller;
  final String? tooltip;
  final VoidCallback? onCleared;

  /// Inset used when the action is an [InputDecoration.suffixIcon]. Custom rows
  /// that already own their padding can pass [EdgeInsets.zero].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => Padding(
        padding: padding,
        child: SundialFieldClearSlot(
          visible: value.text.isNotEmpty,
          onPressed: () {
            controller.clear();
            onCleared?.call();
          },
          tooltip: tooltip,
        ),
      ),
    );
  }
}
