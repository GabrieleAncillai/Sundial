import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/plan/pages/plan_page.dart';
import 'package:sundial/features/plan/widgets/week_agenda.dart';
import 'package:sundial/features/spaces/pages/space_overview_page.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/screens/entry_editor.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/state/providers.dart';
import 'package:sundial/state/settings_controller.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    initializeTimeZones();
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  late AppDatabase database;
  final now = DateTime.utc(2026, 11, 15, 12);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
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
      theme: SundialTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('the phone plan offers a scrollable week agenda', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await database.seedDefaults();
    await database.saveEntry(
      Entry(
        id: 'home-task',
        spaceId: 'home',
        title: 'Sort the garage',
        date: LocalDate.parse('2026-11-15'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(host(const PlanPage()));
    await tester.pumpAndSettle();

    expect(find.text('Month'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('plan-month')), findsNothing);
    expect(find.byKey(const ValueKey('plan-week')), findsOneWidget);
    expect(find.byType(WeekAgenda), findsOneWidget);
    expect(find.text('Nov 9 – Nov 15'), findsOneWidget);
    expect(find.text('Sort the garage'), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('Nov 16 – Nov 22'), findsOneWidget);

    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plan-day')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a space page offers a task before its first context', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await database.seedDefaults();

    await tester.pumpWidget(host(const SpaceOverviewPage(spaceId: 'home')));
    await tester.pumpAndSettle();

    expect(find.text('No homes yet.'), findsOneWidget);
    expect(find.text('Add a task'), findsOneWidget);
    expect(find.text('Create the first one'), findsOneWidget);
    expect(
      find.text('Homes group house projects and tasks. Inventory and shopping work without one.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Add a task'));
    await tester.pumpAndSettle();
    expect(find.byType(EntryEditorSheet), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
