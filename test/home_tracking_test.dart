import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/data/home_reference_defaults.dart';
import 'package:sundial/features/home_inventory/pages/maintenance_page.dart';
import 'package:sundial/features/home_inventory/pages/shopping_list_page.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/models/home_item.dart';
import 'package:sundial/models/maintenance_log.dart';
import 'package:sundial/models/shopping_item.dart';
import 'package:sundial/state/providers.dart';
import 'package:sundial/state/settings_controller.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial_core/sundial_core.dart';

void main() {
  testWidgets('shopping groups linked lines by home category', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeItemsProvider.overrideWith(
            (ref) => Stream.value(const [
              HomeItem(id: 'rice', name: 'Rice', category: 'Pantry', location: 'Kitchen', quantity: 1),
            ]),
          ),
          shoppingItemsProvider.overrideWith(
            (ref) => Stream.value(const [
              ShoppingItem(id: 'rice-buy', name: 'Rice', quantity: 2, homeItemId: 'rice'),
              ShoppingItem(id: 'soap-buy', name: 'Soap'),
            ]),
          ),
          homeCategoriesProvider.overrideWith((ref) => Stream.value(defaultHomeCategories)),
          homeLocationsProvider.overrideWith((ref) => Stream.value(defaultHomeLocations)),
          homeUnitsProvider.overrideWith((ref) => Stream.value(defaultHomeUnits)),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShoppingListPage(),
        ),
      ),
    );
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Clear bought'), findsNothing);
  });

  testWidgets('maintenance shows due tasks', (tester) async {
    final now = DateTime.utc(2026, 11, 9, 12);
    final today = localDateAt(now, 'Europe/Madrid');
    final entry = Entry(
      id: 'water',
      spaceId: 'home',
      title: 'Water tank',
      date: today.addDays(-2),
      allDay: true,
      repeatAfterCompletionDays: 90,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialSettingsProvider.overrideWithValue(const AppSettings()),
          deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: 'Europe/Madrid')),
          nowProvider.overrideWithValue(now),
          maintenanceEntriesProvider.overrideWith((ref) => Stream.value([entry])),
          maintenanceLogsProvider.overrideWith((ref, entryId) => Stream.value(const <MaintenanceLog>[])),
        ],
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MaintenancePage(),
        ),
      ),
    );
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Water tank'), findsOneWidget);
    expect(find.text('DUE NOW'), findsOneWidget);
  });
}
