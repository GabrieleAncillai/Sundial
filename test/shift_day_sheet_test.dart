import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/calendar/pages/calendar_page.dart';
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

  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await database.seedDefaults();
  });

  tearDown(() => database.close());

  Widget host() => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(database),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
      nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 12)),
      initialSettingsProvider.overrideWithValue(const AppSettings()),
    ],
    child: MaterialApp(
      theme: SundialTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: CalendarPage()),
    ),
  );

  Future<List<QueryRow>> exceptions() => database
      .customSelect('SELECT type, date_key, start_minute, end_minute FROM shift_exception_records')
      .get();

  Future<void> selectSaturday(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('calendar-day-2026-11-14')));
    await tester.pumpAndSettle();
  }

  test('setting a day override replaces every exception on that date only', () async {
    final saturday = LocalDate.parse('2026-11-14');
    final sunday = LocalDate.parse('2026-11-15');
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'pizza',
        spaceId: 'work',
        name: 'Pizza',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: LocalDate.parse('2026-11-09'),
        exceptions: [
          ShiftException(date: saturday, type: ShiftExceptionType.extra, startMinute: 600, endMinute: 900),
          ShiftException(date: saturday, type: ShiftExceptionType.extra, startMinute: 960, endMinute: 1320),
          ShiftException(date: sunday, type: ShiftExceptionType.free),
        ],
      ),
    );

    await database.setShiftDayOverride(
      'pizza',
      saturday,
      ShiftException(date: saturday, type: ShiftExceptionType.free),
    );

    final rows = await exceptions();
    expect(rows, hasLength(2));
    expect(rows.map((row) => (row.data['type'], row.data['date_key'])).toSet(), {
      ('free', 20261114),
      ('free', 20261115),
    });

    await database.setShiftDayOverride('pizza', saturday, null);
    final remaining = await exceptions();
    expect(remaining, hasLength(1));
    expect(remaining.single.data['date_key'], 20261115);
  });

  testWidgets('records a floating weekend shift as an override', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Pizza works Monday to Friday. Saturday is decided week by week, so the
    // pattern has no weekend slot at all.
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'pizza',
        spaceId: 'work',
        name: 'Pizza',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: LocalDate.parse('2026-11-09'),
        slots: const [
          ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 22 * 60),
          ShiftSlot(dayIndex: 1, startMinute: 15 * 60, endMinute: 22 * 60),
          ShiftSlot(dayIndex: 2, startMinute: 15 * 60, endMinute: 22 * 60),
          ShiftSlot(dayIndex: 3, startMinute: 15 * 60, endMinute: 22 * 60),
          ShiftSlot(dayIndex: 4, startMinute: 15 * 60, endMinute: 22 * 60),
        ],
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await selectSaturday(tester);

    expect(find.text('Pizza'), findsNothing);

    await tester.tap(find.byTooltip('Adjust shifts'));
    await tester.pumpAndSettle();
    expect(find.text('Day shifts'), findsOneWidget);
    expect(find.text('Free all day'), findsOneWidget);

    await tester.tap(find.text('Working'));
    await tester.pumpAndSettle();
    expect(find.text('Shift times'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final rows = await exceptions();
    expect(rows, hasLength(1));
    expect(rows.single.data['type'], 'override');
    expect(rows.single.data['date_key'], 20261114);
    expect(rows.single.data['start_minute'], 15 * 60);
    expect(rows.single.data['end_minute'], 22 * 60);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Pizza'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('marks a working Saturday free and restores it', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The shop works every Saturday; one Saturday a month is taken free.
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'shop',
        spaceId: 'work',
        name: 'Shop',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: LocalDate.parse('2026-11-09'),
        slots: const [ShiftSlot(dayIndex: 5, startMinute: 9 * 60, endMinute: 17 * 60)],
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await selectSaturday(tester);

    expect(find.text('Shop'), findsOneWidget);

    await tester.tap(find.byTooltip('Adjust shifts'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Working ·'), findsOneWidget);

    await tester.tap(find.text('Free'));
    await tester.pumpAndSettle();

    final rows = await exceptions();
    expect(rows, hasLength(1));
    expect(rows.single.data['type'], 'free');
    expect(rows.single.data['start_minute'], isNull);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Shop'), findsNothing);

    await tester.tap(find.byTooltip('Adjust shifts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usual'));
    await tester.pumpAndSettle();

    expect(await exceptions(), isEmpty);
    expect(find.text('Free all day'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
