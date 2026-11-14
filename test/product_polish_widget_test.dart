import 'dart:ffi';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/core/i18n/l10n.dart';
import 'package:mane/features/calendar/widgets/day_timeline.dart';
import 'package:mane/features/spaces/pages/context_detail_page.dart';
import 'package:mane/features/settings/pages/settings_page.dart';
import 'package:mane/features/stats/pages/stats_page.dart';
import 'package:mane/models/app_settings.dart';
import 'package:mane/screens/today_screen.dart';
import 'package:mane/services/app_database.dart';
import 'package:mane/state/providers.dart';
import 'package:mane/state/settings_controller.dart';
import 'package:mane_core/mane_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase database;
  final now = DateTime.utc(2026, 11, 9, 12);
  final today = LocalDate.parse('2026-11-09');

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
    await database.saveEntry(
      Entry(
        id: 'task',
        spaceId: 'personal',
        title: 'Call the dentist',
        date: today,
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() => database.close());

  Widget host(Widget child) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
      nowProvider.overrideWithValue(now),
      initialSettingsProvider.overrideWithValue(const AppSettings()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('personal detail does not show household sections', (tester) async {
    await database.saveContext(
      const PlannerContext(id: 'mom', spaceId: 'personal', name: 'Mom', colorValue: 0xFFB07D5C),
    );

    await tester.pumpWidget(host(const ContextDetailPage(spaceId: 'personal', contextId: 'mom')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('HABITS'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('HABITS'), findsOneWidget);
    expect(find.text('Home inventory'), findsNothing);
    expect(find.text('Shopping list'), findsNothing);
    expect(find.text('Gadgets'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('work detail offers adding a project', (tester) async {
    await database.saveContext(
      const PlannerContext(id: 'cafe', spaceId: 'work', name: 'Cafe', colorValue: 0xFF2F7ED8),
    );

    await tester.pumpWidget(host(const ContextDetailPage(spaceId: 'work', contextId: 'cafe')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Add project'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('Add project'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Today switches between the friendly list and the timeline', (tester) async {
    await tester.pumpWidget(host(const TodayScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Call the dentist'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);

    await tester.tap(find.text('Timeline'));
    await tester.pumpAndSettle();

    expect(find.byType(DayTimeline), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('stats opens on a month and accepts a quarter range', (tester) async {
    await tester.pumpWidget(host(const StatsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    await tester.tap(find.text('Quarter'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('settings search narrows to the matching section', (tester) async {
    await tester.pumpWidget(host(const SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'theme');
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Preferences'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
