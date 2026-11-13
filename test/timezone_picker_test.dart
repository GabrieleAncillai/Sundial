import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/core/i18n/l10n.dart';
import 'package:mane/core/timezone/timezone_picker.dart';

void main() {
  Widget host({required ValueChanged<BuildContext> onOpen}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(onPressed: () => onOpen(context), child: const Text('open picker')),
        ),
      ),
    ),
  );

  Future<void> openPicker(WidgetTester tester, {required ValueChanged<BuildContext> onOpen}) async {
    await tester.pumpWidget(host(onOpen: onOpen));
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
  }

  testWidgets('searches zones and returns the tapped IANA id', (tester) async {
    String? picked;
    await openPicker(
      tester,
      onOpen: (context) {
        showTimeZonePicker(
          context,
          selected: 'Europe/Madrid',
          title: 'Time zone',
          searchHint: 'Search city or region',
          deviceLabel: 'Device time zone',
          deviceZone: 'Europe/Madrid',
        ).then((value) => picked = value);
      },
    );

    await tester.enterText(find.byType(TextField), 'Madrid');
    await tester.pumpAndSettle();

    final row = find.descendant(of: find.byType(ListView), matching: find.text('Madrid'));
    expect(row, findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(picked, 'Europe/Madrid');
  });

  testWidgets('device row returns an empty zone id', (tester) async {
    String? picked;
    await openPicker(
      tester,
      onOpen: (context) {
        showTimeZonePicker(
          context,
          selected: 'Europe/Madrid',
          title: 'Time zone',
          searchHint: 'Search city or region',
          deviceLabel: 'Device time zone',
          deviceZone: 'Europe/Madrid',
        ).then((value) => picked = value);
      },
    );

    await tester.tap(find.text('Device time zone'));
    await tester.pumpAndSettle();

    expect(picked, '');
  });
}
