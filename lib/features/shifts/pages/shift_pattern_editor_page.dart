import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sundial_core/sundial_core.dart';
import 'package:uuid/uuid.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/time/time_field.dart';
import '../../../core/timezone/timezone_picker.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../models/shift_checklist.dart';
import '../../../state/providers.dart';

class ShiftPatternEditorPage extends ConsumerStatefulWidget {
  const ShiftPatternEditorPage({super.key, this.pattern, this.contextId});

  final ShiftPattern? pattern;
  final String? contextId;

  @override
  ConsumerState<ShiftPatternEditorPage> createState() => _ShiftPatternEditorPageState();
}

class _ShiftPatternEditorPageState extends ConsumerState<ShiftPatternEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _timeZoneController;
  late String _spaceId;
  String? _contextId;
  late int _cycleDays;
  late LocalDate _anchorDate;
  late List<_SlotDraft> _slots;
  late List<ShiftException> _exceptions;
  late Set<String> _tagIds;
  late final TextEditingController _commuteController;
  late final TextEditingController _windDownController;
  List<_ChecklistDraft> _checklist = <_ChecklistDraft>[];
  Set<String> _initialChecklistIds = <String>{};
  bool _checklistLoading = false;
  late String _deviceTimeZone;
  late String _baseline;
  int _nextDraftId = 0;
  bool _saving = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    final pattern = widget.pattern;
    _deviceTimeZone = ref.read(deviceTimeZoneProvider);
    _nameController = TextEditingController(text: pattern?.name ?? '');
    _timeZoneController = TextEditingController(text: pattern?.timeZone ?? _deviceTimeZone);
    _spaceId = 'work';
    _contextId = pattern?.contextId ?? widget.contextId;
    _cycleDays = pattern?.cycleDays ?? 7;
    _anchorDate = pattern?.anchorDate ?? localDateAt(ref.read(nowProvider), _deviceTimeZone);
    _tagIds = {...?pattern?.tagIds};
    _commuteController = TextEditingController(text: pattern?.commuteMinutes?.toString() ?? '');
    _windDownController = TextEditingController(text: pattern?.windDownMinutes?.toString() ?? '');
    _slots = [
      for (final slot in pattern?.slots ?? const <ShiftSlot>[])
        _SlotDraft(
          id: _nextDraftId++,
          syncId: slot.syncId.isEmpty ? const Uuid().v4() : slot.syncId,
          dayIndex: slot.dayIndex,
          label: slot.label,
          startMinute: slot.startMinute,
          endMinute: slot.endMinute,
        ),
    ];
    _exceptions = [...?pattern?.exceptions];
    if (pattern != null) _loadChecklist(pattern.id);
    _baseline = _fingerprint();
  }

  Future<void> _loadChecklist(String patternId) async {
    setState(() => _checklistLoading = true);
    try {
      final items = await ref.read(repositoryProvider).readShiftChecklistItems(patternId);
      if (!mounted) return;
      setState(() {
        _checklist = [
          for (final item in items)
            _ChecklistDraft(
              id: item.id,
              label: item.label,
              dayIndex: item.dayIndex != null && item.dayIndex! < _cycleDays ? item.dayIndex : null,
            ),
        ];
        _initialChecklistIds = items.map((item) => item.id).toSet();
        _checklistLoading = false;
        _baseline = _fingerprint();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _checklistLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
    }
  }

  void _addChecklistItem() {
    setState(() => _checklist.add(_ChecklistDraft(id: const Uuid().v4(), label: '')));
  }

  void _removeChecklistItem(int index) {
    setState(() => _checklist.removeAt(index));
  }

  void _moveChecklistItem(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _checklist.length) return;
    setState(() {
      final item = _checklist.removeAt(index);
      _checklist.insert(target, item);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeZoneController.dispose();
    _commuteController.dispose();
    _windDownController.dispose();
    super.dispose();
  }

  int? _optionalMinutes(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  /// Everything the page can change, in a stable order. Comparing this with
  /// the value captured on load avoids false prompts when a field is reverted.
  String _fingerprint() {
    final slots = [..._slots]
      ..sort((a, b) {
        final byDay = a.dayIndex.compareTo(b.dayIndex);
        if (byDay != 0) return byDay;
        final byStart = a.startMinute.compareTo(b.startMinute);
        if (byStart != 0) return byStart;
        return a.endMinute.compareTo(b.endMinute);
      });
    final exceptions = [..._exceptions]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.type.index.compareTo(b.type.index);
      });
    final tags = _tagIds.toList()..sort();
    return [
      _nameController.text,
      _contextId ?? '',
      _timeZoneController.text,
      _commuteController.text.trim(),
      _windDownController.text.trim(),
      '$_cycleDays',
      _anchorDate.key,
      for (final slot in slots) '${slot.dayIndex}|${slot.label}|${slot.startMinute}|${slot.endMinute}',
      for (final exception in exceptions)
        '${exception.date.key}|${exception.type.name}|${exception.startMinute}|'
            '${exception.endMinute}|${exception.note}',
      tags.join(','),
      for (final item in _checklist) '${item.id}|${item.label}|${item.dayIndex}',
    ].join('\u0000');
  }

  bool get _dirty => _fingerprint() != _baseline;

  Future<void> _confirmLeave() async {
    if (_leaving) return;
    if (!_dirty) {
      _leave();
      return;
    }
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardChangesQuestion),
        content: Text(l10n.discardChangesBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.keepEditing)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardChanges),
          ),
        ],
      ),
    );
    if (discard == true && mounted) _leave();
  }

  void _leave() {
    _leaving = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    _spaceId = 'work';
    final availableTags = (ref.watch(tagsProvider).value ?? const <Tag>[])
        .where((tag) => tag.appliesTo(_spaceId))
        .toList();
    final contexts = ref.watch(contextsProvider(_spaceId)).value ?? const <PlannerContext>[];
    if (_contextId != null && !contexts.any((item) => item.id == _contextId)) {
      _contextId = null;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();

    final preview = _preview();
    final conflicts = preview?.findConflicts() ?? const <ShiftConflict>[];

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: SundialPage(
        title: widget.pattern == null ? l10n.newShiftPattern : l10n.editShiftPattern,
        actions: [
          GlassIconButton(
            icon: Icons.check_rounded,
            tooltip: l10n.savePattern,
            onTap: _saving ? null : _save,
          ),
          if (widget.pattern != null)
            GlassIconButton(
              icon: Icons.delete_outline,
              tooltip: l10n.delete,
              onTap: _saving ? null : _delete,
            ),
        ],
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
            children: [
              SundialTextField(
                controller: _nameController,
                label: l10n.patternName,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => value == null || value.trim().isEmpty ? l10n.patternNameRequired : null,
              ),
              if (contexts.isNotEmpty) ...[
                const SizedBox(height: 12),
                SundialSelectField(
                  label: l10n.context,
                  valueLabel:
                      contexts.where((item) => item.id == _contextId).firstOrNull?.name ?? l10n.noContext,
                  leading: const Icon(Icons.work_outline),
                  onTap: () async {
                    final picked = await showSundialSelectSheet<String>(
                      context: context,
                      title: l10n.context,
                      selected: _contextId ?? '',
                      options: [
                        SundialSelectOption(value: '', label: l10n.noContext),
                        for (final item in contexts)
                          SundialSelectOption(
                            value: item.id,
                            label: item.name,
                            leading: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Color(item.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    );
                    if (picked != null && mounted) {
                      setState(() => _contextId = picked.isEmpty ? null : picked);
                    }
                  },
                ),
              ],
              if (availableTags.isNotEmpty) ...[
                const SizedBox(height: 14),
                SectionLabel(l10n.shiftTags),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in availableTags)
                      FilterChip(
                        label: Text(tag.name),
                        selected: _tagIds.contains(tag.id),
                        avatar: CircleAvatar(backgroundColor: Color(tag.colorValue), radius: 5),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _tagIds.add(tag.id);
                          } else {
                            _tagIds.remove(tag.id);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              SundialSelectField(
                label: l10n.timeZone,
                valueLabel: _timeZoneController.text,
                leading: const Icon(Icons.public),
                onTap: () => _pickTimeZone(context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _commuteController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.commuteOverride,
                        helperText: l10n.inheritSleepBuffers,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final minutes = int.tryParse(text);
                        return minutes == null || minutes < 0 || minutes > 1440 ? l10n.invalidTimeZone : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _windDownController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.windDownOverride,
                        helperText: l10n.inheritSleepBuffers,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final minutes = int.tryParse(text);
                        return minutes == null || minutes < 0 || minutes > 1440 ? l10n.invalidTimeZone : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(l10n.cycleLength, style: theme.textTheme.bodyLarge)),
                  IconButton(
                    onPressed: _cycleDays > 1 ? () => _setCycleDays(_cycleDays - 1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(l10n.cycleLengthValue(_cycleDays), style: theme.textTheme.titleMedium),
                  IconButton(
                    onPressed: _cycleDays < 28 ? () => _setCycleDays(_cycleDays + 1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SundialDateField(
                label: l10n.anchorDate,
                valueLabel: formatFullDate(context, _anchorDate.toDateTime()),
                onTap: _pickAnchorDate,
              ),
              const SizedBox(height: 20),
              for (var index = 0; index < _cycleDays; index++) _buildDay(index, locale),
              const SizedBox(height: 8),
              _SectionHeader(title: l10n.exceptions, actionLabel: l10n.addException, onAction: _addException),
              if (_exceptions.isEmpty)
                Text(
                  l10n.noExceptions,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                for (final exception in _exceptions) _buildException(exception, locale),
              const SizedBox(height: 20),
              _SectionHeader(
                title: l10n.shiftChecklist,
                actionLabel: l10n.addChecklistItem,
                onAction: _addChecklistItem,
              ),
              if (_checklistLoading)
                const LinearProgressIndicator()
              else if (_checklist.isEmpty)
                Text(
                  l10n.noChecklistItems,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                )
              else
                for (var index = 0; index < _checklist.length; index++) _buildChecklistItem(index),
              const SizedBox(height: 20),
              _SectionHeader(title: l10n.preview),
              if (preview != null && conflicts.isNotEmpty)
                Text(
                  l10n.conflictsFound,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                )
              else if (preview != null)
                Text(
                  l10n.noConflicts,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              if (preview != null && conflicts.isEmpty)
                _Preview(
                  pattern: preview,
                  deviceTimeZone: _deviceTimeZone,
                  today: localDateAt(ref.watch(nowProvider), _deviceTimeZone),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.savePattern),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDay(int index, String locale) {
    final l10n = context.l10n;
    final date = _anchorDate.addDays(index);
    final daySlots = _slots.where((slot) => slot.dayIndex == index).toList();

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      radius: SundialRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.cycleDay(index + 1)} · ${DateFormat.E(locale).format(date.toDateTime())}',
                  style: SundialType.title(13.5, color: context.mc.text),
                ),
              ),
              Text(
                formatShortDate(context, date.toDateTime()),
                style: SundialType.body(11.5, color: context.mc.textSecondary),
              ),
            ],
          ),
          if (daySlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(l10n.noSlots, style: SundialType.body(11.5, color: context.mc.textTertiary)),
            ),
          for (final slot in daySlots) _buildSlot(slot),
          TextButton.icon(
            key: ValueKey('day-$index-add-slot'),
            onPressed: () => _addSlot(index),
            icon: const Icon(Icons.add, size: 17),
            label: Text(l10n.addSlot),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(int index) {
    final l10n = context.l10n;
    final c = context.mc;
    final item = _checklist[index];
    return Container(
      key: ValueKey('checklist-card-${item.id}'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 10),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(SundialRadii.sm),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: SundialTextField(
                  key: ValueKey('checklist-${item.id}'),
                  initialValue: item.label,
                  label: l10n.checklistItemLabel,
                  hintText: l10n.checklistItemHint,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => _checklist[index] = _checklist[index].copyWith(label: value),
                ),
              ),
              SundialMenuButton<String>(
                key: ValueKey('checklist-menu-${item.id}'),
                tooltip: l10n.moreActions,
                headerTitle: item.label.trim().isEmpty ? null : item.label,
                headerCaption: item.dayIndex == null
                    ? l10n.allDays
                    : l10n.checklistForDay(item.dayIndex! + 1),
                onSelected: (value) => switch (value) {
                  'up' => _moveChecklistItem(index, -1),
                  'down' => _moveChecklistItem(index, 1),
                  _ => _removeChecklistItem(index),
                },
                actions: [
                  if (index > 0)
                    SundialMenuAction(value: 'up', label: l10n.moveUp, icon: Icons.arrow_upward_rounded),
                  if (index < _checklist.length - 1)
                    SundialMenuAction(
                      value: 'down',
                      label: l10n.moveDown,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  SundialMenuAction(
                    value: 'delete',
                    label: l10n.delete,
                    icon: Icons.delete_outline_rounded,
                    destructive: true,
                    dividerBefore: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SundialSelectField(
            key: ValueKey('checklist-day-${item.id}'),
            label: l10n.checklistAppliesTo,
            valueLabel: item.dayIndex == null ? l10n.allDays : l10n.checklistForDay(item.dayIndex! + 1),
            leading: const Icon(Icons.repeat_rounded),
            onTap: () => _pickChecklistDay(index),
          ),
        ],
      ),
    );
  }

  Future<void> _pickChecklistDay(int index) async {
    final l10n = context.l10n;
    // A null result would double as "sheet dismissed", so the every-day
    // choice travels as -1 and is mapped back afterwards.
    final picked = await showSundialSelectSheet<int>(
      context: context,
      title: l10n.checklistAppliesTo,
      selected: _checklist[index].dayIndex ?? -1,
      options: [
        SundialSelectOption(value: -1, label: l10n.allDays),
        for (var day = 0; day < _cycleDays; day++)
          SundialSelectOption(value: day, label: l10n.checklistForDay(day + 1)),
      ],
    );
    if (picked == null || !mounted || index >= _checklist.length) return;
    setState(() => _checklist[index] = _checklist[index].copyWith(dayIndex: picked < 0 ? null : picked));
  }

  Widget _buildSlot(_SlotDraft slot) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
      decoration: BoxDecoration(
        color: context.mc.surfaceAlt,
        borderRadius: BorderRadius.circular(SundialRadii.sm),
        border: Border.all(color: context.mc.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SundialTextField(
                  key: ValueKey('slot-label-${slot.id}'),
                  initialValue: slot.label,
                  label: l10n.slotLabel,
                  onChanged: (value) => slot.label = value,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _slots.remove(slot)),
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.removeSlot,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SundialTimeField(
                  label: l10n.startTime,
                  valueLabel: _timeLabel(slot.startMinute),
                  initialMinute: slot.startMinute,
                  clearable: false,
                  onChanged: (minute) => setState(() => _applySlotTime(slot, true, minute)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SundialTimeField(
                  label: l10n.endTime,
                  valueLabel: _timeLabel(slot.endMinute),
                  initialMinute: slot.endMinute,
                  clearable: false,
                  onChanged: (minute) => setState(() => _applySlotTime(slot, false, minute)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildException(ShiftException exception, String locale) {
    final l10n = context.l10n;
    final type = switch (exception.type) {
      ShiftExceptionType.free => l10n.exceptionFree,
      ShiftExceptionType.override => l10n.exceptionOverride,
      ShiftExceptionType.extra => l10n.exceptionExtra,
    };
    final times = exception.hasTimes
        ? ' · ${_timeLabel(exception.startMinute!)} – ${_timeLabel(exception.endMinute!)}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: context.mc.surfaceAlt,
        borderRadius: BorderRadius.circular(SundialRadii.md),
        border: Border.all(color: context.mc.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatFullDate(context, exception.date.toDateTime())} · $type$times',
                    style: SundialType.body(12.5, color: context.mc.text),
                  ),
                  if (exception.note.isNotEmpty)
                    Text(exception.note, style: SundialType.body(11.5, color: context.mc.textSecondary)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _exceptions.remove(exception)),
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.delete,
          ),
        ],
      ),
    );
  }

  String _timeLabel(int minutes) {
    return formatMinuteLabel(context, minutes, overnightSuffix: context.l10n.overnightSuffix);
  }

  void _setCycleDays(int value) {
    setState(() {
      _cycleDays = value;
      _slots.removeWhere((slot) => slot.dayIndex >= value);
      // A stale day index would make the dropdown value invalid and crash.
      _checklist = [
        for (final item in _checklist)
          item.dayIndex != null && item.dayIndex! >= value ? item.copyWith(dayIndex: null) : item,
      ];
    });
  }

  void _addSlot(int dayIndex) {
    setState(() {
      // A new day starts from the nearest earlier day that already has slots, so
      // a repeating week does not have to be retyped. Adding another slot to a
      // day that already has one keeps the neutral default times.
      final source = _seedSlotsFor(dayIndex);
      if (source.isEmpty) {
        _slots.add(
          _SlotDraft(
            id: _nextDraftId++,
            syncId: const Uuid().v4(),
            dayIndex: dayIndex,
            label: '',
            startMinute: 9 * 60,
            endMinute: 17 * 60,
          ),
        );
        return;
      }
      for (final slot in source) {
        _slots.add(
          _SlotDraft(
            id: _nextDraftId++,
            syncId: const Uuid().v4(),
            dayIndex: dayIndex,
            label: slot.label,
            startMinute: slot.startMinute,
            endMinute: slot.endMinute,
          ),
        );
      }
    });
  }

  /// Slots to copy into an empty day, taken from the closest earlier day that
  /// has any. Day 1 and days before the first populated day fall back to the
  /// defaults. A day that already has slots gets a plain new slot instead.
  List<_SlotDraft> _seedSlotsFor(int dayIndex) {
    if (_slots.any((slot) => slot.dayIndex == dayIndex)) return const [];
    for (var index = dayIndex - 1; index >= 0; index--) {
      final slots = [
        for (final slot in _slots)
          if (slot.dayIndex == index) slot,
      ]..sort((a, b) => a.startMinute.compareTo(b.startMinute));
      if (slots.isNotEmpty) return slots;
    }
    return const [];
  }

  void _applySlotTime(_SlotDraft slot, bool isStart, int value) {
    if (isStart) {
      final duration = slot.endMinute - slot.startMinute;
      slot.startMinute = value;
      slot.endMinute = value + duration;
    } else {
      slot.endMinute = value > slot.startMinute ? value : value + 1440;
    }
  }

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchorDate.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() => _anchorDate = LocalDate.fromDateTime(picked));
  }

  Future<void> _addException() async {
    final exception = await showDialog<ShiftException>(
      context: context,
      builder: (context) => _ExceptionDialog(initialDate: _anchorDate),
    );
    if (exception != null && mounted) {
      setState(() => _exceptions.add(exception));
    }
  }

  ShiftPattern? _preview() {
    try {
      return ShiftPattern(
        id: widget.pattern?.id ?? 'preview',
        spaceId: _spaceId,
        contextId: _contextId,
        name: _nameController.text.trim(),
        timeZone: _timeZoneController.text.trim(),
        cycleDays: _cycleDays,
        anchorDate: _anchorDate,
        slots: [
          for (final draft in _slots)
            ShiftSlot(
              syncId: draft.syncId,
              dayIndex: draft.dayIndex,
              label: draft.label,
              startMinute: draft.startMinute,
              endMinute: draft.endMinute,
            ),
        ],
        exceptions: _exceptions,
        tagIds: _tagIds,
        commuteMinutes: _optionalMinutes(_commuteController),
        windDownMinutes: _optionalMinutes(_windDownController),
        enabled: true,
      );
    } on ArgumentError {
      return null;
    }
  }

  Future<void> _pickTimeZone(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showTimeZonePicker(
      context,
      selected: _timeZoneController.text,
      title: l10n.timeZone,
      searchHint: l10n.timezoneSearch,
      deviceLabel: l10n.timezoneDevice,
      deviceZone: _deviceTimeZone,
    );
    if (picked == null || !mounted) return;
    setState(() => _timeZoneController.text = picked.isEmpty ? _deviceTimeZone : picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final pattern = _preview();
    if (pattern == null) {
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.invalidTimeZone)));
      return;
    }
    if (pattern.findConflicts().isNotEmpty) {
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.conflictsFound)));
      return;
    }

    setState(() => _saving = true);
    final saved = ShiftPattern(
      id: widget.pattern?.id ?? const Uuid().v4(),
      spaceId: pattern.spaceId,
      contextId: pattern.contextId,
      name: pattern.name,
      timeZone: pattern.timeZone,
      cycleDays: pattern.cycleDays,
      anchorDate: pattern.anchorDate,
      slots: pattern.slots,
      exceptions: pattern.exceptions,
      tagIds: pattern.tagIds,
      commuteMinutes: pattern.commuteMinutes,
      windDownMinutes: pattern.windDownMinutes,
      enabled: widget.pattern?.enabled ?? true,
    );
    try {
      await ref.read(repositoryProvider).saveShiftPattern(saved, previous: widget.pattern);
      await ref.read(repositoryProvider).saveShiftChecklistItems(saved.id, [
        for (final draft in _checklist)
          if (draft.label.trim().isNotEmpty)
            ShiftChecklistItem(
              id: draft.id,
              patternId: saved.id,
              label: draft.label.trim(),
              dayIndex: draft.dayIndex,
            ),
      ], previousIds: _initialChecklistIds);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }
    if (!mounted) return;
    playUiSound(context, UiSound.confirm);
    _leave();
  }

  Future<void> _delete() async {
    final pattern = widget.pattern;
    if (pattern == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePatternQuestion),
        content: Text(context.l10n.deletePatternBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(repositoryProvider).deleteShiftPattern(pattern.id);
    if (!mounted) return;
    playUiSound(context, UiSound.remove);
    _leave();
  }
}

class _ChecklistDraft {
  const _ChecklistDraft({required this.id, required this.label, this.dayIndex});

  final String id;
  final String label;
  final int? dayIndex;

  _ChecklistDraft copyWith({String? label, Object? dayIndex = _unset}) => _ChecklistDraft(
    id: id,
    label: label ?? this.label,
    dayIndex: identical(dayIndex, _unset) ? this.dayIndex : dayIndex as int?,
  );
}

const _unset = Object();

class _SlotDraft {
  _SlotDraft({
    required this.id,
    required this.syncId,
    required this.dayIndex,
    required this.label,
    required this.startMinute,
    required this.endMinute,
  });

  final int id;
  final String syncId;
  final int dayIndex;
  String label;
  int startMinute;
  int endMinute;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SectionLabel(
      title,
      trailing: actionLabel == null ? null : TextButton(onPressed: onAction, child: Text(actionLabel!)),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.pattern, required this.deviceTimeZone, required this.today});

  final ShiftPattern pattern;
  final String deviceTimeZone;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final l10n = context.l10n;
    final occurrences = pattern.occurrencesBetween(today, today.addDays(27), viewerTimeZone: deviceTimeZone);
    if (occurrences.isEmpty) {
      return Text(l10n.noSlots, style: SundialType.body(11.5, color: c.textSecondary));
    }

    return Column(
      children: [
        for (final occurrence in occurrences.take(40))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    formatShortDate(context, occurrence.displayDate.toDateTime()),
                    style: SundialType.body(11.5, color: c.textSecondary),
                  ),
                ),
                Expanded(
                  child: Text(
                    occurrence.slot.label.isEmpty ? pattern.name : occurrence.slot.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_formatTime(context, occurrence.startAt, deviceTimeZone)} – '
                  '${_formatTime(context, occurrence.endAt, deviceTimeZone)}',
                  style: SundialType.body(11.5, color: c.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatTime(BuildContext context, DateTime instant, String timeZone) {
    final local = localDateTimeAt(instant, timeZone);
    return TimeOfDay(hour: local.hour, minute: local.minute).format(context);
  }
}

class _ExceptionDialog extends StatefulWidget {
  const _ExceptionDialog({required this.initialDate});

  final LocalDate initialDate;

  @override
  State<_ExceptionDialog> createState() => _ExceptionDialogState();
}

class _ExceptionDialogState extends State<_ExceptionDialog> {
  late LocalDate _date;
  ShiftExceptionType _type = ShiftExceptionType.free;
  int _startMinute = 9 * 60;
  int _endMinute = 17 * 60;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addException),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SundialDateField(
              label: l10n.exceptionDate,
              valueLabel: formatFullDate(context, _date.toDateTime()),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ShiftExceptionType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.type, border: const OutlineInputBorder()),
              items: [
                DropdownMenuItem(value: ShiftExceptionType.free, child: Text(l10n.exceptionFree)),
                DropdownMenuItem(value: ShiftExceptionType.override, child: Text(l10n.exceptionOverride)),
                DropdownMenuItem(value: ShiftExceptionType.extra, child: Text(l10n.exceptionExtra)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            if (_type != ShiftExceptionType.free) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SundialTimeField(
                      label: l10n.startTime,
                      valueLabel: _timeLabel(_startMinute),
                      initialMinute: _startMinute,
                      clearable: false,
                      onChanged: (minute) => setState(() => _startMinute = minute % 1440),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SundialTimeField(
                      label: l10n.endTime,
                      valueLabel: _timeLabel(_endMinute),
                      initialMinute: _endMinute,
                      clearable: false,
                      onChanged: (minute) => setState(() => _endMinute = minute % 1440),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: l10n.exceptionNote, border: const OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  String _timeLabel(int minutes) {
    return formatMinuteLabel(context, minutes, overnightSuffix: context.l10n.overnightSuffix);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = LocalDate.fromDateTime(picked));
  }

  void _save() {
    Navigator.of(context).pop(
      ShiftException(
        syncId: const Uuid().v4(),
        date: _date,
        type: _type,
        startMinute: _type == ShiftExceptionType.free ? null : _startMinute,
        endMinute: _type == ShiftExceptionType.free ? null : _endMinute,
        note: _noteController.text.trim(),
      ),
    );
  }
}
