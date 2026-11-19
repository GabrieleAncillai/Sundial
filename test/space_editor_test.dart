import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/spaces/widgets/context_editor.dart';
import 'package:sundial/features/spaces/widgets/space_controls.dart';
import 'package:sundial/features/tags/tag_colors.dart';
import 'package:sundial/theme/app_theme.dart';

void main() {
  test('the appearance palettes offer at least thirty distinct colours', () {
    expect(spacePalette.toSet().length, greaterThanOrEqualTo(30));
    expect(tagPalette.toSet().length, greaterThanOrEqualTo(30));
  });

  testWidgets('the context avatar opens the icon picker', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: SundialTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showContextEditor(
                    context,
                    spaceId: 'home',
                    title: 'New home',
                    recommendedIcons: const ['home', 'house'],
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Choose an icon'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Choose an icon'));
    await tester.pumpAndSettle();

    expect(find.text('Choose an icon'), findsOneWidget);
    expect(find.text('Search icons'), findsOneWidget);
  });
}
