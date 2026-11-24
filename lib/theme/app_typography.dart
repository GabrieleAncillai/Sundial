import 'package:flutter/material.dart';

/// The bundled typefaces and Sundial's type scale.
///
/// Classic uses Nunito, the face GymMane uses for its small-app shell. Aero
/// uses Open Sans, the humanist Web 2.0 face closest to the Segoe/Frutiger
/// lineage that is available under the SIL Open Font License. Styles created
/// here leave `fontFamily` unset so they inherit the resolved theme family.
class SundialType {
  SundialType._();

  static const family = 'Nunito';
  static const aeroFamily = 'Open Sans';

  static TextStyle _style(
    double size, {
    FontWeight weight = FontWeight.w600,
    double height = 1.25,
    double? spacing,
    Color? color,
  }) => TextStyle(fontSize: size, fontWeight: weight, height: height, letterSpacing: spacing, color: color);

  static TextStyle display(double size, {FontWeight weight = FontWeight.w800, Color? color}) =>
      _style(size, weight: weight, height: 1.08, spacing: -0.6, color: color);

  static TextStyle headline(double size, {FontWeight weight = FontWeight.w800, Color? color}) =>
      _style(size, weight: weight, height: 1.15, spacing: -0.3, color: color);

  static TextStyle title(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      _style(size, weight: weight, height: 1.25, color: color);

  static TextStyle body(double size, {FontWeight weight = FontWeight.w500, Color? color}) =>
      _style(size, weight: weight, height: 1.4, color: color);

  static TextStyle label(double size, {FontWeight weight = FontWeight.w700, Color? color}) =>
      _style(size, weight: weight, height: 1.2, color: color);

  static TextStyle kicker({Color? color}) =>
      _style(10.5, weight: FontWeight.w800, height: 1.2, spacing: 1.4, color: color);

  static TextTheme textTheme(Color text, Color muted, {String? fontFamily}) {
    final theme = TextTheme(
      displayLarge: display(34, color: text),
      displayMedium: display(30, color: text),
      displaySmall: display(26, color: text),
      headlineLarge: headline(26, color: text),
      headlineMedium: headline(22, color: text),
      headlineSmall: headline(19, color: text),
      titleLarge: title(18, color: text),
      titleMedium: title(16, color: text),
      titleSmall: title(14, color: text),
      bodyLarge: body(15, color: text),
      bodyMedium: body(14, color: text),
      bodySmall: body(12.5, color: muted),
      labelLarge: label(13.5, color: text),
      labelMedium: label(12, color: muted),
      labelSmall: _style(10.5, weight: FontWeight.w800, spacing: 1.2, color: muted),
    );
    return fontFamily == null ? theme : theme.apply(fontFamily: fontFamily);
  }
}
