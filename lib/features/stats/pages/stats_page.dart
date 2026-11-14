import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../features/export/export_files.dart';
import '../../../models/time_entry.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../report_data.dart';
import '../report_writer.dart';

enum _StatsRange { week, month, quarter, year }

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  _StatsRange _range = _StatsRange.month;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final now = ref.watch(nowProvider);
    final today = localDateAt(now, timeZone);
    final settings = ref.watch(settingsProvider);
    final (start, end) = _bounds(today, settings.weekStart);
    final entriesState = ref.watch(entriesProvider((start: start, end: end)));
    final openState = ref.watch(openEntriesProvider(today));
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final projects = ref.watch(projectsProvider(null)).value ?? const <Project>[];
    final habits = ref.watch(habitsProvider('personal')).value ?? const <Habit>[];
    final completions = ref.watch(habitCompletionsProvider).value ?? const <String, Set<LocalDate>>{};
    final timeAsync = ref.watch(
      timeEntriesRangeProvider((
        start: instantAt(start, 0, timeZone),
        end: instantAt(end.addDays(1), 0, timeZone),
      )),
    );
    final timeEntries = timeAsync.value ?? const <TimeEntry>[];
    final trackedEntries =
        ref
            .watch(
              trackedEntriesProvider((
                start: instantAt(start, 0, timeZone),
                end: instantAt(end.addDays(1), 0, timeZone),
              )),
            )
            .value ??
        const <String, Entry>{};
    final occurrences = (entriesState.value ?? const <EntryOccurrence>[]).where((occurrence) {
      if (occurrence.displayDate.isBefore(start) || occurrence.displayDate.isAfter(end)) return false;
      if (occurrence.entry.spaceId != 'work') return true;
      if (settings.hideWorkSpace) return false;
      return true;
    }).toList();
    final allEntries = <String, Entry>{
      for (final occurrence in occurrences) occurrence.entry.id: occurrence.entry,
      ...trackedEntries,
    };
    final completed = occurrences.where((occurrence) => occurrence.completed).length;
    final total = occurrences.length;
    final tracked = timeEntries.fold(Duration.zero, (sum, entry) => sum + entry.durationAt(now.toUtc()));
    final overdue = (openState.value ?? const <Entry>[]).where((entry) {
      final due = entry.endAt;
      return entry.isDeadline && due != null && due.isBefore(now.toUtc()) && entry.status == EntryStatus.open;
    }).length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(entriesProvider((start: start, end: end)));
        ref.invalidate(openEntriesProvider(today));
        ref.invalidate(habitCompletionsProvider);
        ref.invalidate(
          timeEntriesRangeProvider((
            start: instantAt(start, 0, timeZone),
            end: instantAt(end.addDays(1), 0, timeZone),
          )),
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.stats, color: c.accent),
                    Text(l10n.overview, style: ManeType.headline(26, color: c.text)),
                  ],
                ),
              ),
              _ExportButton(
                onSelected: (value) => _export(value, start, end, occurrences, timeEntries, allEntries),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ManeSegmented<_StatsRange>(
            segments: [
              ManeSegment(value: _StatsRange.week, label: l10n.rangeWeek),
              ManeSegment(value: _StatsRange.month, label: l10n.rangeMonth),
              ManeSegment(value: _StatsRange.quarter, label: l10n.rangeQuarter),
              ManeSegment(value: _StatsRange.year, label: l10n.rangeYear),
            ],
            selected: _range,
            onChanged: (value) => setState(() => _range = value),
            compact: true,
          ),
          const SizedBox(height: 6),
          Text(
            '${formatFullDate(context, start.toDateTime())} – '
            '${formatFullDate(context, end.toDateTime())}',
            style: ManeType.body(11.5, color: c.textTertiary),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: _StatCard(
                      icon: Icons.task_alt,
                      label: l10n.tasksCompleted,
                      value: '$completed',
                      accent: c.success,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatCard(
                      icon: Icons.donut_large,
                      label: l10n.completionRate,
                      value: total == 0 ? '—' : '${(completed / total * 100).round()}%',
                      accent: c.accent,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatCard(
                      icon: Icons.timer_outlined,
                      label: l10n.totalTracked,
                      value: _duration(tracked),
                      accent: c.info,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _StatCard(
                      icon: Icons.flag_outlined,
                      label: l10n.overdueDeadlines,
                      value: '$overdue',
                      accent: overdue > 0 ? c.warning : c.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(l10n.byDay),
                const SizedBox(height: 10),
                _BarChart(values: _dailyValues(start, end, occurrences)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SoftCard(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(l10n.bySpace),
                const SizedBox(height: 8),
                for (final space in spaces)
                  _BreakdownRow(
                    label: space.name,
                    color: Color(space.colorValue),
                    tracked: _trackedForSpace(timeEntries, allEntries, space.id, now),
                    completed: occurrences
                        .where((item) => item.entry.spaceId == space.id && item.completed)
                        .length,
                    totalTracked: tracked,
                  ),
              ],
            ),
          ),
          if (projects.isNotEmpty) ...[
            const SizedBox(height: 14),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(l10n.byProject),
                  const SizedBox(height: 8),
                  for (final project in projects.where((project) {
                    return timeEntries.any((time) => allEntries[time.entryId]?.projectId == project.id);
                  }))
                    _BreakdownRow(
                      label: project.name,
                      color: Color(project.colorValue),
                      tracked: _trackedForProject(timeEntries, allEntries, project.id, now),
                      completed: occurrences
                          .where((item) => item.entry.projectId == project.id && item.completed)
                          .length,
                      totalTracked: tracked,
                    ),
                  if (!timeEntries.any((time) => allEntries[time.entryId]?.projectId != null))
                    Text(l10n.noTrackedTime, style: ManeType.body(12, color: c.textTertiary)),
                ],
              ),
            ),
          ],
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 14),
            SoftCard(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(l10n.habitConsistency),
                  const SizedBox(height: 10),
                  for (final habit in habits)
                    _HabitRow(
                      habit: habit,
                      completions: completions[habit.id] ?? const <LocalDate>{},
                      start: start,
                      end: end,
                      weekStart: settings.weekStart,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (tracked == Duration.zero)
            Text(l10n.noTrackedTime, style: ManeType.body(10.5, color: c.textTertiary)),
        ],
      ),
    );
  }

  (LocalDate, LocalDate) _bounds(LocalDate today, int weekStart) {
    return switch (_range) {
      _StatsRange.week => (today.startOfWeek(weekStart), today.startOfWeek(weekStart).addDays(6)),
      _StatsRange.month => (LocalDate(today.year, today.month, 1), _lastDayOfMonth(today.year, today.month)),
      _StatsRange.quarter => () {
        final startMonth = ((today.month - 1) ~/ 3) * 3 + 1;
        return (LocalDate(today.year, startMonth, 1), _lastDayOfMonth(today.year, startMonth + 2));
      }(),
      _StatsRange.year => (LocalDate(today.year, 1, 1), LocalDate(today.year, 12, 31)),
    };
  }

  LocalDate _lastDayOfMonth(int year, int month) {
    final next = month == 12 ? LocalDate(year + 1, 1, 1) : LocalDate(year, month + 1, 1);
    return next.addDays(-1);
  }

  List<double> _dailyValues(LocalDate start, LocalDate end, List<EntryOccurrence> entries) {
    final days = end.differenceInDays(start) + 1;
    final bucketDays = days <= 62 ? 1 : 7;
    final count = (days / bucketDays).ceil();
    final values = List<double>.filled(count, 0);
    for (final entry in entries) {
      if (!entry.completed) continue;
      final index = entry.displayDate.differenceInDays(start) ~/ bucketDays;
      if (index >= 0 && index < values.length) values[index] += 1;
    }
    return values;
  }

  Duration _trackedForSpace(List<TimeEntry> entries, Map<String, Entry> byId, String spaceId, DateTime now) {
    return entries.fold(Duration.zero, (sum, item) {
      if (byId[item.entryId]?.spaceId != spaceId) return sum;
      return sum + item.durationAt(now.toUtc());
    });
  }

  Duration _trackedForProject(
    List<TimeEntry> entries,
    Map<String, Entry> byId,
    String projectId,
    DateTime now,
  ) {
    return entries.fold(Duration.zero, (sum, item) {
      if (byId[item.entryId]?.projectId != projectId) return sum;
      return sum + item.durationAt(now.toUtc());
    });
  }

  Future<void> _export(
    String value,
    LocalDate start,
    LocalDate end,
    List<EntryOccurrence> occurrences,
    List<TimeEntry> timeEntries,
    Map<String, Entry> entryById,
  ) async {
    final l10n = context.l10n;
    final spaces = ref.read(spacesProvider).value ?? fallbackSpaces;
    final contexts = ref.read(contextsProvider(null)).value ?? const <PlannerContext>[];
    final projects = ref.read(projectsProvider(null)).value ?? const <Project>[];
    final spaceNames = {for (final space in spaces) space.id: space.name};
    final contextNames = {for (final context in contexts) context.id: context.name};
    final projectNames = {for (final project in projects) project.id: project.name};
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = DateTime.now().toUtc();
    final rows = <String, ReportRow>{};
    for (final entry in entryById.values) {
      final label = entry.projectId != null
          ? projectNames[entry.projectId] ?? l10n.noProject
          : entry.contextId != null
          ? contextNames[entry.contextId] ?? l10n.noContext
          : spaceNames[entry.spaceId] ?? entry.spaceId;
      final current = rows[label] ?? ReportRow(label: label, tracked: Duration.zero, completed: 0);
      rows[label] = ReportRow(
        label: label,
        tracked: current.tracked,
        completed: current.completed,
        spaceId: entry.spaceId,
        contextId: entry.contextId,
        projectId: entry.projectId,
      );
    }
    for (final item in timeEntries) {
      final entry = entryById[item.entryId];
      if (entry == null) continue;
      final label = entry.projectId != null
          ? projectNames[entry.projectId] ?? l10n.noProject
          : entry.contextId != null
          ? contextNames[entry.contextId] ?? l10n.noContext
          : spaceNames[entry.spaceId] ?? entry.spaceId;
      final current = rows[label] ?? const ReportRow(label: '', tracked: Duration.zero, completed: 0);
      rows[label] = ReportRow(
        label: label,
        tracked: current.tracked + item.durationAt(now),
        completed: current.completed,
        spaceId: entry.spaceId,
        contextId: entry.contextId,
        projectId: entry.projectId,
      );
    }
    for (final occurrence in occurrences.where((item) => item.completed)) {
      final entry = occurrence.entry;
      final label = entry.projectId != null
          ? projectNames[entry.projectId] ?? l10n.noProject
          : entry.contextId != null
          ? contextNames[entry.contextId] ?? l10n.noContext
          : spaceNames[entry.spaceId] ?? entry.spaceId;
      final current = rows[label] ?? ReportRow(label: label, tracked: Duration.zero, completed: 0);
      rows[label] = ReportRow(
        label: label,
        tracked: current.tracked,
        completed: current.completed + 1,
        spaceId: entry.spaceId,
        contextId: entry.contextId,
        projectId: entry.projectId,
      );
    }
    final details = <ReportDetail>[];
    for (final item in timeEntries) {
      final entry = entryById[item.entryId];
      if (entry == null) continue;
      final ended = item.endedAt ?? now;
      details.add(
        ReportDetail(
          date: localDateTimeAt(item.startedAt, ref.read(deviceTimeZoneProvider)),
          start: localDateTimeAt(item.startedAt, ref.read(deviceTimeZoneProvider)),
          end: localDateTimeAt(ended, ref.read(deviceTimeZoneProvider)),
          duration: item.durationAt(now),
          title: entry.title,
          space: spaceNames[entry.spaceId] ?? entry.spaceId,
          context: entry.contextId == null ? null : contextNames[entry.contextId],
          project: entry.projectId == null ? null : projectNames[entry.projectId],
        ),
      );
    }
    final totalTracked = timeEntries.fold(Duration.zero, (sum, item) => sum + item.durationAt(now));
    final data = ReportData(
      title: value == 'summary'
          ? l10n.exportSummaryReport
          : value == 'detailed'
          ? l10n.exportDetailedReport
          : l10n.exportReportCsv,
      rangeLabel:
          '${formatFullDate(context, start.toDateTime())} – '
          '${formatFullDate(context, end.toDateTime())}',
      generatedAt: now,
      totalTracked: totalTracked,
      completedTasks: occurrences.where((item) => item.completed).length,
      openTasks: occurrences.where((item) => !item.completed).length,
      rows: rows.values.toList(),
      details: details,
      languageCode: locale,
    );
    try {
      String? savedPath;
      if (value == 'summary') {
        final bytes = await ReportWriter.summaryPdf(data);
        savedPath = await savePdfFile(
          bytes,
          dialogTitle: l10n.exportSummaryReport,
          fileName: _fileName('summary'),
        );
      } else if (value == 'detailed') {
        final bytes = await ReportWriter.detailedPdf(data);
        savedPath = await savePdfFile(
          bytes,
          dialogTitle: l10n.exportDetailedReport,
          fileName: _fileName('detailed'),
        );
      } else {
        savedPath = await saveCsvFile(
          ReportWriter.csv(data),
          dialogTitle: l10n.exportReportCsv,
          fileName: _fileName('report').replaceAll('.pdf', '.csv'),
        );
      }
      if (!mounted || savedPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportExported)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportFailed('$error'))));
    }
  }

  String _fileName(String kind) {
    final now = DateTime.now();
    return 'mane-$kind-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.pdf';
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.exportReport,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(value: 'summary', child: Text(l10n.exportSummaryReport)),
        PopupMenuItem(value: 'detailed', child: Text(l10n.exportDetailedReport)),
        PopupMenuItem(value: 'csv', child: Text(l10n.exportReportCsv)),
      ],
      icon: Icon(Icons.ios_share_outlined, color: context.mc.text),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.accent});

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: accent),
          const SizedBox(height: 9),
          Text(value, style: ManeType.headline(23, color: c.text)),
          const SizedBox(height: 1),
          Text(label, maxLines: 2, style: ManeType.body(11, color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final top = values.isEmpty ? 1.0 : math.max(1.0, values.reduce(math.max));
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: math.max(3, values[index] / top * 82),
                      decoration: BoxDecoration(
                        color: values[index] == 0 ? c.surfaceHigh : c.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (index == 0 || index == values.length - 1)
                      Text('${index + 1}', style: ManeType.label(8, color: c.textTertiary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.color,
    required this.tracked,
    required this.completed,
    required this.totalTracked,
  });

  final String label;
  final Color color;
  final Duration tracked;
  final int completed;
  final Duration totalTracked;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final ratio = totalTracked.inSeconds == 0 ? 0.0 : tracked.inSeconds / totalTracked.inSeconds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ManeType.body(12.5, weight: FontWeight.w700, color: c.text),
                ),
              ),
              Text(
                '${_duration(tracked)} · ${context.l10n.completed} $completed',
                style: ManeType.label(10, color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 4,
              backgroundColor: c.surfaceHigh,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.completions,
    required this.start,
    required this.end,
    required this.weekStart,
  });

  final Habit habit;
  final Set<LocalDate> completions;
  final LocalDate start;
  final LocalDate end;
  final int weekStart;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final weeks = math.max(1, (end.differenceInDays(start) + 1) / 7);
    final done = completions.where((date) => date.isOnOrAfter(start) && date.isOnOrBefore(end)).length;
    final target = math.max(1, (habit.cleanTarget * weeks).ceil());
    final ratio = (done / target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: Color(habit.colorValue), shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ManeType.body(12.5, color: c.text),
            ),
          ),
          SizedBox(
            width: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 5,
                backgroundColor: c.surfaceHigh,
                color: Color(habit.colorValue),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(ratio * 100).round()}%', style: ManeType.label(10, color: c.textTertiary)),
        ],
      ),
    );
  }
}

String _duration(Duration value) {
  final minutes = value.inMinutes;
  final hours = minutes ~/ 60;
  return '$hours:${(minutes % 60).toString().padLeft(2, '0')}';
}
