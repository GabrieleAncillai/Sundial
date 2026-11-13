import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/app/app_shell.dart';
import 'package:mane/core/i18n/l10n.dart';
import 'package:mane/core/settings_scope.dart';
import 'package:mane/models/app_settings.dart';
import 'package:mane/models/home_item.dart';
import 'package:mane/models/shopping_item.dart';
import 'package:mane/services/app_database.dart';
import 'package:mane/services/notification_service.dart';
import 'package:mane/state/providers.dart';
import 'package:mane/state/settings_controller.dart';
import 'package:mane/theme/app_theme.dart';
import 'package:mane_core/mane_core.dart';
import 'package:sqlite3/open.dart';

const _phone = (size: Size(1290, 2796), dpr: 3.0);
const _desktop = (size: Size(2560, 1600), dpr: 2.0);
final _today = LocalDate.parse('2026-11-09');
final _now = DateTime.utc(2026, 11, 9, 10, 30);

void main() {
  setUpAll(() async {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    initializeTimeZones();
    await _loadFonts();
  });

  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory(), defaultTimeZone: 'Europe/Madrid');
    await _seed(database);
  });

  tearDown(() => database.close());

  testWidgets('render mobile Today list', (tester) async {
    await _renderShell(tester, 'v1.0-today-list-light.png', database, view: _phone);
  });

  testWidgets('render mobile Today timeline', (tester) async {
    await _renderShell(
      tester,
      'v1.0-today-timeline-light.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render desktop Work', (tester) async {
    await _renderShell(
      tester,
      'v1.0-work-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Work'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render desktop Plan', (tester) async {
    await _renderShell(
      tester,
      'v1.0-plan-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render desktop Stats', (tester) async {
    await _renderShell(
      tester,
      'v1.0-stats-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Stats'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Personal', (tester) async {
    await _renderShell(
      tester,
      'v1.0-personal-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.text('Personal'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Settings', (tester) async {
    await _renderShell(
      tester,
      'v1.0-settings-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Appearance', (tester) async {
    await _renderShell(
      tester,
      'v1.0-appearance-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Preferences with sound and time zone', (tester) async {
    await _renderShell(
      tester,
      'v1.2-preferences-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Preferences'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render Aero Today', (tester) async {
    await _renderShell(
      tester,
      'v1.2-today-aero.png',
      database,
      view: _phone,
      settings: const AppSettings(themeVariant: ManeThemeVariant.aero),
    );
  });
}

Future<void> _loadFonts() async {
  final materialFont = _locateMaterialFont();
  if (materialFont != null) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(materialFont.readAsBytesSync())));
    await icons.load();
  }
  final loader = FontLoader('Nunito');
  for (final file in [
    'Nunito-Regular.ttf',
    'Nunito-Italic.ttf',
    'Nunito-Medium.ttf',
    'Nunito-SemiBold.ttf',
    'Nunito-SemiBoldItalic.ttf',
    'Nunito-Bold.ttf',
    'Nunito-ExtraBold.ttf',
    'Nunito-Black.ttf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

Future<void> _renderShell(
  WidgetTester tester,
  String name,
  AppDatabase database, {
  required ({Size size, double dpr}) view,
  Future<void> Function(WidgetTester tester)? act,
  AppSettings settings = const AppSettings(),
}) async {
  tester.view.physicalSize = view.size;
  tester.view.devicePixelRatio = view.dpr;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          notificationServiceProvider.overrideWithValue(
            // ignore: invalid_use_of_visible_for_testing_member
            NotificationService.withPlugin(FlutterLocalNotificationsPlugin()),
          ),
          initialSettingsProvider.overrideWithValue(settings),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(_now),
        ],
        child: AppSettingsScope(
          settings: settings,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ManeTheme.forSettings(settings, Brightness.light),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AppShell(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (act != null) await act(tester);

  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory('docs/screenshots')..createSync(recursive: true);
    File('${dir.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  });

  // AppShell owns a periodic clock; drop the tree so the timer is cancelled.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _seed(AppDatabase database) async {
  await database.seedDefaults();
  final created = DateTime.utc(2026, 11, 1, 8);

  const pizzeria = PlannerContext(
    id: 'pizzeria',
    spaceId: 'work',
    name: 'The Pizzeria',
    description: 'Evening shifts and weekend prep',
    colorValue: 0xFFE08A3C,
    icon: 'restaurant',
    position: 0,
  );
  const studio = PlannerContext(
    id: 'studio',
    spaceId: 'work',
    name: 'Studio North',
    description: 'Design and front-end work',
    colorValue: 0xFF4F7CAC,
    icon: 'laptop',
    position: 1,
  );
  const apartment = PlannerContext(
    id: 'apartment',
    spaceId: 'home',
    name: 'Apartment 4B',
    description: 'Everything shared under one roof',
    colorValue: 0xFF6B9B7B,
    icon: 'home',
    position: 0,
  );
  const family = PlannerContext(
    id: 'family',
    spaceId: 'personal',
    name: 'Family',
    description: 'Time with the people who matter',
    colorValue: 0xFFB06AB3,
    icon: 'group',
    position: 0,
  );
  for (final context in [pizzeria, studio, apartment, family]) {
    await database.saveContext(context);
  }

  for (final project in const [
    Project(
      id: 'relaunch',
      spaceId: 'work',
      contextId: 'studio',
      name: 'Website relaunch',
      description: 'Portfolio refresh',
      colorValue: 0xFF4F7CAC,
      icon: 'rocket',
    ),
    Project(
      id: 'deep-clean',
      spaceId: 'home',
      contextId: 'apartment',
      name: 'Deep clean',
      description: 'Room-by-room reset',
      colorValue: 0xFF6B9B7B,
      icon: 'cleaning',
    ),
    Project(
      id: 'parents',
      spaceId: 'personal',
      contextId: 'family',
      name: 'Weekend with Mom & Dad',
      description: 'Monthly visit',
      colorValue: 0xFFB06AB3,
      icon: 'favorite',
    ),
  ]) {
    await database.saveProject(project);
  }

  await database.saveHabit(
    Habit(
      id: 'walk',
      spaceId: 'personal',
      contextId: 'family',
      name: 'Morning walk',
      description: 'Twenty minutes before work',
      colorValue: 0xFF6B9B7B,
      icon: 'directions_run',
      targetPerWeek: 5,
      createdAt: created,
    ),
  );

  for (final entry in _entries(created)) {
    await database.saveEntry(entry);
  }

  await database.saveShiftPattern(
    ShiftPattern(
      id: 'pizzeria-shifts',
      spaceId: 'work',
      contextId: 'pizzeria',
      name: 'Pizzeria',
      timeZone: 'Europe/Madrid',
      cycleDays: 7,
      anchorDate: _today,
      slots: const [ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 23 * 60, label: 'Floor')],
    ),
  );

  await database.startTimeEntry(entryId: 'review', at: DateTime.utc(2026, 11, 9, 10));

  await database.saveHomeItem(
    const HomeItem(
      id: 'rice',
      name: 'Rice',
      category: 'Pantry',
      location: 'Kitchen',
      quantity: 2,
      unit: 'kg',
      reorderLevel: 1,
    ),
  );
  await database.saveShoppingItem(const ShoppingItem(id: 'milk', name: 'Milk', quantity: 2, unit: 'L'));
}

List<Entry> _entries(DateTime created) {
  Entry entry(
    String id,
    String space,
    String title, {
    EntryKind kind = EntryKind.task,
    bool allDay = true,
    int? start,
    int? end,
    String? context,
    String? project,
    EntryPriority priority = EntryPriority.none,
    EntryStatus status = EntryStatus.open,
    DateTime? completedAt,
    LocalDate? date,
    int? repeatAfterCompletionDays,
  }) {
    return Entry(
      id: id,
      spaceId: space,
      title: title,
      kind: kind,
      date: date ?? _today,
      allDay: allDay,
      startMinute: allDay ? null : start,
      endMinute: allDay ? null : end,
      timeZone: allDay ? null : 'Europe/Madrid',
      contextId: context,
      projectId: project,
      priority: priority,
      status: status,
      completedAt: completedAt,
      repeatAfterCompletionDays: repeatAfterCompletionDays,
      createdAt: created,
      updatedAt: created,
    );
  }

  return [
    entry('dough', 'work', 'Prep the dough', allDay: false, start: 8 * 60, end: 10 * 60, context: 'pizzeria'),
    entry(
      'standup',
      'work',
      'Team standup',
      allDay: false,
      start: 10 * 60,
      end: 10 * 60 + 30,
      context: 'studio',
      project: 'relaunch',
      status: EntryStatus.done,
      completedAt: DateTime.utc(2026, 11, 9, 9, 40),
    ),
    entry(
      'review',
      'work',
      'Review the release notes',
      allDay: false,
      start: 11 * 60,
      end: 12 * 60 + 30,
      context: 'studio',
      project: 'relaunch',
      priority: EntryPriority.high,
    ),
    entry('dentist', 'personal', 'Call the dentist', context: 'family'),
    entry(
      'passport',
      'personal',
      'Renew the passport',
      kind: EntryKind.deadline,
      allDay: false,
      end: 17 * 60,
      context: 'family',
      priority: EntryPriority.medium,
    ),
    entry('plants', 'home', 'Water the plants', kind: EntryKind.obligation, context: 'apartment'),
    entry(
      'pump',
      'home',
      'Service the water pump',
      kind: EntryKind.obligation,
      context: 'apartment',
      date: _today.addDays(-9),
      repeatAfterCompletionDays: 90,
    ),
    entry(
      'dinner',
      'personal',
      'Anniversary dinner',
      kind: EntryKind.event,
      allDay: false,
      start: 20 * 60,
      end: 22 * 60,
      context: 'family',
      date: _today.addDays(3),
    ),
  ];
}

File? _locateMaterialFont() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 10; i++) {
    for (final candidate in [
      File('${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf'),
      File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'),
      File('${dir.path}/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'),
    ]) {
      if (candidate.existsSync()) return candidate;
    }
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}
