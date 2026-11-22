import 'dart:ffi' show DynamicLibrary;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/shifts/pages/shift_pattern_editor_page.dart';
import 'package:sundial/models/shift_checklist.dart';
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

  testWidgets('shrinking the cycle clamps checklist day indexes', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();
    final pattern = ShiftPattern(
      id: 'rotation',
      spaceId: 'work',
      name: 'Rotation',
      timeZone: 'Europe/Madrid',
      cycleDays: 7,
      anchorDate: LocalDate.parse('2026-11-09'),
    );
    await database.saveShiftPattern(pattern);
    await database.saveShiftChecklistItems('rotation', const [
      ShiftChecklistItem(id: 'sunday', patternId: 'rotation', label: 'Sunday prep', dayIndex: 6),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShiftPatternEditorPage(pattern: pattern),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 4; index++) {
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();
    }
    await tester.scrollUntilVisible(
      find.text('Save pattern'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save pattern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save pattern'));
    await tester.pumpAndSettle();

    expect((await database.readShiftChecklistItems('rotation')).single.dayIndex, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('leaving with edits asks before discarding them', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShiftPatternEditorPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextFormField).first, 'Night rotation');
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Discard your changes?'), findsOneWidget);
    expect(find.byType(ShiftPatternEditorPage), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(ShiftPatternEditorPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftPatternEditorPage), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('leaving an untouched pattern closes without a prompt', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShiftPatternEditorPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Discard your changes?'), findsNothing);
    expect(find.byType(ShiftPatternEditorPage), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('creates a pattern with a slot and saves it', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShiftPatternEditorPage(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextFormField).first, 'Night rotation');
    await tester.tap(find.text('Add a slot').first);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Save pattern'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save pattern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save pattern'));
    await tester.pump(const Duration(milliseconds: 500));

    final rows = await database.customSelect('SELECT name, time_zone FROM shift_pattern_records').get();
    expect(rows, hasLength(1));
    expect(rows.single.data['name'], 'Night rotation');
    expect(rows.single.data['time_zone'], 'Europe/Madrid');

    final slots = await database.customSelect('SELECT * FROM shift_slot_records').get();
    expect(slots, hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('adding a slot to an empty day copies the nearest previous day', (tester) async {
    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();
    final pattern = ShiftPattern(
      id: 'rotation',
      spaceId: 'work',
      name: 'Rotation',
      timeZone: 'Europe/Madrid',
      cycleDays: 7,
      anchorDate: LocalDate.parse('2026-11-09'),
      slots: const [
        ShiftSlot(dayIndex: 0, label: 'Opening', startMinute: 9 * 60, endMinute: 13 * 60),
        ShiftSlot(dayIndex: 0, label: 'Closing', startMinute: 15 * 60, endMinute: 22 * 60),
      ],
    );
    await database.saveShiftPattern(pattern);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShiftPatternEditorPage(pattern: pattern),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final dayTwoAdd = find.byKey(const ValueKey('day-1-add-slot'));
    await tester.scrollUntilVisible(dayTwoAdd, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(dayTwoAdd);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Save pattern'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save pattern'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save pattern'));
    await tester.pump(const Duration(milliseconds: 500));

    final slots = await database
        .customSelect(
          'SELECT day_index, label, start_minute, end_minute FROM shift_slot_records '
          'ORDER BY day_index, start_minute',
        )
        .get();
    expect(slots, hasLength(4));
    expect(
      [
        for (final row in slots)
          [row.data['day_index'], row.data['label'], row.data['start_minute'], row.data['end_minute']],
      ],
      [
        [0, 'Opening', 540, 780],
        [0, 'Closing', 900, 1320],
        [1, 'Opening', 540, 780],
        [1, 'Closing', 900, 1320],
      ],
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('header save validates and persists the pattern', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShiftPatternEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save pattern'));
    await tester.pumpAndSettle();
    expect(find.text('Give the pattern a name.'), findsOneWidget);
    expect(find.byType(ShiftPatternEditorPage), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Header save');
    await tester.tap(find.byTooltip('Save pattern'));
    await tester.pumpAndSettle();

    expect(find.byType(ShiftPatternEditorPage), findsNothing);
    final rows = await database.customSelect('SELECT name FROM shift_pattern_records').get();
    expect(rows.map((row) => row.data['name']), contains('Header save'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('field captions sit above their controls at phone width', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    addTearDown(database.close);
    await database.seedDefaults();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 9, 8)),
          initialSettingsProvider.overrideWithValue(const AppSettings()),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShiftPatternEditorPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final nameLabel = find.text('Pattern name');
    final nameField = find.byType(TextFormField).first;
    final nameLabelRect = tester.getRect(nameLabel);
    expect(nameLabelRect.top, greaterThanOrEqualTo(0));
    expect(nameLabelRect.bottom, lessThanOrEqualTo(tester.getRect(nameField).top));

    await tester.enterText(nameField, 'Night rotation');
    await tester.pumpAndSettle();
    expect(
      tester.getRect(nameLabel).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('Night rotation')).top),
    );

    final anchorLabel = tester.getRect(find.text('Anchor date'));
    final anchorValue = tester.getRect(find.text('November 9, 2026'));
    expect(anchorLabel.bottom, lessThanOrEqualTo(anchorValue.top));

    final addSlot = find.byKey(const ValueKey('day-0-add-slot'));
    await tester.ensureVisible(addSlot);
    await tester.pumpAndSettle();
    await tester.tap(addSlot);
    await tester.pumpAndSettle();

    final slotLabel = find.text('Label');
    await tester.ensureVisible(slotLabel);
    await tester.pumpAndSettle();
    final slotField = find.descendant(
      of: find.byKey(const ValueKey('slot-label-0')),
      matching: find.byType(TextFormField),
    );
    expect(slotField, findsOneWidget);
    final slotLabelRect = tester.getRect(slotLabel);
    expect(slotLabelRect.top, greaterThanOrEqualTo(0));
    expect(slotLabelRect.bottom, lessThanOrEqualTo(tester.getRect(slotField).top));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
