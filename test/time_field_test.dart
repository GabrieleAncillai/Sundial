import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/core/i18n/l10n.dart';
import 'package:mane/core/time/time_field.dart';
import 'package:mane/theme/app_theme.dart';

void main() {
  group('parseTimeInput', () {
    test('accepts 24-hour, compact and 12-hour forms', () {
      expect(parseTimeInput('0:00', use24Hour: true), 0);
      expect(parseTimeInput('9', use24Hour: true), 9 * 60);
      expect(parseTimeInput('9:30', use24Hour: true), 9 * 60 + 30);
      expect(parseTimeInput('0930', use24Hour: true), 9 * 60 + 30);
      expect(parseTimeInput('21:15', use24Hour: true), 21 * 60 + 15);
      expect(parseTimeInput('7:5', use24Hour: true), 7 * 60 + 5);
      expect(parseTimeInput('9:30 pm', use24Hour: false), 21 * 60 + 30);
      expect(parseTimeInput('9.30pm', use24Hour: false), 21 * 60 + 30);
      expect(parseTimeInput('12:00 am', use24Hour: false), 0);
      expect(parseTimeInput('12:00 pm', use24Hour: false), 12 * 60);
    });

    test('rejects impossible or ambiguous input', () {
      expect(parseTimeInput('', use24Hour: true), isNull);
      expect(parseTimeInput('abc', use24Hour: true), isNull);
      expect(parseTimeInput('25:00', use24Hour: true), isNull);
      expect(parseTimeInput('9:60', use24Hour: true), isNull);
      expect(parseTimeInput('13:00 pm', use24Hour: false), isNull);
      expect(parseTimeInput('9:30:15', use24Hour: true), isNull);
      expect(parseTimeInput('12345', use24Hour: true), isNull);
    });
  });

  group('formatTimeInput', () {
    test('round-trips through the parser', () {
      for (final minute in const [0, 1, 7 * 60, 12 * 60, 13 * 60 + 45, 23 * 60 + 59]) {
        expect(parseTimeInput(formatTimeInput(minute, use24Hour: true), use24Hour: true), minute);
        expect(parseTimeInput(formatTimeInput(minute, use24Hour: false), use24Hour: false), minute);
      }
    });
  });

  testWidgets('desktop picker focuses the input and selects the value', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ManeTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showManeTimePicker(context, initialMinute: 9 * 60, title: 'Starts'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    expect(editable.controller.selection.baseOffset, 0);
    expect(editable.controller.selection.extentOffset, editable.controller.text.length);
  });

  testWidgets('desktop picker accepts a typed time', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    int? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ManeTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showManeTimePicker(context, initialMinute: 9 * 60, title: 'Starts');
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Starts'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '14:45');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(result, 14 * 60 + 45);
  });

  testWidgets('desktop picker reports invalid input instead of closing', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ManeTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showManeTimePicker(context, initialMinute: 9 * 60),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nonsense');
    await tester.tap(find.text('Set'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a time like 9:30 or 21:30.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
