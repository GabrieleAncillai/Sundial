import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/calendar/pages/calendar_page.dart';
import 'package:sundial/features/calendar/widgets/day_timeline.dart';
import 'package:sundial/features/calendar/widgets/open_end_entry_block.dart';
import 'package:sundial/features/shifts/shift_block_painter.dart';
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

  testWidgets('calendar days expose a descriptive semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.bySemanticsLabel(RegExp(r'November 9, 2026, 0 items')), findsOneWidget);
    handle.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('selecting a day shows its entries and keeps the selected date', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await database.saveEntry(
      Entry(
        id: 'dentist',
        spaceId: 'personal',
        title: 'Dentist',
        date: LocalDate.parse('2026-11-15'),
        allDay: true,
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    expect(find.text('November 2026'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('calendar-day-2026-11-15')));
    await tester.pumpAndSettle();

    expect(find.text('Dentist'), findsOneWidget);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);

    await tester.tap(find.byTooltip('Jump to today'));
    await tester.pumpAndSettle();
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Dentist'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('week mode navigates by whole weeks', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('week-day-2026-11-09')), findsOneWidget);

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('week-day-2026-11-16')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('day mode shows the timeline with shifts and entries', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await database.saveEntry(
      Entry(
        id: 'standup',
        spaceId: 'personal',
        title: 'Dentist',
        date: LocalDate.parse('2026-11-09'),
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'bar',
        spaceId: 'work',
        name: 'Bar',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: LocalDate.parse('2026-11-09'),
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 23 * 60)],
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.byType(DayTimeline), findsOneWidget);
    expect(find.text('Dentist'), findsWidgets);
    expect(find.text('Bar'), findsWidgets);
    expect(find.text('12:00 PM'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('day mode shows an entry with no end as an open-ended block', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await database.saveEntry(
      Entry(
        id: 'clock',
        spaceId: 'personal',
        title: 'Open task',
        date: LocalDate.parse('2026-11-09'),
        startMinute: 9 * 60,
        timeZone: 'Europe/Madrid',
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(find.byType(OpenEndEntryBlock), findsOneWidget);
    expect(find.text('Open task'), findsWidgets);
    expect(find.text('09:00 –'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('overlapping shifts stay full width and blend in the day timeline', (tester) async {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await database.saveShiftPattern(
      ShiftPattern(
        id: 'banco',
        spaceId: 'work',
        name: 'Banco',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: LocalDate.parse('2026-11-09'),
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 9 * 60, endMinute: 13 * 60)],
      ),
    );
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'pizza',
        spaceId: 'work',
        name: 'Pizza',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: LocalDate.parse('2026-11-09'),
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 12 * 60, endMinute: 16 * 60)],
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    final bankRect = tester.getRect(find.text('Banco'));
    final pizzaRect = tester.getRect(find.text('Pizza'));

    expect(bankRect.left, pizzaRect.left);
    expect(bankRect.width, pizzaRect.width);
    expect(bankRect.width, greaterThan(200));

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<ShiftBlockPainter>()
        .firstWhere((painter) => painter.blocks.isNotEmpty);
    expect(painter.blocks, hasLength(2));
    expect(painter.blocks.every((block) => block.rect.left == painter.blocks.first.rect.left), isTrue);
    expect(painter.blocks[0].rect.width, painter.blocks[1].rect.width);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a Sunday week start rotates the month grid', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 12)),
          initialSettingsProvider.overrideWithValue(const AppSettings(weekStart: DateTime.sunday)),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: CalendarPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1 November 2026 is a Sunday, so the first cell is the 1st itself.
    final firstCell = find.byKey(const ValueKey('calendar-day-2026-11-01'));
    expect(firstCell, findsOneWidget);
    final firstRect = tester.getRect(firstCell);
    final secondRect = tester.getRect(find.byKey(const ValueKey('calendar-day-2026-11-02')));
    expect(secondRect.left, greaterThan(firstRect.left));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
