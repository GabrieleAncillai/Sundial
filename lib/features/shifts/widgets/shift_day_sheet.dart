import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/time/time_field.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';

/// Opens the per-day shift sheet for [date].
Future<void> showShiftDaySheet({required BuildContext context, required LocalDate date}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => ShiftDaySheet(date: date),
  );
}

/// Sets what each work pattern does on one date: follow the pattern, work, or
/// take the day free.
///
/// The choice is stored as a single [ShiftException] on the pattern, so a
/// floating weekend (work Saturday or Sunday, decided weekly) and a monthly
/// free Saturday both use the same primitive. Days are never rewritten as
/// one-off entries.
class ShiftDaySheet extends ConsumerStatefulWidget {
  const ShiftDaySheet({super.key, required this.date});

  final LocalDate date;

  @override
  ConsumerState<ShiftDaySheet> createState() => _ShiftDaySheetState();
}

class _ShiftDaySheetState extends ConsumerState<ShiftDaySheet> {
  String? _savingId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final patterns = (ref.watch(shiftPatternsProvider).value ?? const <ShiftPattern>[])
        .where((pattern) => pattern.enabled)
        .toList();

    return AppSheet(
      title: l10n.shiftDayTitle,
      subtitle: formatFullDate(context, widget.date.toDateTime()),
      children: [
        if (patterns.isEmpty)
          AppEmptyState(icon: Icons.event_busy_outlined, title: l10n.noShiftPatterns, compact: true)
        else
          for (final pattern in patterns) _buildPattern(pattern),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
        ),
      ],
    );
  }

  Widget _buildPattern(ShiftPattern pattern) {
    final c = context.mc;
    final l10n = context.l10n;
    final state = shiftDayOverrideFor(pattern, widget.date);
    final slots = pattern.slotsFor(widget.date);
    final multiple = slots.length > 1;
    final saving = _savingId == pattern.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(SundialRadii.md),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(pattern.name, style: SundialType.title(14, color: c.text)),
              ),
              if (saving)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 2),
          Text(_summary(state, slots), style: SundialType.body(12, color: c.textSecondary)),
          const SizedBox(height: 8),
          SundialSegmented<ShiftDayOverride>(
            segments: [
              SundialSegment(value: ShiftDayOverride.pattern, label: l10n.shiftDayUsual),
              // A day with several shifts can only be free or follow the
              // pattern; collapsing it into one shift would lose the others.
              if (!multiple || state == ShiftDayOverride.working)
                SundialSegment(value: ShiftDayOverride.working, label: l10n.shiftDayWorking),
              SundialSegment(value: ShiftDayOverride.free, label: l10n.shiftDayFree),
            ],
            selected: state,
            onChanged: (value) => _select(pattern, value),
            compact: true,
          ),
          if (multiple) ...[
            const SizedBox(height: 6),
            Text(l10n.shiftDayMultipleHint, style: SundialType.body(11.5, color: c.textTertiary)),
          ],
        ],
      ),
    );
  }

  String _summary(ShiftDayOverride state, List<ShiftSlot> slots) {
    final l10n = context.l10n;
    if (state == ShiftDayOverride.free || slots.isEmpty) return l10n.shiftDayFreeAllDay;
    if (slots.length > 1) return l10n.shiftDayShiftCount(slots.length);
    final slot = slots.first;
    final start = formatMinuteLabel(context, slot.startMinute, overnightSuffix: l10n.overnightSuffix);
    final end = formatMinuteLabel(context, slot.endMinute, overnightSuffix: l10n.overnightSuffix);
    return '${l10n.shiftDayWorking} · $start – $end';
  }

  Future<void> _select(ShiftPattern pattern, ShiftDayOverride value) async {
    if (_savingId != null) return;
    if (shiftDayOverrideFor(pattern, widget.date) == value) return;

    if (value == ShiftDayOverride.working) {
      final times = await showDialog<({int startMinute, int endMinute})>(
        context: context,
        builder: (_) => _ShiftTimesDialog(initial: suggestedShiftTimes(pattern, widget.date)),
      );
      if (times == null || !mounted) return;
      await _apply(
        pattern,
        ShiftException(
          syncId: 'day:${pattern.id}:${widget.date.key}',
          date: widget.date,
          type: ShiftExceptionType.override,
          startMinute: times.startMinute,
          endMinute: times.endMinute,
        ),
      );
      return;
    }

    await _apply(
      pattern,
      value == ShiftDayOverride.free
          ? ShiftException(
              syncId: 'day:${pattern.id}:${widget.date.key}',
              date: widget.date,
              type: ShiftExceptionType.free,
            )
          : null,
    );
  }

  Future<void> _apply(ShiftPattern pattern, ShiftException? exception) async {
    setState(() => _savingId = pattern.id);
    try {
      await ref.read(repositoryProvider).setShiftDayOverride(pattern.id, widget.date, exception);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }
}

class _ShiftTimesDialog extends StatefulWidget {
  const _ShiftTimesDialog({this.initial});

  final ({int startMinute, int endMinute})? initial;

  @override
  State<_ShiftTimesDialog> createState() => _ShiftTimesDialogState();
}

class _ShiftTimesDialogState extends State<_ShiftTimesDialog> {
  late int _startMinute;
  late int _endMinute;

  @override
  void initState() {
    super.initState();
    _startMinute = widget.initial?.startMinute ?? 9 * 60;
    _endMinute = widget.initial?.endMinute ?? 17 * 60;
  }

  bool get _overnight => _endMinute <= _startMinute;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.shiftTimes),
      content: Row(
        children: [
          Expanded(
            child: SundialTimeField(
              label: l10n.startTime,
              valueLabel: formatMinuteLabel(context, _startMinute),
              initialMinute: _startMinute,
              clearable: false,
              onChanged: (minute) => setState(() => _startMinute = minute),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SundialTimeField(
              label: l10n.endTime,
              valueLabel: formatMinuteLabel(
                context,
                _overnight ? _endMinute + 1440 : _endMinute,
                overnightSuffix: l10n.overnightSuffix,
              ),
              initialMinute: _endMinute,
              clearable: false,
              onChanged: (minute) => setState(() => _endMinute = minute),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((startMinute: _startMinute, endMinute: _overnight ? _endMinute + 1440 : _endMinute)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
