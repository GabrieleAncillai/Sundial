import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_data.dart';

/// Writes Clockify-style summary, detailed and CSV reports.
///
/// The PDF methods are asynchronous because `package:pdf` only exposes
/// `Document.save()` as a `Future` (it may serialise on a worker isolate).
/// CSV generation is synchronous.
abstract final class ReportWriter {
  static final PdfColor _accent = PdfColor.fromHex('#0A8FCF');
  static final PdfColor _ink = PdfColor.fromHex('#17212B');
  static final PdfColor _muted = PdfColor.fromHex('#6B7785');
  static final PdfColor _rule = PdfColor.fromHex('#DCE3EA');
  static final PdfColor _zebra = PdfColor.fromHex('#F3F6F9');
  static final PdfColor _headerFill = PdfColor.fromHex('#EAF6FD');
  static final PdfColor _panel = PdfColor.fromHex('#F7F9FB');

  static final pw.ThemeData _theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    italic: pw.Font.helveticaOblique(),
    boldItalic: pw.Font.helveticaBoldOblique(),
  );

  static final pw.TextStyle _titleStyle = pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    color: _ink,
    letterSpacing: -0.3,
  );
  static final pw.TextStyle _subtitleStyle = pw.TextStyle(fontSize: 10.5, color: _ink);
  static final pw.TextStyle _metaLabelStyle = pw.TextStyle(
    fontSize: 7.5,
    fontWeight: pw.FontWeight.bold,
    color: _muted,
    letterSpacing: 0.7,
  );
  static final pw.TextStyle _metaValueStyle = pw.TextStyle(fontSize: 9, color: _ink);
  static final pw.TextStyle _sectionStyle = pw.TextStyle(
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: _muted,
    letterSpacing: 0.6,
  );
  static final pw.TextStyle _statLabelStyle = pw.TextStyle(
    fontSize: 7.5,
    fontWeight: pw.FontWeight.bold,
    color: _muted,
    letterSpacing: 0.7,
  );
  static final pw.TextStyle _statValueStyle = pw.TextStyle(
    fontSize: 17,
    fontWeight: pw.FontWeight.bold,
    color: _ink,
  );
  static final pw.TextStyle _tableHeaderStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: _accent,
    letterSpacing: 0.2,
  );
  static final pw.TextStyle _bodyStyle = pw.TextStyle(fontSize: 8.4, color: _ink);
  static final pw.TextStyle _captionStyle = pw.TextStyle(fontSize: 7.5, color: _muted);
  static final pw.TextStyle _emptyStyle = pw.TextStyle(fontSize: 9.5, color: _muted);

  static final pw.TableBorder _tableBorder = pw.TableBorder(
    horizontalInside: pw.BorderSide(color: _rule, width: 0.4),
    bottom: pw.BorderSide(color: _rule, width: 0.6),
  );

  static const pw.EdgeInsets _pageMargin = pw.EdgeInsets.fromLTRB(40, 46, 40, 38);
  static const int _maxPages = 1000;

  /// Builds the one-page-per-few-dozen-rows summary report.
  static Future<Uint8List> summaryPdf(ReportData data) {
    final summaryTitle = _label(data, 'Summary report', 'Informe resumido');
    final byGroup = _label(data, 'BY GROUP', 'POR GRUPO');
    final document = pw.Document(title: summaryTitle, author: 'Mane', creator: 'Mane');
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        theme: _theme,
        maxPages: _maxPages,
        footer: (context) => _footer(context, data),
        build: (context) => [
          _header(data, summaryTitle),
          pw.SizedBox(height: 18),
          _stats(data),
          pw.SizedBox(height: 22),
          pw.Text(byGroup, style: _sectionStyle),
          pw.SizedBox(height: 6),
          _summaryTable(data),
        ],
      ),
    );
    return document.save();
  }

  /// Builds the session-by-session detailed report.
  static Future<Uint8List> detailedPdf(ReportData data) {
    final detailedTitle = _label(data, 'Detailed report', 'Informe detallado');
    final sessions = _label(data, 'SESSIONS', 'SESIONES');
    final document = pw.Document(title: detailedTitle, author: 'Mane', creator: 'Mane');
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: _pageMargin,
        theme: _theme,
        maxPages: _maxPages,
        footer: (context) => _footer(context, data),
        build: (context) => [
          _header(data, detailedTitle),
          pw.SizedBox(height: 22),
          pw.Text(sessions, style: _sectionStyle),
          pw.SizedBox(height: 6),
          _detailTable(data),
        ],
      ),
    );
    return document.save();
  }

  /// Summary CSV with the same groups, durations and shares as the summary
  /// PDF, plus a reconciling total row.
  static String summaryCsv(ReportData data) {
    final rows = List<ReportRow>.of(data.rows)
      ..sort((a, b) {
        final byTracked = b.tracked.compareTo(a.tracked);
        return byTracked != 0 ? byTracked : a.label.compareTo(b.label);
      });
    final total = data.totalTracked > Duration.zero ? data.totalTracked : _sumTracked(rows);
    final groupHeading = _label(data, 'Group', 'Grupo');
    final trackedHeading = _label(data, 'Tracked', 'Tiempo');
    final shareHeading = _label(data, 'Share', 'Porcentaje');
    final completedHeading = _label(data, 'Completed', 'Completadas');
    final ungrouped = _label(data, 'Ungrouped', 'Sin grupo');
    final budget = StringBuffer()
      ..write([groupHeading, trackedHeading, shareHeading, completedHeading].map(_csvCell).join(','))
      ..write('\r\n');
    for (final row in rows) {
      final label = row.label.trim().isEmpty ? ungrouped : row.label;
      budget
        ..write(_csvCell(label))
        ..write(',')
        ..write(_csvCell(_formatDuration(row.tracked)))
        ..write(',')
        ..write(_csvCell(_formatShare(row.tracked, total)))
        ..write(',')
        ..write(row.completed)
        ..write('\r\n');
    }
    budget
      ..write(_csvCell(_label(data, 'Total', 'Total')))
      ..write(',')
      ..write(_csvCell(_formatDuration(total)))
      ..write(',')
      ..write(_csvCell(total > Duration.zero ? '100%' : '0%'))
      ..write(',')
      ..write(rows.fold<int>(0, (sum, row) => sum + row.completed))
      ..write('\r\n');
    return budget.toString();
  }

  /// RFC 4180 CSV with CRLF record separators and no BOM.
  static String csv(ReportData data) {
    final headers = [
      _label(data, 'Date', 'Fecha'),
      _label(data, 'Start', 'Inicio'),
      _label(data, 'End', 'Fin'),
      _label(data, 'Duration', 'Duración'),
      _label(data, 'Space', 'Espacio'),
      _label(data, 'Context', 'Contexto'),
      _label(data, 'Project', 'Proyecto'),
      _label(data, 'Task', 'Tarea'),
    ];
    final buffer = StringBuffer('${headers.map(_csvCell).join(',')}\r\n');
    for (final detail in data.details) {
      buffer
        ..write(_csvCell(_formatDate(detail.date, data.datePattern, data.languageCode)))
        ..write(',')
        ..write(_csvCell(_formatTime(detail.start)))
        ..write(',')
        ..write(_csvCell(_formatTime(detail.end)))
        ..write(',')
        ..write(_csvCell(_formatDuration(detail.duration)))
        ..write(',')
        ..write(_csvCell(detail.space))
        ..write(',')
        ..write(_csvCell(detail.context ?? ''))
        ..write(',')
        ..write(_csvCell(detail.project ?? ''))
        ..write(',')
        ..write(_csvCell(detail.title))
        ..write('\r\n');
    }
    return buffer.toString();
  }

  static pw.Widget _header(ReportData data, String title) {
    final profile = _pdfSafe(data.profileLabel).trim();
    final subtitle = [
      _pdfSafe(data.title).trim(),
      _pdfSafe(data.rangeLabel).trim(),
    ].where((part) => part.isNotEmpty).join('   \u00B7   ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 38,
          height: 3.5,
          decoration: pw.BoxDecoration(color: _accent, borderRadius: pw.BorderRadius.circular(2)),
        ),
        pw.SizedBox(height: 10),
        pw.Text(title, style: _titleStyle),
        if (subtitle.isNotEmpty) ...[pw.SizedBox(height: 5), pw.Text(subtitle, style: _subtitleStyle)],
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 18,
          runSpacing: 3,
          children: [
            _meta('PROFILE', profile.isEmpty ? 'Mane' : profile),
            _meta('GENERATED', _formatDate(data.generatedAt, data.datePattern, data.languageCode)),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.Container(width: double.infinity, height: 0.6, color: _rule),
      ],
    );
  }

  static pw.Widget _meta(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(label, style: _metaLabelStyle),
        pw.SizedBox(width: 5),
        pw.Text(value, style: _metaValueStyle),
      ],
    );
  }

  static pw.Widget _stats(ReportData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _statBox('Total tracked', _formatDuration(data.totalTracked))),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _statBox('Tasks completed', '${data.completedTasks}')),
        pw.SizedBox(width: 10),
        pw.Expanded(child: _statBox('Open', '${data.openTasks}')),
      ],
    );
  }

  static pw.Widget _statBox(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _rule, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label.toUpperCase(), style: _statLabelStyle),
          pw.SizedBox(height: 5),
          pw.Text(value, style: _statValueStyle),
        ],
      ),
    );
  }

  static pw.Widget _summaryTable(ReportData data) {
    final rows = List<ReportRow>.of(data.rows)
      ..sort((a, b) {
        final byTracked = b.tracked.compareTo(a.tracked);
        return byTracked != 0 ? byTracked : a.label.compareTo(b.label);
      });
    if (rows.isEmpty) {
      return _empty(
        _label(data, 'No tracked time in this range.', 'No hay tiempo registrado en este rango.'),
      );
    }

    final total = data.totalTracked > Duration.zero ? data.totalTracked : _sumTracked(rows);

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      border: _tableBorder,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _headerFill),
          children: [
            _heading(_label(data, 'Group', 'Grupo')),
            _heading(_label(data, 'Tracked', 'Tiempo'), alignRight: true),
            _heading(_label(data, 'Share', 'Porcentaje'), alignRight: true),
            _heading(_label(data, 'Completed', 'Completadas'), alignRight: true),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: _zebra) : null,
            children: [
              _cell(rows[i].label.trim().isEmpty ? _label(data, 'Ungrouped', 'Sin grupo') : rows[i].label),
              _cell(_formatDuration(rows[i].tracked), alignRight: true),
              _cell(_formatShare(rows[i].tracked, total), alignRight: true),
              _cell('${rows[i].completed}', alignRight: true),
            ],
          ),
      ],
    );
  }

  static pw.Widget _detailTable(ReportData data) {
    final details = data.details.where((detail) => detail.duration > Duration.zero).toList(growable: false);
    if (details.isEmpty) {
      return _empty(
        _label(
          data,
          'No sessions with tracked time in this range.',
          'No hay sesiones con tiempo registrado en este rango.',
        ),
      );
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(56),
        1: pw.FixedColumnWidth(36),
        2: pw.FixedColumnWidth(36),
        3: pw.FixedColumnWidth(50),
        4: pw.FixedColumnWidth(52),
        5: pw.FixedColumnWidth(52),
        6: pw.FixedColumnWidth(52),
        7: pw.FlexColumnWidth(),
      },
      border: _tableBorder,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _headerFill),
          children: [
            _heading(_label(data, 'Date', 'Fecha')),
            _heading(_label(data, 'Start', 'Inicio')),
            _heading(_label(data, 'End', 'Fin')),
            _heading(_label(data, 'Duration', 'Duración')),
            _heading(_label(data, 'Space', 'Espacio')),
            _heading(_label(data, 'Context', 'Contexto')),
            _heading(_label(data, 'Project', 'Proyecto')),
            _heading(_label(data, 'Task', 'Tarea')),
          ],
        ),
        for (var i = 0; i < details.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? pw.BoxDecoration(color: _zebra) : null,
            children: [
              _cell(_formatDate(details[i].date, data.datePattern, data.languageCode)),
              _cell(_formatTime(details[i].start)),
              _cell(_formatTime(details[i].end)),
              _cell(_formatDuration(details[i].duration), alignRight: true),
              _cell(details[i].space),
              _cell(details[i].context ?? ''),
              _cell(details[i].project ?? ''),
              _cell(details[i].title, maxLines: 2),
            ],
          ),
      ],
    );
  }

  static pw.Widget _heading(String value, {bool alignRight = false}) {
    return _cell(value, alignRight: alignRight, style: _tableHeaderStyle);
  }

  static pw.Widget _cell(String value, {bool alignRight = false, int? maxLines, pw.TextStyle? style}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        _pdfSafe(value),
        style: style ?? _bodyStyle,
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static pw.Widget _empty(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: pw.BoxDecoration(color: _panel, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Text(message, style: _emptyStyle),
    );
  }

  static pw.Widget _footer(pw.Context context, ReportData data) {
    final footer = _label(data, 'Created with Mane', 'Creado con Mane');
    final pageLabel = _label(data, 'Page', 'Página');
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(width: double.infinity, height: 0.5, color: _rule),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(footer, style: _captionStyle),
            if (context.pagesCount > 1)
              pw.Text('$pageLabel ${context.pageNumber} / ${context.pagesCount}', style: _captionStyle),
          ],
        ),
      ],
    );
  }

  static String _label(ReportData data, String english, String spanish) =>
      data.languageCode.toLowerCase().startsWith('es') ? spanish : english;

  static Duration _sumTracked(List<ReportRow> rows) {
    var total = Duration.zero;
    for (final row in rows) {
      total += row.tracked;
    }
    return total;
  }

  static String _formatShare(Duration tracked, Duration total) {
    if (tracked <= Duration.zero || total <= Duration.zero) {
      return '0%';
    }
    final percent = tracked.inMicroseconds * 100 / total.inMicroseconds;
    if (percent >= 99.95) {
      return '100%';
    }
    if (percent < 0.05) {
      return '<0.1%';
    }
    final text = percent.toStringAsFixed(1);
    return text.endsWith('.0') ? '${text.substring(0, text.length - 2)}%' : '$text%';
  }

  static String _formatDuration(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    return '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime value, String pattern, String locale) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    final months = locale.toLowerCase().startsWith('es')
        ? const ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic']
        : const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return pattern
        .replaceAll('yyyy', year)
        .replaceAll('MMM', months[value.month - 1])
        .replaceAll('MM', month)
        .replaceAll('dd', day);
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _csvCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r');
    if (!needsQuotes) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }

  /// Helvetica is a Latin-1 Type 1 font, so PDF text cannot carry arbitrary
  /// Unicode. Common typographic characters are folded; the rest become '?'.
  static String _pdfSafe(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      if (rune == 0x09 ||
          rune == 0x0A ||
          rune == 0x0D ||
          (rune >= 0x20 && rune <= 0x7E) ||
          (rune >= 0xA1 && rune <= 0xFF)) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write(_typographicFallback[rune] ?? '?');
      }
    }
    return buffer.toString();
  }

  static const Map<int, String> _typographicFallback = {
    0x00A0: ' ',
    0x2013: '-',
    0x2014: '-',
    0x2018: "'",
    0x2019: "'",
    0x201A: "'",
    0x201C: '"',
    0x201D: '"',
    0x201E: '"',
    0x2022: '-',
    0x2026: '...',
  };
}
