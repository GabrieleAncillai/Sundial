import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/theme/app_colors.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial/theme/sundial_style.dart';

void main() {
  test('classic and aero resolve distinct materials', () {
    final classic = SundialStyle.resolve(SundialVisualStyle.classic, Brightness.light);
    final aero = SundialStyle.resolve(SundialVisualStyle.aero, Brightness.light);

    expect(classic.bodyFontFamily, 'Nunito');
    expect(aero.bodyFontFamily, 'Open Sans');
    expect(classic.surfaceGradient, isNull);
    expect(aero.surfaceGradient, isNotNull);
    expect(aero.skyGradient, isNotNull);
    expect(aero.environment, SundialEnvironment.aero);
    expect(aero.colors.surface, SundialColors.aeroLight.surface);
    expect(classic.colors.surface, SundialColors.light.surface);
  });

  test('aero dark uses the dark palette and keeps its glass recipes', () {
    final aero = SundialStyle.resolve(SundialVisualStyle.aero, Brightness.dark);

    expect(aero.brightness, Brightness.dark);
    expect(aero.colors.text, SundialColors.aeroDark.text);
    expect(aero.colors.accent, SundialColors.aeroDark.accent);
    expect(aero.gloss, isTrue);
    expect(aero.blurChrome, isTrue);
  });

  test('performance mode removes gloss, blur and card shadows', () {
    final aero = SundialStyle.resolve(SundialVisualStyle.aero, Brightness.light, performanceMode: true);

    expect(aero.gloss, isFalse);
    expect(aero.blurChrome, isFalse);
    expect(aero.cardShadows, isEmpty);
    expect(aero.surfaceGradient, isNotNull);
  });

  test('the theme carries the style extension and family', () {
    final theme = SundialTheme.forStyle(SundialVisualStyle.aero, Brightness.light);
    final style = theme.extension<SundialStyleTheme>()?.style;

    expect(style?.isAero, isTrue);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Open Sans');
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
  });

  test('date pickers keep the selected year and today legible', () {
    for (final visualStyle in SundialVisualStyle.values) {
      for (final brightness in Brightness.values) {
        final theme = SundialTheme.forStyle(visualStyle, brightness);
        final picker = theme.datePickerTheme;
        final colors = theme.extension<SundialStyleTheme>()!.style.colors;
        const selected = <WidgetState>{WidgetState.selected};
        const unselected = <WidgetState>{};

        expect(picker.dayBackgroundColor?.resolve(selected), colors.accent);
        expect(picker.dayForegroundColor?.resolve(selected), colors.onAccent);
        // The year picker paints the current year with todayForegroundColor
        // even when it is the selected pill, so it must yield onAccent then.
        expect(picker.todayForegroundColor?.resolve(selected), colors.onAccent);
        expect(picker.todayForegroundColor?.resolve(unselected), colors.accent);
      }
    }
  });
}
