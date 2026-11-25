import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/settings/pages/settings_detail_page.dart';
import 'package:sundial/features/sync/pages/sync_debug_page.dart';
import 'package:sundial/models/app_settings.dart';
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
  final day = LocalDate.parse('2026-11-09');
  final now = DateTime.utc(2026, 11, 9, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
  });

  tearDown(() => database.close());

  Widget host(Widget child, {AppSettings settings = const AppSettings()}) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
      initialSettingsProvider.overrideWithValue(settings),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: SundialTheme.light,
      home: child,
    ),
  );

  testWidgets('the developer switch gates the sync debug entry', (tester) async {
    await tester.pumpWidget(host(const SettingsDetailPage(section: SettingsDetailSection.developer)));
    await tester.pumpAndSettle();

    expect(find.text('Enable developer options'), findsOneWidget);
    expect(find.text('Sync debug log'), findsNothing);

    await tester.tap(find.text('Enable developer options'));
    await tester.pumpAndSettle();

    expect(find.text('Sync debug log'), findsOneWidget);
    expect((await database.readSettings())['developerOptions'], 'true');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('the sync debug page lists local change actions', (tester) async {
    await database.saveEntry(
      Entry(
        id: 'dentist',
        spaceId: 'personal',
        title: 'Dentist',
        date: day,
        allDay: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      host(const SyncDebugPage(), settings: const AppSettings(developerOptionsEnabled: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Local sync state'), findsOneWidget);
    expect(find.text('Changes'), findsWidgets);
    expect(find.textContaining('entry · dentist'), findsOneWidget);
    expect(find.textContaining('Upsert'), findsOneWidget);

    await tester.tap(find.textContaining('entry · dentist'));
    await tester.pumpAndSettle();
    expect(find.text('Row payload'), findsOneWidget);
    expect(find.text('Copy change'), findsOneWidget);

    await tester.tap(find.text('Fields'));
    await tester.pumpAndSettle();
    expect(find.text('title'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
  });
}
