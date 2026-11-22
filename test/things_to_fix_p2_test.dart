import 'dart:ffi' show DynamicLibrary;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/core/widgets/sundial_nav_bar.dart';
import 'package:sundial/core/widgets/sundial_page.dart';
import 'package:sundial/features/settings/widgets/settings_rows.dart';
import 'package:sundial/features/stats/pages/stats_page.dart';
import 'package:sundial/features/tags/pages/tags_page.dart';
import 'package:sundial/l10n/app_localizations_en.dart';
import 'package:sundial/l10n/app_localizations_es.dart';
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
  final now = DateTime.utc(2026, 11, 11, 12);

  setUp(() {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
  });

  tearDown(() => database.close());

  Widget dbHost(Widget child) => ProviderScope(
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

  Widget widgetHost(Widget child, {Size size = const Size(360, 770), Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: SundialTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(width: size.width, child: child),
      ),
    );
  }

  testWidgets('stats shows a message instead of invisible zero bars', (tester) async {
    await database.seedDefaults();

    await tester.pumpWidget(dbHost(const Scaffold(body: StatsPage())));
    await tester.pumpAndSettle();

    expect(find.text('No data in this range.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the tag manager uses tag terminology', (tester) async {
    await database.seedDefaults();

    await tester.pumpWidget(dbHost(const TagsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Categories'), findsNothing);
    expect(find.byTooltip('Add a tag'), findsOneWidget);

    await tester.tap(find.byTooltip('Add a tag'));
    await tester.pumpAndSettle();
    expect(find.text('Add a tag'), findsOneWidget);
    expect(find.text('Categories'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Spanish bottom navigation labels fit a six-tab bar', (tester) async {
    final l10n = AppLocalizationsEs();
    final items = <SundialNavItem>[
      (icon: Icons.today_outlined, selectedIcon: Icons.today, label: l10n.todayTab),
      (icon: Icons.work_outline, selectedIcon: Icons.work, label: l10n.workTab),
      (icon: Icons.home_outlined, selectedIcon: Icons.home, label: l10n.homeTab),
      (icon: Icons.people_outline, selectedIcon: Icons.people, label: l10n.personalTab),
      (icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: l10n.planTab),
      (icon: Icons.insights_outlined, selectedIcon: Icons.insights, label: l10n.statsTab),
    ];
    const barWidth = 278.0;
    const slot = barWidth / 6;

    await tester.pumpWidget(
      widgetHost(
        Center(
          child: SizedBox(
            width: barWidth,
            height: 64,
            child: SundialNavBar(index: 0, onSelected: (_) {}, items: items),
          ),
        ),
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();

    for (final item in items) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(item.label));
      expect(paragraph.didExceedMaxLines, isFalse, reason: item.label);
      expect(tester.getRect(find.text(item.label)).width, lessThanOrEqualTo(slot + 0.1), reason: item.label);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a long settings value below the title leaves room for the subtitle', (tester) async {
    final l10n = AppLocalizationsEn();

    await tester.pumpWidget(
      widgetHost(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SettingsNavRow(
            icon: Icons.public,
            title: l10n.timeZone,
            subtitle: l10n.timezoneSubtitle,
            value: 'America/Caracas',
            valueBelow: true,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.getRect(find.text(l10n.timeZone));
    final value = tester.getRect(find.text('America/Caracas'));
    final subtitle = tester.getRect(find.text(l10n.timezoneSubtitle));
    expect(value.top, greaterThanOrEqualTo(title.bottom));
    expect(subtitle.top, greaterThanOrEqualTo(value.bottom));

    final subtitleText = tester.widget<Text>(find.text(l10n.timezoneSubtitle));
    expect(subtitleText.maxLines, 2);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a page header subtitle wraps to a second line', (tester) async {
    final l10n = AppLocalizationsEn();
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      widgetHost(
        Padding(
          padding: const EdgeInsets.all(16),
          child: SundialPageHeader(title: l10n.devices, subtitle: l10n.devicesSubtitle, onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final subtitle = tester.widget<Text>(find.text(l10n.devicesSubtitle));
    expect(subtitle.maxLines, 2);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(l10n.devicesSubtitle));
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: l10n.devicesSubtitle.length),
    );
    expect(boxes.length, greaterThan(1));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
