import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../screens/entry_editor.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/entry_widgets.dart';

/// A vertical seven-day agenda. Phones use it instead of the seven-column
/// [WeekTimeGrid], which needs more width than a 360 dp screen can give each
/// day.
class WeekAgenda extends StatelessWidget {
  const WeekAgenda({
    super.key,
    required this.start,
    required this.today,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
  });

  final LocalDate start;
  final LocalDate today;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;

  @override
  Widget build(BuildContext context) {
    final entriesByDate = <LocalDate, List<EntryOccurrence>>{};
    for (final occurrence in entries) {
      (entriesByDate[occurrence.displayDate] ??= []).add(occurrence);
    }
    final shiftsByDate = <LocalDate, List<ShiftOccurrence>>{};
    for (final occurrence in shifts) {
      (shiftsByDate[occurrence.displayDate] ??= []).add(occurrence);
    }

    return Column(
      children: [
        for (var index = 0; index < 7; index++) ...[
          WeekAgendaDay(
            date: start.addDays(index),
            isToday: start.addDays(index) == today,
            entries: entriesByDate[start.addDays(index)] ?? const [],
            shifts: shiftsByDate[start.addDays(index)] ?? const [],
            spaces: spaces,
            contexts: contexts,
          ),
          if (index < 6) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class WeekAgendaDay extends StatelessWidget {
  const WeekAgendaDay({
    super.key,
    required this.date,
    required this.isToday,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
  });

  final LocalDate date;
  final bool isToday;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final empty = entries.isEmpty && shifts.isEmpty;
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      color: isToday ? c.accentSoft : c.surface,
      borderColor: isToday ? c.accent.withValues(alpha: 0.35) : c.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? c.accent : c.surfaceAlt,
                  borderRadius: BorderRadius.circular(SundialRadii.sm),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E(locale).format(date.toDateTime()).toUpperCase(),
                      style: SundialType.label(9.5, color: isToday ? c.onAccent : c.textTertiary),
                    ),
                    Text('${date.day}', style: SundialType.title(16, color: isToday ? c.onAccent : c.text)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: shifts.isEmpty
                    ? const SizedBox.shrink()
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: shifts
                            .map((item) => ShiftChip(occurrence: item, contexts: contexts))
                            .toList(),
                      ),
              ),
              GlassIconButton(
                icon: Icons.add,
                tooltip: context.l10n.addOnThisDay,
                size: 34,
                onTap: () => showEntryEditor(context, initialDate: date, spaces: spaces),
              ),
            ],
          ),
          if (empty)
            Padding(
              padding: const EdgeInsets.fromLTRB(54, 8, 8, 2),
              child: Text(context.l10n.nothingPlanned, style: SundialType.body(12, color: c.textTertiary)),
            )
          else if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    if (index > 0) const Divider(height: 1, indent: 44),
                    EntryTile(occurrence: entries[index], spaces: spaces, dense: true),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
