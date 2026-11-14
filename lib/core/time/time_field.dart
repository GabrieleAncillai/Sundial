import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../i18n/l10n.dart';
import '../widgets/app_sheet.dart';
import '../widgets/mane_select_field.dart';

/// Parses a typed wall-clock time into minutes from midnight.
///
/// Accepts `9`, `9:30`, `0930`, `21:15`, `9:30 pm` and `9.30`. A bare hour is
/// read on the 24-hour clock unless [use24Hour] is false and an AM/PM suffix
/// makes the intent explicit. Returns null when the text is not a time.
int? parseTimeInput(String raw, {required bool use24Hour}) {
  var text = raw.trim().toLowerCase().replaceAll('.', '').replaceAll(' ', '');
  if (text.isEmpty) return null;

  var afternoon = false;
  var morning = false;
  for (final suffix in const ['am', 'pm']) {
    if (text.endsWith(suffix)) {
      text = text.substring(0, text.length - suffix.length);
      afternoon = suffix == 'pm';
      morning = suffix == 'am';
      break;
    }
  }
  if (text.endsWith(':')) return null;

  // Compact forms such as `930` or `2130` are one colon away from a time.
  if (!text.contains(':') && text.length >= 3 && text.length <= 4 && int.tryParse(text) != null) {
    text = '${text.substring(0, text.length - 2)}:${text.substring(text.length - 2)}';
  }

  final parts = text.split(':');
  if (parts.length > 2) return null;
  final hourText = parts.first;
  final minuteText = parts.length == 2 ? parts[1] : '';
  if (hourText.isEmpty || hourText.length > 2 || minuteText.length > 2) return null;
  final hour = int.tryParse(hourText);
  if (hour == null) return null;

  int minute;
  if (minuteText.isEmpty) {
    minute = 0;
  } else {
    final parsed = int.tryParse(minuteText);
    if (parsed == null) return null;
    minute = parsed;
  }
  if (minute < 0 || minute > 59) return null;

  if (afternoon || morning) {
    if (hour < 1 || hour > 12) return null;
    final base = hour % 12;
    return (afternoon ? base + 12 : base) * 60 + minute;
  }
  if (hour < 0 || hour > 23) return null;
  return hour * 60 + minute;
}

/// Formats minutes from midnight as an editable value for [parseTimeInput].
String formatTimeInput(int minute, {required bool use24Hour}) {
  final normalized = minute % 1440;
  final hour = normalized ~/ 60;
  final minutePart = (normalized % 60).toString().padLeft(2, '0');
  if (use24Hour) return '${hour.toString().padLeft(2, '0')}:$minutePart';
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$hour12:$minutePart ${hour < 12 ? 'AM' : 'PM'}';
}

/// Formats a stored minute for display, using the locale's clock convention.
/// Values of 1440 or more are shown on the next day.
String formatMinuteLabel(BuildContext context, int minute, {String? overnightSuffix}) {
  final normalized = minute % 1440;
  final label = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60));
  return minute >= 1440 && overnightSuffix != null ? '$label $overnightSuffix' : label;
}

/// A compact time picker shared by the entry editor, shifts, reminders and
/// settings.
///
/// Phones keep the platform sheet. Wide layouts get a text-entry dialog with
/// 15-minute snaps, exact minutes and keyboard submit, because the stock dial
/// is a poor fit for a mouse and keyboard.
Future<int?> showManeTimePicker(BuildContext context, {int? initialMinute, String? title}) {
  if (MediaQuery.sizeOf(context).width < appSheetCompactBreakpoint) {
    final initial = initialMinute ?? 9 * 60;
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (initial ~/ 60) % 24, minute: initial % 60),
    ).then((picked) => picked == null ? null : picked.hour * 60 + picked.minute);
  }
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => _TimeEntryDialog(initialMinute: initialMinute, title: title),
  );
}

/// A labelled time row with an optional clear action.
///
/// [valueLabel] is supplied by the caller so overnight values keep their own
/// wording. Tapping anywhere on the row opens [showManeTimePicker].
class ManeTimeField extends StatelessWidget {
  const ManeTimeField({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.onChanged,
    required this.initialMinute,
    this.icon = Icons.schedule,
    this.clearTooltip,
    this.clearable = true,
    this.enabled = true,
    this.onClear,
  });

  final String label;
  final String valueLabel;
  final ValueChanged<int> onChanged;
  final int? initialMinute;
  final IconData icon;
  final String? clearTooltip;
  final bool clearable;
  final bool enabled;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: ManeSelectField(
            label: label,
            valueLabel: valueLabel,
            leading: Icon(icon, size: 19),
            enabled: enabled,
            onTap: enabled
                ? () async {
                    final picked = await showManeTimePicker(
                      context,
                      initialMinute: initialMinute,
                      title: label,
                    );
                    if (picked != null) onChanged(picked);
                  }
                : null,
          ),
        ),
        if (clearable && initialMinute != null)
          IconButton(
            onPressed: enabled ? onClear : null,
            icon: const Icon(Icons.close, size: 18),
            tooltip: clearTooltip ?? l10n.clearTime,
          ),
      ],
    );
  }
}

class _TimeEntryDialog extends StatefulWidget {
  const _TimeEntryDialog({required this.initialMinute, this.title});

  final int? initialMinute;
  final String? title;

  @override
  State<_TimeEntryDialog> createState() => _TimeEntryDialogState();
}

class _TimeEntryDialogState extends State<_TimeEntryDialog> {
  late final bool _use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);
  late final TextEditingController _controller = TextEditingController(
    text: formatTimeInput(widget.initialMinute ?? 9 * 60, use24Hour: _use24Hour),
  );
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  int? _parse() => parseTimeInput(_controller.text, use24Hour: _use24Hour);

  void _submit() {
    final minute = _parse();
    if (minute == null) {
      setState(() => _error = context.l10n.timeFieldInvalid);
      return;
    }
    Navigator.of(context).pop(minute);
  }

  void _snap(int minuteOfHour) {
    final current = _parse() ?? widget.initialMinute ?? 9 * 60;
    final hour = current ~/ 60;
    _controller.text = formatTimeInput(hour * 60 + minuteOfHour, use24Hour: _use24Hour);
    setState(() => _error = null);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: Text(widget.title ?? l10n.time),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    hintText: _use24Hour ? '21:30' : '9:30 PM',
                    errorText: _error,
                    prefixIcon: const Icon(Icons.schedule, size: 19),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final minute in const [0, 15, 30, 45])
                      ChoiceChip(
                        label: Text(':${minute.toString().padLeft(2, '0')}'),
                        selected: (_parse() ?? -1) % 60 == minute,
                        onSelected: (_) => _snap(minute),
                        labelStyle: ManeType.label(12, color: c.textSecondary),
                        showCheckmark: false,
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
            FilledButton(onPressed: _submit, child: Text(l10n.setTime)),
          ],
        ),
      ),
    );
  }
}
