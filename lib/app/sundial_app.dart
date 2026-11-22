import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/l10n.dart';
import '../core/settings_scope.dart';
import '../core/window/window_chrome.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class SundialApp extends ConsumerWidget {
  const SundialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lightTheme = SundialTheme.forSettings(settings, Brightness.light);
    final darkTheme = SundialTheme.forSettings(settings, Brightness.dark);
    final themeMode = settings.resolvedThemeMode;
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final brightness = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => media.platformBrightness,
        };
        final chromeTheme = brightness == Brightness.dark ? darkTheme : lightTheme;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SundialTheme.systemBars(brightness),
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(settings.textScale),
              disableAnimations: settings.performanceMode || media.disableAnimations,
            ),
            child: WindowChromeSync(
              colors: chromeTheme.extension<SundialColors>() ?? SundialColors.light,
              brightness: brightness,
              child: AppSettingsScope(settings: settings, child: child ?? const SizedBox.shrink()),
            ),
          ),
        );
      },
      home: const AppShell(),
    );
  }
}
