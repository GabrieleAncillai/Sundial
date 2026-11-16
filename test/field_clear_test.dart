import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/core/widgets/sundial_date_field.dart';
import 'package:sundial/core/widgets/sundial_field_clear.dart';
import 'package:sundial/core/widgets/sundial_search_field.dart';
import 'package:sundial/theme/app_theme.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: SundialTheme.light,
    home: Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  );

  void expectInside(Rect field, Rect action) {
    expect(field.contains(action.topLeft), isTrue);
    expect(field.contains(action.bottomRight), isTrue);
  }

  testWidgets('a text input keeps its clear action inside the field', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var cleared = 0;
    await tester.pumpWidget(
      host(
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Title',
            suffixIcon: SundialTextClear(
              controller: controller,
              tooltip: 'Clear text',
              onCleared: () => cleared++,
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear text'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Dentist');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Clear text'), findsOneWidget);
    expectInside(tester.getRect(find.byType(TextField)), tester.getRect(find.byTooltip('Clear text')));

    await tester.tap(find.byTooltip('Clear text'));
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(cleared, 1);
    expect(find.byTooltip('Clear text'), findsNothing);
  });

  testWidgets('the search text input clears from inside the pill', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changed;
    await tester.pumpWidget(
      host(SundialSearchField(controller: controller, hint: 'Search', onChanged: (value) => changed = value)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'taxes');
    await tester.pumpAndSettle();
    final clear = find.byTooltip(
      MaterialLocalizations.of(tester.element(find.byType(TextField))).deleteButtonTooltip,
    );
    expect(clear, findsOneWidget);
    expectInside(tester.getRect(find.byType(SundialSearchField)), tester.getRect(clear));

    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(controller.text, isEmpty);
    expect(changed, '');
  });

  testWidgets('a date field keeps its clear action inside the field', (tester) async {
    var cleared = 0;
    var opened = 0;
    await tester.pumpWidget(
      host(
        SundialDateField(
          label: 'Ends on',
          valueLabel: 'November 17, 2026',
          onTap: () => opened++,
          onClear: () => cleared++,
          clearTooltip: 'Clear date',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectInside(tester.getRect(find.byType(InputDecorator)), tester.getRect(find.byTooltip('Clear date')));

    await tester.tap(find.byTooltip('Clear date'));
    await tester.pumpAndSettle();
    expect(cleared, 1);
    expect(opened, 0);
  });
}
