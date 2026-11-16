import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/plan/pages/plan_page.dart';
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
  });

  Future<AppDatabase> seededDatabase() async {
    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
    return database;
  }

  test('an all-day task dated today is in both open and range queries', () async {
    final db = await seededDatabase();
    addTearDown(db.close);
    final today = LocalDate.parse('2026-11-15');
    final now = DateTime.utc(2026, 11, 15, 10);

    await db.saveEntry(
      Entry(
        id: 'anytime',
        spaceId: 'home',
        title: 'Anytime home task',
        date: today,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.saveEntry(
      Entry(
        id: 'timed',
        spaceId: 'home',
        title: 'Timed home task',
        date: today,
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.saveEntry(
      Entry(
        id: 'overdue',
        spaceId: 'home',
        title: 'Overdue home task',
        date: today.addDays(-3),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final open = await db.watchOpenEntries(today).first;
    final range = await db.loadEntriesBetween(today, today, 'Europe/Madrid');

    expect(open.map((entry) => entry.id), containsAll(['anytime', 'timed', 'overdue']));
    expect(range.map((occurrence) => occurrence.entry.id), containsAll(['anytime', 'timed']));
    expect(range.map((occurrence) => occurrence.entry.id), isNot(contains('overdue')));
  });

  testWidgets('the plan shows an all-day home task dated today', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = await seededDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 11, 15, 12);
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
    await database.saveEntry(
      Entry(
        id: 'home-recurring',
        spaceId: 'home',
        title: 'Water the plants',
        date: LocalDate.parse('2026-11-09'),
        recurrence: const RecurrenceRule(frequency: RecurrenceFrequency.weekly),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
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
          home: const Scaffold(body: PlanPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sort the garage'), findsOneWidget);
    // A weekly series anchored on Mon Nov 9 does not occur on Sun Nov 15.
    expect(find.text('Water the plants'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
