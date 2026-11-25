import 'package:sundial_core/sundial_core.dart';
import 'package:test/test.dart';

void main() {
  group('LocalDate', () {
    test('parses and formats ISO dates', () {
      expect(LocalDate.parse('2026-11-09').iso, '2026-11-09');
      expect(LocalDate.parse('2024-02-29').iso, '2024-02-29');
    });

    test('rejects dates that do not exist', () {
      expect(() => LocalDate.parse('2026-02-31'), throwsFormatException);
      expect(() => LocalDate.parse('2025-02-29'), throwsFormatException);
      expect(() => LocalDate.parse('2026-13-01'), throwsFormatException);
      expect(() => LocalDate.parse('09/11/2026'), throwsFormatException);
    });

    test('adds days across months, years and leap days', () {
      expect(LocalDate.parse('2026-12-31').addDays(1).iso, '2027-01-01');
      expect(LocalDate.parse('2024-02-28').addDays(1).iso, '2024-02-29');
      expect(LocalDate.parse('2026-03-01').addDays(-1).iso, '2026-02-28');
    });

    test('adds months and clamps the day to the month length', () {
      expect(LocalDate.parse('2026-01-31').addMonths(1).iso, '2026-02-28');
      expect(LocalDate.parse('2024-01-31').addMonths(1).iso, '2024-02-29');
      expect(LocalDate.parse('2026-11-15').addMonths(2).iso, '2027-01-15');
      expect(LocalDate.parse('2026-01-15').addMonths(-1).iso, '2025-12-15');
      expect(LocalDate.parse('2026-03-31').addMonths(-1).iso, '2026-02-28');
    });

    test('computes whole-day differences', () {
      final monday = LocalDate.parse('2026-11-09');
      final friday = LocalDate.parse('2026-11-13');
      expect(friday.differenceInDays(monday), 4);
      expect(monday.differenceInDays(friday), -4);
    });

    test('uses ISO weekdays', () {
      expect(LocalDate.parse('2026-11-09').weekday, 1);
      expect(LocalDate.parse('2026-11-15').weekday, 7);
      expect(LocalDate.parse('2026-11-15').mondayOfWeek.iso, '2026-11-09');
    });

    test('round-trips through the database key', () {
      final date = LocalDate.parse('2026-11-09');
      expect(date.key, 20261109);
      expect(LocalDate.fromKey(date.key), date);
    });
  });
}
