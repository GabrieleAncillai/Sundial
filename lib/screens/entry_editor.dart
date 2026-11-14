import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mane_core/mane_core.dart';
import 'package:uuid/uuid.dart';

import '../core/i18n/date_labels.dart';
import '../core/i18n/l10n.dart';
import '../core/i18n/recurrence_label.dart';
import '../core/i18n/reminder_label.dart';
import '../core/sound/sound_service.dart';
import '../core/time/time_field.dart';
import '../core/timezone/timezone_picker.dart';
import '../core/widgets/ui_kit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../features/entries/widgets/repeat_editor_sheet.dart';
import '../features/reminders/widgets/reminder_offset_sheet.dart';
import '../models/reminder.dart';
import '../state/providers.dart';
import '../state/settings_controller.dart';

const _editorFallbackSpaces = <Space>[
  Space(id: 'personal', name: 'Personal', colorValue: 0xFFB07D5C, position: 0),
  Space(id: 'work', name: 'Work', colorValue: 0xFF4A6FA5, position: 1),
  Space(id: 'home', name: 'Home', colorValue: 0xFF5B7F6B, position: 2),
];

Future<void> showEntryEditor(
  BuildContext context, {
  Entry? entry,
  LocalDate? initialDate,
  int? initialStartMinute,
  int? initialEndMinute,
  String? initialSpaceId,
  String? initialContextId,
  String? initialUnitId,
  String? initialProjectId,
  int? initialMaintenanceDays,
  required List<Space> spaces,
}) {
  if (entry?.readOnly == true) {
    return _showReadOnlyEntry(context, entry!);
  }
  return showAppSheet<void>(
    context: context,
    builder: (context) => EntryEditorSheet(
      entry: entry,
      initialDate: initialDate,
      initialStartMinute: initialStartMinute,
      initialEndMinute: initialEndMinute,
      initialSpaceId: initialSpaceId,
      initialContextId: initialContextId,
      initialUnitId: initialUnitId,
      initialProjectId: initialProjectId,
      initialMaintenanceDays: initialMaintenanceDays,
      spaces: spaces,
    ),
  );
}

Future<void> _showReadOnlyEntry(BuildContext context, Entry entry) {
  final l10n = context.l10n;
  final c = context.mc;
  return showAppSheet<void>(
    context: context,
    builder: (sheetContext) => AppSheet(
      children: [
        Text(entry.title, style: ManeType.headline(21, color: c.text)),
        const SizedBox(height: 6),
        Text(l10n.importedEvent, style: ManeType.label(12, color: c.accent)),
        const SizedBox(height: 12),
        Text(l10n.readOnlyNotice, style: ManeType.body(14, color: c.textSecondary)),
        if (entry.notes.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(entry.notes, style: ManeType.body(14, color: c.text)),
        ],
        const SizedBox(height: 22),
        FilledButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(l10n.close)),
      ],
    ),
  );
}

class EntryEditorSheet extends ConsumerStatefulWidget {
  const EntryEditorSheet({
    super.key,
    required this.spaces,
    this.entry,
    this.initialDate,
    this.initialStartMinute,
    this.initialEndMinute,
    this.initialSpaceId,
    this.initialContextId,
    this.initialUnitId,
    this.initialProjectId,
    this.initialMaintenanceDays,
  });

  final List<Space> spaces;
  final Entry? entry;
  final LocalDate? initialDate;
  final int? initialStartMinute;
  final int? initialEndMinute;
  final String? initialSpaceId;
  final String? initialContextId;
  final String? initialUnitId;
  final String? initialProjectId;
  final int? initialMaintenanceDays;

  @override
  ConsumerState<EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends ConsumerState<EntryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late String _spaceId;
  late EntryKind _kind;
  late EntryPriority _priority;
  String? _contextId;
  String? _projectId;
  late LocalDate _date;
  late LocalDate? _endDate;
  late bool _allDay;
  int? _startMinute;
  int? _endMinute;
  late String _timeZone;
  RecurrenceRule? _recurrence;
  late bool _repeatAfterCompletion;
  late int _repeatDays;
  late String _deviceTimeZone;
  late Set<String> _tagIds;
  late Set<LocalDate> _skipDates;
  late Set<int> _reminderOffsets;
  late Set<int> _reminderTimes;
  bool _onlyThisOccurrence = false;
  bool _remindersLoaded = true;
  bool _remindersLoadFailed = false;
  List<Reminder> _disabledReminders = const <Reminder>[];
  bool _saving = false;

  List<Space> get _spaces => widget.spaces.isEmpty ? _editorFallbackSpaces : widget.spaces;

  /// Derived from which time fields are present, matching the four task
  /// shapes in the v2 request. The UI never stores a separate mode.
  EntryTiming get _timing {
    if (_allDay) return EntryTiming.anytime;
    if (_startMinute != null && _endMinute != null) return EntryTiming.scheduled;
    if (_startMinute != null) return EntryTiming.clockIn;
    if (_endMinute != null) return EntryTiming.deadline;
    return EntryTiming.anytime;
  }

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _deviceTimeZone = ref.read(deviceTimeZoneProvider);
    _titleController = TextEditingController(text: entry?.title ?? '');
    _notesController = TextEditingController(text: entry?.notes ?? '');
    final requestedSpace = entry?.spaceId ?? widget.initialSpaceId;
    _spaceId = requestedSpace != null && _spaces.any((space) => space.id == requestedSpace)
        ? requestedSpace
        : _spaces.first.id;
    _kind = entry?.kind ?? EntryKind.task;
    _priority = entry?.priority ?? EntryPriority.none;
    _contextId = entry?.contextId ?? widget.initialUnitId ?? widget.initialContextId;
    _projectId = entry?.projectId ?? widget.initialProjectId;
    _date = entry?.date ?? widget.initialDate ?? localDateAt(ref.read(nowProvider), _deviceTimeZone);
    _endDate = entry?.endDate;
    _allDay = entry?.allDay ?? false;
    // Never invent times for an existing entry: a clock-in, deadline or anytime
    // task must keep its shape after an edit.
    _startMinute = entry != null ? entry.startMinute : (widget.initialStartMinute ?? 9 * 60);
    _endMinute = entry != null ? entry.endMinute : (widget.initialEndMinute ?? 10 * 60);
    final planningZone = ref.read(settingsProvider).timezoneOverride;
    _timeZone = entry?.timeZone ?? (planningZone.isEmpty ? _deviceTimeZone : planningZone);
    _recurrence = entry?.recurrence;
    _repeatAfterCompletion = entry?.repeatAfterCompletionDays != null;
    _repeatDays = entry?.repeatAfterCompletionDays ?? 30;
    if (entry == null && widget.initialMaintenanceDays != null) {
      _kind = EntryKind.obligation;
      _repeatAfterCompletion = true;
      _repeatDays = widget.initialMaintenanceDays!;
    }
    _tagIds = {...?entry?.tagIds};
    _skipDates = {...?entry?.recurrence?.skipDates};
    if (entry == null) {
      _reminderOffsets = {...ref.read(settingsProvider).defaultReminderOffsets};
      _reminderTimes = <int>{};
    } else {
      _reminderOffsets = <int>{};
      _reminderTimes = <int>{};
      _remindersLoaded = false;
      _loadReminders(entry.id);
    }
  }

  Future<void> _loadReminders(String entryId) async {
    try {
      final reminders = await ref.read(repositoryProvider).readRemindersForEntry(entryId);
      if (!mounted) return;
      setState(() {
        _reminderOffsets = {
          for (final reminder in reminders)
            if (reminder.enabled && !reminder.isAtTime) reminder.offsetMinutes,
        };
        _reminderTimes = {
          for (final reminder in reminders)
            if (reminder.enabled && reminder.timeMinute != null) reminder.timeMinute!,
        };
        _disabledReminders = reminders.where((reminder) => !reminder.enabled).toList();
        _remindersLoaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _remindersLoaded = true;
        _remindersLoadFailed = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotLoadReminders('$error'))));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final l10n = context.l10n;
    if (widget.entry?.readOnly == true) {
      final entry = widget.entry!;
      return AppSheet(
        children: [
          Text(entry.title, style: ManeType.headline(21, color: c.text)),
          const SizedBox(height: 6),
          Text(l10n.importedEvent, style: ManeType.label(12, color: c.accent)),
          const SizedBox(height: 12),
          Text(l10n.readOnlyNotice, style: ManeType.body(14, color: c.textSecondary)),
          if (entry.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(entry.notes, style: ManeType.body(14, color: c.text)),
          ],
          const SizedBox(height: 22),
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
        ],
      );
    }
    final title = widget.entry == null ? l10n.newEntry : l10n.editEntry;
    final availableTags = (ref.watch(tagsProvider).value ?? const <Tag>[])
        .where((tag) => tag.appliesTo(_spaceId))
        .toList();
    final contexts = ref.watch(contextsProvider(_spaceId)).value ?? const <PlannerContext>[];
    final projects = ref.watch(projectsProvider(_spaceId)).value ?? const <Project>[];
    if (_contextId != null && !contexts.any((item) => item.id == _contextId)) _contextId = null;
    if (_contextId == null && contexts.length == 1) _contextId = contexts.single.id;
    if (_projectId != null && !projects.any((item) => item.id == _projectId)) _projectId = null;

    return AppSheet(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: ManeType.headline(20, color: c.text)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.close,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.titleQuestion),
                validator: (value) => value == null || value.trim().isEmpty ? l10n.titleRequired : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.notesOptional, alignLabelWithHint: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ManeSelectField(
                      label: l10n.space,
                      valueLabel: _spaceName(_spaceId),
                      leading: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: _spaceColor(_spaceId), shape: BoxShape.circle),
                      ),
                      onTap: () => _pickSpace(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ManeSelectField(
                      label: l10n.type,
                      valueLabel: entryKindLabel(context, _kind),
                      leading: const Icon(Icons.category_outlined),
                      onTap: () => _pickKind(context),
                    ),
                  ),
                ],
              ),
              if (contexts.isNotEmpty) ...[
                const SizedBox(height: 12),
                ManeSelectField(
                  label: l10n.context,
                  valueLabel: _contextName(contexts, _contextId) ?? l10n.noContext,
                  leading: _contextColor(contexts, _contextId) == null
                      ? const Icon(Icons.work_outline)
                      : Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: _contextColor(contexts, _contextId),
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () => _pickContext(context, contexts),
                ),
              ],
              if (projects.isNotEmpty) ...[
                const SizedBox(height: 12),
                ManeSelectField(
                  label: l10n.project,
                  valueLabel: _projectName(projects, _projectId) ?? l10n.noProject,
                  leading: const Icon(Icons.folder_outlined),
                  onTap: () => _pickProject(context, projects),
                ),
              ],
              const SizedBox(height: 12),
              if (availableTags.isNotEmpty) ...[
                Text(l10n.categories, style: ManeType.label(12.5, color: c.textSecondary)),
                const SizedBox(height: 6),
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
                const SizedBox(height: 12),
              ],
              Text(l10n.priority, style: ManeType.label(12.5, color: c.textSecondary)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final priority in EntryPriority.values)
                    ChoiceChip(
                      label: Text(_priorityLabel(context, priority)),
                      selected: _priority == priority,
                      onSelected: (_) => setState(() => _priority = priority),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.allDay),
                value: _allDay,
                onChanged: (value) => setState(() {
                  _allDay = value;
                  if (value) {
                    _startMinute = null;
                    _endMinute = null;
                    _endDate = null;
                  }
                }),
              ),
              if (!_allDay)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(_timingIcon(_timing), size: 16, color: c.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _timingHint(context, _timing),
                          style: ManeType.body(11.5, color: c.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              _PickerRow(
                icon: Icons.event_outlined,
                label: l10n.date,
                value: formatFullDate(context, _date.toDateTime()),
                onTap: _pickDate,
              ),
              if (_allDay || (_startMinute != null && _endMinute != null)) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PickerRow(
                        icon: Icons.date_range_outlined,
                        label: l10n.endDate,
                        value: _endDate == null
                            ? l10n.singleDay
                            : formatFullDate(context, _endDate!.toDateTime()),
                        onTap: _pickEndDate,
                      ),
                    ),
                    if (_endDate != null)
                      IconButton(
                        onPressed: () => setState(() => _endDate = null),
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: l10n.singleDay,
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 0, 0),
                  child: Text(l10n.multiDayHint, style: ManeType.body(11, color: c.textTertiary)),
                ),
              ],
              if (!_allDay) ...[
                const SizedBox(height: 10),
                ManeTimeField(
                  label: l10n.starts,
                  icon: Icons.schedule,
                  valueLabel: _startMinute == null ? l10n.noTime : _timeLabel(_startMinute!),
                  initialMinute: _startMinute,
                  clearTooltip: l10n.clearStart,
                  onClear: () => setState(() => _startMinute = null),
                  onChanged: (minute) => setState(() => _applyStart(minute)),
                ),
                const SizedBox(height: 10),
                ManeTimeField(
                  label: _timing == EntryTiming.deadline ? l10n.deadline : l10n.ends,
                  icon: _timing == EntryTiming.deadline ? Icons.flag_outlined : Icons.schedule_outlined,
                  valueLabel: _endMinute == null ? l10n.noTime : _timeLabel(_endMinute!),
                  initialMinute: _endMinute,
                  clearTooltip: l10n.clearEnd,
                  onClear: () => setState(() => _endMinute = null),
                  onChanged: (minute) => setState(() => _applyEnd(minute)),
                ),
                const SizedBox(height: 10),
                ManeSelectField(
                  label: l10n.timeZone,
                  valueLabel: _timeZone,
                  leading: const Icon(Icons.public),
                  onTap: () => _pickTimeZone(context),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
                  child: Text(
                    l10n.timesDefinedIn(_timeZone),
                    style: ManeType.body(11.5, color: c.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ManeSelectField(
                label: l10n.repeat,
                valueLabel: _repeatSummary(context),
                leading: const Icon(Icons.repeat),
                onTap: () => _editRepeat(context),
              ),
              if (widget.entry?.recurrence != null && widget.initialDate != null) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.onlyThisOccurrence),
                  subtitle: Text(l10n.onlyThisOccurrenceSubtitle),
                  value: _onlyThisOccurrence,
                  onChanged: (value) => setState(() => _onlyThisOccurrence = value),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      final date = widget.initialDate!;
                      if (!_skipDates.remove(date)) _skipDates.add(date);
                    }),
                    icon: Icon(
                      _skipDates.contains(widget.initialDate) ? Icons.undo : Icons.event_busy_outlined,
                      size: 18,
                    ),
                    label: Text(
                      _skipDates.contains(widget.initialDate)
                          ? l10n.skippedOccurrences
                          : l10n.skipThisOccurrence,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.reminders, style: ManeType.label(12.5, color: c.textSecondary)),
                  ),
                  TextButton.icon(
                    onPressed: _saving ? null : _editReminders,
                    icon: const Icon(Icons.notifications_outlined, size: 18),
                    label: Text(l10n.addReminder),
                  ),
                ],
              ),
              if (_remindersLoadFailed)
                Text(l10n.remindersUnavailable, style: ManeType.body(11.5, color: c.danger))
              else if (_reminderOffsets.isEmpty && _reminderTimes.isEmpty)
                Text(l10n.remindersOff, style: ManeType.body(11.5, color: c.textTertiary))
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final offset in (_reminderOffsets.toList()..sort()))
                      InputChip(
                        label: Text(reminderOffsetLabel(context, offset)),
                        onDeleted: _saving ? null : () => setState(() => _reminderOffsets.remove(offset)),
                      ),
                    for (final minute in (_reminderTimes.toList()..sort()))
                      InputChip(
                        label: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60)),
                        ),
                        onDeleted: _saving ? null : () => setState(() => _reminderTimes.remove(minute)),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving || !_remindersLoaded ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.entry == null ? l10n.addEntry : l10n.saveChanges),
                ),
              ),
              if (widget.entry != null)
                TextButton(
                  onPressed: _saving ? null : _delete,
                  style: TextButton.styleFrom(foregroundColor: c.danger),
                  child: Text(l10n.delete),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _timingHint(BuildContext context, EntryTiming timing) => switch (timing) {
    EntryTiming.scheduled => context.l10n.timingScheduledHint,
    EntryTiming.clockIn => context.l10n.timingClockInHint,
    EntryTiming.deadline => context.l10n.timingDeadlineHint,
    EntryTiming.anytime => context.l10n.timingAnytimeHint,
  };

  String _priorityLabel(BuildContext context, EntryPriority priority) => switch (priority) {
    EntryPriority.none => context.l10n.priorityNone,
    EntryPriority.low => context.l10n.priorityLow,
    EntryPriority.medium => context.l10n.priorityMedium,
    EntryPriority.high => context.l10n.priorityHigh,
  };

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
    if (picked == null || !mounted) return;
    setState(() {
      _date = LocalDate.fromDateTime(picked);
      if (_endDate != null && _endDate!.isBefore(_date)) _endDate = null;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (_endDate ?? _date).toDateTime(),
      firstDate: _date.toDateTime(),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    final end = LocalDate.fromDateTime(picked);
    setState(() => _endDate = end.isAfter(_date) ? end : null);
  }

  void _applyStart(int minute) {
    final previous = _startMinute;
    _startMinute = minute;
    final end = _endMinute;
    if (end == null) return;
    if (previous == null) {
      if (end <= _startMinute!) _endMinute = _startMinute! + 60;
    } else {
      _endMinute = _startMinute! + (end - previous);
    }
  }

  void _applyEnd(int picked) {
    var end = picked;
    // A single-day end at or before the start runs into tomorrow. An explicit
    // end date already carries the day, so keep the picked wall-clock time.
    final start = _startMinute;
    if (start != null && _endDate == null && end <= start) end += 1440;
    _endMinute = end;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final existing = widget.entry;
    if (existing?.readOnly == true) return;
    final scheduled = !_allDay && _startMinute != null && _endMinute != null;
    final endDate = (scheduled || _allDay) && _endDate != null && _endDate!.isAfter(_date) ? _endDate : null;
    if (scheduled && endDate == null && _endMinute! <= _startMinute!) {
      ref.read(soundControllerProvider).play(UiSound.error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.endAfterStartError)));
      return;
    }
    final singleOccurrence =
        _onlyThisOccurrence && existing?.recurrence != null && widget.initialDate != null;

    setState(() => _saving = true);
    final now = DateTime.now();
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();
    var recurrence = _repeatAfterCompletion ? null : _recurrence;
    if (recurrence != null) recurrence = recurrence.copyWith(skipDates: _skipDates);
    if (singleOccurrence) {
      final original = widget.initialDate!;
      final overrides = [
        ...existing!.recurrence!.overrides.where((override) => override.date != original),
        if (!_skipDates.contains(original))
          RecurrenceOverride(
            date: original,
            dateOverride: _date == original ? null : _date,
            startMinute: _allDay ? null : _startMinute,
            endMinute: _allDay ? null : _endMinute,
            allDay: _allDay == existing.allDay ? null : _allDay,
            title: title == existing.title ? null : title,
            notes: notes == existing.notes ? null : notes,
          ),
      ];
      recurrence = existing.recurrence!.copyWith(skipDates: _skipDates, overrides: overrides);
    }

    final entry = existing == null
        ? Entry(
            id: const Uuid().v4(),
            spaceId: _spaceId,
            title: title,
            notes: notes,
            kind: _kind,
            date: _date,
            endDate: endDate,
            startMinute: _allDay ? null : _startMinute,
            endMinute: _allDay ? null : _endMinute,
            timeZone: _allDay || (_startMinute == null && _endMinute == null) ? null : _timeZone,
            contextId: _contextId,
            projectId: _projectId,
            priority: _priority,
            tagIds: _tagIds,
            allDay: _allDay,
            recurrence: recurrence,
            repeatAfterCompletionDays: _repeatAfterCompletion ? (_repeatDays <= 0 ? 1 : _repeatDays) : null,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            spaceId: _spaceId,
            title: singleOccurrence ? existing.title : title,
            notes: singleOccurrence ? existing.notes : notes,
            kind: _kind,
            date: singleOccurrence ? existing.date : _date,
            endDate: singleOccurrence ? existing.endDate : endDate,
            startMinute: singleOccurrence ? existing.startMinute : (_allDay ? null : _startMinute),
            endMinute: singleOccurrence ? existing.endMinute : (_allDay ? null : _endMinute),
            timeZone: singleOccurrence
                ? existing.timeZone
                : (_allDay || (_startMinute == null && _endMinute == null) ? null : _timeZone),
            contextId: singleOccurrence ? existing.contextId : _contextId,
            projectId: singleOccurrence ? existing.projectId : _projectId,
            priority: _priority,
            tagIds: _tagIds,
            allDay: singleOccurrence ? existing.allDay : _allDay,
            recurrence: recurrence,
            repeatAfterCompletionDays: _repeatAfterCompletion ? (_repeatDays <= 0 ? 1 : _repeatDays) : null,
            updatedAt: now,
          );

    try {
      final repository = ref.read(repositoryProvider);
      await repository.saveEntry(entry);
      // A failed reminder read must not silently erase reminders on save.
      if (!_remindersLoadFailed) {
        await repository.saveRemindersForEntry(entry.id, [
          ..._disabledReminders,
          for (final offset in _reminderOffsets)
            Reminder(id: Reminder.idFor(entry.id, offset), entryId: entry.id, offsetMinutes: offset),
          for (final minute in _reminderTimes)
            Reminder(
              id: Reminder.timeIdFor(entry.id, minute),
              entryId: entry.id,
              offsetMinutes: 0,
              timeMinute: minute,
            ),
        ]);
      }
      if (!_remindersLoadFailed && (_reminderOffsets.isNotEmpty || _reminderTimes.isNotEmpty)) {
        final allowed = await ref.read(notificationServiceProvider).ensurePermissions();
        if (!allowed && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.notificationPermissionDenied)));
        }
      }
      await ref.read(reminderCoordinatorProvider).reschedule();
      ref.read(soundControllerProvider).play(UiSound.confirm);
    } catch (error) {
      ref.read(soundControllerProvider).play(UiSound.error);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final entry = widget.entry;
    if (entry == null || entry.readOnly) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteEntryQuestion),
        content: Text(context.l10n.deleteEntryBody),
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

    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).deleteEntry(entry.id);
      await ref.read(reminderCoordinatorProvider).reschedule();
      ref.read(soundControllerProvider).play(UiSound.back);
    } catch (error) {
      ref.read(soundControllerProvider).play(UiSound.error);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotDelete('$error'))));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _editReminders() async {
    final result = await showReminderSelectionSheet(
      context,
      offsets: _reminderOffsets,
      times: _reminderTimes,
    );
    if (result != null && mounted) {
      setState(() {
        _reminderOffsets = result.offsets;
        _reminderTimes = result.times;
      });
    }
  }

  Future<void> _editRepeat(BuildContext context) async {
    final picked = await showRepeatEditor(
      context,
      initial: RepeatSelection(
        rule: _recurrence,
        afterCompletion: _repeatAfterCompletion,
        intervalDays: _repeatDays,
      ),
      anchor: _date,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _repeatAfterCompletion = picked.afterCompletion;
      _repeatDays = picked.intervalDays;
      _recurrence = picked.rule;
    });
  }

  String _repeatSummary(BuildContext context) {
    final l10n = context.l10n;
    if (_repeatAfterCompletion) return '${l10n.repeatAfterCompletion} · ${l10n.daysValue(_repeatDays)}';
    final rule = _recurrence;
    if (rule == null) return l10n.repeatSummaryNever;
    final base = recurrenceLabel(context, rule, _date);
    final until = rule.until;
    if (until != null) {
      return '$base · ${l10n.recurrenceUntil(formatFullDate(context, until.toDateTime()))}';
    }
    final count = rule.count;
    if (count != null) return '$base · ${l10n.repeatOccurrences(count)}';
    return base;
  }

  String _spaceName(String id) {
    for (final space in _spaces) {
      if (space.id == id) return space.name;
    }
    return id;
  }

  Color _spaceColor(String id) {
    for (final space in _spaces) {
      if (space.id == id) return Color(space.colorValue);
    }
    return const Color(0xFF4F6D5A);
  }

  String? _contextName(List<PlannerContext> contexts, String? id) {
    if (id == null) return null;
    for (final context in contexts) {
      if (context.id == id) return context.name;
    }
    return null;
  }

  Color? _contextColor(List<PlannerContext> contexts, String? id) {
    if (id == null) return null;
    for (final context in contexts) {
      if (context.id == id) return Color(context.colorValue);
    }
    return null;
  }

  String? _projectName(List<Project> projects, String? id) {
    if (id == null) return null;
    for (final project in projects) {
      if (project.id == id) return project.name;
    }
    return null;
  }

  Future<void> _pickSpace(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showManeSelectSheet<String>(
      context: context,
      title: l10n.space,
      selected: _spaceId,
      options: [
        for (final space in _spaces)
          ManeSelectOption(
            value: space.id,
            label: space.name,
            leading: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: Color(space.colorValue), shape: BoxShape.circle),
            ),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _spaceId = picked;
      _contextId = null;
      _projectId = null;
      final allowed = (ref.read(tagsProvider).value ?? const <Tag>[])
          .where((tag) => tag.appliesTo(picked))
          .map((tag) => tag.id)
          .toSet();
      _tagIds.removeWhere((id) => !allowed.contains(id));
    });
  }

  Future<void> _pickKind(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showManeSelectSheet<EntryKind>(
      context: context,
      title: l10n.type,
      selected: _kind,
      options: [
        for (final kind in EntryKind.values)
          ManeSelectOption(value: kind, label: entryKindLabel(context, kind)),
      ],
    );
    if (picked != null && mounted) setState(() => _kind = picked);
  }

  Future<void> _pickContext(BuildContext context, List<PlannerContext> contexts) async {
    final l10n = context.l10n;
    final picked = await showManeSelectSheet<String>(
      context: context,
      title: l10n.context,
      selected: _contextId ?? '',
      options: [
        ManeSelectOption(value: '', label: l10n.noContext),
        for (final item in contexts)
          ManeSelectOption(
            value: item.id,
            label: item.name,
            leading: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: Color(item.colorValue), shape: BoxShape.circle),
            ),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _contextId = picked.isEmpty ? null : picked;
      _projectId = null;
    });
  }

  Future<void> _pickProject(BuildContext context, List<Project> projects) async {
    final l10n = context.l10n;
    final picked = await showManeSelectSheet<String>(
      context: context,
      title: l10n.project,
      selected: _projectId ?? '',
      searchHint: l10n.search,
      options: [
        ManeSelectOption(value: '', label: l10n.noProject),
        for (final project in projects) ManeSelectOption(value: project.id, label: project.name),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _projectId = picked.isEmpty ? null : picked);
  }

  Future<void> _pickTimeZone(BuildContext context) async {
    final l10n = context.l10n;
    final picked = await showTimeZonePicker(
      context,
      selected: _timeZone,
      title: l10n.timeZone,
      searchHint: l10n.timezoneSearch,
      deviceLabel: l10n.timezoneDevice,
      deviceZone: _deviceTimeZone,
    );
    if (picked == null || !mounted) return;
    setState(() => _timeZone = picked.isEmpty ? _deviceTimeZone : picked);
  }

  IconData _timingIcon(EntryTiming timing) => switch (timing) {
    EntryTiming.scheduled => Icons.schedule,
    EntryTiming.clockIn => Icons.play_circle_outline,
    EntryTiming.deadline => Icons.flag_outlined,
    EntryTiming.anytime => Icons.all_inclusive,
  };
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
        child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
