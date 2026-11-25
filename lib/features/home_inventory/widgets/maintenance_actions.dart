import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/time/time_field.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../models/maintenance_log.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

Future<void> showLogMaintenanceSheet(
  BuildContext context, {
  required Entry gadget,
  required LocalDate today,
}) => showAppSheet<void>(
  context: context,
  builder: (_) => _LogServiceSheet(gadget: gadget, today: today),
);

Future<void> showRescheduleMaintenanceSheet(
  BuildContext context, {
  required Entry gadget,
  required LocalDate today,
}) => showAppSheet<void>(
  context: context,
  builder: (_) => _RescheduleSheet(gadget: gadget, today: today),
);

Future<void> showServiceHistorySheet(BuildContext context, Entry gadget) => showAppSheet<void>(
  context: context,
  builder: (_) => _ServiceHistorySheet(gadget: gadget),
);

class _LogServiceSheet extends ConsumerStatefulWidget {
  const _LogServiceSheet({required this.gadget, required this.today});

  final Entry gadget;
  final LocalDate today;

  @override
  ConsumerState<_LogServiceSheet> createState() => _LogServiceSheetState();
}

class _LogServiceSheetState extends ConsumerState<_LogServiceSheet> {
  late LocalDate _performedOn = widget.today;
  final _note = TextEditingController();
  late bool _addCalendarEvent = false;
  late int _startMinute = widget.gadget.startMinute ?? 9 * 60;
  late int _durationMinutes = _initialDuration();
  bool _busy = false;

  int _initialDuration() {
    final start = widget.gadget.startMinute;
    final end = widget.gadget.endMinute;
    if (start == null || end == null) return 60;
    return (end - start).clamp(15, 12 * 60);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final interval = widget.gadget.repeatAfterCompletionDays ?? 0;
    final nextDue = _performedOn.addDays(interval <= 0 ? 1 : interval);
    return AppSheet(
      title: l10n.logServiceTitle,
      subtitle: widget.gadget.title,
      children: [
        SundialDateField(
          label: l10n.serviceDate,
          valueLabel: formatFullDate(context, _performedOn.toDateTime()),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.serviceNote, hintText: l10n.serviceNoteHint),
        ),
        const SizedBox(height: 14),
        _ToggleRow(
          icon: Icons.event_available_outlined,
          title: l10n.addCalendarEvent,
          subtitle: l10n.addCalendarEventBody,
          value: _addCalendarEvent,
          onChanged: (value) => setState(() => _addCalendarEvent = value),
        ),
        if (_addCalendarEvent) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SundialTimeField(
                  label: l10n.serviceAt,
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
        const SizedBox(height: 12),
        Text(
          l10n.gadgetNextDue(formatFullDate(context, nextDue.toDateTime())),
          style: SundialType.body(11.5, color: c.textSecondary),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.logService),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedOn.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: widget.today.toDateTime(),
    );
    if (picked == null || !mounted) return;
    setState(() => _performedOn = LocalDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final next = await _logServiceOrThrow();
      if (!mounted) return;
      if (next == null) {
        setState(() => _busy = false);
        playUiSound(context, UiSound.error);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotLogService)));
        return;
      }
      playUiSound(context, UiSound.complete);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.serviceLogged(formatFullDate(context, next.toDateTime())))));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotSave('$error'))));
    }
  }

  Future<LocalDate?> _logServiceOrThrow() async {
    final gadget = widget.gadget;
    final now = DateTime.now().toUtc();
    final timeZone = ref.read(deviceTimeZoneProvider);
    final event = _addCalendarEvent
        ? Entry(
            id: const Uuid().v4(),
            spaceId: 'home',
            contextId: gadget.contextId,
            title: context.l10n.serviceEventTitle(gadget.title),
            icon: gadget.icon,
            kind: EntryKind.event,
            date: _performedOn,
            allDay: false,
            startMinute: _startMinute,
            endMinute: _startMinute + _durationMinutes,
            timeZone: timeZone,
            status: EntryStatus.done,
            completedAt: now,
            createdAt: now,
            updatedAt: now,
          )
        : null;
    final next = await ref
        .read(repositoryProvider)
        .logMaintenanceService(
          entryId: gadget.id,
          performedOn: _performedOn,
          note: _note.text.trim(),
          durationMinutes: _addCalendarEvent ? _durationMinutes : null,
          calendarEvent: event,
        );
    await ref.read(reminderCoordinatorProvider).reschedule();
    return next;
  }
}

class _RescheduleSheet extends ConsumerStatefulWidget {
  const _RescheduleSheet({required this.gadget, required this.today});

  final Entry gadget;
  final LocalDate today;

  @override
  ConsumerState<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends ConsumerState<_RescheduleSheet> {
  late LocalDate _date = widget.gadget.date ?? widget.today;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: l10n.rescheduleMaintenance,
      subtitle: widget.gadget.title,
      children: [
        Text(l10n.rescheduleBody, style: SundialType.body(12.5, color: c.textSecondary)),
        const SizedBox(height: 14),
        SundialDateField(
          label: l10n.newDueDate,
          valueLabel: formatFullDate(context, _date.toDateTime()),
          onTap: _pickDate,
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.reschedule),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = LocalDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final next = await ref.read(repositoryProvider).rescheduleMaintenance(widget.gadget.id, _date);
      await ref.read(reminderCoordinatorProvider).reschedule();
      if (!mounted) return;
      if (next == null) {
        setState(() => _busy = false);
        playUiSound(context, UiSound.error);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotReschedule)));
        return;
      }
      playUiSound(context, UiSound.confirm);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.rescheduled(formatFullDate(context, next.toDateTime())))));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotSave('$error'))));
    }
  }
}

class _ServiceHistorySheet extends ConsumerWidget {
  const _ServiceHistorySheet({required this.gadget});

  final Entry gadget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final logs = ref.watch(maintenanceLogsProvider(gadget.id)).value ?? const <MaintenanceLog>[];
    return AppSheet(
      title: l10n.serviceHistory,
      subtitle: gadget.title,
      children: [
        if (logs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(l10n.serviceHistoryEmpty, style: SundialType.body(13, color: c.textSecondary)),
          )
        else
          for (var index = 0; index < logs.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: c.homeSoft, shape: BoxShape.circle),
                    child: Icon(Icons.check, size: 18, color: c.home),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatFullDate(context, logs[index].performedOn.toDateTime()),
                          style: SundialType.body(13, weight: FontWeight.w700, color: c.text),
                        ),
                        if (logs[index].note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(logs[index].note, style: SundialType.body(12, color: c.textSecondary)),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          l10n.serviceHistoryNext(
                                formatShortDate(context, logs[index].nextDue.toDateTime()),
                              ) +
                              (logs[index].durationMinutes == null
                                  ? ''
                                  : ' · ${l10n.durationMinutes(logs[index].durationMinutes!)}'),
                          style: SundialType.body(11, color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < logs.length - 1) const Divider(height: 1, indent: 45),
          ],
      ],
    );
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
