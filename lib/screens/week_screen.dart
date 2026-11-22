import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../core/i18n/date_labels.dart';
import '../core/i18n/l10n.dart';
import '../core/widgets/ui_kit.dart';
import '../features/plan/widgets/week_agenda.dart';
import '../state/providers.dart';
import '../state/settings_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  int _offsetWeeks = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final deviceTimeZone = ref.watch(deviceTimeZoneProvider);
    final now = ref.watch(nowProvider);
    final today = localDateAt(now, deviceTimeZone);
    final start = today.startOfWeek(settings.weekStart).addDays(7 * _offsetWeeks);
    final range = (start: start, end: start.addDays(6));
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final contexts = ref.watch(contextsProvider(null)).value ?? const <PlannerContext>[];
    final entriesState = ref.watch(entriesProvider(range));
    final shiftsState = ref.watch(shiftsProvider(range));
    final allEntries = entriesState.value ?? const <EntryOccurrence>[];
    final allShifts = shiftsState.value ?? const <ShiftOccurrence>[];
    final entries = allEntries.where((entry) {
      if (entry.entry.spaceId != 'work') return true;
      if (settings.hideWorkSpace) return false;
      if (entry.entry.kind == EntryKind.deadline) return true;
      return settings.isWorkTime(now, deviceTimeZone);
    }).toList();
    final shifts = settings.hideWorkSpace || !settings.isWorkTime(now, deviceTimeZone)
        ? const <ShiftOccurrence>[]
        : allShifts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        _WeekHeader(
          start: start,
          onPrevious: () => setState(() => _offsetWeeks--),
          onNext: () => setState(() => _offsetWeeks++),
          onToday: () => setState(() => _offsetWeeks = 0),
        ),
        const SizedBox(height: 16),
        if (entriesState.hasError) SundialNotice(text: context.l10n.couldNotLoadDay('${entriesState.error}')),
        if (shiftsState.hasError)
          SundialNotice(text: context.l10n.couldNotLoadShifts('${shiftsState.error}')),
        WeekAgenda(
          start: start,
          today: today,
          entries: entries,
          shifts: shifts,
          spaces: spaces,
          contexts: contexts,
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.start,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final LocalDate start;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final end = start.addDays(6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(context.l10n.week, color: c.accent),
        Row(
          children: [
            Expanded(
              child: Text(
                '${formatShortDate(context, start.toDateTime())} – '
                '${formatShortDate(context, end.toDateTime())}',
                style: SundialType.headline(23, color: c.text),
              ),
            ),
            GlassIconButton(
              icon: Icons.chevron_left,
              tooltip: context.l10n.previousWeek,
              size: 36,
              onTap: onPrevious,
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              icon: Icons.today_outlined,
              tooltip: context.l10n.jumpToToday,
              size: 36,
              onTap: onToday,
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              icon: Icons.chevron_right,
              tooltip: context.l10n.nextWeek,
              size: 36,
              onTap: onNext,
            ),
          ],
        ),
      ],
    );
  }
}
