import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/widgets/app_background.dart';

void main() {
  test('the aero environment returns to its start pose at the loop seam', () {
    for (var layer = 0; layer < 3; layer++) {
      final start = math.sin(AeroMotion.wavePhase(0, layer));
      final end = math.sin(AeroMotion.wavePhase(1, layer));
      expect(end, closeTo(start, 1e-9), reason: 'wave layer $layer');
    }

    const size = Size(390, 844);
    for (final phase in const [0.0, 0.4, 1.2, 2.6, 3.9, 5.1]) {
      final start = AeroMotion.bubbleDrift(0, phase, size);
      final end = AeroMotion.bubbleDrift(1, phase, size);
      expect(end.dx, closeTo(start.dx, 1e-9), reason: 'bubble x, phase $phase');
      expect(end.dy, closeTo(start.dy, 1e-9), reason: 'bubble y, phase $phase');
    }
  });
}
