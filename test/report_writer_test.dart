import 'package:flutter_test/flutter_test.dart';
import 'package:mane/features/stats/report_data.dart' show ReportData, ReportDetail, ReportRow;
import 'package:mane/features/stats/report_writer.dart' show ReportWriter;

void main() {
  late ReportData data;

  setUp(() {
    data = ReportData(
      title: 'Work report',
      rangeLabel: '2026-11-01 \u2013 2026-11-07',
      generatedAt: DateTime(2026, 11, 12, 9, 30),
      totalTracked: const Duration(hours: 5, minutes: 30),
      completedTasks: 2,
      openTasks: 1,
      rows: const [
        ReportRow(label: 'Day job', tracked: Duration(hours: 3, minutes: 30), completed: 1),
        ReportRow(label: 'Home', tracked: Duration(hours: 2), completed: 1),
      ],
      details: [
        ReportDetail(
          date: DateTime(2026, 11, 2),
          start: DateTime(2026, 11, 2, 9, 15),
          end: DateTime(2026, 11, 2, 11, 45),
          duration: const Duration(hours: 2, minutes: 30),
          title: 'Quarterly "review", part 1',
          space: 'Work',
          context: 'Office',
          project: 'Day job',
        ),
        ReportDetail(
          date: DateTime(2026, 11, 3),
          start: DateTime(2026, 11, 3, 13),
          end: DateTime(2026, 11, 3, 16),
          duration: const Duration(hours: 3),
          title: 'Groceries\nand meal prep',
          space: 'Home',
          context: 'Errands',
        ),
      ],
      profileLabel: 'Sam',
    );
  });

  test('summary PDF is a PDF document', () async {
    final bytes = await ReportWriter.summaryPdf(data);

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('detailed PDF is a PDF document', () async {
    final bytes = await ReportWriter.detailedPdf(data);

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('CSV has the header, CRLF endings and RFC 4180 escaping', () {
    final csv = ReportWriter.csv(data);

    expect(csv, startsWith('Date,Start,End,Duration,Space,Context,Project,Task\r\n'));
    expect(
      csv,
      contains('2026-11-02,09:15,11:45,2:30,Work,Office,Day job,"Quarterly ""review"", part 1"\r\n'),
    );
    expect(csv, contains('2026-11-03,13:00,16:00,3:00,Home,Errands,,"Groceries\nand meal prep"\r\n'));
    expect(csv.split('\r\n').length, 4);
    expect(csv.codeUnitAt(0), isNot(0xFEFF));
  });

  test('summary CSV reconciles rows, shares and the total', () {
    final csv = ReportWriter.summaryCsv(data);
    final lines = csv.split('\r\n').where((line) => line.isNotEmpty).toList();

    expect(lines.first, 'Group,Tracked,Share,Completed');
    expect(lines, contains('Home,2:00,36.4%,1'));
    expect(lines, contains('Day job,3:30,63.6%,1'));
    expect(lines.last, 'Total,5:30,100%,2');
    expect(csv.codeUnitAt(0), isNot(0xFEFF));
  });

  test('summary CSV follows the report language', () {
    final spanish = ReportData(
      title: 'Informe',
      rangeLabel: '2026-11-01 \u2013 2026-11-07',
      generatedAt: DateTime(2026, 11, 12),
      totalTracked: const Duration(hours: 1),
      completedTasks: 1,
      openTasks: 0,
      rows: const [ReportRow(label: 'Trabajo', tracked: Duration(hours: 1), completed: 1)],
      details: const [],
      languageCode: 'es',
    );

    final csv = ReportWriter.summaryCsv(spanish);
    expect(csv, startsWith('Grupo,Tiempo,Porcentaje,Completadas\r\n'));
    expect(csv, endsWith('Total,1:00,100%,1\r\n'));
  });

  test('durations above 24 hours keep the H:MM shape', () {
    final long = ReportData(
      title: 'Long range',
      rangeLabel: '2026-11-01 \u2013 2026-11-30',
      generatedAt: DateTime(2026, 12, 1),
      totalTracked: const Duration(hours: 27, minutes: 5),
      completedTasks: 0,
      openTasks: 0,
      rows: const [ReportRow(label: 'Work', tracked: Duration(hours: 27, minutes: 5), completed: 0)],
      details: [
        ReportDetail(
          date: DateTime(2026, 11, 30),
          start: DateTime(2026, 11, 30, 8),
          end: DateTime(2026, 12, 1, 11, 5),
          duration: const Duration(hours: 27, minutes: 5),
          title: 'Long session',
          space: 'Work',
        ),
      ],
    );

    expect(ReportWriter.csv(long), contains(',27:05,'));
  });
}
