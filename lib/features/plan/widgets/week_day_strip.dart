import 'package:flutter/material.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/widgets/pressable.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// The collapsed phone calendar: the seven days of the selected week above the
/// day timeline.
///
/// The desktop week grid carries the same header inside [WeekTimeGrid]; on a
/// phone the week stays visible while only one day gets the hour lane.
class WeekDayStrip extends StatelessWidget {
  const WeekDayStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.weekStart,
    required this.onSelected,
  });

  final LocalDate selected;
  final LocalDate today;
  final int weekStart;
  final ValueChanged<LocalDate> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = selected.startOfWeek(weekStart);
    return SizedBox(
      height: 46,
      child: Row(
        children: [
          for (var index = 0; index < 7; index++)
            Expanded(
              child: _Day(
                date: start.addDays(index),
                selected: selected,
                today: today,
                onTap: () => onSelected(start.addDays(index)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.date, required this.selected, required this.today, required this.onTap});

  final LocalDate date;
  final LocalDate selected;
  final LocalDate today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final isSelected = date == selected;
    final isToday = date == today;

    return Semantics(
      button: true,
      selected: isSelected,
      label: formatFullDate(context, date.toDateTime()),
      child: Pressable(
        key: ValueKey('plan-week-day-${date.iso}'),
        onTap: onTap,
        scale: 0.94,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shortWeekday(context, date.weekday).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SundialType.label(9, color: isSelected || isToday ? c.accent : c.textTertiary),
            ),
            const SizedBox(height: 3),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? c.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected ? Border.all(color: c.accent, width: 1.3) : null,
              ),
              child: Text(
                '${date.day}',
                style: SundialType.body(
                  12.5,
                  weight: FontWeight.w700,
                  color: isSelected ? c.onAccent : c.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
