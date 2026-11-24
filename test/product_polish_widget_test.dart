import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/calendar/widgets/day_timeline.dart';
import 'package:sundial/features/spaces/pages/context_detail_page.dart';
import 'package:sundial/features/settings/pages/settings_page.dart';
import 'package:sundial/features/stats/pages/stats_page.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/models/shift_checklist.dart';
import 'package:sundial/screens/today_screen.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/state/providers.dart';
import 'package:sundial/state/settings_controller.dart';
import 'package:sundial_core/sundial_core.dart';
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

  Widget host(Widget child, {AppSettings settings = const AppSettings()}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
      nowProvider.overrideWithValue(now),
      initialSettingsProvider.overrideWithValue(settings),
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

  testWidgets('Today list exposes the shift checklist', (tester) async {
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'shift',
        spaceId: 'work',
        name: 'Evening',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: today,
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 23 * 60, label: 'Floor')],
      ),
    );
    await database.saveShiftChecklistItems('shift', const [
      ShiftChecklistItem(id: 'item', patternId: 'shift', label: 'Count the till'),
    ]);

    await tester.pumpWidget(host(const TodayScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Count the till'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Count the till'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Today shows checklist items saved after it opened', (tester) async {
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'shift',
        spaceId: 'work',
        name: 'Evening',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: today,
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 23 * 60, label: 'Floor')],
      ),
    );

    await tester.pumpWidget(host(const TodayScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Count the till'), findsNothing);

    // The pattern editor saves items while Today stays mounted underneath.
    await database.saveShiftChecklistItems('shift', const [
      ShiftChecklistItem(id: 'item', patternId: 'shift', label: 'Count the till'),
    ]);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Count the till'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Count the till'), findsOneWidget);

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

  testWidgets('desktop settings keeps the menu beside the selected panel', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const SettingsPage()));
    await tester.pumpAndSettle();

    // The sidebar lists the top-level sections and Appearance is selected.
    expect(find.text('Appearance'), findsWidgets);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Data and backup'), findsOneWidget);
    expect(find.text('Online functionalities'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Style'), findsOneWidget);
    expect(find.text('Brightness'), findsOneWidget);

    await tester.tap(find.text('Preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Style'), findsNothing);
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Data and backup'));
    await tester.pumpAndSettle();
    expect(find.text('Export a backup'), findsOneWidget);

    await tester.tap(find.text('Online functionalities'));
    await tester.pumpAndSettle();
    expect(find.text('Enable online functionalities'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('LICENSE'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('desktop settings sidebar follows the navigation side setting', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final side in SundialNavSide.values) {
      await tester.pumpWidget(host(const SettingsPage(), settings: AppSettings(navSide: side)));
      await tester.pumpAndSettle();

      final sidebarBack = tester.getCenter(find.byIcon(Icons.chevron_left));
      final paneRow = tester.getCenter(find.text('Style'));
      expect(
        sidebarBack.dx < paneRow.dx,
        side == SundialNavSide.left,
        reason: '${side.name} sidebar should sit ${side.name} of the settings pane',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('desktop settings search opens the matching row in the pane', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(const SettingsPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'quiet hours');
    await tester.pumpAndSettle();

    expect(find.text('Quiet hours'), findsOneWidget);
    await tester.tap(find.text('Quiet hours'));
    await tester.pumpAndSettle();

    // The Preferences panel is selected and the matching row is visible.
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Quiet hours'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
