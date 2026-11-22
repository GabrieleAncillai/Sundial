import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/entry_widgets.dart';
import '../../shifts/widgets/shift_checklist_view.dart';

class CalendarDayDetail extends StatelessWidget {
  const CalendarDayDetail({
    super.key,
    required this.date,
    required this.entries,
    required this.shifts,
    required this.spaces,
    required this.contexts,
    required this.onAdd,
    this.onShifts,
  });

  final LocalDate date;
  final List<EntryOccurrence> entries;
  final List<ShiftOccurrence> shifts;
  final List<Space> spaces;
  final List<PlannerContext> contexts;
  final VoidCallback onAdd;

  /// Opens the per-day shift sheet. Null when there is no pattern to adjust.
  final VoidCallback? onShifts;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title =
        '${DateFormat.EEEE(locale).format(date.toDateTime())} · '
        '${formatFullDate(context, date.toDateTime())}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: SundialType.title(15, color: c.text)),
            ),
            if (onShifts != null) ...[
              GlassIconButton(
                icon: Icons.work_outline,
                tooltip: context.l10n.adjustShifts,
                size: 34,
                onTap: onShifts!,
              ),
              const SizedBox(width: 8),
            ],
            GlassIconButton(icon: Icons.add, tooltip: context.l10n.addOnThisDay, size: 34, onTap: onAdd),
          ],
        ),
        if (shifts.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final shift in shifts) ShiftTile(occurrence: shift, contexts: contexts),
          for (final shift in shifts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ShiftChecklistSection(
                patternId: shift.pattern.id,
                date: shift.date,
                slotKey: shift.slotKey,
                dayIndex: shift.pattern.cycleIndexFor(shift.date),
              ),
            ),
        ],
        if (entries.isEmpty && shifts.isEmpty)
          AppEmptyState(
            icon: Icons.event_available_outlined,
            title: context.l10n.noEntriesOnDay,
            compact: true,
          )
        else
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 44),
            EntryTile(occurrence: entries[index], spaces: spaces, dense: true),
          ],
      ],
    );
  }
}
