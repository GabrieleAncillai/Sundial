import 'package:flutter/material.dart';

import '../layout/sundial_layout.dart';

/// Centres a page body in the shared reading column.
///
/// Wide windows keep the same calm gutters as the settings master-detail
/// layout instead of stretching cards and rows to the window edge. Canvas
/// screens such as the Plan grid opt out and stay full-bleed.
class SundialContentPane extends StatelessWidget {
  const SundialContentPane({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
