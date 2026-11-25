import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import 'app_radii.dart';
import 'app_typography.dart';
import 'sundial_style.dart';

class SundialTheme {
  SundialTheme._();

  static ThemeData get light => _build(SundialStyle.classic(Brightness.light));
  static ThemeData get dark => _build(SundialStyle.classic(Brightness.dark));

  static ThemeData forSettings(AppSettings settings, Brightness brightness) {
    // OLED paints black behind the content; the light Aero sky would become
    // unreadable there, so OLED always resolves to the dark style.
    final effective = settings.backgroundStyle == SundialBackgroundStyle.oled ? Brightness.dark : brightness;
    var style = SundialStyle.resolve(
      settings.visualStyle,
      effective,
      performanceMode: settings.performanceMode,
    );
    if (settings.visualStyle == SundialVisualStyle.classic) {
      style = style.withColors(style.colors.withAccent(_accentFor(settings.accentScheme, effective)));
    }
    return _build(style);
  }

  /// Builds a style directly. Used by tests and the screenshot harness.
  static ThemeData forStyle(
    SundialVisualStyle visualStyle,
    Brightness brightness, {
    bool performanceMode = false,
    SundialAccentScheme accentScheme = SundialAccentScheme.sage,
  }) {
    var style = SundialStyle.resolve(visualStyle, brightness, performanceMode: performanceMode);
    if (visualStyle == SundialVisualStyle.classic) {
      style = style.withColors(style.colors.withAccent(_accentFor(accentScheme, brightness)));
    }
    return _build(style);
  }

  static Color _accentFor(SundialAccentScheme scheme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (scheme) {
      SundialAccentScheme.sage => dark ? const Color(0xFF8FB39D) : const Color(0xFF4F6D5A),
      SundialAccentScheme.ocean => dark ? const Color(0xFF82B1FF) : const Color(0xFF2D6CDF),
      SundialAccentScheme.sunset => dark ? const Color(0xFFE89A7B) : const Color(0xFFC25B3F),
      SundialAccentScheme.violet => dark ? const Color(0xFFB6A2FF) : const Color(0xFF6E52D8),
      SundialAccentScheme.mono => dark ? const Color(0xFFD0D0D0) : const Color(0xFF444444),
    };
  }

  static SystemUiOverlayStyle systemBars(Brightness brightness) {
    final icons = brightness == Brightness.dark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _build(SundialStyle style) {
    final c = style.colors;
    final brightness = style.brightness;
    final aero = style.hasControlGradient;
    final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.text,
      secondary: c.work,
      onSecondary: c.onAccent,
      secondaryContainer: c.workSoft,
      onSecondaryContainer: c.text,
      tertiary: c.personal,
      onTertiary: c.onAccent,
      tertiaryContainer: c.personalSoft,
      onTertiaryContainer: c.text,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerLowest: c.pageBg,
      surfaceContainerLow: c.surfaceAlt,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceHigh,
      surfaceContainerHighest: c.surfaceHigh,
      outline: c.border,
      outlineVariant: c.border,
      error: c.danger,
      onError: c.onAccent,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
    );

    final text = SundialType.textTheme(c.text, c.textSecondary, fontFamily: style.bodyFontFamily);
    // Explicit component styles are separate TextStyles, so they need the
    // resolved family too. Relying on inheritance leaves Material buttons on
    // the platform default face.
    TextStyle font(TextStyle value) => value.copyWith(fontFamily: style.bodyFontFamily);
    final buttonShape = StadiumBorder(
      side: aero ? BorderSide(color: style.highlight.withValues(alpha: 0.30)) : BorderSide.none,
    );
    final fieldRadius = BorderRadius.circular(SundialRadii.md);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: style.bodyFontFamily,
      textTheme: text,
      primaryTextTheme: text,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: c.pageBg,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: c.surfaceAlt.withValues(alpha: 0.6),
      dividerColor: c.border,
      disabledColor: c.textTertiary,
      visualDensity: VisualDensity.standard,
      extensions: [c, SundialStyleTheme(style)],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: systemBars(brightness),
        foregroundColor: c.text,
        iconTheme: IconThemeData(color: c.text, size: 22),
        titleTextStyle: font(SundialType.headline(20, color: c.text)),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.shadow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: SundialShapes.rounded(
          radius: SundialRadii.lg,
          side: BorderSide(color: aero ? style.rim : c.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.38),
        elevation: 0,
        constraints: const BoxConstraints(maxWidth: 620),
        shape: SundialShapes.sheetTop(
          radius: SundialRadii.xxl,
          side: aero ? BorderSide(color: style.rim) : BorderSide.none,
        ),
        dragHandleColor: c.borderStrong,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
        shape: SundialShapes.rounded(
          radius: SundialRadii.xl,
          side: aero ? BorderSide(color: style.rim) : BorderSide.none,
        ),
        titleTextStyle: font(SundialType.headline(19, color: c.text)),
        contentTextStyle: font(SundialType.body(14, color: c.textSecondary)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surfaceHigh,
        contentTextStyle: font(SundialType.body(13.5, color: c.text)),
        actionTextColor: c.accent,
        elevation: 0,
        shape: SundialShapes.rounded(radius: SundialRadii.md),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.navBg,
        indicatorColor: c.accentSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorShape: SundialShapes.rounded(radius: SundialRadii.md),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(font(SundialType.label(10.5, color: c.textSecondary))),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? c.accent : c.textSecondary,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? c.surfaceHigh : c.accent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? c.textTertiary : c.onAccent,
          ),
          elevation: WidgetStatePropertyAll(aero ? 3 : 0),
          shadowColor: WidgetStatePropertyAll(aero ? c.accent.withValues(alpha: 0.35) : Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 22, vertical: 14)),
          shape: WidgetStatePropertyAll(buttonShape),
          side: WidgetStatePropertyAll(
            aero ? BorderSide(color: style.highlight.withValues(alpha: 0.30)) : BorderSide.none,
          ),
          textStyle: WidgetStatePropertyAll(font(SundialType.label(14, color: c.onAccent))),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.text),
          side: WidgetStatePropertyAll(BorderSide(color: aero ? style.rim : c.borderStrong)),
          minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(font(SundialType.label(13.5, color: c.text))),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: const StadiumBorder(),
          textStyle: font(SundialType.label(13.5, color: c.accent)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: c.text, highlightColor: c.surfaceAlt),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceAlt,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: font(SundialType.body(14, color: c.textTertiary)),
        labelStyle: font(SundialType.body(13.5, color: c.textSecondary)),
        floatingLabelStyle: font(SundialType.label(12.5, color: c.accent)),
        errorStyle: font(SundialType.body(12, color: c.danger)),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: aero ? style.rim : c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: c.accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: c.danger, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onAccent),
        side: BorderSide(color: aero ? style.rim : c.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SundialRadii.xxs)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.borderStrong,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.onAccent : c.textSecondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAlt,
        selectedColor: c.accentSoft,
        disabledColor: c.surfaceAlt,
        side: BorderSide(color: aero ? style.rim : c.border),
        shape: aero
            ? const StadiumBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(SundialRadii.xs)),
        labelStyle: font(SundialType.label(12.5, color: c.textSecondary)),
        secondaryLabelStyle: font(SundialType.label(12.5, color: c.accent)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.shadow,
        elevation: 12,
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
        shape: SundialShapes.rounded(
          radius: SundialRadii.md,
          side: BorderSide(color: aero ? style.rim : c.border),
        ),
        textStyle: font(SundialType.body(14, color: c.text)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.text,
        titleTextStyle: font(SundialType.body(15, color: c.text)),
        subtitleTextStyle: font(SundialType.body(12.5, color: c.textSecondary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent, linearTrackColor: c.surfaceHigh),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.surfaceHigh,
          borderRadius: BorderRadius.circular(SundialRadii.xs),
          border: aero ? Border.all(color: style.rim) : null,
        ),
        textStyle: font(SundialType.body(12, color: c.text)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.surface,
        shape: SundialShapes.rounded(radius: SundialRadii.xl),
        hourMinuteShape: SundialShapes.rounded(radius: SundialRadii.md),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accentSoft : c.surfaceAlt,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.text,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accentSoft : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : c.textSecondary,
        ),
        dayPeriodBorderSide: BorderSide(color: c.border),
        helpTextStyle: font(SundialType.kicker(color: c.textSecondary)),
        entryModeIconColor: c.textSecondary,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: c.textSecondary),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: c.accent),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: SundialShapes.rounded(radius: SundialRadii.xl),
        headerBackgroundColor: c.accentSoft,
        headerForegroundColor: c.text,
        // Flutter paints the current year's selected pill (and today's selected
        // day) with todayForegroundColor, so it must yield onAccent over the
        // accent fill instead of accent-on-accent.
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.onAccent : c.accent,
        ),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.accent : Colors.transparent,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.onAccent : c.text,
        ),
      ),
    );
  }
}
