import 'local_date.dart';
import 'recurrence.dart';
import 'time.dart';

enum EntryKind { task, event, obligation, deadline }

enum EntryStatus { open, done, cancelled }

/// Explicit weighting chosen by the user. A dated deadline can raise the
/// effective priority through [deadlineUrgency].
enum EntryPriority { none, low, medium, high }

/// How a task relates to time.
///
/// [scheduled] has a start and an end. [clockIn] has a start but no end until
/// the user clocks out. [deadline] has only an end. [anytime] has neither.
enum EntryTiming { scheduled, clockIn, deadline, anytime }

/// One thing on the plan.
///
/// Timed entries keep the wall-clock [date], [startMinute] and [endMinute] in
/// [timeZone], plus the resolved UTC anchor instants [startAt] and [endAt].
/// The wall-clock fields are the recurrence template; the instants are what
/// the app shows, schedules and syncs.
///
/// All-day entries keep only [date] (and optional [endDate]). A date is not an
/// instant: a birthday or a tax deadline must not shift by a day when the
/// device timezone changes.
class Entry {
  Entry({
    required this.id,
    required this.spaceId,
    required this.title,
    this.notes = '',
    this.kind = EntryKind.task,
    this.date,
    this.endDate,
    this.startMinute,
    this.endMinute,
    this.timeZone,
    this.contextId,
    this.projectId,
    this.icon = '',
    this.priority = EntryPriority.none,
    this.completedAt,
    this.tagIds = const <String>{},
    this.allDay = false,
    this.source,
    this.externalId,
    this.readOnly = false,
    this.lastCompletedAt,
    this.repeatAfterCompletionDays,
    this.status = EntryStatus.open,
    this.recurrence,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    DateTime? startAt,
    DateTime? endAt,
  }) : startAt = startAt ?? _resolve(date, startMinute, timeZone, allDay),
       endAt = endAt ?? _resolveEnd(date, endDate, endMinute, timeZone, allDay) {
    _check();
  }

  static const _unset = Object();

  final String id;
  final String spaceId;
  final String title;
  final String notes;
  final EntryKind kind;

  /// Anchor date in the entry's own timezone. Null means unscheduled.
  final LocalDate? date;

  /// Last date for a multi-day all-day entry.
  final LocalDate? endDate;

  /// Local minutes from midnight in [timeZone], null for an all-day entry.
  /// An end of 1440 or more means the entry crosses midnight.
  final int? startMinute;
  final int? endMinute;

  /// IANA timezone the wall-clock fields are defined in. Null for all-day or
  /// date-only tasks.
  final String? timeZone;

  /// Job, home or person/group this entry belongs to.
  final String? contextId;

  /// Optional project inside the space/context.
  final String? projectId;

  /// Optional icon name from `SundialIcons`. Used by home gadgets; empty for most
  /// entries.
  final String icon;

  final EntryPriority priority;

  /// Set when a one-off task is completed. Recurring occurrences use the
  /// completions table instead.
  final DateTime? completedAt;

  /// Tags attached to this entry. The join rows live in `entry_tags`.
  final Set<String> tagIds;

  /// Where the entry came from, for example `ics`. Null for user entries.
  final String? source;

  /// Identifier in [source], used to deduplicate a re-import.
  final String? externalId;

  /// Imported entries are shown read-only.
  final bool readOnly;

  /// Last time a maintenance task was completed.
  final DateTime? lastCompletedAt;

  /// Maintenance interval in days. When set, completing the task moves its
  /// date forward instead of using a fixed recurrence rule.
  final int? repeatAfterCompletionDays;

  /// Resolved anchor instants in UTC. Null for all-day or unscheduled entries.
  final DateTime? startAt;
  final DateTime? endAt;

  final bool allDay;
  final EntryStatus status;
  final RecurrenceRule? recurrence;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isRecurring => recurrence != null;

  bool get isDone => status == EntryStatus.done;

  bool get isTimed => !allDay && date != null && startMinute != null;

  bool get hasStart => startMinute != null && startAt != null;

  bool get hasEnd => endMinute != null && endAt != null;

  EntryTiming get timing {
    if (hasStart && hasEnd) return EntryTiming.scheduled;
    if (hasStart) return EntryTiming.clockIn;
    if (hasEnd) return EntryTiming.deadline;
    return EntryTiming.anytime;
  }

  bool get isClockInTask => timing == EntryTiming.clockIn;

  bool get isDeadline => timing == EntryTiming.deadline;

  bool get isAnytime => timing == EntryTiming.anytime;

  bool get isMaintenance => repeatAfterCompletionDays != null;

  /// How many calendar days after [date] the entry ends. Zero for a single-day
  /// entry, including one that crosses midnight through [endMinute].
  int get endDayOffset {
    final start = date;
    final end = endDate;
    if (start == null || end == null) return 0;
    return end.differenceInDays(start);
  }

  /// Whether this entry covers more than one day in its stored timezone.
  bool get isMultiDay => endDate != null || (!allDay && (endMinute ?? 0) >= 1440);

  /// The date this entry appears on when viewed in [viewerTimeZone].
  ///
  /// All-day entries return their stored date unchanged. Timed entries return
  /// the device-local date of their start instant, so travelling can move
  /// them by a day.
  LocalDate displayDateIn(String viewerTimeZone) {
    final anchor = date;
    if (anchor == null) {
      throw StateError('An unscheduled entry has no display date');
    }
    final start = startAt;
    return start == null ? anchor : localDateAt(start, viewerTimeZone);
  }

  /// Whether this entry appears on [day] in its stored timezone.
  ///
  /// Recurring entries are expanded by their start dates. A multi-day
  /// recurring entry is not supported; that needs an explicit end offset per
  /// occurrence, which is a later decision.
  bool occursOn(LocalDate day) {
    if (deletedAt != null || status == EntryStatus.cancelled) return false;
    final anchor = date;
    if (anchor == null) return false;
    if (recurrence != null) return recurrence!.occursOn(day, anchor);
    final last = allDay ? (endDate ?? anchor) : anchor;
    return day.isOnOrAfter(anchor) && day.isOnOrBefore(last);
  }

  Entry copyWith({
    String? spaceId,
    String? title,
    String? notes,
    EntryKind? kind,
    Object? date = _unset,
    Object? endDate = _unset,
    Object? startMinute = _unset,
    Object? endMinute = _unset,
    Object? timeZone = _unset,
    Object? contextId = _unset,
    Object? projectId = _unset,
    String? icon,
    EntryPriority? priority,
    Object? completedAt = _unset,
    Set<String>? tagIds,
    bool? allDay,
    Object? source = _unset,
    Object? externalId = _unset,
    bool? readOnly,
    Object? lastCompletedAt = _unset,
    Object? repeatAfterCompletionDays = _unset,
    EntryStatus? status,
    Object? recurrence = _unset,
    DateTime? updatedAt,
    Object? deletedAt = _unset,
  }) => Entry(
    id: id,
    spaceId: spaceId ?? this.spaceId,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    kind: kind ?? this.kind,
    date: identical(date, _unset) ? this.date : date as LocalDate?,
    endDate: identical(endDate, _unset) ? this.endDate : endDate as LocalDate?,
    startMinute: identical(startMinute, _unset) ? this.startMinute : startMinute as int?,
    endMinute: identical(endMinute, _unset) ? this.endMinute : endMinute as int?,
    timeZone: identical(timeZone, _unset) ? this.timeZone : timeZone as String?,
    contextId: identical(contextId, _unset) ? this.contextId : contextId as String?,
    projectId: identical(projectId, _unset) ? this.projectId : projectId as String?,
    icon: icon ?? this.icon,
    priority: priority ?? this.priority,
    completedAt: identical(completedAt, _unset) ? this.completedAt : completedAt as DateTime?,
    tagIds: tagIds ?? this.tagIds,
    allDay: allDay ?? this.allDay,
    source: identical(source, _unset) ? this.source : source as String?,
    externalId: identical(externalId, _unset) ? this.externalId : externalId as String?,
    readOnly: readOnly ?? this.readOnly,
    lastCompletedAt: identical(lastCompletedAt, _unset) ? this.lastCompletedAt : lastCompletedAt as DateTime?,
    repeatAfterCompletionDays: identical(repeatAfterCompletionDays, _unset)
        ? this.repeatAfterCompletionDays
        : repeatAfterCompletionDays as int?,
    status: status ?? this.status,
    recurrence: identical(recurrence, _unset) ? this.recurrence : recurrence as RecurrenceRule?,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: identical(deletedAt, _unset) ? this.deletedAt : deletedAt as DateTime?,
  );

  static DateTime? _resolve(LocalDate? date, int? minute, String? timeZone, bool allDay) {
    if (allDay || date == null || minute == null || timeZone == null) {
      return null;
    }
    return instantAt(date, minute, timeZone);
  }

  static DateTime? _resolveEnd(
    LocalDate? date,
    LocalDate? endDate,
    int? minute,
    String? timeZone,
    bool allDay,
  ) {
    if (allDay || date == null || minute == null || timeZone == null) {
      return null;
    }
    final day = endDate ?? date;
    return instantAt(day, minute, timeZone);
  }

  void _check() {
    if (repeatAfterCompletionDays != null) {
      if (repeatAfterCompletionDays! <= 0) {
        throw ArgumentError.value(repeatAfterCompletionDays, 'repeatAfterCompletionDays', 'must be positive');
      }
      if (recurrence != null) {
        throw ArgumentError('Use either a recurrence rule or a completion interval, not both');
      }
    }
    final anchor = date;
    if (allDay) {
      if (timeZone != null || startMinute != null || endMinute != null) {
        throw ArgumentError('An all-day entry cannot carry a time or timezone');
      }
      if (startAt != null || endAt != null) {
        throw ArgumentError('An all-day entry cannot carry an instant');
      }
      if (anchor != null && endDate != null && endDate!.isBefore(anchor)) {
        throw ArgumentError.value(endDate, 'endDate', 'must not be before date');
      }
      return;
    }

    if (anchor == null) {
      if (startMinute != null || endMinute != null || timeZone != null) {
        throw ArgumentError('An unscheduled entry cannot carry a time');
      }
      if (startAt != null || endAt != null) {
        throw ArgumentError('An unscheduled entry cannot carry an instant');
      }
      return;
    }

    final start = startMinute;
    final end = endMinute;
    if (start == null && end == null) {
      if (timeZone != null) throw ArgumentError('A date-only task cannot carry a timezone');
      if (endDate != null) throw ArgumentError('A date-only task cannot carry an end date');
      if (startAt != null || endAt != null) throw ArgumentError('A date-only task cannot carry an instant');
      return;
    }
    if (timeZone == null || timeZone!.isEmpty) {
      throw ArgumentError('A timed entry needs an IANA timezone');
    }
    if (start != null && (start < 0 || start >= 1440)) {
      throw ArgumentError.value(startMinute, 'startMinute', 'must be between 0 and 1439');
    }
    if (end != null && end < 0) {
      throw ArgumentError.value(endMinute, 'endMinute', 'must not be negative');
    }

    if (start != null && end == null) {
      if (endDate != null) throw ArgumentError('A clock-in task cannot carry an end date');
      if (startAt == null || !startAt!.isUtc) throw ArgumentError('A clock-in task needs a start instant');
      if (endAt != null) throw ArgumentError('A clock-in task cannot carry an end instant');
      return;
    }
    if (start == null && end != null) {
      if (endDate != null) throw ArgumentError('A deadline cannot carry an end date');
      if (startAt != null) throw ArgumentError('A deadline cannot carry a start instant');
      if (endAt == null || !endAt!.isUtc) throw ArgumentError('A deadline needs an end instant');
      return;
    }

    if (endDate != null && endDate!.isBefore(date!)) {
      throw ArgumentError.value(endDate, 'endDate', 'must not be before date');
    }
    if (endDate == null) {
      if (end! <= start! || end - start > 1440) {
        throw ArgumentError.value(endMinute, 'endMinute', 'must be after start and at most 24 hours later');
      }
    } else {
      if (end! >= 1440) {
        throw ArgumentError.value(endMinute, 'endMinute', 'must be between 0 and 1439 with an end date');
      }
      if (endDate == date && end <= start!) {
        throw ArgumentError.value(endMinute, 'endMinute', 'must be after start on the same day');
      }
    }
    if (startAt == null || endAt == null || !startAt!.isUtc || !endAt!.isUtc) {
      throw ArgumentError('A timed entry needs resolved UTC instants');
    }
    if (!endAt!.isAfter(startAt!)) {
      throw ArgumentError('A timed entry must end after it starts');
    }
  }
}

/// An entry placed on a date by the recurrence expander.
class EntryOccurrence {
  const EntryOccurrence({
    required this.date,
    required this.displayDate,
    required this.entry,
    this.completed = false,
    this.startAt,
    this.endAt,
    this.tracked = Duration.zero,
    this.clockedIn = false,
  });

  /// Date in the entry's stored timezone.
  final LocalDate date;

  /// Date in the viewer's timezone. This is what lists and calendars group by.
  final LocalDate displayDate;

  final Entry entry;

  /// Completion is per occurrence for recurring entries, so checking this
  /// week's bins does not check next week's.
  final bool completed;

  /// Resolved instants for this occurrence, null for all-day entries.
  final DateTime? startAt;
  final DateTime? endAt;

  /// Actual tracked time recorded through clock in/out sessions.
  final Duration tracked;

  /// Whether a tracking session is open for this occurrence right now.
  final bool clockedIn;

  EntryOccurrence copyWith({bool? completed, Duration? tracked, bool? clockedIn}) => EntryOccurrence(
    date: date,
    displayDate: displayDate,
    entry: entry,
    completed: completed ?? this.completed,
    startAt: startAt,
    endAt: endAt,
    tracked: tracked ?? this.tracked,
    clockedIn: clockedIn ?? this.clockedIn,
  );
}

/// Next due date for an interval-after-completion task.
///
/// The anchor is the last service date, or the current due date shifted back by
/// the previous interval. Editing the name or the interval therefore never
/// moves an existing due date by a whole extra interval.
LocalDate nextMaintenanceDue({
  LocalDate? lastServiced,
  LocalDate? currentDue,
  int? currentInterval,
  required int interval,
  required LocalDate today,
}) {
  final safeInterval = interval <= 0 ? 1 : interval;
  final anchor =
      lastServiced ??
      (currentDue != null && currentInterval != null && currentInterval > 0
          ? currentDue.addDays(-currentInterval)
          : today);
  return anchor.addDays(safeInterval);
}
