import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/settings/widgets/settings_rows.dart';
import 'package:sundial/theme/app_colors.dart';
import 'package:sundial/theme/app_theme.dart';

void main() {
  testWidgets('a highlighted section scrolls to the matching row and flashes it', (tester) async {
    tester.view.physicalSize = const Size(420, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: SundialTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                for (var index = 0; index < 12; index++) const SizedBox(height: 80),
                SettingsSection(
                  title: 'Preferences',
                  highlight: 'Quiet hours',
                  children: [
                    for (var index = 0; index < 8; index++)
                      SettingsSwitchRow(
                        icon: Icons.circle_outlined,
                        title: 'Row $index',
                        value: false,
                        onChanged: (_) {},
                      ),
                    SettingsSwitchRow(
                      icon: Icons.bedtime_outlined,
                      title: 'Quiet hours',
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(scroll.offset, greaterThan(0));
    final row = tester.getRect(find.text('Quiet hours'));
    expect(row.top, inInclusiveRange(0, 800));
    final flash = tester.widget<AnimatedContainer>(
      find.ancestor(of: find.text('Quiet hours'), matching: find.byType(AnimatedContainer)).first,
    );
    expect((flash.decoration as BoxDecoration?)?.color, SundialColors.light.accentSoft);
  });
}
