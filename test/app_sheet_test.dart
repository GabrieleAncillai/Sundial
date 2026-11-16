import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/core/widgets/app_sheet.dart';
import 'package:sundial/core/widgets/sundial_select_field.dart';
import 'package:sundial/theme/app_theme.dart';

void main() {
  Widget host(Future<void> Function(BuildContext context) onOpen) => MaterialApp(
    theme: SundialTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(onPressed: () => onOpen(context), child: const Text('Open')),
        ),
      ),
    ),
  );

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('narrow hosts keep the bottom-sheet layout', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        (context) => showAppSheet<void>(
          context: context,
          builder: (_) => const AppSheet(title: 'Reminders', children: [Text('At the start time')]),
        ),
      ),
    );
    await openSheet(tester);

    expect(find.byKey(const ValueKey('app-sheet-compact')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-sheet-wide')), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(SheetHandle), findsOneWidget);

    final rect = tester.getRect(find.byKey(const ValueKey('app-sheet-compact')));
    expect(rect.bottom, closeTo(800, 0.5));
    expect(rect.width, lessThanOrEqualTo(390));
  });

  testWidgets('wide hosts get the floating dialog layout', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      host(
        (context) => showAppSheet<void>(
          context: context,
          builder: (_) => const AppSheet(title: 'Reminders', children: [Text('At the start time')]),
        ),
      ),
    );
    await openSheet(tester);

    expect(find.byKey(const ValueKey('app-sheet-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('app-sheet-compact')), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(SheetHandle), findsNothing);

    final rect = tester.getRect(find.byKey(const ValueKey('app-sheet-wide')));
    expect(rect.width, lessThanOrEqualTo(660));
    expect(rect.height, lessThanOrEqualTo(780));
    expect(rect.center.dx, closeTo(640, 0.5));
    expect(rect.center.dy, closeTo(450, 0.5));
  });

  testWidgets('wide dialogs dismiss from the blurred backdrop', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var closed = false;
    await tester.pumpWidget(
      host((context) async {
        await showAppSheet<void>(
          context: context,
          builder: (_) => const AppSheet(title: 'Reminders', children: [Text('At the start time')]),
        );
        closed = true;
      }),
    );
    await openSheet(tester);
    expect(find.byKey(const ValueKey('app-sheet-wide')), findsOneWidget);

    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(find.byKey(const ValueKey('app-sheet-wide')), findsNothing);
  });

  testWidgets('select sheet filters options and returns the tapped value', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int? picked;
    await tester.pumpWidget(
      host((context) async {
        picked = await showSundialSelectSheet<int>(
          context: context,
          title: 'Space',
          searchHint: 'Search spaces',
          selected: 1,
          options: const [
            SundialSelectOption(value: 1, label: 'Personal'),
            SundialSelectOption(value: 2, label: 'Work'),
            SundialSelectOption(value: 3, label: 'Home'),
          ],
        );
      }),
    );
    await openSheet(tester);

    expect(find.byKey(const ValueKey('sundial-select-sheet')), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'wor');
    await tester.pumpAndSettle();

    expect(find.text('Personal'), findsNothing);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(picked, 2);
    expect(find.byKey(const ValueKey('sundial-select-sheet')), findsNothing);
  });
}
