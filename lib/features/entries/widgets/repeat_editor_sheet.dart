import 'package:flutter/material.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// The repeat editor's result. [afterCompletion] wins; [rule] is null then.
class RepeatSelection {
  const RepeatSelection({this.rule, this.afterCompletion = false, this.intervalDays = 30});

  final RecurrenceRule? rule;
  final bool afterCompletion;
  final int intervalDays;

  bool get repeats => afterCompletion || rule != null;
}

enum _RepeatEnd { never, onDate, afterCount }

/// Opens Streak-style repeat controls plus Mane's repeat-after-completion mode.
Future<RepeatSelection?> showRepeatEditor(
  BuildContext context, {
  required RepeatSelection initial,
  required LocalDate anchor,
}) {
  return showAppSheet<RepeatSelection>(
    context: context,
    builder: (_) => _RepeatEditorSheet(initial: initial, anchor: anchor),
  );
}

class _RepeatEditorSheet extends StatefulWidget {
  const _RepeatEditorSheet({required this.initial, required this.anchor});

  final RepeatSelection initial;
  final LocalDate anchor;

  @override
  State<_RepeatEditorSheet> createState() => _RepeatEditorSheetState();
}

class _RepeatEditorSheetState extends State<_RepeatEditorSheet> {
  late bool _afterCompletion;
  late int _intervalDays;
  late RecurrenceFrequency? _frequency;
  late int _interval;
  late Set<int> _weekdays;
  late bool _monthlyOrdinal;
  late int _ordinal;
  late int _ordinalWeekday;
  late _RepeatEnd _end;
  late LocalDate? _until;
  late int _count;
  late final TextEditingController _intervalController;
  late final TextEditingController _countController;
  late final TextEditingController _afterController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _afterCompletion = initial.afterCompletion;
    _intervalDays = initial.intervalDays;
    final rule = initial.rule;
    _frequency = rule?.frequency;
    _interval = rule?.interval ?? 1;
    _weekdays = {...?rule?.weekdays};
    if (_weekdays.isEmpty && _frequency == RecurrenceFrequency.weekly) {
      _weekdays = {widget.anchor.weekday};
    }
    final ordinal = rule?.ordinalWeekdays.isNotEmpty == true ? rule!.ordinalWeekdays.first : null;
    _monthlyOrdinal = ordinal != null;
    _ordinal = ordinal?.ordinal ?? 1;
    _ordinalWeekday = ordinal?.weekday ?? widget.anchor.weekday;
    _until = rule?.until;
    _count = rule?.count ?? 10;
    _end = rule?.until != null
        ? _RepeatEnd.onDate
        : rule?.count != null
        ? _RepeatEnd.afterCount
        : _RepeatEnd.never;
    _intervalController = TextEditingController(text: '$_interval');
    _countController = TextEditingController(text: '$_count');
    _afterController = TextEditingController(text: '$_intervalDays');
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    _afterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: l10n.repeat,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.repeatAfterCompletion),
          subtitle: Text(l10n.repeatAfterCompletionSubtitle),
          value: _afterCompletion,
          onChanged: (value) => setState(() => _afterCompletion = value),
        ),
        if (_afterCompletion) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _afterController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.repeatAfterDaysLabel),
            onChanged: (value) => setState(() => _intervalDays = int.tryParse(value) ?? 0),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(l10n.repeat, style: ManeType.label(12, color: c.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _frequencyChip(context, null, l10n.repeatNever),
              _frequencyChip(context, RecurrenceFrequency.daily, l10n.repeatDaily),
              _frequencyChip(context, RecurrenceFrequency.weekly, l10n.repeatWeekly),
              _frequencyChip(context, RecurrenceFrequency.monthly, l10n.repeatMonthly),
              _frequencyChip(context, RecurrenceFrequency.yearly, l10n.repeatYearly),
            ],
          ),
          if (_frequency != null) ...[
            const SizedBox(height: 14),
            _intervalRow(context),
            if (_frequency == RecurrenceFrequency.weekly) ...[
              const SizedBox(height: 14),
              Text(l10n.repeatOnDays, style: ManeType.label(12, color: c.textSecondary)),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final weekday in weekdaysFrom(DateTime.monday))
                    FilterChip(
                      label: Text(shortWeekday(context, weekday)),
                      selected: _weekdays.contains(weekday),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _weekdays.add(weekday);
                        } else if (_weekdays.length > 1) {
                          _weekdays.remove(weekday);
                        }
                      }),
                    ),
                ],
              ),
            ],
            if (_frequency == RecurrenceFrequency.monthly) ...[
              const SizedBox(height: 14),
              Text(l10n.repeatMonthlyMode, style: ManeType.label(12, color: c.textSecondary)),
              const SizedBox(height: 7),
              ManeSegmented<bool>(
                segments: [
                  ManeSegment(value: false, label: l10n.repeatMonthlyDay),
                  ManeSegment(value: true, label: l10n.repeatMonthlyOrdinal),
                ],
                selected: _monthlyOrdinal,
                onChanged: (value) => setState(() => _monthlyOrdinal = value),
                compact: true,
              ),
              if (_monthlyOrdinal) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ManeSelectField(
                        label: l10n.repeatMonthlyOrdinal,
                        valueLabel: _ordinalLabel(context, _ordinal),
                        onTap: () => _pickOrdinal(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ManeSelectField(
                        label: l10n.repeatOnDays,
                        valueLabel: shortWeekday(context, _ordinalWeekday),
                        onTap: () => _pickOrdinalWeekday(context),
                      ),
                    ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    l10n.recurrenceOnDayOfMonth(widget.anchor.day),
                    style: ManeType.body(12, color: c.textSecondary),
                  ),
                ),
            ],
            if (_frequency == RecurrenceFrequency.yearly)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  formatFullDate(context, widget.anchor.toDateTime()),
                  style: ManeType.body(12, color: c.textSecondary),
                ),
              ),
            const SizedBox(height: 16),
            Text(l10n.repeatEnds, style: ManeType.label(12, color: c.textSecondary)),
            const SizedBox(height: 7),
            ManeSegmented<_RepeatEnd>(
              segments: [
                ManeSegment(value: _RepeatEnd.never, label: l10n.repeatEndsNever),
                ManeSegment(value: _RepeatEnd.onDate, label: l10n.repeatEndsOnDate),
                ManeSegment(value: _RepeatEnd.afterCount, label: l10n.repeatEndsAfter),
              ],
              selected: _end,
              onChanged: (value) => setState(() {
                _end = value;
                if (value == _RepeatEnd.onDate && _until == null) {
                  _until = widget.anchor.addDays(30);
                }
              }),
              compact: true,
            ),
            if (_end == _RepeatEnd.onDate) ...[
              const SizedBox(height: 9),
              ManeSelectField(
                label: l10n.repeatEndDate,
                valueLabel: formatFullDate(context, (_until ?? widget.anchor).toDateTime()),
                leading: const Icon(Icons.event_outlined),
                onTap: () => _pickUntil(context),
              ),
            ],
            if (_end == _RepeatEnd.afterCount) ...[
              const SizedBox(height: 9),
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.repeatOccurrences(_count)),
                onChanged: (value) => setState(() => _count = int.tryParse(value) ?? 1),
              ),
            ],
          ],
        ],
        const SizedBox(height: 20),
        FilledButton(onPressed: _save, child: Text(context.l10n.save)),
      ],
    );
  }

  Widget _frequencyChip(BuildContext context, RecurrenceFrequency? value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _frequency == value,
      onSelected: (_) => setState(() {
        _frequency = value;
        if (value == RecurrenceFrequency.weekly && _weekdays.isEmpty) {
          _weekdays = {widget.anchor.weekday};
        }
      }),
    );
  }

  Widget _intervalRow(BuildContext context) {
    final l10n = context.l10n;
    final unit = switch (_frequency!) {
      RecurrenceFrequency.daily => l10n.repeatUnitDays,
      RecurrenceFrequency.weekly => l10n.repeatUnitWeeks,
      RecurrenceFrequency.monthly => l10n.repeatUnitMonths,
      RecurrenceFrequency.yearly => l10n.repeatUnitYears,
    };
    return Row(
      children: [
        Text(l10n.repeatEvery, style: ManeType.body(13, color: context.mc.textSecondary)),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(vertical: 10)),
            onChanged: (value) => setState(() => _interval = int.tryParse(value) ?? 1),
          ),
        ),
        const SizedBox(width: 10),
        Text(unit, style: ManeType.body(13, color: context.mc.textSecondary)),
      ],
    );
  }

  String _ordinalLabel(BuildContext context, int ordinal) {
    final l10n = context.l10n;
    return switch (ordinal) {
      1 => l10n.repeatOrdinalFirst,
      2 => l10n.repeatOrdinalSecond,
      3 => l10n.repeatOrdinalThird,
      4 => l10n.repeatOrdinalFourth,
      _ => l10n.repeatOrdinalLast,
    };
  }

  Future<void> _pickOrdinal(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showManeSelectSheet<int>(
      context: context,
      title: l10n.repeatMonthlyOrdinal,
      selected: _ordinal,
      options: [
        for (final value in [1, 2, 3, 4, -1])
          ManeSelectOption(value: value, label: _ordinalLabel(context, value)),
      ],
    );
    if (picked != null && mounted) setState(() => _ordinal = picked);
  }

  Future<void> _pickOrdinalWeekday(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showManeSelectSheet<int>(
      context: context,
      title: l10n.repeatOnDays,
      selected: _ordinalWeekday,
      options: [
        for (final weekday in weekdaysFrom(DateTime.monday))
          ManeSelectOption(value: weekday, label: shortWeekday(context, weekday)),
      ],
    );
    if (picked != null && mounted) setState(() => _ordinalWeekday = picked);
  }

  Future<void> _pickUntil(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (_until ?? widget.anchor).toDateTime(),
      firstDate: widget.anchor.toDateTime(),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _until = LocalDate.fromDateTime(picked));
  }

  void _save() {
    if (_afterCompletion) {
      Navigator.of(
        context,
      ).pop(RepeatSelection(afterCompletion: true, intervalDays: _intervalDays <= 0 ? 1 : _intervalDays));
      return;
    }
    final frequency = _frequency;
    if (frequency == null) {
      Navigator.of(context).pop(const RepeatSelection());
      return;
    }

    final existing = widget.initial.rule;
    final rrule = RecurrenceRule(
      frequency: frequency,
      interval: _interval < 1 ? 1 : _interval,
      weekdays: frequency == RecurrenceFrequency.weekly
          ? (_weekdays.isEmpty ? {widget.anchor.weekday} : _weekdays)
          : const <int>{},
      monthDay: frequency == RecurrenceFrequency.monthly && !_monthlyOrdinal
          ? widget.anchor.day
          : frequency == RecurrenceFrequency.yearly
          ? widget.anchor.day
          : null,
      ordinalWeekdays: frequency == RecurrenceFrequency.monthly && _monthlyOrdinal
          ? [WeekdayOrdinal(weekday: _ordinalWeekday, ordinal: _ordinal)]
          : const <WeekdayOrdinal>[],
      until: _end == _RepeatEnd.onDate ? _until : null,
      count: _end == _RepeatEnd.afterCount ? (_count < 1 ? 1 : _count) : null,
      skipDates: existing?.skipDates ?? const <LocalDate>{},
      overrides: existing?.overrides ?? const <RecurrenceOverride>[],
    );
    Navigator.of(context).pop(RepeatSelection(rule: rrule));
  }
}
