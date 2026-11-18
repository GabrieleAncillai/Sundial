import 'dart:ffi' hide Size;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/data/home_reference_defaults.dart';
import 'package:sundial/features/home_inventory/maintenance_dates.dart';
import 'package:sundial/features/home_inventory/pages/home_inventory_page.dart';
import 'package:sundial/features/home_inventory/pages/household_catalog_page.dart';
import 'package:sundial/features/home_inventory/widgets/gadget_sheet.dart';
import 'package:sundial/features/home_inventory/widgets/home_art.dart';
import 'package:sundial/features/home_inventory/widgets/home_item_sheet.dart';
import 'package:sundial/features/home_inventory/shopping_suggestions.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/home_reference.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial/services/app_database.dart';
import 'package:sundial/state/providers.dart';
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

  test('seeds categories, locations and units once', () async {
    final categories = await database.watchHomeCategories().first;
    final locations = await database.watchHomeLocations().first;
    final units = await database.watchHomeUnits().first;

    expect(categories.map((category) => category.id), contains('home-food'));
    expect(locations.map((location) => location.id), contains('home-loc-kitchen'));
    expect(units.map((unit) => unit.id), contains('home-unit-kg'));
    expect(categories.length, greaterThanOrEqualTo(8));
    expect(locations.length, greaterThanOrEqualTo(10));
    expect(units.length, greaterThanOrEqualTo(15));
  });

  test('one product keeps sizes with separate stock, units and minimums', () async {
    await database.saveHomeItem(
      HomeItem(
        id: 'water-gallon',
        groupId: 'water',
        name: 'Drinking water',
        category: 'Food & pantry',
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 gal',
        quantity: 3,
        minQuantity: 1,
      ),
    );
    await database.saveHomeItem(
      HomeItem(
        id: 'water-litre',
        groupId: 'water',
        name: 'Drinking water',
        category: 'Food & pantry',
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 L',
        quantity: 4,
        minQuantity: 2,
      ),
    );

    final items = await database.watchHomeItems().first;
    expect(items, hasLength(2));
    expect(items.map((item) => item.productGroupId).toSet(), {'water'});
    final groups = groupHomeProducts(items);
    expect(groups, hasLength(1));
    expect(groups.single.variants, hasLength(2));
    expect(groups.single.variants.map((item) => item.packSize), ['5 gal', '5 L']);
    expect(groups.single.isLowStock, isFalse);

    await database.adjustHomeQuantity('water-litre', -2);
    final stocked = await database.watchHomeItems().first;
    final litre = stocked.firstWhere((item) => item.id == 'water-litre');
    expect(litre.isLowStock, isTrue);
    expect(litre.suggestedPurchase, 2);
    expect(groupHomeProducts(stocked).single.isLowStock, isTrue);
  });

  test('saving an item maps text to the household reference rows', () async {
    await database.saveHomeItem(
      const HomeItem(
        id: 'rice',
        name: 'Rice',
        category: 'Food & pantry',
        location: 'Kitchen, Pantry',
        quantity: 2,
        unit: 'kg',
        minQuantity: 1,
      ),
    );

    final item = (await database.watchHomeItems().first).single;
    expect(item.categoryId, 'home-food');
    expect(item.unitId, 'home-unit-kg');
    expect(item.locationIds.toSet(), {'home-loc-kitchen', 'home-loc-pantry'});
    expect(item.minimumStock, 1);
    expect(item.groupId, 'rice');
  });

  test('renaming and deleting reference rows keeps inventory readable', () async {
    const category = HomeCategory(id: 'shelf', name: 'Shelf', icon: 'inventory', colorValue: 0xFF4F7F7A);
    const location = HomeLocation(id: 'rack', name: 'Rack', icon: 'warehouse', colorValue: 0xFF5A6470);
    const unit = HomeUnit(id: 'rolls', name: 'Roll custom', symbol: 'rls');
    await database.saveHomeCategory(category);
    await database.saveHomeLocation(location);
    await database.saveHomeUnit(unit);
    await database.saveHomeItem(
      const HomeItem(
        id: 'paper',
        name: 'Paper',
        category: 'Book shelf',
        categoryId: 'shelf',
        unit: 'Roll custom',
        unitId: 'rolls',
        location: 'Rack',
        locationIds: ['rack'],
        quantity: 4,
      ),
    );

    await database.saveHomeCategory(category.copyWith(name: 'Book shelf'));
    await database.saveHomeUnit(unit.copyWith(name: 'Rolls'));
    var item = (await database.watchHomeItems().first).single;
    expect(item.category, 'Book shelf');
    expect(item.unit, 'Rolls');

    await database.deleteHomeLocation('rack');
    item = (await database.watchHomeItems().first).single;
    expect(item.locationIds, isEmpty);
    expect(item.location, '');

    await database.deleteHomeUnit('rolls');
    item = (await database.watchHomeItems().first).single;
    expect(item.unitId, isNull);
    expect(item.unit, 'Rolls');

    await database.deleteHomeCategory('shelf');
    item = (await database.watchHomeItems().first).single;
    expect(item.categoryId, isNull);
    expect(item.category, 'Book shelf');

    await database.saveHomeItem(
      item.copyWith(category: 'Book shelf', categoryId: null, unit: 'Rolls', unitId: null),
    );
    item = (await database.watchHomeItems().first).single;
    expect(item.categoryId, isNull, reason: 'a deleted category must not be relinked by text');
    expect(item.unitId, isNull, reason: 'a deleted unit must not be relinked by text');
  });

  test('shopping suggestions cover out-of-stock, low and expired stock', () async {
    final today = LocalDate.parse('2026-11-17');
    const items = [
      HomeItem(id: 'rice', name: 'Rice', quantity: 0, minQuantity: 1),
      HomeItem(id: 'coffee', name: 'Coffee', quantity: 1, minQuantity: 2),
      HomeItem(id: 'milk', name: 'Milk', quantity: 5, minQuantity: 2, expiresAt: LocalDate(2026, 11, 10)),
      HomeItem(id: 'soap', name: 'Soap', quantity: 5, minQuantity: 2),
    ];
    const shopping = [ShoppingItem(id: 'buy-coffee', name: 'Coffee', homeItemId: 'coffee')];
    final suggestions = buildShoppingSuggestions(items: items, shopping: shopping, today: today);

    expect(suggestions.map((suggestion) => suggestion.item.id), ['rice', 'coffee', 'milk']);
    expect(suggestions.first.reason, ShoppingSuggestionReason.outOfStock);
    expect(
      suggestions.firstWhere((suggestion) => suggestion.item.id == 'coffee').reason,
      ShoppingSuggestionReason.lowStock,
    );
    expect(suggestions.firstWhere((suggestion) => suggestion.item.id == 'coffee').alreadyListed, isTrue);
    expect(
      suggestions.firstWhere((suggestion) => suggestion.item.id == 'milk').reason,
      ShoppingSuggestionReason.expired,
    );
    expect(suggestions.firstWhere((suggestion) => suggestion.item.id == 'rice').quantity, 2);
  });

  test('checking a linked line restocks that exact variant', () async {
    await database.saveHomeItem(
      const HomeItem(
        id: 'water-gallon',
        groupId: 'water',
        name: 'Drinking water',
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 gal',
        quantity: 1,
        minQuantity: 1,
      ),
    );
    await database.saveHomeItem(
      const HomeItem(
        id: 'water-litre',
        groupId: 'water',
        name: 'Drinking water',
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 L',
        quantity: 1,
        minQuantity: 1,
      ),
    );
    await database.saveShoppingItem(
      const ShoppingItem(
        id: 'buy-gallon',
        name: 'Drinking water',
        quantity: 3,
        unit: 'Bottle',
        packSize: '5 gal',
        homeItemId: 'water-gallon',
      ),
    );

    await database.setShoppingChecked('buy-gallon', true);
    final items = await database.watchHomeItems().first;
    expect(items.firstWhere((item) => item.id == 'water-gallon').quantity, 4);
    expect(items.firstWhere((item) => item.id == 'water-litre').quantity, 1);

    await database.setShoppingChecked('buy-gallon', false);
    expect(
      (await database.watchHomeItems().first).firstWhere((item) => item.id == 'water-gallon').quantity,
      1,
    );
  });

  test('unchecking reverses the recorded purchase, not the edited line', () async {
    await database.saveHomeItem(
      const HomeItem(
        id: 'water-gallon',
        groupId: 'water',
        name: 'Drinking water',
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 gal',
        quantity: 1,
      ),
    );
    await database.saveShoppingItem(
      const ShoppingItem(id: 'buy-gallon', name: 'Drinking water', quantity: 3, homeItemId: 'water-gallon'),
    );
    await database.setShoppingChecked('buy-gallon', true);
    expect(
      (await database.watchHomeItems().first).firstWhere((item) => item.id == 'water-gallon').quantity,
      4,
    );

    final line = (await database.watchShoppingItems().first).single;
    await database.saveShoppingItem(line.copyWith(quantity: 10));
    await database.setShoppingChecked('buy-gallon', false);

    expect(
      (await database.watchHomeItems().first).firstWhere((item) => item.id == 'water-gallon').quantity,
      1,
      reason: 'undo uses the quantity recorded when the line was checked',
    );
  });

  test('archiving a variant unlinks its shopping lines', () async {
    await database.saveHomeItem(
      const HomeItem(id: 'water-gallon', name: 'Drinking water', quantity: 2, unit: 'Bottle'),
    );
    await database.saveShoppingItem(
      const ShoppingItem(id: 'buy-gallon', name: 'Drinking water', quantity: 1, homeItemId: 'water-gallon'),
    );

    await database.archiveHomeItem('water-gallon');

    final line = (await database.watchShoppingItems().first).single;
    expect(line.homeItemId, isNull);
    await database.setShoppingChecked('buy-gallon', true);
    expect((await database.watchHomeItems().first), isEmpty);
  });

  test('quantity labels show the pack without multiplying it', () {
    const item = HomeItem(
      id: 'water-gallon',
      name: 'Drinking water',
      quantity: 3,
      unit: 'Bottle',
      unitId: 'home-unit-bottle',
      packSize: '5 gal',
    );
    const shopping = ShoppingItem(
      id: 'buy-gallon',
      name: 'Drinking water',
      quantity: 4,
      unit: 'Bottle',
      packSize: '5 gal',
    );

    expect(variantQuantityLabel(item, defaultHomeUnits, const Locale('en')), '3 Bottle · 5 gal');
    expect(variantQuantityLabel(item, defaultHomeUnits, const Locale('es')), '3 Botella · 5 gal');
    expect(shoppingQuantityLabel(shopping, item, defaultHomeUnits, const Locale('en')), '4 Bottle · 5 gal');
  });

  test('service dates follow the entry zone instead of the device zone', () {
    final timed = Entry(
      id: 'boiler',
      spaceId: 'home',
      title: 'Boiler',
      date: LocalDate.parse('2026-11-09'),
      startMinute: 9 * 60,
      endMinute: 10 * 60,
      timeZone: 'Europe/Madrid',
      lastCompletedAt: DateTime.utc(2026, 11, 10, 11),
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    final allDay = Entry(
      id: 'ac',
      spaceId: 'home',
      title: 'AC',
      date: LocalDate.parse('2026-11-09'),
      allDay: true,
      lastCompletedAt: DateTime.utc(2026, 11, 10, 12),
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );

    expect(maintenanceServiceDate(timed), LocalDate.parse('2026-11-10'));
    expect(maintenanceServiceDate(allDay), LocalDate.parse('2026-11-10'));
  });

  test('logging a service counts from the performed date and records history', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveEntry(
      Entry(
        id: 'boiler',
        spaceId: 'home',
        title: 'Boiler service',
        date: LocalDate.parse('2026-11-09'),
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        timeZone: 'Europe/Madrid',
        repeatAfterCompletionDays: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final next = await database.completeMaintenanceEntry(
      'boiler',
      LocalDate.parse('2026-11-10'),
      note: 'Replaced the filter',
      durationMinutes: 60,
    );
    expect(next, LocalDate.parse('2026-12-10'));

    final logs = await database.watchMaintenanceLogs('boiler').first;
    expect(logs.single.performedOn, LocalDate.parse('2026-11-10'));
    expect(logs.single.nextDue, LocalDate.parse('2026-12-10'));
    expect(logs.single.note, 'Replaced the filter');
    expect(logs.single.durationMinutes, 60);

    final entry = await database.readEntry('boiler');
    expect(entry!.date, LocalDate.parse('2026-12-10'));
    expect(entry.lastCompletedAt, DateTime.utc(2026, 11, 10, 11));
    expect(entry.startMinute, 9 * 60, reason: 'the wall time survives the next due date');
  });

  test('a service can create a completed calendar event atomically', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveEntry(
      Entry(
        id: 'ac',
        spaceId: 'home',
        title: 'AC service',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        repeatAfterCompletionDays: 180,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final event = Entry(
      id: 'ac-service-event',
      spaceId: 'home',
      title: 'AC service',
      kind: EntryKind.event,
      date: LocalDate.parse('2026-11-09'),
      startMinute: 10 * 60,
      endMinute: 11 * 60,
      timeZone: 'Europe/Madrid',
      status: EntryStatus.done,
      completedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await database.completeMaintenanceEntry(
      'ac',
      LocalDate.parse('2026-11-09'),
      note: 'Cleaned the coils',
      calendarEvent: event,
    );

    final saved = await database.readEntry('ac-service-event');
    expect(saved, isNotNull);
    expect(saved!.status, EntryStatus.done);
    expect(saved.startMinute, 10 * 60);
    expect(saved.endMinute, 11 * 60);
  });

  test('rescheduling moves the due date without logging a service', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveEntry(
      Entry(
        id: 'tank',
        spaceId: 'home',
        title: 'Water tank',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        repeatAfterCompletionDays: 90,
        lastCompletedAt: DateTime.utc(2026, 10, 1, 10),
        createdAt: now,
        updatedAt: now,
      ),
    );
    final next = await database.rescheduleMaintenance('tank', LocalDate.parse('2026-11-20'));
    expect(next, LocalDate.parse('2026-11-20'));
    expect((await database.readEntry('tank'))!.date, LocalDate.parse('2026-11-20'));
    expect(await database.watchMaintenanceLogs('tank').first, isEmpty);
  });

  test('clearAllData removes service logs before entries and reseeds references', () async {
    final now = DateTime.utc(2026, 11, 1, 8);
    await database.saveEntry(
      Entry(
        id: 'boiler',
        spaceId: 'home',
        title: 'Boiler service',
        date: LocalDate.parse('2026-11-09'),
        allDay: true,
        repeatAfterCompletionDays: 30,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.completeMaintenanceEntry('boiler', LocalDate.parse('2026-11-10'));
    expect(await database.watchMaintenanceLogs('boiler').first, isNotEmpty);

    await database.clearAllData();

    expect(await database.watchMaintenanceLogs('boiler').first, isEmpty);
    expect(await database.readEntry('boiler'), isNull);
    expect(await database.watchHomeCategories().first, isNotEmpty);
    expect(await database.watchHomeUnits().first, isNotEmpty);
  });

  testWidgets('empty inventory shows one add action and no floating button', (tester) async {
    await tester.pumpWidget(_inventoryApp(items: const [], now: DateTime.utc(2026, 11, 17, 12)));
    await tester.pump();

    expect(find.text('Your home inventory is empty.'), findsOneWidget);
    expect(find.text('Browse the household catalog'), findsOneWidget);
    expect(find.byTooltip('Add to inventory'), findsNothing);
  });

  testWidgets('inventory groups two sizes under one product', (tester) async {
    final items = [
      const HomeItem(
        id: 'water-gallon',
        groupId: 'water',
        name: 'Drinking water',
        icon: 'water',
        quantity: 3,
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 gal',
        minQuantity: 1,
      ),
      const HomeItem(
        id: 'water-litre',
        groupId: 'water',
        name: 'Drinking water',
        icon: 'water',
        quantity: 4,
        unit: 'Bottle',
        unitId: 'home-unit-bottle',
        packSize: '5 L',
        minQuantity: 1,
      ),
    ];
    await tester.pumpWidget(_inventoryApp(items: items, now: DateTime.utc(2026, 11, 17, 12)));
    await tester.pump();

    expect(find.text('Drinking water'), findsOneWidget);
    expect(find.textContaining('5 gal'), findsWidgets);
    expect(find.textContaining('5 L'), findsWidgets);
    expect(find.textContaining('2 sizes'), findsOneWidget);
    expect(find.textContaining('3 Bottle · 5 gal'), findsOneWidget);
    expect(find.textContaining('4 Bottle · 5 L'), findsOneWidget);
  });

  testWidgets('catalog reuses the existing product group when adding another size', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const existing = HomeItem(
      id: 'water-gallon',
      contextId: 'home',
      groupId: 'water',
      name: 'Drinking water',
      catalogId: 'catalog-drinking-water',
      icon: 'water',
      quantity: 3,
      unit: 'Bottle',
      unitId: 'home-unit-bottle',
      packSize: '5 gal',
      minQuantity: 1,
    );
    await tester.pumpWidget(_catalogApp(existing: existing, now: DateTime.utc(2026, 11, 17, 12)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drinking water'));
    await tester.pumpAndSettle();

    expect(find.text('Add another size'), findsOneWidget);
  });

  testWidgets('editing a serviced gadget keeps a manual reschedule', (tester) async {
    final now = DateTime.utc(2026, 11, 17, 12);
    final today = localDateAt(now, 'Europe/Madrid');
    final gadget = Entry(
      id: 'ac',
      spaceId: 'home',
      title: 'AC service',
      date: LocalDate.parse('2026-11-20'),
      allDay: true,
      repeatAfterCompletionDays: 30,
      lastCompletedAt: DateTime.utc(2026, 11, 10, 11),
      createdAt: now,
      updatedAt: now,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nowProvider.overrideWithValue(now),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGadgetEditor(context, homeId: 'home', today: today, gadget: gadget),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('November 20, 2026'), findsOneWidget);
  });

  testWidgets('clearing the category and unit in the editor persists the clear', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const saved = HomeItem(
      id: 'rice',
      name: 'Rice',
      category: 'Food & pantry',
      categoryId: 'home-food',
      unit: 'kg',
      unitId: 'home-unit-kg',
      quantity: 2,
    );
    await database.saveHomeItem(saved);
    final item = (await database.watchHomeItems().first).single;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          nowProvider.overrideWithValue(DateTime.utc(2026, 11, 17, 12)),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: HomeItemSheet(item: item, updateGroup: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Clear text'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Clear text').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Clear text').first);
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final cleared = (await database.watchHomeItems().first).single;
    expect(cleared.categoryId, isNull);
    expect(cleared.category, isEmpty);
    expect(cleared.unitId, isNull);
    expect(cleared.unit, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}

Widget _inventoryApp({required List<HomeItem> items, required DateTime now}) {
  return ProviderScope(
    overrides: [
      homeItemsProvider.overrideWith((ref) => Stream.value(items)),
      shoppingItemsProvider.overrideWith((ref) => Stream.value(const <ShoppingItem>[])),
      homeCategoriesProvider.overrideWith((ref) => Stream.value(defaultHomeCategories)),
      homeLocationsProvider.overrideWith((ref) => Stream.value(defaultHomeLocations)),
      homeUnitsProvider.overrideWith((ref) => Stream.value(defaultHomeUnits)),
      nowProvider.overrideWithValue(now),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
    ],
    child: MaterialApp(
      theme: SundialTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeInventoryPage(),
    ),
  );
}

Widget _catalogApp({required HomeItem existing, required DateTime now}) {
  return ProviderScope(
    overrides: [
      homeItemsProvider.overrideWith((ref) => Stream.value([existing])),
      shoppingItemsProvider.overrideWith((ref) => Stream.value(const <ShoppingItem>[])),
      homeCategoriesProvider.overrideWith((ref) => Stream.value(defaultHomeCategories)),
      homeLocationsProvider.overrideWith((ref) => Stream.value(defaultHomeLocations)),
      homeUnitsProvider.overrideWith((ref) => Stream.value(defaultHomeUnits)),
      nowProvider.overrideWithValue(now),
      deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
    ],
    child: MaterialApp(
      theme: SundialTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HouseholdCatalogPage(homeId: 'home'),
    ),
  );
}
