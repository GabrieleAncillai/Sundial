import 'package:flutter/material.dart';

/// The geometry and colours of one shift after overlap slicing.
class ShiftLanePaintBlock {
  const ShiftLanePaintBlock({
    required this.rects,
    required this.fillColor,
    required this.stripeColor,
    required this.overlaps,
  });

  final List<Rect> rects;
  final Color fillColor;
  final Color stripeColor;
  final bool overlaps;
}

/// Paints shift segments as one continuous shape.
///
/// The fill and the job-colour stripe are drawn per segment, with rounded
/// corners only on the first and last slice. Overlapping shifts get a single
/// outline around the union of their slices, so a width change at an overlap
/// boundary reads as a step instead of a stack of separate cards.
class ShiftLanePainter extends CustomPainter {
  ShiftLanePainter({
    required this.blocks,
    required this.warningColor,
    required this.cornerRadius,
    required this.stripeWidth,
  });

  final List<ShiftLanePaintBlock> blocks;
  final Color warningColor;
  final double cornerRadius;
  final double stripeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final stripe = Paint();
    for (final block in blocks) {
      fill.color = block.fillColor;
      stripe.color = block.stripeColor;
      for (var index = 0; index < block.rects.length; index++) {
        final rect = block.rects[index];
        if (rect.width <= 0 || rect.height <= 0) continue;
        final segment = _segment(block, index);
        canvas.drawRRect(segment, fill);
        canvas.save();
        canvas.clipRRect(segment);
        canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, stripeWidth, rect.height), stripe);
        canvas.restore();
      }
    }

    if (warningColor.a == 0) return;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = warningColor;
    for (final block in blocks) {
      if (!block.overlaps) continue;
      Path? path;
      for (var index = 0; index < block.rects.length; index++) {
        final rect = block.rects[index];
        if (rect.width <= 1 || rect.height <= 1) continue;
        final segment = Path()..addRRect(_segment(block, index).deflate(0.5));
        path = path == null ? segment : Path.combine(PathOperation.union, path, segment);
      }
      if (path != null) canvas.drawPath(path, outline);
    }
  }

  RRect _segment(ShiftLanePaintBlock block, int index) {
    final rect = block.rects[index];
    final radius = Radius.circular(cornerRadius);
    return RRect.fromRectAndCorners(
      rect,
      topLeft: index == 0 ? radius : Radius.zero,
      topRight: index == 0 ? radius : Radius.zero,
      bottomLeft: index == block.rects.length - 1 ? radius : Radius.zero,
      bottomRight: index == block.rects.length - 1 ? radius : Radius.zero,
    );
  }

  @override
  bool shouldRepaint(covariant ShiftLanePainter oldDelegate) =>
      oldDelegate.blocks != blocks ||
      oldDelegate.warningColor != warningColor ||
      oldDelegate.cornerRadius != cornerRadius ||
      oldDelegate.stripeWidth != stripeWidth;
}
