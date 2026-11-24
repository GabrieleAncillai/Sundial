import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/theme/aero_colors.dart';
import 'package:sundial/theme/app_colors.dart';

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

  test('shipped Aero light palette meets WCAG AA', () {
    const c = SundialColors.aeroLight;
    expectContrast('shipped body ink / pearl', AeroColors.contrast(c.text, c.surface), 7);
    expectContrast('shipped muted ink / pearl', AeroColors.contrast(c.textSecondary, c.surface), 4.5);
    expectContrast('shipped tertiary ink / pearl', AeroColors.contrast(c.textTertiary, c.surface), 4.5);
    expectContrast('shipped accent / pearl', AeroColors.contrast(c.accent, c.surface), 4.5);
    expectContrast('shipped on accent / accent', AeroColors.contrast(c.onAccent, c.accent), 4.5);
    expectContrast('shipped ink / accent soft', AeroColors.contrast(c.text, c.accentSoft), 4.5);
    expectContrast('shipped danger / pearl', AeroColors.contrast(c.danger, c.surface), 4.5);
    expectContrast('shipped warning / pearl', AeroColors.contrast(c.warning, c.surface), 4.5);
    expectContrast('shipped success / pearl', AeroColors.contrast(c.success, c.surface), 4.5);
  });

  test('shipped Aero dark palette meets WCAG AA', () {
    const c = SundialColors.aeroDark;
    expectContrast('shipped body ink / pearl', AeroColors.contrast(c.text, c.surface), 7);
    expectContrast('shipped muted ink / pearl', AeroColors.contrast(c.textSecondary, c.surface), 4.5);
    expectContrast('shipped tertiary ink / pearl', AeroColors.contrast(c.textTertiary, c.surface), 4.5);
    expectContrast('shipped accent / pearl', AeroColors.contrast(c.accent, c.surface), 4.5);
    expectContrast('shipped on accent / accent', AeroColors.contrast(c.onAccent, c.accent), 4.5);
    expectContrast('shipped ink / accent soft', AeroColors.contrast(c.text, c.accentSoft), 4.5);
    expectContrast('shipped danger / pearl', AeroColors.contrast(c.danger, c.surface), 4.5);
    expectContrast('shipped warning / pearl', AeroColors.contrast(c.warning, c.surface), 4.5);
    expectContrast('shipped success / pearl', AeroColors.contrast(c.success, c.surface), 4.5);
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
