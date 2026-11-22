import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/core/widgets/app_empty_state.dart';
import 'package:sundial/features/search/pages/search_page.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/screens/today_screen.dart';
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
  final now = DateTime.utc(2026, 11, 11, 12);

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
      home: child,
    ),
  );

  testWidgets('Today keeps the weekday on one line on a 360 dp phone', (tester) async {
    tester.view.physicalSize = const Size(360, 770);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await database.seedDefaults();

    await tester.pumpWidget(host(const Scaffold(body: TodayScreen())));
    await tester.pumpAndSettle();

    final weekday = find.text('Wednesday');
    expect(weekday, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(weekday);
    final boxes = paragraph.getBoxesForSelection(const TextSelection(baseOffset: 0, extentOffset: 9));
    expect(boxes, hasLength(1));

    // On a narrow phone the view switch moves below the header instead of
    // squeezing the display type.
    expect(tester.getRect(weekday).bottom, lessThan(tester.getRect(find.text('Timeline')).top));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Today shows the empty message exactly once', (tester) async {
    await database.seedDefaults();

    await tester.pumpWidget(host(const Scaffold(body: TodayScreen())));
    await tester.pumpAndSettle();

    expect(find.text('Nothing planned for today.'), findsOneWidget);
    expect(find.text('Add something'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Search empty state scrolls when the keyboard shrinks the page', (tester) async {
    tester.view.physicalSize = const Size(360, 770);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 480);
    addTearDown(tester.view.reset);
    await database.seedDefaults();

    await tester.pumpWidget(host(const SearchPage()));
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
