import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sundial/core/i18n/l10n.dart';
import 'package:sundial/features/calendar/widgets/open_end_entry_block.dart';
import 'package:sundial/features/plan/widgets/week_time_grid.dart';
import 'package:sundial/features/shifts/shift_block_painter.dart';
import 'package:sundial/theme/app_theme.dart';
import 'package:sundial_core/sundial_core.dart';

void main() {
  setUpAll(initializeTimeZones);

  final weekStart = LocalDate.parse('2026-11-09');
  const timeZone = 'Europe/Madrid';

  ShiftPattern pattern(String id, String name, int startMinute, int endMinute) => ShiftPattern(
    id: id,
    spaceId: 'work',
    name: name,
    timeZone: timeZone,
    cycleDays: 7,
    anchorDate: weekStart,
    slots: [ShiftSlot(dayIndex: 0, startMinute: startMinute, endMinute: endMinute)],
  );

  EntryOccurrence occurrence(String id, String title, int startMinute, {int? endMinute, LocalDate? date}) {
    final day = date ?? weekStart;
    final entry = Entry(
      id: id,
      spaceId: 'work',
      title: title,
      date: day,
      startMinute: startMinute,
      endMinute: endMinute,
      timeZone: timeZone,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    return EntryOccurrence(
      date: day,
      displayDate: day,
      entry: entry,
      startAt: entry.startAt,
      endAt: entry.endAt,
    );
  }

  Widget host(
    List<ShiftOccurrence> shifts, {
    List<EntryOccurrence> entries = const [],
    ValueChanged<EntryOccurrence>? onOpen,
    void Function(LocalDate date, int startMinute, int endMinute)? onCreate,
    void Function(EntryOccurrence occurrence, LocalDate date, int startMinute, int endMinute)? onMove,
    void Function(EntryOccurrence occurrence, int endMinute)? onResize,
  }) => MaterialApp(
    theme: SundialTheme.light,
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
            entries: entries,
            shifts: shifts,
            spaces: const [],
            contexts: const [],
            timeZone: timeZone,
            now: DateTime.utc(2026, 11, 9, 12),
            onOpen: onOpen ?? (_) {},
            onCreate: onCreate ?? (_, _, _) {},
            onMove: onMove ?? (_, _, _, _) {},
            onResize: onResize ?? (_, _) {},
          ),
        ),
      ),
    ),
  );

  Finder resizeHandle() => find.byWidgetPredicate(
    (widget) => widget is MouseRegion && widget.cursor == SystemMouseCursors.resizeUpDown,
  );

  testWidgets('overlapping shifts stay full width and blend in the week grid', (tester) async {
    final bank = pattern('banco', 'Banco', 9 * 60, 13 * 60);
    final pizza = pattern('pizza', 'Pizza', 12 * 60, 16 * 60);
    final shifts = [
      ...bank.occurrencesBetween(weekStart, weekStart, viewerTimeZone: timeZone),
      ...pizza.occurrencesBetween(weekStart, weekStart, viewerTimeZone: timeZone),
    ];

    await tester.pumpWidget(host(shifts));
    await tester.pumpAndSettle();

    final bankRect = tester.getRect(find.text('Banco'));
    final pizzaRect = tester.getRect(find.text('Pizza'));

    expect(bankRect.left, pizzaRect.left);
    expect(bankRect.width, pizzaRect.width);
    expect(bankRect.width, greaterThan(80));

    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<ShiftBlockPainter>()
        .firstWhere((painter) => painter.blocks.isNotEmpty);
    expect(painter.blocks, hasLength(2));
    expect(painter.blocks.every((block) => block.rect.left == 0), isTrue);
    expect(painter.blocks[0].rect.width, painter.blocks[1].rect.width);
  });

  testWidgets('an entry without an end renders as an open-ended block', (tester) async {
    final entry = Entry(
      id: 'clock',
      spaceId: 'work',
      title: 'Prep the bar',
      date: weekStart,
      startMinute: 9 * 60,
      timeZone: timeZone,
      createdAt: DateTime.utc(2026, 11, 1),
      updatedAt: DateTime.utc(2026, 11, 1),
    );
    final item = EntryOccurrence(
      date: weekStart,
      displayDate: weekStart,
      entry: entry,
      startAt: entry.startAt,
    );

    await tester.pumpWidget(host(const [], entries: [item]));
    await tester.pumpAndSettle();

    expect(find.byType(OpenEndEntryBlock), findsOneWidget);
    expect(find.text('Prep the bar'), findsOneWidget);
    expect(find.text('09:00 –'), findsOneWidget);
  });

  testWidgets('dragging an event moves its block with the pointer', (tester) async {
    final item = occurrence('deep', 'Deep work', 9 * 60, endMinute: 10 * 60);
    final moves = <({LocalDate date, int start, int end})>[];
    final created = <({LocalDate date, int start, int end})>[];
    await tester.pumpWidget(
      host(
        const [],
        entries: [item],
        onCreate: (date, start, end) => created.add((date: date, start: start, end: end)),
        onMove: (occurrence, date, start, end) => moves.add((date: date, start: start, end: end)),
      ),
    );
    await tester.pumpAndSettle();

    final start = tester.getCenter(find.text('Deep work'));
    final columnWidth = tester.getRect(find.byType(WeekTimeGrid)).width / 7;
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await gesture.moveBy(Offset(columnWidth, 2 * 52));
    await tester.pump();

    // The block itself is previewed under the pointer, with the source left as
    // a faint placeholder, instead of a detached feedback copy.
    expect(find.text('Deep work'), findsNWidgets(2));
    expect(find.text('11:00 – 12:00'), findsOneWidget);
    expect(moves, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(moves, hasLength(1));
    expect(created, isEmpty);
    expect(moves.single.date, LocalDate.parse('2026-11-10'));
    expect(moves.single.start, 11 * 60);
    expect(moves.single.end, 12 * 60);
  });

  testWidgets('resizing an event updates its height before the pointer is released', (tester) async {
    final item = occurrence('deep', 'Deep work', 9 * 60, endMinute: 10 * 60);
    final resized = <int>[];
    await tester.pumpWidget(host(const [], entries: [item], onResize: (_, end) => resized.add(end)));
    await tester.pumpAndSettle();

    expect(find.text('09:00 – 10:00'), findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(resizeHandle()),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 52));
    await tester.pump();

    expect(find.text('09:00 – 11:00'), findsOneWidget);
    expect(resized, isEmpty);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(resized, [11 * 60]);
  });

  testWidgets('a mouse drag on empty space still creates an event', (tester) async {
    final created = <({LocalDate date, int start, int end})>[];
    await tester.pumpWidget(
      host(const [], onCreate: (date, start, end) => created.add((date: date, start: start, end: end))),
    );
    await tester.pumpAndSettle();

    final grid = tester.getRect(find.byType(WeekTimeGrid));
    final gesture = await tester.startGesture(
      Offset(grid.left + 120, grid.top + 300),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 52));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(created, hasLength(1));
    expect(created.single.end, greaterThan(created.single.start));
  });

  testWidgets('a trackpad pan scrolls without starting an event', (tester) async {
    final created = <({LocalDate date, int start, int end})>[];
    await tester.pumpWidget(
      host(const [], onCreate: (date, start, end) => created.add((date: date, start: start, end: end))),
    );
    await tester.pumpAndSettle();

    final grid = tester.getRect(find.byType(WeekTimeGrid));
    final point = Offset(grid.left + 120, grid.top + 300);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    await gesture.panZoomStart(point);
    await gesture.panZoomUpdate(point, pan: const Offset(0, -40));
    await gesture.panZoomUpdate(point, pan: const Offset(0, 60));
    await gesture.panZoomEnd();
    await tester.pumpAndSettle();

    expect(created, isEmpty);
  });

  testWidgets('a touch scroll on empty space does not start an event', (tester) async {
    final created = <({LocalDate date, int start, int end})>[];
    await tester.pumpWidget(
      host(const [], onCreate: (date, start, end) => created.add((date: date, start: start, end: end))),
    );
    await tester.pumpAndSettle();

    final grid = tester.getRect(find.byType(WeekTimeGrid));
    final gesture = await tester.startGesture(
      Offset(grid.left + 120, grid.top + 300),
      kind: PointerDeviceKind.touch,
    );
    await gesture.moveBy(const Offset(0, -80));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(created, isEmpty);
  });
}
