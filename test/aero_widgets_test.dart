import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/settings_scope.dart';
import 'package:sundial/core/widgets/soft_card.dart';
import 'package:sundial/models/app_settings.dart';
import 'package:sundial/theme/app_colors.dart';
import 'package:sundial/theme/app_theme.dart';

Widget _host({required Widget child, AppSettings? settings}) {
  final theme = settings == null ? SundialTheme.light : SundialTheme.forSettings(settings, Brightness.light);
  final app = MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  );
  if (settings == null) return app;
  return AppSettingsScope(settings: settings, child: app);
}

BoxDecoration _cardDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(of: find.byType(SoftCard), matching: find.byType(Container)),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('an aero SoftCard paints a gradient, gloss and glow', (tester) async {
    const settings = AppSettings(themeVariant: SundialThemeVariant.aero);
    await tester.pumpWidget(
      _host(
        settings: settings,
        child: const SoftCard(child: Text('Aero')),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(SoftCard), matching: find.byType(Container)),
    );
    final decoration = _cardDecoration(tester);
    expect(decoration.gradient, isA<LinearGradient>());
    expect(decoration.color, isNull);
    expect(decoration.border, isNotNull);
    expect(decoration.boxShadow, isNotEmpty);
    expect(container.foregroundDecoration, isA<BoxDecoration>());
    expect((container.foregroundDecoration! as BoxDecoration).gradient, isA<LinearGradient>());
  });

  testWidgets('aero with performance mode keeps the gradient but drops gloss and glow', (tester) async {
    const settings = AppSettings(themeVariant: SundialThemeVariant.aero, performanceMode: true);
    await tester.pumpWidget(
      _host(
        settings: settings,
        child: const SoftCard(child: Text('Lean')),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(SoftCard), matching: find.byType(Container)),
    );
    final decoration = _cardDecoration(tester);
    expect(decoration.gradient, isA<LinearGradient>());
    expect(decoration.boxShadow, isNull);
    expect(container.foregroundDecoration, isNull);
  });

  testWidgets('a default SoftCard stays a flat surface', (tester) async {
    await tester.pumpWidget(_host(child: const SoftCard(child: Text('Plain'))));

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(SoftCard), matching: find.byType(Container)),
    );
    final decoration = _cardDecoration(tester);
    expect(decoration.gradient, isNull);
    expect(decoration.color, SundialColors.light.surface);
    expect(container.foregroundDecoration, isNull);
  });
}
