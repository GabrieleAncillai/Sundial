import 'package:flutter/widgets.dart';

import '../models/app_settings.dart';

/// Makes the current preferences available to pushed pages and backgrounds
/// without converting every screen into a Riverpod consumer.
class AppSettingsScope extends InheritedWidget {
  const AppSettingsScope({super.key, required this.settings, required super.child});

  final AppSettings settings;

  static AppSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppSettingsScope>()?.settings;

  @override
  bool updateShouldNotify(AppSettingsScope oldWidget) => !identical(settings, oldWidget.settings);
}
