import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Aero 2.0 design tokens.
///
/// This file is the approved-token candidate from `docs/aero-2.md`. It is not
/// wired into the app theme yet: the Aero direction is a stop gate, so no
/// screen uses these values until the concept review signs off. Keeping the
/// palette here means the rollout can consume tokens instead of raw colours.
class AeroTokens {
  const AeroTokens({
    required this.skyTop,
    required this.skyBottom,
    required this.pearl,
    required this.pearlAlt,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.accentFill,
    required this.onAccentFill,
    required this.accentSoft,
    required this.leaf,
    required this.sun,
    required this.coral,
    required this.glass,
    required this.glassEdge,
    required this.highlight,
    required this.shadow,
  });

  final Color skyTop;
  final Color skyBottom;

  /// Main content surface. Mostly opaque so body copy stays readable.
  final Color pearl;
  final Color pearlAlt;

  final Color ink;
  final Color inkMuted;

  /// Accent for icons, rims and selected labels. Contrast-checked as text.
  final Color accent;

  /// Fill for primary buttons and filled selected states.
  final Color accentFill;
  final Color onAccentFill;
  final Color accentSoft;

  final Color leaf;
  final Color sun;
  final Color coral;

  /// Glass fill for navigation, sheets and overlays.
  final Color glass;
  final Color glassEdge;

  /// The single specular highlight. Never stack more than one.
  final Color highlight;
  final Color shadow;

  LinearGradient get sky =>
      LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [skyTop, skyBottom]);
}

abstract final class AeroColors {
  static const light = AeroTokens(
    skyTop: Color(0xFFDDF3FF),
    skyBottom: Color(0xFFA9D8F5),
    pearl: Color(0xFFF2FAFF),
    pearlAlt: Color(0xFFE2F4FF),
    ink: Color(0xFF102A43),
    inkMuted: Color(0xFF4C6780),
    // The decorative aqua is too light for text or a 3:1 rim on pearl; the deep
    // variant is the accessible one.
    accent: Color(0xFF0B6E8A),
    accentFill: Color(0xFF0B6E8A),
    onAccentFill: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD6F3FC),
    leaf: Color(0xFF2F7D4F),
    sun: Color(0xFF8A6100),
    coral: Color(0xFFB23A3A),
    glass: Color(0x9EFFFFFF),
    glassEdge: Color(0xCCFFFFFF),
    highlight: Color(0x8CFFFFFF),
    shadow: Color(0x1A102A43),
  );

  static const dark = AeroTokens(
    skyTop: Color(0xFF071A2B),
    skyBottom: Color(0xFF0B2740),
    pearl: Color(0xFF132B3E),
    pearlAlt: Color(0xFF17354B),
    ink: Color(0xFFEAF6FF),
    inkMuted: Color(0xFF9DB8CC),
    accent: Color(0xFF8CE7FF),
    accentFill: Color(0xFF8CE7FF),
    onAccentFill: Color(0xFF03212E),
    accentSoft: Color(0xFF0E3E52),
    leaf: Color(0xFF8FE3B0),
    sun: Color(0xFFFFD166),
    coral: Color(0xFFFFB4B4),
    glass: Color(0x940E283C),
    glassEdge: Color(0x4D78D2F0),
    highlight: Color(0x1FB4E6FF),
    shadow: Color(0x66000000),
  );

  /// WCAG 2.1 relative luminance.
  static double luminance(Color color) {
    double channel(double value) =>
        value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
  }

  /// WCAG contrast ratio between two opaque colours, from 1 to 21.
  static double contrast(Color foreground, Color background) {
    final a = luminance(foreground);
    final b = luminance(background);
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }
}
