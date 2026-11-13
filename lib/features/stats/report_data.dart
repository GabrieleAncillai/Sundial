/// One row of a summary report, grouped by space, job/home/person or project.
class ReportRow {
  const ReportRow({
    required this.label,
    required this.tracked,
    required this.completed,
    this.spaceId,
    this.contextId,
    this.projectId,
  });

  final String label;
  final Duration tracked;
  final int completed;
  final String? spaceId;
  final String? contextId;
  final String? projectId;
}

/// One tracked session in the detailed report.
class ReportDetail {
  const ReportDetail({
    required this.date,
    required this.start,
    required this.end,
    required this.duration,
    required this.title,
    required this.space,
    this.context,
    this.project,
  });

  final DateTime date;
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final String title;
  final String space;
  final String? context;
  final String? project;
}

/// Everything a summary or detailed report needs. The PDF and CSV writers
/// depend only on this shape, not on Drift or Riverpod.
class ReportData {
  const ReportData({
    required this.title,
    required this.rangeLabel,
    required this.generatedAt,
    required this.totalTracked,
    required this.completedTasks,
    required this.openTasks,
    required this.rows,
    required this.details,
    this.profileLabel = 'Mane',
    this.languageCode = 'en',
  });

  final String title;
  final String rangeLabel;
  final DateTime generatedAt;
  final Duration totalTracked;
  final int completedTasks;
  final int openTasks;
  final List<ReportRow> rows;
  final List<ReportDetail> details;
  final String profileLabel;
  final String languageCode;
}
