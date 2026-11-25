import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/icons/aero_glyph.dart';
import 'package:sundial/core/layout/sundial_layout.dart';
import 'package:sundial/core/widgets/ui_kit.dart';
import 'package:sundial/theme/app_colors.dart';
import 'package:sundial/theme/app_radii.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial/theme/sundial_style.dart';

void main() {
  testWidgets('the theme carries Sundial tokens, Nunito and component shapes', (tester) async {
    final theme = SundialTheme.light;
    final colors = theme.extension<SundialColors>();

    expect(colors, isNotNull);
    expect(colors!.accent, SundialColors.light.accent);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Nunito');
    expect(theme.textTheme.displayLarge?.fontWeight, FontWeight.w800);
    expect(theme.appBarTheme.backgroundColor, Colors.transparent);
    expect(theme.snackBarTheme.behavior, SnackBarBehavior.floating);
    expect(theme.filledButtonTheme.style?.shape?.resolve({}), isA<StadiumBorder>());
    // Sheets and cards follow the icon's continuous-corner silhouette.
    expect(theme.bottomSheetTheme.shape, isA<RoundedSuperellipseBorder>());
    expect(theme.cardTheme.shape, isA<RoundedSuperellipseBorder>());
    expect(theme.dialogTheme.shape, isA<RoundedSuperellipseBorder>());
    expect(
      (theme.cardTheme.shape! as RoundedSuperellipseBorder).borderRadius,
      BorderRadius.circular(SundialRadii.lg),
    );
    expect(theme.cardTheme.color, SundialColors.light.surface);
  });

  testWidgets('the app logo uses the shipped launcher artwork for its style', (tester) async {
    Future<String> assetFor(SundialVisualStyle style) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SundialTheme.forStyle(style, Brightness.dark),
          home: const Scaffold(body: Center(child: SundialLogo())),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image));
      return (image.image as AssetImage).assetName;
    }

    expect(await assetFor(SundialVisualStyle.classic), 'assets/icons/icon_classic.png');
    expect(await assetFor(SundialVisualStyle.aero), 'assets/icons/icon_aero.png');
  });

  testWidgets('the shared kit renders and responds', (tester) async {
    var taps = 0;
    var toggled = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SectionLabel('Today'),
                SoftCard(
                  child: Pressable(onTap: () => setState(() => taps++), child: const Text('Pressable row')),
                ),
                TinySwitch(
                  value: toggled,
                  onChanged: (value) => setState(() => toggled = value),
                  semanticLabel: 'Quiet hours',
                ),
                const AppEmptyState(icon: Icons.event_note, title: 'Nothing planned', compact: true),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('TODAY'), findsOneWidget);
    expect(find.byType(SoftCard), findsOneWidget);
    expect(find.text('Nothing planned'), findsOneWidget);

    await tester.tap(find.text('Pressable row'));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.tap(find.bySemanticsLabel('Quiet hours'));
    await tester.pumpAndSettle();
    expect(toggled, isTrue);
  });

  testWidgets('the shared sidebar keeps one width and selected treatment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.forStyle(SundialVisualStyle.aero, Brightness.dark),
        home: Scaffold(
          body: Row(
            children: [
              SundialSidebar(
                child: ListView(
                  children: [
                    SundialSidebarItem(
                      icon: Icons.today_outlined,
                      selectedIcon: Icons.today,
                      title: 'Today',
                      selected: true,
                      onTap: () {},
                    ),
                    SundialSidebarItem(icon: Icons.settings_outlined, title: 'Settings', onTap: () {}),
                  ],
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );

    final surface = tester.getRect(find.byType(GlassSurface));
    expect(surface.left, 12);
    expect(surface.width, kSidebarWidth);

    final style = tester.element(find.byType(SundialSidebar)).style;
    final selected = tester.widget<AnimatedContainer>(
      find.ancestor(of: find.text('Today'), matching: find.byType(AnimatedContainer)),
    );
    final decoration = selected.decoration! as BoxDecoration;
    expect(decoration.gradient, style.selectedGradient);
    expect(decoration.borderRadius, BorderRadius.circular(SundialRadii.md));
    expect(selected.foregroundDecoration, isNotNull);

    final unselected = tester.widget<AnimatedContainer>(
      find.ancestor(of: find.text('Settings'), matching: find.byType(AnimatedContainer)),
    );
    expect((unselected.decoration! as BoxDecoration).gradient, isNull);
  });

  testWidgets('a search action stays inside the field frame', (tester) async {
    var taps = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.forStyle(SundialVisualStyle.aero, Brightness.dark),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SundialSearchField(
                controller: controller,
                hint: 'Search',
                onChanged: (_) {},
                trailing: SundialSearchAction(
                  icon: Icons.filter_alt_outlined,
                  tooltip: 'Filter by tag',
                  selected: true,
                  onTap: () => taps++,
                  badge: const Text('2'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final field = tester.getRect(find.byType(SundialSearchField));
    final action = tester.getRect(find.byType(SundialSearchAction));
    expect(field.contains(action.center), isTrue);
    expect(find.text('2'), findsOneWidget);

    final container = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(SundialSearchAction), matching: find.byType(AnimatedContainer)),
    );
    expect((container.decoration! as BoxDecoration).gradient, isNotNull);

    await tester.tap(find.byTooltip('Filter by tag'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('page bodies centre in the reading column on wide windows', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.light,
        home: const Scaffold(
          body: SundialContentPane(child: SizedBox.expand(key: Key('pane-body'))),
        ),
      ),
    );

    final box = tester.getRect(find.byKey(const Key('pane-body')));
    expect(box.width, kContentMaxWidth);
    expect(box.center.dx, 800);
    expect(box.height, 900);

    tester.view.physicalSize = const Size(500, 800);
    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.light,
        home: const Scaffold(
          body: SundialContentPane(child: SizedBox.expand(key: Key('pane-body'))),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('pane-body'))).width, 500);
  });

  testWidgets('the floating nav reports the selected destination', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.light,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.bottomCenter,
              child: SundialNavBar(
                index: selected,
                onSelected: (value) => setState(() => selected = value),
                items: const [
                  (icon: Icons.today_outlined, selectedIcon: Icons.today, label: 'Today'),
                  (
                    icon: Icons.calendar_view_week_outlined,
                    selectedIcon: Icons.calendar_view_week,
                    label: 'Week',
                  ),
                  (
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month,
                    label: 'Calendar',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('the selected lens stays inside the floating shelf on a phone', (tester) async {
    const items = <SundialNavItem>[
      (icon: Icons.today_outlined, selectedIcon: Icons.today, label: 'Today'),
      (icon: Icons.work_outline, selectedIcon: Icons.work, label: 'Work'),
      (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
      (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Personal'),
      (icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Plan'),
      (icon: Icons.insights_outlined, selectedIcon: Icons.insights, label: 'Stats'),
    ];
    Widget host(int index) => MaterialApp(
      theme: SundialTheme.forStyle(SundialVisualStyle.aero, Brightness.dark),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 344,
            height: SundialNavBar.height,
            child: SundialNavBar(index: index, onSelected: (_) {}, items: items),
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(0));
    final bar = tester.getRect(find.byType(SundialNavBar));
    final first = tester.getRect(find.byKey(const ValueKey('nav-selected-lens')));
    expect(first.left - bar.left, closeTo(SundialNavBar.shelfPadding, 0.01));
    expect(first.top - bar.top, closeTo(6, 0.01));
    expect(bar.bottom - first.bottom, closeTo(6, 0.01));

    await tester.pumpWidget(host(items.length - 1));
    await tester.pumpAndSettle();
    final last = tester.getRect(find.byKey(const ValueKey('nav-selected-lens')));
    expect(bar.right - last.right, closeTo(SundialNavBar.shelfPadding, 0.01));
  });

  testWidgets('a pushed page uses the custom header, not an AppBar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.light,
        home: const SundialPage(title: 'Tags', subtitle: 'Jobs and people', child: Text('Body')),
      ),
    );

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Tags'), findsOneWidget);
    expect(find.text('Jobs and people'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('a sheet opens with the reference handle and title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SundialTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAppSheet<void>(
                  context: context,
                  builder: (context) =>
                      const AppSheet(title: 'Reminders', children: [Text('At the start time')]),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(SheetHandle), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('At the start time'), findsOneWidget);
  });
}
