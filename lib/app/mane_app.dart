import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/l10n.dart';
import '../core/settings_scope.dart';
import '../state/settings_controller.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class ManeApp extends ConsumerWidget {
  const ManeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      theme: ManeTheme.forSettings(settings, Brightness.light),
      darkTheme: ManeTheme.forSettings(settings, Brightness.dark),
      themeMode: settings.resolvedThemeMode,
      locale: settings.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: ManeTheme.systemBars(Theme.of(context).brightness),
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(settings.textScale),
              disableAnimations: settings.performanceMode || media.disableAnimations,
            ),
            child: AppSettingsScope(settings: settings, child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      home: const AppShell(),
    );
  }
}
