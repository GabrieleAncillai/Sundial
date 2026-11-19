import 'package:flutter/material.dart';

/// The rectangle and colours of one shift block.
class ShiftBlockPaint {
  const ShiftBlockPaint({required this.rect, required this.fillColor, required this.stripeColor});

  final Rect rect;
  final Color fillColor;
  final Color stripeColor;
}

/// Paints shift blocks back to front.
///
/// The fills are translucent, so a block that starts later blends over the one
/// beneath it for the minutes they share. A collision reads as a deeper tint
/// rather than a split column with an outline.
class ShiftBlockPainter extends CustomPainter {
  ShiftBlockPainter({required this.blocks, required this.cornerRadius, required this.stripeWidth});

  final List<ShiftBlockPaint> blocks;
  final double cornerRadius;
  final double stripeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final stripe = Paint();
    for (final block in blocks) {
      final rect = block.rect;
      if (rect.width <= 0 || rect.height <= 0) continue;
      fill.color = block.fillColor;
      stripe.color = block.stripeColor;
      final shape = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
      canvas.drawRRect(shape, fill);
      canvas.save();
      canvas.clipRRect(shape);
      canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, stripeWidth, rect.height), stripe);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ShiftBlockPainter oldDelegate) =>
      oldDelegate.blocks != blocks ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.stripeWidth != stripeWidth;
}
