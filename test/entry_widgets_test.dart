import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial/widgets/entry_widgets.dart';
import 'package:sundial/state/providers.dart';
import 'package:sundial_core/sundial_core.dart';

void main() {
  setUpAll(initializeTimeZones);

  final createdAt = DateTime.utc(2026, 11, 1, 8);
  final monday = LocalDate.parse('2026-11-09');
  const spaces = <Space>[Space(id: 'work', name: 'Work', colorValue: 0xFF4A6FA5)];

  Widget host(Widget child, {String timeZone = 'Europe/Madrid'}) => ProviderScope(
    overrides: [deviceTimeZoneProvider.overrideWith(() => DeviceTimeZoneController(initial: timeZone))],
    child: MaterialApp(
      theme: SundialTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('a timed entry renders in the viewer timezone', (tester) async {
    final entry = Entry(
      id: 'late',
      spaceId: 'work',
      title: 'Late shift',
      date: monday,
      startMinute: 23 * 60,
      endMinute: 24 * 60,
      timeZone: 'America/New_York',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final occurrence = EntryOccurrence(
      date: monday,
      displayDate: monday.addDays(1),
      entry: entry,
      startAt: entry.startAt,
      endAt: entry.endAt,
    );

    await tester.pumpWidget(host(EntryTile(occurrence: occurrence, spaces: spaces)));

    expect(find.textContaining('5:00'), findsOneWidget);
    expect(find.textContaining('6:00'), findsOneWidget);
    expect(find.textContaining('23:00'), findsNothing);
  });

  testWidgets('an all-day entry never shows a shifted time', (tester) async {
    final entry = Entry(
      id: 'birthday',
      spaceId: 'work',
      title: 'Birthday',
      date: monday,
      allDay: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final occurrence = EntryOccurrence(date: monday, displayDate: monday, entry: entry);

    await tester.pumpWidget(
      host(
        EntryTile(occurrence: occurrence, spaces: spaces),
        timeZone: 'Pacific/Auckland',
      ),
    );

    expect(find.textContaining('All day'), findsOneWidget);
  });

  testWidgets('an entry without an end shows its start and an open dash', (tester) async {
    final entry = Entry(
      id: 'clock',
      spaceId: 'work',
      title: 'Open task',
      date: monday,
      startMinute: 9 * 60,
      timeZone: 'Europe/Madrid',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final occurrence = EntryOccurrence(
      date: monday,
      displayDate: monday,
      entry: entry,
      startAt: entry.startAt,
    );

    await tester.pumpWidget(host(EntryTile(occurrence: occurrence, spaces: spaces)));

    expect(find.textContaining('9:00'), findsOneWidget);
    expect(find.textContaining('All day'), findsNothing);
  });

  testWidgets('an imported entry is read-only and explains why', (tester) async {
    final entry = Entry(
      id: 'imported',
      spaceId: 'work',
      title: 'Standup',
      date: monday,
      startMinute: 9 * 60,
      endMinute: 10 * 60,
      timeZone: 'Europe/Madrid',
      source: 'ics',
      externalId: 'uid:standup@example.com',
      readOnly: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final occurrence = EntryOccurrence(
      date: monday,
      displayDate: monday,
      entry: entry,
      startAt: entry.startAt,
      endAt: entry.endAt,
    );

    await tester.pumpWidget(host(EntryTile(occurrence: occurrence, spaces: spaces)));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('Standup'));
    await tester.pumpAndSettle();
    expect(find.text('Imported calendar event'), findsOneWidget);
    expect(find.text('This event comes from an imported calendar and is read-only.'), findsOneWidget);
  });

  testWidgets('a shift wears its job colour', (tester) async {
    final pattern = ShiftPattern(
      id: 'pizzeria',
      spaceId: 'work',
      contextId: 'job-pizzeria',
      name: 'Pizzeria',
      timeZone: 'Europe/Madrid',
      cycleDays: 7,
      anchorDate: monday,
      slots: const [ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 23 * 60)],
    );
    final occurrence = pattern.occurrencesBetween(monday, monday, viewerTimeZone: 'Europe/Madrid').single;
    const contexts = <PlannerContext>[
      PlannerContext(id: 'job-pizzeria', spaceId: 'work', name: 'Pizzeria', colorValue: 0xFFC25B3F),
    ];

    await tester.pumpWidget(host(ShiftTile(occurrence: occurrence, contexts: contexts)));

    final tile = tester.widget<Container>(
      find.descendant(of: find.byType(ShiftTile), matching: find.byType(Container)).first,
    );
    expect((tile.decoration! as BoxDecoration).color, const Color(0xFFC25B3F).withValues(alpha: 0.16));
  });

  testWidgets('a shift rail is clipped to the card at full height', (tester) async {
    final pattern = ShiftPattern(
      id: 'pizzeria',
      spaceId: 'work',
      name: 'Pizzeria',
      timeZone: 'Europe/Madrid',
      cycleDays: 7,
      anchorDate: monday,
      slots: const [ShiftSlot(dayIndex: 0, startMinute: 15 * 60, endMinute: 23 * 60)],
    );
    final occurrence = pattern.occurrencesBetween(monday, monday, viewerTimeZone: 'Europe/Madrid').single;

    await tester.pumpWidget(host(ShiftTile(occurrence: occurrence)));

    final cardFinder = find.descendant(of: find.byType(ShiftTile), matching: find.byType(Container)).first;
    final card = tester.widget<Container>(cardFinder);
    expect(card.clipBehavior, Clip.antiAlias);

    final railFinder = find.descendant(of: find.byType(ShiftTile), matching: find.byType(ColoredBox));
    final stackFinder = find.descendant(of: find.byType(ShiftTile), matching: find.byType(Stack));
    final rail = tester.getRect(railFinder);
    final content = tester.getRect(stackFinder);
    expect(rail.top, content.top);
    expect(rail.bottom, content.bottom);
    expect(rail.left, content.left);
  });

  testWidgets('a shift renders in the viewer timezone', (tester) async {
    final pattern = ShiftPattern(
      id: 'night',
      spaceId: 'work',
      name: 'Night',
      timeZone: 'America/New_York',
      cycleDays: 7,
      anchorDate: monday,
      slots: const [ShiftSlot(dayIndex: 0, startMinute: 1320, endMinute: 1800)],
    );
    final occurrence = pattern.occurrencesBetween(monday, monday, viewerTimeZone: 'Europe/Madrid').single;

    await tester.pumpWidget(host(ShiftTile(occurrence: occurrence)));

    expect(find.text('Night'), findsOneWidget);
    expect(find.textContaining('4:00'), findsOneWidget);
    expect(find.textContaining('12:00'), findsOneWidget);
  });
}
