import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/theme/aero_colors.dart';

/// Renders the three Aero 2.0 concept screens required before approval.
///
/// These are standalone compositions that use the approved-token candidate and
/// shared recipes from `docs/aero-2.md`. They do not import or restyle the app
/// screens, because the Aero direction is still a stop gate.
void main() {
  setUpAll(_loadFonts);

  testWidgets('render Aero 2.0 Today phone light', (tester) async {
    await _render(tester, 'aero2-today-phone-light.png', const Size(390, 844), 3, AeroColors.light);
  });

  testWidgets('render Aero 2.0 Plan desktop light', (tester) async {
    await _render(tester, 'aero2-plan-desktop-light.png', const Size(1280, 800), 2, AeroColors.light);
  });

  testWidgets('render Aero 2.0 Settings phone dark', (tester) async {
    await _render(tester, 'aero2-settings-phone-dark.png', const Size(390, 844), 3, AeroColors.dark);
  });
}

Future<void> _render(WidgetTester tester, String name, Size size, double dpr, AeroTokens tokens) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: _ConceptApp(tokens: tokens, width: size.width, height: size.height, name: name),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: dpr);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory('docs/screenshots')..createSync(recursive: true);
    File('${dir.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  await tester.pumpWidget(const SizedBox.shrink());
}

class _ConceptApp extends StatelessWidget {
  const _ConceptApp({required this.tokens, required this.width, required this.height, required this.name});

  final AeroTokens tokens;
  final double width;
  final double height;
  final String name;

  @override
  Widget build(BuildContext context) {
    final dark = identical(tokens, AeroColors.dark);
    final screen = switch (name) {
      'aero2-today-phone-light.png' => _TodayPhone(tokens: tokens),
      'aero2-plan-desktop-light.png' => _PlanDesktop(tokens: tokens),
      _ => _SettingsPhone(tokens: tokens),
    };
    return MediaQuery(
      data: MediaQueryData(size: Size(width, height), devicePixelRatio: 1),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: tokens.skyBottom,
          child: Theme(
            data: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
              fontFamily: 'Nunito',
              useMaterial3: true,
            ),
            child: DefaultTextStyle(style: _body(13, tokens.ink), child: screen),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared primitives

TextStyle _body(double size, Color color, {FontWeight weight = FontWeight.w500, double height = 1.3}) =>
    TextStyle(fontFamily: 'Nunito', fontSize: size, color: color, fontWeight: weight, height: height);

TextStyle _kicker(Color color) => _body(9.5, color, weight: FontWeight.w800).copyWith(letterSpacing: 1.4);

class _Sky extends StatelessWidget {
  const _Sky({required this.tokens, required this.child});

  final AeroTokens tokens;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: tokens.sky),
      child: Stack(
        children: [
          Positioned(
            left: -70,
            top: -40,
            child: _Bubble(size: 230, color: tokens.highlight.withValues(alpha: 0.55)),
          ),
          Positioned(
            right: 30,
            top: 120,
            child: _Bubble(size: 120, color: tokens.highlight.withValues(alpha: 0.32)),
          ),
          Positioned(
            left: 60,
            bottom: 90,
            child: _Bubble(size: 80, color: tokens.highlight.withValues(alpha: 0.22)),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)], stops: const [0.2, 1]),
      ),
    );
  }
}

class _PearlCard extends StatelessWidget {
  const _PearlCard({
    required this.tokens,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.radius = 20,
  });

  final AeroTokens tokens;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tokens.pearl, tokens.pearlAlt],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokens.glassEdge),
        boxShadow: [BoxShadow(color: tokens.shadow, blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({
    required this.tokens,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(12),
  });

  final AeroTokens tokens;
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tokens.glass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: tokens.glassEdge),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.tokens, required this.label, this.icon, this.selected = false});

  final AeroTokens tokens;
  final String label;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? tokens.accentSoft : tokens.pearlAlt;
    final fg = selected ? tokens.accent : tokens.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? tokens.accent : tokens.glassEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 5)],
          Text(label, style: _body(10.5, fg, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.tokens,
    required this.options,
    required this.selected,
    this.compact = false,
  });

  final AeroTokens tokens;
  final List<String> options;
  final int selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.pearlAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.glassEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < options.length; index++)
            Container(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18, vertical: compact ? 5 : 7),
              decoration: BoxDecoration(
                color: index == selected ? tokens.pearl : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: index == selected ? Border.all(color: tokens.accent) : null,
                boxShadow: index == selected
                    ? [BoxShadow(color: tokens.shadow, blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Text(
                options[index],
                style: _body(11.5, index == selected ? tokens.ink : tokens.inkMuted, weight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.tokens, required this.on});

  final AeroTokens tokens;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: on ? tokens.accentFill : tokens.pearlAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? tokens.accentFill : tokens.inkMuted),
      ),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: on ? tokens.onAccentFill : tokens.inkMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.tokens, required this.done});

  final AeroTokens tokens;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: done ? tokens.accentFill : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: done ? tokens.accentFill : tokens.inkMuted, width: 1.6),
      ),
      child: done ? Icon(Icons.check, size: 14, color: tokens.onAccentFill) : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Today, phone, light

class _TodayPhone extends StatelessWidget {
  const _TodayPhone({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _Sky(
      tokens: tokens,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('9:41', style: _body(11, tokens.ink, weight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.signal_cellular_alt, size: 13, color: tokens.ink),
                const SizedBox(width: 4),
                Icon(Icons.wifi, size: 13, color: tokens.ink),
                const SizedBox(width: 4),
                Icon(Icons.battery_full, size: 13, color: tokens.ink),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MONDAY, 9 NOVEMBER', style: _kicker(tokens.accent)),
                      const SizedBox(height: 2),
                      Text('Today', style: _body(31, tokens.ink, weight: FontWeight.w800, height: 1.05)),
                    ],
                  ),
                ),
                Icon(Icons.search, size: 21, color: tokens.ink),
                const SizedBox(width: 14),
                Icon(Icons.settings_outlined, size: 20, color: tokens.ink),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Segmented(tokens: tokens, options: const ['List', 'Timeline'], selected: 0, compact: true),
                const Spacer(),
                _Pill(tokens: tokens, label: '2 done', icon: Icons.check_circle_outline),
              ],
            ),
            const SizedBox(height: 12),
            _Glass(
              tokens: tokens,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: tokens.accentSoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.work_outline, size: 17, color: tokens.accent),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next shift · The Pizzeria',
                          style: _body(12, tokens.ink, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 1),
                        Text('15:00 – 23:00 · Floor', style: _body(10.5, tokens.inkMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('WORK', style: _kicker(tokens.inkMuted)),
            const SizedBox(height: 7),
            _TaskCard(
              tokens: tokens,
              title: 'Prep the dough',
              time: '08:00 – 10:00',
              chips: const [(Icons.storefront_outlined, 'The Pizzeria'), (Icons.flag_outlined, 'High')],
            ),
            const SizedBox(height: 8),
            _TaskCard(
              tokens: tokens,
              title: 'Team standup',
              time: '10:00 – 10:30',
              done: true,
              chips: const [(Icons.rocket_launch_outlined, 'Website relaunch')],
            ),
            const SizedBox(height: 14),
            Text('PERSONAL', style: _kicker(tokens.inkMuted)),
            const SizedBox(height: 7),
            _TaskCard(
              tokens: tokens,
              title: 'Call the dentist',
              time: 'Anytime today',
              chips: const [(Icons.group_outlined, 'Family')],
            ),
            const Spacer(),
            _BottomBar(tokens: tokens),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.tokens,
    required this.title,
    required this.time,
    required this.chips,
    this.done = false,
  });

  final AeroTokens tokens;
  final String title;
  final String time;
  final List<(IconData, String)> chips;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return _PearlCard(
      tokens: tokens,
      padding: const EdgeInsets.fromLTRB(13, 11, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: _Check(tokens: tokens, done: done),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _body(
                    13.5,
                    done ? tokens.inkMuted : tokens.ink,
                    weight: FontWeight.w700,
                  ).copyWith(decoration: done ? TextDecoration.lineThrough : null),
                ),
                const SizedBox(height: 2),
                Text(time, style: _body(10.5, tokens.inkMuted)),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final chip in chips)
                      _Pill(tokens: tokens, icon: chip.$1, label: chip.$2, selected: true),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.more_horiz, size: 17, color: tokens.inkMuted),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.today_outlined, 'Today', true),
      (Icons.work_outline, 'Work', false),
      (Icons.home_outlined, 'Home', false),
      (Icons.person_outline, 'Personal', false),
      (Icons.calendar_month_outlined, 'Plan', false),
      (Icons.bar_chart_outlined, 'Stats', false),
    ];
    return Transform.translate(
      offset: const Offset(0, 10),
      child: _Glass(
        tokens: tokens,
        radius: 26,
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 12),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.$3 ? tokens.accentSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: item.$3 ? Border.all(color: tokens.accent) : null,
                      ),
                      child: Icon(item.$1, size: 17, color: item.$3 ? tokens.accent : tokens.inkMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.$2,
                      style: _body(8, item.$3 ? tokens.accent : tokens.inkMuted, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan, desktop, light

class _PlanDesktop extends StatelessWidget {
  const _PlanDesktop({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _Sky(
      tokens: tokens,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            SizedBox(width: 226, child: _Rail(tokens: tokens)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOVEMBER 2026', style: _kicker(tokens.accent)),
                          const SizedBox(height: 2),
                          Text('Plan', style: _body(29, tokens.ink, weight: FontWeight.w800, height: 1.05)),
                        ],
                      ),
                      const Spacer(),
                      _Segmented(tokens: tokens, options: const ['Month', 'Week'], selected: 1),
                      const SizedBox(width: 10),
                      _Pill(tokens: tokens, label: 'Today', icon: Icons.today_outlined, selected: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MonthStrip(tokens: tokens),
                  const SizedBox(height: 12),
                  Expanded(child: _WeekGrid(tokens: tokens)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.today_outlined, 'Today', true),
      (Icons.work_outline, 'Work', false),
      (Icons.home_outlined, 'Home', false),
      (Icons.person_outline, 'Personal', false),
      (Icons.calendar_month_outlined, 'Plan', false),
      (Icons.bar_chart_outlined, 'Stats', false),
    ];
    return _Glass(
      tokens: tokens,
      radius: 26,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [tokens.accent, tokens.accentFill]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.pets, size: 17, color: tokens.onAccentFill),
              ),
              const SizedBox(width: 9),
              Text('Mane', style: _body(17, tokens.ink, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: tokens.pearl,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.accent),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: tokens.inkMuted),
                const SizedBox(width: 8),
                Text('Search', style: _body(12, tokens.inkMuted)),
                const Spacer(),
                Icon(Icons.tune, size: 14, color: tokens.accent),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _Pill(tokens: tokens, label: 'Filters · 2', selected: true),
              _Pill(tokens: tokens, label: 'The Pizzeria'),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: item.$3 ? tokens.accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: item.$3 ? Border.all(color: tokens.accent) : null,
              ),
              child: Row(
                children: [
                  Icon(item.$1, size: 17, color: item.$3 ? tokens.accent : tokens.inkMuted),
                  const SizedBox(width: 10),
                  Text(
                    item.$2,
                    style: _body(
                      12.5,
                      item.$3 ? tokens.accent : tokens.ink,
                      weight: item.$3 ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          const Divider(color: Color(0x33000000), height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 17, color: tokens.inkMuted),
                const SizedBox(width: 10),
                Text('Settings', style: _body(12.5, tokens.ink, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    const days = [
      ('M', '9', true),
      ('T', '10', false),
      ('W', '11', false),
      ('T', '12', false),
      ('F', '13', false),
      ('S', '14', false),
      ('S', '15', false),
    ];
    return _PearlCard(
      tokens: tokens,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      radius: 18,
      child: Row(
        children: [
          for (final day in days)
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(day.$1, style: _body(9, tokens.inkMuted, weight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: day.$3 ? tokens.accentFill : Colors.transparent,
                        shape: BoxShape.circle,
                        border: day.$3 ? null : Border.all(color: tokens.glassEdge),
                      ),
                      child: Text(
                        day.$2,
                        style: _body(
                          11.5,
                          day.$3 ? tokens.onAccentFill : tokens.ink,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon 9', 'Tue 10', 'Wed 11', 'Thu 12', 'Fri 13', 'Sat 14', 'Sun 15'];
    const hourHeight = 52.0;
    const startHour = 8;
    const hours = 10;

    return _PearlCard(
      tokens: tokens,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      radius: 20,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 46),
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: Center(
                    child: Text(
                      days[index],
                      style: _body(10, index == 0 ? tokens.accent : tokens.inkMuted, weight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // All-day row shares the time gutter so chips line up with columns.
          Row(
            children: [
              SizedBox(
                width: 46,
                child: Text('All day', style: _body(8.5, tokens.inkMuted, weight: FontWeight.w700)),
              ),
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: Container(
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index == 5 ? tokens.accentSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: index == 5
                        ? Text('Market', style: _body(8, tokens.accent, weight: FontWeight.w700))
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 46,
                  height: hourHeight * hours,
                  child: Stack(
                    children: [
                      for (var hour = 0; hour < hours; hour++)
                        Positioned(
                          top: hour == 0 ? 2 : hour * hourHeight - 5,
                          right: 6,
                          child: Text(
                            '${startHour + hour}:00',
                            style: _body(8.5, tokens.inkMuted, weight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var index = 0; index < days.length; index++)
                  Expanded(
                    child: _DayColumn(tokens: tokens, index: index, hourHeight: hourHeight, hours: hours),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.tokens,
    required this.index,
    required this.hourHeight,
    required this.hours,
  });

  final AeroTokens tokens;
  final int index;
  final double hourHeight;
  final int hours;

  @override
  Widget build(BuildContext context) {
    final blocks = switch (index) {
      0 => const [_Block(9, 11, 'Prep', _BlockKind.task)],
      1 => const [_Block(10, 10.5, 'Standup', _BlockKind.done), _Block(14, 16, 'Review', _BlockKind.task)],
      2 => const [_Block(15, 18, 'Pizzeria shift', _BlockKind.shift)],
      3 => const [_Block(9, 12, 'Relaunch', _BlockKind.task)],
      _ => const [],
    };
    final minuteOfDay = 10.5;
    return Container(
      height: hourHeight * hours,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0x22000000))),
      ),
      child: Stack(
        children: [
          for (var hour = 0; hour < hours; hour++)
            Positioned(
              top: hour * hourHeight,
              left: 0,
              right: 0,
              child: Container(height: 1, color: const Color(0x18000000)),
            ),
          for (final block in blocks)
            Positioned(
              top: (block.start - 8) * hourHeight + 2,
              left: 3,
              right: 3,
              height: (block.end - block.start) * hourHeight - 4,
              child: _EventBlock(tokens: tokens, block: block),
            ),
          if (index == 0)
            Positioned(
              top: (minuteOfDay - 8) * hourHeight,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: tokens.coral, shape: BoxShape.circle),
                  ),
                  Expanded(child: Container(height: 1.4, color: tokens.coral)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

enum _BlockKind { task, done, shift }

class _Block {
  const _Block(this.start, this.end, this.label, this.kind);

  final double start;
  final double end;
  final String label;
  final _BlockKind kind;
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({required this.tokens, required this.block});

  final AeroTokens tokens;
  final _Block block;

  @override
  Widget build(BuildContext context) {
    final shift = block.kind == _BlockKind.shift;
    final done = block.kind == _BlockKind.done;
    final fill = shift
        ? tokens.accent.withValues(alpha: 0.14)
        : done
        ? tokens.pearlAlt
        : tokens.accentSoft;
    final text = shift
        ? tokens.inkMuted
        : done
        ? tokens.inkMuted
        : tokens.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
        border: shift ? null : Border.all(color: tokens.accent.withValues(alpha: 0.7)),
        // The single gloss highlight on an event block.
        gradient: shift
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withValues(alpha: 0.28), Colors.white.withValues(alpha: 0)],
              ),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          block.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _body(
            shift ? 8.5 : 9.5,
            text,
            weight: shift ? FontWeight.w600 : FontWeight.w800,
            height: 1.15,
          ).copyWith(decoration: done ? TextDecoration.lineThrough : null),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings, phone, dark

class _SettingsPhone extends StatelessWidget {
  const _SettingsPhone({required this.tokens});

  final AeroTokens tokens;

  @override
  Widget build(BuildContext context) {
    return _Sky(
      tokens: tokens,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('9:41', style: _body(11, tokens.ink, weight: FontWeight.w800)),
                const Spacer(),
                Icon(Icons.signal_cellular_alt, size: 13, color: tokens.ink),
                const SizedBox(width: 4),
                Icon(Icons.wifi, size: 13, color: tokens.ink),
                const SizedBox(width: 4),
                Icon(Icons.battery_full, size: 13, color: tokens.ink),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.arrow_back, size: 20, color: tokens.ink),
                const SizedBox(width: 12),
                Text('Settings', style: _body(24, tokens.ink, weight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.pearl,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.glassEdge),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16, color: tokens.inkMuted),
                  const SizedBox(width: 8),
                  Text('Search settings', style: _body(12, tokens.inkMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('ONLINE', style: _kicker(tokens.inkMuted)),
            const SizedBox(height: 6),
            _PearlCard(
              tokens: tokens,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.public,
                    title: 'Enable online functionalities',
                    subtitle: 'Devices, sync and the local MCP server',
                    trailing: _Switch(tokens: tokens, on: true),
                  ),
                  Divider(height: 1, indent: 52, color: tokens.glassEdge),
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.devices_other,
                    title: 'Devices & Sync',
                    subtitle: '2 paired devices',
                    trailing: Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                  ),
                  Divider(height: 1, indent: 52, color: tokens.glassEdge),
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.terminal,
                    title: 'MCP Server',
                    subtitle: 'Loopback · port 4719',
                    trailing: Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('APPEARANCE', style: _kicker(tokens.inkMuted)),
            const SizedBox(height: 6),
            _PearlCard(
              tokens: tokens,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 17, color: tokens.accent),
                      const SizedBox(width: 10),
                      Text('Theme', style: _body(13, tokens.ink, weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Segmented(
                    tokens: tokens,
                    options: const ['System', 'Light', 'Dark', 'Aero'],
                    selected: 3,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _PearlCard(
              tokens: tokens,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.wallpaper_outlined,
                    title: 'Background',
                    subtitle: 'Dots · soft sky',
                    trailing: Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                  ),
                  Divider(height: 1, indent: 52, color: tokens.glassEdge),
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.format_size,
                    title: 'Text size',
                    subtitle: 'Default',
                    trailing: Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('PREFERENCES', style: _kicker(tokens.inkMuted)),
            const SizedBox(height: 6),
            _PearlCard(
              tokens: tokens,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.volume_up_outlined,
                    title: 'Interaction sounds',
                    subtitle: 'Soft pack · off by default',
                    trailing: _Switch(tokens: tokens, on: false),
                  ),
                  Divider(height: 1, indent: 52, color: tokens.glassEdge),
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'English',
                    trailing: Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                  ),
                  Divider(height: 1, indent: 52, color: tokens.glassEdge),
                  _SettingsRow(
                    tokens: tokens,
                    icon: Icons.public,
                    title: 'Time zone',
                    subtitle: 'Europe/Madrid · UTC+1',
                    trailing: Icon(Icons.chevron_right, size: 18, color: tokens.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.tokens,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final AeroTokens tokens;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: tokens.accentSoft, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: tokens.accent),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _body(12.5, tokens.ink, weight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(subtitle, style: _body(10, tokens.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

Future<void> _loadFonts() async {
  final materialFont = _locateMaterialFont();
  if (materialFont != null) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(materialFont.readAsBytesSync())));
    await icons.load();
  }
  final loader = FontLoader('Nunito');
  for (final file in [
    'Nunito-Regular.ttf',
    'Nunito-Italic.ttf',
    'Nunito-Medium.ttf',
    'Nunito-SemiBold.ttf',
    'Nunito-SemiBoldItalic.ttf',
    'Nunito-Bold.ttf',
    'Nunito-ExtraBold.ttf',
    'Nunito-Black.ttf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

File? _locateMaterialFont() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 10; i++) {
    for (final candidate in [
      File('${dir.path}/artifacts/material_fonts/MaterialIcons-Regular.otf'),
      File('${dir.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'),
      File('${dir.path}/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'),
    ]) {
      if (candidate.existsSync()) return candidate;
    }
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}
