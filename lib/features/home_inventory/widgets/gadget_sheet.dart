import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../spaces/widgets/space_controls.dart';

/// Adds or edits a home gadget.
///
/// Gadgets stay maintenance entries: completion advances the next date from the
/// completion day. The sheet adds the two fields entries cannot express on their
/// own, an icon and the last service date, and keeps the due date stable when
/// only the name or notes change.
Future<void> showGadgetEditor(
  BuildContext context, {
  required String homeId,
  required LocalDate today,
  Entry? gadget,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _GadgetSheet(homeId: homeId, today: today, gadget: gadget),
  );
}

class _GadgetSheet extends ConsumerStatefulWidget {
  const _GadgetSheet({required this.homeId, required this.today, this.gadget});

  final String homeId;
  final LocalDate today;
  final Entry? gadget;

  @override
  ConsumerState<_GadgetSheet> createState() => _GadgetSheetState();
}

class _GadgetSheetState extends ConsumerState<_GadgetSheet> {
  late final TextEditingController _name = TextEditingController(text: widget.gadget?.title ?? '');
  late final TextEditingController _notes = TextEditingController(text: widget.gadget?.notes ?? '');
  late final TextEditingController _interval = TextEditingController(
    text: '${widget.gadget?.repeatAfterCompletionDays ?? 30}',
  );
  late String _icon = widget.gadget?.icon ?? 'build';
  late LocalDate? _lastServiced = widget.gadget?.lastCompletedAt == null
      ? null
      : LocalDate.fromDateTime(widget.gadget!.lastCompletedAt!.toLocal());
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _interval.dispose();
    super.dispose();
  }

  int get _intervalDays {
    final parsed = int.tryParse(_interval.text.trim());
    return parsed == null || parsed <= 0 ? 30 : parsed.clamp(1, 3650);
  }

  LocalDate get _nextDue => nextMaintenanceDue(
    lastServiced: _lastServiced,
    currentDue: widget.gadget?.date,
    currentInterval: widget.gadget?.repeatAfterCompletionDays,
    interval: _intervalDays,
    today: widget.today,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return AppSheet(
      title: widget.gadget == null ? l10n.addGadget : l10n.gadgetEdit,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
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
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: l10n.gadgetIntervalDays),
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
          onClear: _lastServiced == null ? null : () => setState(() => _lastServiced = null),
          clearTooltip: l10n.clearDate,
        ),
        const SizedBox(height: 8),
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
    setState(() => _lastServiced = LocalDate.fromDateTime(picked));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    final repository = ref.read(repositoryProvider);
    final now = DateTime.now().toUtc();
    final lastServiced = _lastServiced?.toDateTime().toUtc();
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
            allDay: true,
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
            repeatAfterCompletionDays: _intervalDays,
            lastCompletedAt: lastServiced,
            updatedAt: now,
          ),
        );
      }
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
    final gadget = widget.gadget;
    if (gadget == null) return;
    setState(() => _busy = true);
    await ref.read(repositoryProvider).deleteEntry(gadget.id);
    if (mounted) Navigator.of(context).pop();
  }
}
