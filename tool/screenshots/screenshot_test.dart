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
import 'package:sundial/app/app_shell.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/core/settings_scope.dart';
import 'package:sundial/features/home_inventory/pages/home_inventory_page.dart';
import 'package:sundial/features/home_inventory/pages/household_catalog_page.dart';
import 'package:sundial/features/home_inventory/pages/maintenance_page.dart';
import 'package:sundial/features/home_inventory/pages/shopping_list_page.dart';
import 'package:sundial/features/sync/pages/sync_debug_page.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/services/notification_service.dart';
import 'package:sundial/state/providers.dart';
import 'package:sundial/state/settings_controller.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial/theme/sundial_style.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:sqlite3/open.dart';

const _phone = (size: Size(1290, 2796), dpr: 3.0);
const _desktop = (size: Size(2560, 1600), dpr: 2.0);
const _desktopTall = (size: Size(2560, 2200), dpr: 2.0);
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
      'v1.4-plan-month-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render desktop Plan week', (tester) async {
    await _renderShell(
      tester,
      'v1.4-plan-week-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Week'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Plan month', (tester) async {
    await _renderShell(
      tester,
      'v1.4-plan-month-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Plan day', (tester) async {
    await _renderShell(
      tester,
      'v1.4-plan-day-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Day'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render dark desktop Plan', (tester) async {
    await _renderShell(
      tester,
      'v1.4-plan-month-dark-desktop.png',
      database,
      view: _desktop,
      brightness: Brightness.dark,
      settings: const AppSettings(themeMode: ThemeMode.dark),
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render desktop Plan with overlapping shifts', (tester) async {
    await database.saveShiftPattern(
      ShiftPattern(
        id: 'studio-shift',
        spaceId: 'work',
        contextId: 'studio',
        name: 'Studio',
        timeZone: 'Europe/Madrid',
        cycleDays: 7,
        anchorDate: _today,
        slots: const [ShiftSlot(dayIndex: 0, startMinute: 16 * 60, endMinute: 18 * 60)],
      ),
    );
    await _renderShell(
      tester,
      'v1.0-plan-overlap-desktop.png',
      database,
      view: _desktopTall,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Week'));
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

  testWidgets('render desktop Settings master-detail', (tester) async {
    await _renderShell(
      tester,
      'v1.3-settings-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile sync debug log', (tester) async {
    await _renderShell(
      tester,
      'v2-sync-debug-mobile.png',
      database,
      view: _phone,
      settings: const AppSettings(developerOptionsEnabled: true),
      home: const SyncDebugPage(),
    );
  });

  testWidgets('render Aero Today', (tester) async {
    await _renderShell(
      tester,
      'v1.2-today-aero.png',
      database,
      view: _phone,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero),
    );
  });

  testWidgets('render Aero dark Today', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-today-dark.png',
      database,
      view: _phone,
      brightness: Brightness.dark,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero, themeMode: ThemeMode.dark),
    );
  });

  testWidgets('render Aero desktop Plan', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-plan-desktop.png',
      database,
      view: _desktop,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero),
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render Aero settings mobile', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-settings-mobile.png',
      database,
      view: _phone,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero),
      act: (tester) async {
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render Aero dark settings desktop', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-settings-desktop.png',
      database,
      view: _desktop,
      brightness: Brightness.dark,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero, themeMode: ThemeMode.dark),
      act: (tester) async {
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render Aero appearance settings', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-appearance-mobile.png',
      database,
      view: _phone,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero),
      act: (tester) async {
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render icon-radius Today', (tester) async {
    await _renderShell(tester, 'v1.5-radii-today-mobile.png', database, view: _phone);
  });

  testWidgets('render icon-radius Today timeline', (tester) async {
    await _renderShell(
      tester,
      'v1.5-radii-timeline-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.text('Timeline'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render icon-radius desktop Plan', (tester) async {
    await _renderShell(
      tester,
      'v1.5-radii-plan-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Plan'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render icon-radius desktop Work', (tester) async {
    await _renderShell(
      tester,
      'v1.5-radii-work-desktop.png',
      database,
      view: _desktop,
      act: (tester) async {
        await tester.tap(find.text('Work'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render icon-radius mobile Settings', (tester) async {
    await _renderShell(
      tester,
      'v1.5-radii-settings-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render icon-radius entry sheet', (tester) async {
    await _renderShell(
      tester,
      'v1.5-radii-entry-sheet-mobile.png',
      database,
      view: _phone,
      act: (tester) async {
        await tester.tap(find.text('Prep the dough'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render mobile Home inventory with sizes', (tester) async {
    await _renderShell(
      tester,
      'v1.6-home-inventory-mobile.png',
      database,
      view: _phone,
      home: const HomeInventoryPage(),
    );
  });

  testWidgets('render mobile household catalog', (tester) async {
    await _renderShell(
      tester,
      'v1.6-home-catalog-mobile.png',
      database,
      view: _phone,
      home: const HouseholdCatalogPage(homeId: 'home'),
    );
  });

  testWidgets('render mobile shopping suggestions', (tester) async {
    await _renderShell(
      tester,
      'v1.6-home-shopping-mobile.png',
      database,
      view: _phone,
      home: const ShoppingListPage(),
    );
  });

  testWidgets('render mobile gadgets with service state', (tester) async {
    await _renderShell(
      tester,
      'v1.6-home-gadgets-mobile.png',
      database,
      view: _phone,
      home: const MaintenancePage(),
    );
  });

  testWidgets('render mobile context menu', (tester) async {
    await _renderShell(
      tester,
      'v2-context-menu-mobile.png',
      database,
      view: _phone,
      home: const HomeInventoryPage(),
      act: (tester) async {
        await tester.tap(find.byIcon(Icons.more_horiz).first);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render Aero context menu', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-context-menu-mobile.png',
      database,
      view: _phone,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero),
      home: const HomeInventoryPage(),
      act: (tester) async {
        await tester.tap(find.byIcon(Icons.more_horiz).first);
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('render Aero dark context menu', (tester) async {
    await _renderShell(
      tester,
      'v2-aero-dark-context-menu-mobile.png',
      database,
      view: _phone,
      brightness: Brightness.dark,
      settings: const AppSettings(visualStyle: SundialVisualStyle.aero, themeMode: ThemeMode.dark),
      home: const HomeInventoryPage(),
      act: (tester) async {
        await tester.tap(find.byIcon(Icons.more_horiz).first);
        await tester.pumpAndSettle();
      },
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

  final aeroLoader = FontLoader('Open Sans');
  for (final file in [
    'OpenSans-Regular.ttf',
    'OpenSans-Italic.ttf',
    'OpenSans-SemiBold.ttf',
    'OpenSans-Bold.ttf',
    'OpenSans-ExtraBold.ttf',
  ]) {
    aeroLoader.addFont(rootBundle.load('assets/fonts/OpenSans/$file'));
  }
  await aeroLoader.load();
}

Future<void> _renderShell(
  WidgetTester tester,
  String name,
  AppDatabase database, {
  required ({Size size, double dpr}) view,
  Future<void> Function(WidgetTester tester)? act,
  AppSettings settings = const AppSettings(),
  Brightness brightness = Brightness.light,
  Widget? home,
}) async {
  tester.view.physicalSize = view.size;
  tester.view.devicePixelRatio = view.dpr;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  // flutter_test disables shadow blur by default, so docs screenshots show
  // harder shadows than the running app. Capture with production shadows and
  // restore the binding's value afterwards.
  final shadowsDisabled = debugDisableShadows;
  debugDisableShadows = false;
  try {
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
              theme: SundialTheme.forSettings(settings, brightness),
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child ?? const SizedBox.shrink(),
              ),
              home: home ?? const AppShell(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (act != null) await act(tester);

    // flutter_test does not finish asynchronous image decoding during a normal
    // pump. Resolve bundled images before capture so the screenshots show the
    // real art instead of blank image frames.
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    if (images.isNotEmpty) {
      final context = tester.element(find.byType(Navigator).first);
      await tester.runAsync(() async {
        for (final image in images) {
          final provider = image.image;
          if (provider is AssetImage) await precacheImage(provider, context);
        }
      });
      await tester.pumpAndSettle();
    }

    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final dir = Directory('docs/screenshots')..createSync(recursive: true);
      File('${dir.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  } finally {
    debugDisableShadows = shadowsDisabled;
  }

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
      targetCount: 5,
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
  await database.saveHomeItem(
    const HomeItem(
      id: 'water-gallon',
      contextId: 'apartment',
      groupId: 'water',
      catalogId: 'catalog-drinking-water',
      name: 'Drinking water',
      icon: 'water',
      category: 'Food & pantry',
      categoryId: 'home-food',
      location: 'Kitchen',
      locationIds: ['home-loc-kitchen'],
      quantity: 3,
      unit: 'Bottle',
      unitId: 'home-unit-bottle',
      packSize: '5 gal',
      minQuantity: 2,
    ),
  );
  await database.saveHomeItem(
    const HomeItem(
      id: 'water-litre',
      contextId: 'apartment',
      groupId: 'water',
      catalogId: 'catalog-drinking-water',
      name: 'Drinking water',
      icon: 'water',
      category: 'Food & pantry',
      categoryId: 'home-food',
      location: 'Kitchen',
      locationIds: ['home-loc-kitchen'],
      quantity: 1,
      unit: 'Bottle',
      unitId: 'home-unit-bottle',
      packSize: '5 L',
      minQuantity: 2,
    ),
  );
  await database.saveHomeItem(
    HomeItem(
      id: 'coffee',
      contextId: 'apartment',
      catalogId: 'catalog-ground-coffee',
      name: 'Ground coffee',
      icon: 'local_cafe',
      category: 'Food & pantry',
      categoryId: 'home-food',
      location: 'Pantry',
      locationIds: const ['home-loc-pantry'],
      quantity: 1,
      unit: 'Bag',
      unitId: 'home-unit-bag',
      packSize: '1 kg',
      minQuantity: 2,
      expiresAt: _today.addDays(9),
    ),
  );
  await database.saveHomeItem(
    const HomeItem(
      id: 'toilet-paper',
      contextId: 'apartment',
      catalogId: 'catalog-toilet-paper',
      name: 'Toilet paper',
      icon: 'toilet_paper',
      category: 'Household consumables',
      categoryId: 'home-consumables',
      location: 'Main bathroom, Guest bathroom',
      locationIds: ['home-loc-main-bathroom', 'home-loc-guest-bathroom'],
      quantity: 8,
      unit: 'Roll',
      unitId: 'home-unit-roll',
      packSize: 'pack of 12',
      minQuantity: 4,
    ),
  );
  await database.saveHomeItem(
    const HomeItem(
      id: 'olive-oil',
      contextId: 'apartment',
      catalogId: 'catalog-olive-oil',
      name: 'Olive oil',
      icon: 'oil',
      category: 'Food & pantry',
      categoryId: 'home-food',
      location: 'Pantry',
      locationIds: ['home-loc-pantry'],
      quantity: 2,
      unit: 'Bottle',
      unitId: 'home-unit-bottle',
      packSize: '1 L',
      minQuantity: 1,
    ),
  );
  await database.saveShoppingItem(
    const ShoppingItem(
      id: 'buy-water',
      contextId: 'apartment',
      name: 'Drinking water',
      quantity: 2,
      unit: 'Bottle',
      packSize: '5 gal',
      homeItemId: 'water-gallon',
      category: 'Food & pantry',
      categoryId: 'home-food',
      icon: 'water',
    ),
  );
  await database.saveShoppingItem(
    const ShoppingItem(
      id: 'buy-coffee',
      contextId: 'apartment',
      name: 'Ground coffee',
      quantity: 2,
      unit: 'Bag',
      packSize: '1 kg',
      homeItemId: 'coffee',
      category: 'Food & pantry',
      categoryId: 'home-food',
      icon: 'local_cafe',
    ),
  );
  await database.saveShoppingItem(
    const ShoppingItem(
      id: 'mugs',
      contextId: 'apartment',
      name: 'Coffee mugs',
      quantity: 4,
      unit: 'Piece',
      category: 'Kitchenware & goods',
      categoryId: 'home-kitchenware',
      icon: 'mug',
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
    DateTime? lastCompletedAt,
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
      lastCompletedAt: lastCompletedAt,
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
      lastCompletedAt: DateTime.utc(2026, 8, 2, 12),
    ),
    entry(
      'ac',
      'home',
      'Service the AC',
      kind: EntryKind.obligation,
      allDay: false,
      start: 9 * 60,
      end: 11 * 60,
      context: 'apartment',
      date: _today.addDays(12),
      repeatAfterCompletionDays: 180,
    ),
    entry(
      'fridge',
      'home',
      'Clean the fridge filter',
      kind: EntryKind.obligation,
      context: 'apartment',
      date: _today.addDays(4),
      repeatAfterCompletionDays: 60,
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
