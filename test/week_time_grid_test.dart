import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mane/core/i18n/l10n.dart';
import 'package:mane/features/plan/widgets/week_time_grid.dart';
import 'package:mane/theme/app_theme.dart';
import 'package:mane_core/mane_core.dart';

void main() {
  setUpAll(initializeTimeZones);

  final weekStart = LocalDate.parse('2026-11-09');

  ShiftPattern pattern(String id, String name, int startMinute, int endMinute) => ShiftPattern(
    id: id,
    spaceId: 'work',
    name: name,
    timeZone: 'Europe/Madrid',
    cycleDays: 7,
    anchorDate: weekStart,
    slots: [ShiftSlot(dayIndex: 0, startMinute: startMinute, endMinute: endMinute)],
  );

  Widget host(List<ShiftOccurrence> shifts) => MaterialApp(
    theme: ManeTheme.light,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 980,
          height: 760,
          child: WeekTimeGrid(
            weekStart: weekStart,
            entries: const [],
            shifts: shifts,
            spaces: const [],
            contexts: const [],
            timeZone: 'Europe/Madrid',
            now: DateTime.utc(2026, 11, 9, 12),
            onOpen: (_) {},
            onCreate: (_, _, _) {},
            onMove: (_, _, _, _) {},
            onResize: (_, _) {},
          ),
        ),
      ),
    ),
  );

  testWidgets('overlapping shifts get side-by-side lanes in the week grid', (tester) async {
    final bank = pattern('banco', 'Banco', 9 * 60, 13 * 60);
    final pizza = pattern('pizza', 'Pizza', 12 * 60, 16 * 60);
    final shifts = [
      ...bank.occurrencesBetween(weekStart, weekStart, viewerTimeZone: 'Europe/Madrid'),
      ...pizza.occurrencesBetween(weekStart, weekStart, viewerTimeZone: 'Europe/Madrid'),
    ];

    await tester.pumpWidget(host(shifts));
    await tester.pumpAndSettle();

    final bankRect = tester.getRect(find.text('Banco'));
    final pizzaRect = tester.getRect(find.text('Pizza'));

    expect(bankRect.overlaps(pizzaRect), isFalse);
    expect(bankRect.width, greaterThan(20));
    expect(pizzaRect.width, greaterThan(20));
  });
}
