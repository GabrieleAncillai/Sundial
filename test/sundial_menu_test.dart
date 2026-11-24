import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/widgets/ui_kit.dart';
import 'package:sundial/models/visual_style.dart';
import 'package:sundial/theme/app_colors.dart';
import 'package:sundial/theme/app_theme.dart';

void main() {
  Widget host(
    ThemeData theme, {
    required List<SundialMenuAction<String>> actions,
    required ValueChanged<String> onSelected,
  }) {
    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: SundialMenuButton<String>(
            headerTitle: 'Milk',
            headerCaption: '2 bottles',
            onSelected: onSelected,
            actions: actions,
          ),
        ),
      ),
    );
  }

  testWidgets('the menu shows its context header, icons, a section divider and danger styling', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        SundialTheme.forStyle(SundialVisualStyle.classic, Brightness.light),
        onSelected: (value) => selected = value,
        actions: const [
          SundialMenuAction(value: 'edit', label: 'Edit', icon: Icons.edit_outlined),
          SundialMenuAction(
            value: 'delete',
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            destructive: true,
            dividerBefore: true,
          ),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2 bottles'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsOneWidget);

    final deleteLabel = tester.widget<Text>(find.text('Delete'));
    expect(deleteLabel.style?.color, SundialColors.light.danger);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(selected, 'delete');
  });

  testWidgets('an optional first action does not leave a leading divider', (tester) async {
    await tester.pumpWidget(
      host(
        SundialTheme.light,
        onSelected: (_) {},
        actions: const [
          SundialMenuAction(
            value: 'delete',
            label: 'Delete',
            icon: Icons.delete_outline,
            dividerBefore: true,
          ),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(find.byType(PopupMenuDivider), findsNothing);
  });

  testWidgets('a selected action carries a checkmark', (tester) async {
    await tester.pumpWidget(
      host(
        SundialTheme.light,
        onSelected: (_) {},
        actions: const [
          SundialMenuAction(value: 'week', label: 'Week', icon: Icons.calendar_view_week, selected: true),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Week'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('a disabled action stays visible but cannot be chosen', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        SundialTheme.light,
        onSelected: (value) => selected = value,
        actions: const [
          SundialMenuAction(value: 'archive', label: 'Archive', icon: Icons.archive_outlined, enabled: false),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });

  testWidgets('the menu opens and selects in Aero', (tester) async {
    String? selected;
    await tester.pumpWidget(
      host(
        SundialTheme.forStyle(SundialVisualStyle.aero, Brightness.dark),
        onSelected: (value) => selected = value,
        actions: const [SundialMenuAction(value: 'edit', label: 'Edit', icon: Icons.edit_outlined)],
      ),
    );

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(selected, 'edit');
  });
}
