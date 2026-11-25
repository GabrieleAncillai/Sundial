import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sundial_core/sundial_core.dart';

import 'app/sundial_app.dart';
import 'models/app_settings.dart';
import 'services/app_database.dart';
import 'services/app_icon_service.dart';
import 'services/notification_service.dart';
import 'state/providers.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeTimeZones();
  final timeZone = await _deviceTimeZone();
  final database = AppDatabase.open(defaultTimeZone: timeZone);
  await database.seedDefaults();
  final settings = AppSettings.fromMap(await database.readSettings());
  // Android remembers the enabled activity alias across launches, but an
  // install, update or backup restore can reset it. Re-apply the stored choice
  // before the first frame so the launcher entry always matches the setting.
  await const AppIconService().apply(settings.appIconStyle);
  final notifications = NotificationService();
  await notifications.initialize(deviceTimeZone: timeZone, alarmSound: settings.alarmSound);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: timeZone)),
        notificationServiceProvider.overrideWithValue(notifications),
        initialSettingsProvider.overrideWithValue(settings),
      ],
      child: const SundialApp(),
    ),
  );
}

/// The device's IANA timezone, or UTC when the platform cannot report one.
///
/// A wrong-but-valid zone is worse than UTC: it would silently move timed
/// plans. The editor still lets the user keep a stored zone on existing items.
Future<String> _deviceTimeZone() async {
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    if (isKnownTimeZone(zone.identifier)) return zone.identifier;
  } catch (_) {
    // Platform lookup is unavailable on some Linux sessions; UTC is safe.
  }
  return 'UTC';
}
