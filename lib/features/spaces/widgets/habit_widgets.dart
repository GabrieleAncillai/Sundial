import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mane_core/mane_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../pages/habit_history_page.dart';
import 'space_controls.dart';

Future<void> showHabitEditor(
  BuildContext context, {
  Habit? habit,
  String? contextId,
  List<String> recommendedIcons = const <String>[],
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _HabitEditorSheet(habit: habit, contextId: contextId, recommendedIcons: recommendedIcons),
  );
}

class _HabitEditorSheet extends ConsumerStatefulWidget {
  const _HabitEditorSheet({this.habit, this.contextId, required this.recommendedIcons});

  final Habit? habit;
  final String? contextId;
  final List<String> recommendedIcons;

  @override
  ConsumerState<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends ConsumerState<_HabitEditorSheet> {
  late final TextEditingController _name;
  late String _icon;
  late int _color;
  late int _target;
  late Set<int> _weekdays;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _icon = habit?.icon ?? (widget.recommendedIcons.isEmpty ? 'star' : widget.recommendedIcons.first);
    _color = habit?.colorValue ?? spacePalette[3];
    _target = habit?.targetPerWeek ?? 7;
    _weekdays = {...?habit?.weekdays};
    if (_weekdays.isEmpty) _weekdays = {1, 2, 3, 4, 5, 6, 7};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: widget.habit == null ? l10n.addHabit : l10n.editHabit,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.habitName),
        ),
        const SizedBox(height: 14),
        Text(l10n.targetPerWeek, style: ManeType.label(12, color: c.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var target = 1; target <= 7; target++)
              ChoiceChip(
                label: Text(l10n.timesPerWeek(target)),
                selected: _target == target,
                onSelected: (_) => setState(() => _target = target),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(l10n.habitActiveDays, style: ManeType.label(12, color: c.textSecondary)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var day = 1; day <= 7; day++)
              FilterChip(
                label: Text(_weekdayLabel(context, day)),
                selected: _weekdays.contains(day),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _weekdays.add(day);
                  } else if (_weekdays.length > 1) {
                    _weekdays.remove(day);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ContextAvatar(icon: _icon, colorValue: _color, size: 46, radius: 14),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _chooseIcon,
              icon: const Icon(Icons.category_outlined, size: 18),
              label: Text(l10n.chooseIcon),
            ),
            TextButton.icon(
              onPressed: _chooseColor,
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: Text(l10n.color),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(widget.habit == null ? l10n.addHabit : l10n.saveChanges),
          ),
        ),
        if (widget.habit != null)
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => HabitHistoryPage(habit: widget.habit!))),
            icon: const Icon(Icons.history, size: 18),
            label: Text(l10n.habitHistory),
          ),
        if (widget.habit != null)
          TextButton(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l10n.delete),
          ),
      ],
    );
  }

  String _weekdayLabel(BuildContext context, int day) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 2026-11-09 is a Monday, so day 1..7 maps onto that week.
    return DateFormat.E(locale).format(DateTime(2026, 11, 8 + day));
  }

  Future<void> _chooseIcon() async {
    final picked = await showIconPicker(context, selected: _icon, recommended: widget.recommendedIcons);
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  Future<void> _chooseColor() async {
    final picked = await showColorPicker(context, selected: _color, title: context.l10n.color);
    if (picked != null && mounted) setState(() => _color = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final existing = widget.habit;
    final habit = Habit(
      id: existing?.id ?? const Uuid().v4(),
      spaceId: 'personal',
      contextId: existing?.contextId ?? widget.contextId,
      name: name,
      colorValue: _color,
      icon: _icon,
      targetPerWeek: _target,
      weekdays: {..._weekdays},
      position: existing?.position ?? 0,
    );
    try {
      await ref.read(repositoryProvider).saveHabit(habit);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final habit = widget.habit;
    if (habit == null) return;
    setState(() => _busy = true);
    await ref.read(repositoryProvider).deleteHabit(habit.id);
    if (mounted) Navigator.of(context).pop();
  }
}

class HabitCard extends ConsumerWidget {
  const HabitCard({super.key, required this.habit, this.recommendedIcons = const <String>[], this.onEdit});

  final Habit habit;
  final List<String> recommendedIcons;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final today = localDateAt(ref.watch(nowProvider), ref.watch(deviceTimeZoneProvider));
    final weekStart = ref.watch(settingsProvider).weekStart;
    final completions = ref.watch(habitCompletionsProvider).value?[habit.id] ?? const <LocalDate>{};
    final doneToday = completions.contains(today);
    final progress = habit.weekProgress(completions, today, weekStart);
    final streak = habit.streak(completions, today, weekStart: weekStart);
    final color = Color(habit.colorValue);
    final start = today.startOfWeek(weekStart);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ContextAvatar(icon: habit.icon, colorValue: habit.colorValue, size: 42, radius: 13),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: ManeType.body(14.5, weight: FontWeight.w700, color: c.text),
                    ),
                    Text(
                      habit.isDaily ? l10n.streakDays(streak) : l10n.streakWeeks(streak),
                      style: ManeType.label(10.5, color: c.textTertiary),
                    ),
                  ],
                ),
              ),
              Pressable(
                onTap: () =>
                    ref.read(repositoryProvider).setHabitCompleted(habit.id, today, completed: !doneToday),
                semanticButton: true,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: doneToday ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: doneToday ? color : c.borderStrong, width: 1.7),
                  ),
                  child: doneToday ? const Icon(Icons.check, size: 19, color: Colors.white) : null,
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: l10n.editHabit,
                  onPressed: onEdit,
                  icon: Icon(Icons.more_horiz, size: 19, color: c.textTertiary),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: _DayTick(
                    date: start.addDays(index),
                    done: completions.contains(start.addDays(index)),
                    scheduled: habit.isScheduled(start.addDays(index)),
                    today: start.addDays(index) == today,
                    color: color,
                    onTap: !habit.isScheduled(start.addDays(index)) || start.addDays(index).isAfter(today)
                        ? null
                        : () => ref
                              .read(repositoryProvider)
                              .setHabitCompleted(
                                habit.id,
                                start.addDays(index),
                                completed: !completions.contains(start.addDays(index)),
                              ),
                  ),
                ),
              const SizedBox(width: 8),
              Text('$progress/${habit.cleanTarget}', style: ManeType.label(11, color: c.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayTick extends StatelessWidget {
  const _DayTick({
    required this.date,
    required this.done,
    required this.scheduled,
    required this.today,
    required this.color,
    this.onTap,
  });

  final LocalDate date;
  final bool done;
  final bool scheduled;
  final bool today;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      children: [
        Text(
          DateFormat.E(locale).format(date.toDateTime()).substring(0, 1),
          style: ManeType.label(9, color: scheduled ? (today ? color : c.textTertiary) : c.textTertiary),
        ),
        const SizedBox(height: 4),
        Pressable(
          onTap: onTap,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: done ? color : (scheduled ? c.surfaceAlt : Colors.transparent),
              shape: BoxShape.circle,
              border: scheduled
                  ? Border.all(
                      color: today && !done
                          ? color
                          : done
                          ? color
                          : c.border,
                      width: today ? 1.6 : 1,
                    )
                  : null,
            ),
            child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
        ),
      ],
    );
  }
}
