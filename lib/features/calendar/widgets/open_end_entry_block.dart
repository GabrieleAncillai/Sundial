import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// A calendar block for an entry that has a start time but no end time.
///
/// Closed entries are rectangles sized to their duration. An open-ended entry
/// has no duration to size against, so it keeps a fixed height and its bottom
/// edge is square and dashed: the plan continues below the block. The bottom
/// corners are intentionally not rounded, which is what makes the block read
/// as cut off rather than complete.
class OpenEndEntryBlock extends StatelessWidget {
  const OpenEndEntryBlock({
    super.key,
    required this.title,
    required this.color,
    this.timeLabel,
    this.height = defaultHeight,
    this.dense = false,
    this.outlined = false,
    this.shadow = false,
  });

  /// Tall enough for the title and start time without pretending to be a
  /// short, closed event.
  static const defaultHeight = 40.0;

  final String title;
  final Color color;
  final String? timeLabel;
  final double height;

  /// Week-grid typography and the left accent bar used by its closed blocks.
  final bool dense;

  /// Day-timeline typography and a full outline instead of the accent bar.
  final bool outlined;

  /// Stronger shadow for the drag feedback copy.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final radius = dense ? 8.0 : 10.0;
    return SizedBox(
      height: height,
      child: CustomPaint(
        foregroundPainter: _CutBottomPainter(color: color, inset: outlined ? 5 : 7),
        child: Container(
          padding: EdgeInsets.fromLTRB(dense ? 6 : 9, 4, dense ? 6 : 9, dense ? 5 : 6),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            border: outlined
                ? Border(
                    top: BorderSide(color: color.withValues(alpha: 0.45)),
                    left: BorderSide(color: color.withValues(alpha: 0.45)),
                    right: BorderSide(color: color.withValues(alpha: 0.45)),
                  )
                : Border(left: BorderSide(color: color, width: 3)),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withValues(alpha: shadow ? 0.5 : 0.35),
                blurRadius: shadow ? 12 : 4,
                offset: Offset(0, shadow ? 4 : 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SundialType.body(dense ? 10.5 : 11.5, weight: FontWeight.w700, color: c.text),
              ),
              if (timeLabel != null)
                Text(
                  timeLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SundialType.label(dense ? 9 : 9.5, color: c.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashes the bottom edge so the block reads as cut off rather than finished.
class _CutBottomPainter extends CustomPainter {
  const _CutBottomPainter({required this.color, required this.inset});

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 3.0;
    final y = size.height - 1;
    final end = size.width - inset;
    var x = inset;
    while (x < end) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + dash, end), y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _CutBottomPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.inset != inset;
}
