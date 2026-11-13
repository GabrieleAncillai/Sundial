/// One clock-in/clock-out session. [endedAt] is null while the timer runs.
class TimeEntry {
  const TimeEntry({
    required this.id,
    required this.entryId,
    this.occurrenceDateKey,
    required this.startedAt,
    this.endedAt,
    this.note = '',
    required this.createdAt,
  });

  final String id;
  final String entryId;
  final int? occurrenceDateKey;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String note;
  final DateTime createdAt;

  bool get isRunning => endedAt == null;

  Duration durationAt(DateTime now) => (endedAt ?? now).difference(startedAt);
}
