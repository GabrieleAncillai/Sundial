import 'dart:ffi';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/core/i18n/l10n.dart';
import 'package:mane/core/settings_scope.dart';
import 'package:mane/features/entries/widgets/repeat_editor_sheet.dart';
import 'package:mane/models/app_settings.dart';
import 'package:mane/screens/entry_editor.dart';
import 'package:mane/services/app_database.dart';
import 'package:mane/services/notification_service.dart';
import 'package:mane/state/providers.dart';
import 'package:mane/state/settings_controller.dart';
import 'package:mane_core/mane_core.dart';
import 'package:sqlite3/open.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel({required int id}) async {}

  @override
  Future<void> cancelAllPendingNotifications() async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {}
}

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    tzdata.initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase database;
  late NotificationService notifications;
  final now = DateTime.utc(2026, 11, 9, 12);
  final today = LocalDate.parse('2026-11-09');

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    notifications = NotificationService.withPlugin(FlutterLocalNotificationsPlugin());
  });

  tearDown(() => database.close());

  Widget host(Widget child, AppSettings settings) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
      nowProvider.overrideWithValue(now),
      initialSettingsProvider.overrideWithValue(settings),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: AppSettingsScope(
      settings: settings,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Widget editorLauncher(List<Space> spaces, {Entry? entry}) => Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => showEntryEditor(context, entry: entry, spaces: spaces),
        child: const Text('open'),
      ),
    ),
  );

  testWidgets('clearing the end turns a scheduled task into a clock-in task', (tester) async {
    final entry = Entry(
      id: 'task',
      spaceId: 'personal',
      title: 'Deep work',
      date: today,
      startMinute: 9 * 60,
      endMinute: 10 * 60,
      timeZone: 'Europe/Madrid',
      createdAt: now,
      updatedAt: now,
    );
    await database.saveEntry(entry);

    await tester.pumpWidget(host(editorLauncher(fallbackSpaces, entry: entry), const AppSettings()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byTooltip('Clear end'));
    await tester.tap(find.byTooltip('Clear end'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = await database.readEntry('task');
    expect(saved, isNotNull);
    expect(saved!.endMinute, isNull);
    expect(saved.startMinute, 9 * 60);
    expect(saved.timing, EntryTiming.clockIn);
    expect(saved.endAt, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('new entries use the planning time zone preference', (tester) async {
    const settings = AppSettings(timezoneOverride: 'America/New_York', defaultReminderOffsets: <int>[]);

    await tester.pumpWidget(host(editorLauncher(fallbackSpaces), settings));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('America/New_York'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Plan the week');
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Add an entry'));
    await tester.tap(find.text('Add an entry'));
    await tester.pumpAndSettle();

    final stored = await database.loadEntriesBetween(today, today, 'Europe/Madrid');
    expect(stored, hasLength(1));
    expect(stored.single.entry.timeZone, 'America/New_York');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('repeat editor builds a weekly rule with the anchor weekday', (tester) async {
    RepeatSelection? result;

    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await showRepeatEditor(context, initial: const RepeatSelection(), anchor: today);
              },
              child: const Text('repeat'),
            ),
          ),
        ),
        const AppSettings(),
      ),
    );

    await tester.tap(find.text('repeat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every week'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.rule?.frequency, RecurrenceFrequency.weekly);
    expect(result!.rule?.weekdays, {today.weekday});

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
