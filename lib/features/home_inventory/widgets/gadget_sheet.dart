import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/time/time_field.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../spaces/widgets/space_controls.dart';
import '../maintenance_dates.dart';

/// Adds or edits a home gadget.
///
/// The gadget is a maintenance entry with an interval that starts on the date
/// the service actually happened. It can optionally reserve a timed block on
/// the calendar so the work has a real slot instead of only a due date.
Future<void> showGadgetEditor(
  BuildContext context, {
  required String homeId,
  required LocalDate today,
  Entry? gadget,
  LocalDate? lastServiced,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _GadgetSheet(homeId: homeId, today: today, gadget: gadget, lastServiced: lastServiced),
  );
}

class _GadgetSheet extends ConsumerStatefulWidget {
  const _GadgetSheet({required this.homeId, required this.today, this.gadget, this.lastServiced});

  final String homeId;
  final LocalDate today;
  final Entry? gadget;
  final LocalDate? lastServiced;

  @override
  ConsumerState<_GadgetSheet> createState() => _GadgetSheetState();
}

class _GadgetSheetState extends ConsumerState<_GadgetSheet> {
  late final _name = TextEditingController(text: widget.gadget?.title ?? '');
  late final _notes = TextEditingController(text: widget.gadget?.notes ?? '');
  late final _interval = TextEditingController(text: '${widget.gadget?.repeatAfterCompletionDays ?? 90}');
  late String _icon = widget.gadget?.icon ?? 'build';
  late LocalDate? _lastServiced =
      widget.lastServiced ?? (widget.gadget == null ? null : maintenanceServiceDate(widget.gadget!));
  late bool _blockCalendar = widget.gadget != null && !widget.gadget!.allDay;
  late int _startMinute = widget.gadget?.startMinute ?? 9 * 60;
  late int _durationMinutes = _initialDuration();
  bool _intervalDirty = false;
  bool _lastServicedDirty = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _interval.dispose();
    super.dispose();
  }

  int _initialDuration() {
    final gadget = widget.gadget;
    if (gadget == null || gadget.startMinute == null || gadget.endMinute == null) return 60;
    return (gadget.endMinute! - gadget.startMinute!).clamp(15, 12 * 60);
  }

  int get _intervalDays {
    final parsed = int.tryParse(_interval.text.trim());
    return parsed == null || parsed <= 0 ? 90 : parsed.clamp(1, 3650);
  }

  LocalDate get _nextDue {
    final existing = widget.gadget;
    if (existing != null && !_intervalDirty && !_lastServicedDirty && existing.date != null) {
      return existing.date!;
    }
    return nextMaintenanceDue(
      lastServiced: _lastServiced,
      currentDue: existing?.date,
      currentInterval: existing?.repeatAfterCompletionDays,
      interval: _intervalDays,
      today: widget.today,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: widget.gadget == null ? l10n.addGadget : l10n.gadgetEdit,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.gadget == null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.gadgetName),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            ContextAvatar(icon: _icon, colorValue: c.home.toARGB32(), size: 44),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _chooseIcon,
              icon: const Icon(Icons.category_outlined, size: 18),
              label: Text(l10n.gadgetIcon),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _interval,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() => _intervalDirty = true),
          decoration: InputDecoration(labelText: l10n.gadgetIntervalDays),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final days in const [30, 90, 180, 365])
              _PresetChip(
                label: l10n.daysValue(days),
                selected: _intervalDays == days,
                onTap: () => setState(() {
                  _interval.text = '$days';
                  _intervalDirty = true;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.gadgetNextDue(formatFullDate(context, _nextDue.toDateTime())),
          style: SundialType.body(11.5, color: c.textSecondary),
        ),
        const SizedBox(height: 14),
        SundialDateField(
          label: l10n.gadgetLastServiced,
          valueLabel: _lastServiced == null
              ? l10n.gadgetNeverServiced
              : formatFullDate(context, _lastServiced!.toDateTime()),
          onTap: _pickLastServiced,
          onClear: _lastServiced == null
              ? null
              : () => setState(() {
                  _lastServiced = null;
                  _lastServicedDirty = true;
                }),
          clearTooltip: l10n.clearDate,
        ),
        const SizedBox(height: 16),
        _ToggleRow(
          icon: Icons.event_available_outlined,
          title: l10n.blockCalendar,
          subtitle: l10n.blockCalendarBody,
          value: _blockCalendar,
          onChanged: (value) => setState(() => _blockCalendar = value),
        ),
        if (_blockCalendar) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SundialTimeField(
                  label: l10n.startTime,
                  valueLabel: formatMinuteLabel(context, _startMinute),
                  initialMinute: _startMinute,
                  clearable: false,
                  onChanged: (minute) => setState(() => _startMinute = minute % 1440),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DurationField(
                  value: _durationMinutes,
                  onChanged: (value) => setState(() => _durationMinutes = value),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.note),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(widget.gadget == null ? l10n.addGadget : l10n.saveChanges),
          ),
        ),
        if (widget.gadget != null)
          TextButton(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l10n.delete),
          ),
      ],
    );
  }

  Future<void> _chooseIcon() async {
    final picked = await showIconPicker(
      context,
      selected: _icon,
      recommended: [...SundialIcons.homeRecommended, 'build', 'kitchen', 'devices', 'cleaning'],
    );
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  Future<void> _pickLastServiced() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (_lastServiced ?? widget.today).toDateTime(),
      firstDate: DateTime(2000),
      lastDate: widget.today.toDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _lastServiced = LocalDate.fromDateTime(picked);
      _lastServicedDirty = true;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final repository = ref.read(repositoryProvider);
    final now = DateTime.now().toUtc();
    final timeZone = ref.read(deviceTimeZoneProvider);
    // All-day rows keep their service date in UTC; timed rows use the zone they
    // block the calendar in. Reading either with toLocal() can shift a day.
    final storedZone = _blockCalendar ? timeZone : 'UTC';
    final lastServiced = _lastServiced == null ? null : instantAt(_lastServiced!, 12 * 60, storedZone);
    final endMinute = _blockCalendar ? _startMinute + _durationMinutes : null;
    try {
      final existing = widget.gadget;
      if (existing == null) {
        await repository.saveEntry(
          Entry(
            id: const Uuid().v4(),
            spaceId: 'home',
            contextId: widget.homeId,
            title: name,
            notes: _notes.text.trim(),
            icon: _icon,
            kind: EntryKind.obligation,
            date: _nextDue,
            allDay: !_blockCalendar,
            startMinute: _blockCalendar ? _startMinute : null,
            endMinute: endMinute,
            timeZone: _blockCalendar ? timeZone : null,
            repeatAfterCompletionDays: _intervalDays,
            lastCompletedAt: lastServiced,
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await repository.saveEntry(
          existing.copyWith(
            title: name,
            notes: _notes.text.trim(),
            icon: _icon,
            date: _nextDue,
            allDay: !_blockCalendar,
            startMinute: _blockCalendar ? _startMinute : null,
            endMinute: endMinute,
            timeZone: _blockCalendar ? timeZone : null,
            repeatAfterCompletionDays: _intervalDays,
            lastCompletedAt: lastServiced,
            updatedAt: now,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (!mounted) return;
    await ref.read(reminderCoordinatorProvider).reschedule();
    if (!mounted) return;
    playUiSound(context, UiSound.confirm);
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final gadget = widget.gadget;
    if (gadget == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteEntryQuestion),
        content: Text(l10n.deleteEntryBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(repositoryProvider).deleteEntry(gadget.id);
      await ref.read(reminderCoordinatorProvider).reschedule();
      if (!mounted) return;
      playUiSound(context, UiSound.remove);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotDelete('$error'))));
    }
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, size: 19, color: c.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SundialType.body(13, weight: FontWeight.w700, color: c.text),
                ),
                Text(subtitle, style: SundialType.body(11, color: c.textSecondary)),
              ],
            ),
          ),
          Semantics(
            label: title,
            child: Switch(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.accentSoft : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.accent.withValues(alpha: 0.35) : c.border),
        ),
        child: Text(label, style: SundialType.label(11.5, color: selected ? c.accent : c.textSecondary)),
      ),
    );
  }
}

class _DurationField extends StatelessWidget {
  const _DurationField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = value % 60 == 0 ? l10n.durationHours(value ~/ 60) : l10n.durationMinutes(value);
    return SundialSelectField(
      label: l10n.duration,
      valueLabel: label,
      leading: const Icon(Icons.timer_outlined),
      onTap: () async {
        final picked = await showSundialSelectSheet<int>(
          context: context,
          title: l10n.duration,
          selected: value,
          options: [
            for (final minutes in const [30, 60, 90, 120, 240, 480])
              SundialSelectOption(
                value: minutes,
                label: minutes % 60 == 0 ? l10n.durationHours(minutes ~/ 60) : l10n.durationMinutes(minutes),
              ),
          ],
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
