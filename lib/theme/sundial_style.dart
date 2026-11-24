import 'package:flutter/material.dart';

import '../models/visual_style.dart';
import 'aero_colors.dart';
import 'app_colors.dart';

export '../models/visual_style.dart';

// SundialVisualStyle is defined in the model layer and re-exported here so a
// widget only needs the style import.

/// The decorative environment painted behind content.
enum SundialEnvironment { calm, aero }

/// How glyphs are rendered. Outline is the reference shell; glossy is Aero.
enum SundialIconTreatment { outline, glossy }

/// The brand mark shape. A future style can add its own mark without making
/// the shell test for a style name.
enum SundialBrandMark { tile, orb }

/// Resolved, immutable style data for one theme instance.
///
/// Widgets read this through `context.style`. The fields are intentionally
/// generic (gradients, rim, glow, shadows, fonts) so a future style can supply
/// its own values instead of forcing every component to know its name.
@immutable
class SundialStyle {
  const SundialStyle({
    required this.visualStyle,
    required this.brightness,
    required this.colors,
    required this.bodyFontFamily,
    required this.displayFontFamily,
    required this.environment,
    required this.iconTreatment,
    required this.brandMark,
    required this.gloss,
    required this.glassChrome,
    required this.blurChrome,
    required this.performanceMode,
    required this.highlight,
    required this.rim,
    required this.glow,
    required this.surfaceGradient,
    required this.chromeGradient,
    required this.selectedGradient,
    required this.controlGradient,
    required this.fieldGradient,
    required this.skyGradient,
    required this.glossGradient,
    required this.skyTop,
    required this.skyBottom,
    required this.horizonGlow,
    required this.cardShadows,
    required this.chromeShadows,
  });

  final SundialVisualStyle visualStyle;
  final Brightness brightness;
  final SundialColors colors;

  final String bodyFontFamily;
  final String displayFontFamily;

  final SundialEnvironment environment;
  final SundialIconTreatment iconTreatment;
  final SundialBrandMark brandMark;

  /// One specular highlight per surface. Null means no gloss at all.
  final bool gloss;
  final bool glassChrome;
  final bool blurChrome;
  final bool performanceMode;

  final Color highlight;
  final Color rim;
  final Color glow;

  final Gradient? surfaceGradient;
  final Gradient? chromeGradient;
  final Gradient? selectedGradient;
  final Gradient? controlGradient;
  final Gradient? fieldGradient;
  final Gradient? skyGradient;
  final Gradient? glossGradient;

  final Color skyTop;
  final Color skyBottom;
  final Color horizonGlow;

  final List<BoxShadow> cardShadows;
  final List<BoxShadow> chromeShadows;

  bool get isAero => visualStyle == SundialVisualStyle.aero;

  // Feature getters are what components branch on. They keep a future style
  // data-driven instead of scattering style-name checks through the widget
  // tree.
  bool get hasSurfaceGradient => surfaceGradient != null;
  bool get hasChromeGradient => chromeGradient != null;
  bool get hasSelectedGradient => selectedGradient != null;
  bool get hasControlGradient => controlGradient != null;
  bool get hasFieldGradient => fieldGradient != null;
  bool get hasSkyGradient => skyGradient != null;

  static SundialStyle resolve(
    SundialVisualStyle visualStyle,
    Brightness brightness, {
    bool performanceMode = false,
  }) => switch (visualStyle) {
    SundialVisualStyle.classic => classic(brightness, performanceMode: performanceMode),
    SundialVisualStyle.aero => aero(brightness, performanceMode: performanceMode),
  };

  static SundialStyle classic(Brightness brightness, {bool performanceMode = false}) {
    final colors = brightness == Brightness.dark ? SundialColors.dark : SundialColors.light;
    return SundialStyle(
      visualStyle: SundialVisualStyle.classic,
      brightness: brightness,
      colors: colors,
      bodyFontFamily: 'Nunito',
      displayFontFamily: 'Nunito',
      environment: SundialEnvironment.calm,
      iconTreatment: SundialIconTreatment.outline,
      brandMark: SundialBrandMark.tile,
      gloss: false,
      glassChrome: false,
      blurChrome: false,
      performanceMode: performanceMode,
      highlight: Colors.transparent,
      rim: colors.border,
      glow: Colors.transparent,
      surfaceGradient: null,
      chromeGradient: null,
      selectedGradient: null,
      controlGradient: null,
      fieldGradient: null,
      skyGradient: null,
      glossGradient: null,
      skyTop: colors.pageBg,
      skyBottom: colors.pageBg,
      horizonGlow: Colors.transparent,
      cardShadows: const [],
      chromeShadows: [
        BoxShadow(color: colors.shadow, blurRadius: 24, offset: const Offset(0, 10)),
        BoxShadow(color: colors.shadow.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1)),
      ],
    );
  }

  static SundialStyle aero(Brightness brightness, {bool performanceMode = false}) {
    final dark = brightness == Brightness.dark;
    final tokens = dark ? AeroColors.dark : AeroColors.light;
    final colors = dark ? SundialColors.aeroDark : SundialColors.aeroLight;
    final accentTop = Color.lerp(tokens.accentFill, Colors.white, dark ? 0.24 : 0.18)!;
    final gloss = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [tokens.highlight, tokens.highlight.withValues(alpha: 0)],
      stops: const [0, 0.55],
    );

    return SundialStyle(
      visualStyle: SundialVisualStyle.aero,
      brightness: brightness,
      colors: colors,
      bodyFontFamily: 'Open Sans',
      displayFontFamily: 'Open Sans',
      environment: SundialEnvironment.aero,
      iconTreatment: SundialIconTreatment.glossy,
      brandMark: SundialBrandMark.orb,
      gloss: !performanceMode,
      glassChrome: true,
      blurChrome: !performanceMode,
      performanceMode: performanceMode,
      highlight: tokens.highlight,
      rim: tokens.glassEdge,
      glow: tokens.accent.withValues(alpha: dark ? 0.26 : 0.16),
      surfaceGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tokens.pearl, tokens.pearlAlt],
      ),
      chromeGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(tokens.pearl, Colors.white, dark ? 0.06 : 0.32)!, tokens.pearlAlt],
      ),
      selectedGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(tokens.accentSoft, Colors.white, dark ? 0.10 : 0.20)!,
          Color.lerp(tokens.accentSoft, tokens.accent, dark ? 0.10 : 0.18)!,
        ],
      ),
      controlGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accentTop, tokens.accentFill],
      ),
      fieldGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tokens.pearl, tokens.pearlAlt],
      ),
      skyGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tokens.skyTop, Color.lerp(tokens.skyTop, tokens.skyBottom, 0.55)!, tokens.skyBottom],
        stops: const [0, 0.55, 1],
      ),
      glossGradient: gloss,
      skyTop: tokens.skyTop,
      skyBottom: tokens.skyBottom,
      horizonGlow: tokens.accent.withValues(alpha: dark ? 0.20 : 0.13),
      cardShadows: performanceMode
          ? const []
          : [
              BoxShadow(color: tokens.shadow, blurRadius: 28, offset: const Offset(0, 10)),
              BoxShadow(color: tokens.accent.withValues(alpha: dark ? 0.18 : 0.10), blurRadius: 20),
            ],
      chromeShadows: performanceMode
          ? [BoxShadow(color: tokens.shadow, blurRadius: 12, offset: const Offset(0, 4))]
          : [
              BoxShadow(color: tokens.shadow, blurRadius: 30, offset: const Offset(0, 12)),
              BoxShadow(color: tokens.accent.withValues(alpha: dark ? 0.24 : 0.16), blurRadius: 24),
            ],
    );
  }

  /// Replaces the palette while keeping the style's recipes. Used for the
  /// classic accent presets; Aero owns its accessible accent.
  SundialStyle withColors(SundialColors colors) => SundialStyle(
    visualStyle: visualStyle,
    brightness: brightness,
    colors: colors,
    bodyFontFamily: bodyFontFamily,
    displayFontFamily: displayFontFamily,
    environment: environment,
    iconTreatment: iconTreatment,
    brandMark: brandMark,
    gloss: gloss,
    glassChrome: glassChrome,
    blurChrome: blurChrome,
    performanceMode: performanceMode,
    highlight: highlight,
    rim: hasChromeGradient ? rim : colors.border,
    glow: glow,
    surfaceGradient: surfaceGradient,
    chromeGradient: chromeGradient,
    selectedGradient: selectedGradient,
    controlGradient: controlGradient,
    fieldGradient: fieldGradient,
    skyGradient: skyGradient,
    glossGradient: glossGradient,
    skyTop: skyTop,
    skyBottom: skyBottom,
    horizonGlow: horizonGlow,
    cardShadows: cardShadows,
    chromeShadows: chromeShadows,
  );
}

/// Convenience extension for the app's resolved style.
extension SundialStyleContext on BuildContext {
  SundialStyle get style =>
      Theme.of(this).extension<SundialStyleTheme>()?.style ?? SundialStyle.classic(Theme.of(this).brightness);

  bool get reducedEffects => style.performanceMode || (MediaQuery.maybeOf(this)?.disableAnimations ?? false);
}

/// Small ThemeExtension wrapper so style changes travel with `ThemeData`.
@immutable
class SundialStyleTheme extends ThemeExtension<SundialStyleTheme> {
  const SundialStyleTheme(this.style);

  final SundialStyle style;

  @override
  SundialStyleTheme copyWith({SundialStyle? style}) => SundialStyleTheme(style ?? this.style);

  @override
  SundialStyleTheme lerp(SundialStyleTheme? other, double t) {
    // Theme changes are instant in Sundial; interpolating every recipe would
    // add cost without a visible transition.
    if (other == null || t < 0.5) return this;
    return other;
  }
}
