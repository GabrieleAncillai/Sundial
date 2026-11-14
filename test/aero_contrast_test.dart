import 'package:flutter_test/flutter_test.dart';
import 'package:mane/theme/aero_colors.dart';

void main() {
  void expectContrast(String name, double actual, double minimum) {
    // Printed so `docs/aero-2.md` can carry the measured table.
    // ignore: avoid_print
    print('$name: ${actual.toStringAsFixed(2)}:1 (min $minimum:1)');
    expect(actual, greaterThanOrEqualTo(minimum), reason: name);
  }

  test('Aero light tokens meet WCAG AA', () {
    const t = AeroColors.light;
    expectContrast('body ink / pearl', AeroColors.contrast(t.ink, t.pearl), 7);
    expectContrast('body ink / pearl alt', AeroColors.contrast(t.ink, t.pearlAlt), 7);
    expectContrast('muted ink / pearl', AeroColors.contrast(t.inkMuted, t.pearl), 4.5);
    expectContrast('muted ink / pearl alt', AeroColors.contrast(t.inkMuted, t.pearlAlt), 4.5);
    expectContrast('accent text / pearl', AeroColors.contrast(t.accent, t.pearl), 4.5);
    expectContrast('accent text / accent soft', AeroColors.contrast(t.accent, t.accentSoft), 4.5);
    expectContrast('button label / accent fill', AeroColors.contrast(t.onAccentFill, t.accentFill), 4.5);
    expectContrast('ink / accent soft', AeroColors.contrast(t.ink, t.accentSoft), 4.5);
    expectContrast('success / pearl', AeroColors.contrast(t.leaf, t.pearl), 4.5);
    expectContrast('warning / pearl', AeroColors.contrast(t.sun, t.pearl), 4.5);
    expectContrast('error / pearl', AeroColors.contrast(t.coral, t.pearl), 4.5);
    // The accent marks controls (rims, selected icons), so 3:1 is the floor.
    expectContrast('accent rim / pearl', AeroColors.contrast(t.accent, t.pearl), 3);
    expectContrast('accent rim / sky bottom', AeroColors.contrast(t.accent, t.skyBottom), 3);
    expectContrast('ink / sky bottom', AeroColors.contrast(t.ink, t.skyBottom), 4.5);
  });

  test('Aero dark tokens meet WCAG AA', () {
    const t = AeroColors.dark;
    expectContrast('body ink / pearl', AeroColors.contrast(t.ink, t.pearl), 7);
    expectContrast('body ink / pearl alt', AeroColors.contrast(t.ink, t.pearlAlt), 7);
    expectContrast('muted ink / pearl', AeroColors.contrast(t.inkMuted, t.pearl), 4.5);
    expectContrast('muted ink / pearl alt', AeroColors.contrast(t.inkMuted, t.pearlAlt), 4.5);
    expectContrast('accent text / pearl', AeroColors.contrast(t.accent, t.pearl), 4.5);
    expectContrast('accent text / accent soft', AeroColors.contrast(t.accent, t.accentSoft), 4.5);
    expectContrast('button label / accent fill', AeroColors.contrast(t.onAccentFill, t.accentFill), 4.5);
    expectContrast('ink / accent soft', AeroColors.contrast(t.ink, t.accentSoft), 4.5);
    expectContrast('success / pearl', AeroColors.contrast(t.leaf, t.pearl), 4.5);
    expectContrast('warning / pearl', AeroColors.contrast(t.sun, t.pearl), 4.5);
    expectContrast('error / pearl', AeroColors.contrast(t.coral, t.pearl), 4.5);
    expectContrast('accent rim / pearl', AeroColors.contrast(t.accent, t.pearl), 3);
    expectContrast('ink / sky bottom', AeroColors.contrast(t.ink, t.skyBottom), 4.5);
  });
}
