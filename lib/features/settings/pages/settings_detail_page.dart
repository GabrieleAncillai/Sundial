import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/i18n/reminder_label.dart';
import '../../../core/sound/sound_service.dart';
import '../../../core/time/time_field.dart';
import '../../../core/timezone/timezone_picker.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../models/app_settings.dart';
import '../../../models/visual_style.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../backup/backup_files.dart';
import '../../backup/backup_service.dart';
import '../../export/csv_interchange.dart';
import '../../export/export_files.dart';
import '../../export/ics_export_service.dart';
import '../../home_inventory/pages/home_inventory_page.dart';
import '../../home_inventory/pages/maintenance_page.dart';
import '../../home_inventory/pages/shopping_list_page.dart';
import '../../import/companion_import.dart';
import '../../import/gymmane_import.dart';
import '../../import/ics_import_service.dart';
import '../../import/import_dialogs.dart';
import '../../import/import_files.dart';
import '../../media/media_store.dart';
import '../../shifts/pages/shift_patterns_page.dart';
import '../../spaces/widgets/space_controls.dart';
import '../../tags/pages/tags_page.dart';
import '../widgets/settings_rows.dart';
import 'about_page.dart';

enum SettingsDetailSection { appearance, preferences, data, about }

class SettingsDetailPage extends ConsumerWidget {
  const SettingsDetailPage({super.key, required this.section, this.highlight, this.embedded = false});

  final SettingsDetailSection section;

  /// Row title from settings search. The matching row is scrolled into view
  /// and flashed.
  final String? highlight;

  /// Renders only the scrollable body so the desktop settings pane can place
  /// it beside the main menu instead of pushing a second full page.
  final bool embedded;

  static const _reminderOffsets = <int>[0, 5, 10, 30, 60, 120, 1440];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    final content = SingleChildScrollView(
      key: ValueKey(section),
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section == SettingsDetailSection.appearance)
            SettingsSection(
              highlight: highlight,
              title: l10n.appearanceSection,
              children: [
                SettingsChoiceRow(
                  icon: Icons.palette_outlined,
                  title: l10n.style,
                  choice: SundialSegmented<SundialVisualStyle>(
                    segments: [
                      SundialSegment(value: SundialVisualStyle.classic, label: l10n.styleClassic),
                      SundialSegment(value: SundialVisualStyle.aero, label: l10n.styleAero),
                    ],
                    selected: settings.visualStyle,
                    onChanged: controller.setVisualStyle,
                    compact: true,
                  ),
                ),
                SettingsChoiceRow(
                  icon: Icons.brightness_6_outlined,
                  title: l10n.brightness,
                  choice: SundialSegmented<ThemeMode>(
                    segments: [
                      SundialSegment(value: ThemeMode.system, label: l10n.themeSystem),
                      SundialSegment(value: ThemeMode.light, label: l10n.themeLight),
                      SundialSegment(value: ThemeMode.dark, label: l10n.themeDark),
                    ],
                    selected: settings.resolvedThemeMode == ThemeMode.dark
                        ? ThemeMode.dark
                        : settings.themeMode,
                    onChanged: controller.setThemeMode,
                    compact: true,
                  ),
                ),
                SettingsNavRow(
                  icon: Icons.texture_outlined,
                  title: l10n.background,
                  value: _backgroundLabel(l10n, settings.backgroundStyle),
                  onTap: () => _pickBackground(context, controller, settings.backgroundStyle),
                ),
                if (settings.backgroundStyle == SundialBackgroundStyle.custom)
                  SettingsNavRow(
                    icon: Icons.colorize_outlined,
                    title: l10n.customBackgroundColor,
                    value:
                        '#'
                        '${(settings.backgroundCustomColor & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                    onTap: () async {
                      final picked = await showColorPicker(
                        context,
                        selected: settings.backgroundCustomColor,
                        title: l10n.customBackgroundColor,
                      );
                      if (picked != null) await controller.setBackgroundCustomColor(picked);
                    },
                  ),
                SettingsNavRow(
                  icon: Icons.format_size,
                  title: l10n.textSize,
                  value: _textScaleLabel(l10n, settings.textScale),
                  onTap: () => _pickTextScale(context, controller, settings.textScale),
                ),
              ],
            ),
          if (section == SettingsDetailSection.preferences)
            SettingsSection(
              highlight: highlight,
              title: l10n.preferencesSection,
              children: [
                SettingsChoiceRow(
                  icon: Icons.translate,
                  title: l10n.language,
                  choice: SundialSegmented<String>(
                    segments: [
                      SundialSegment(value: 'system', label: l10n.languageSystem),
                      SundialSegment(value: 'en', label: l10n.languageEnglish),
                      SundialSegment(value: 'es', label: l10n.languageSpanish),
                    ],
                    selected: settings.locale?.languageCode ?? 'system',
                    onChanged: (value) => controller.setLocale(value == 'system' ? null : Locale(value)),
                    compact: true,
                  ),
                ),
                SettingsNavRow(
                  icon: Icons.public,
                  title: l10n.timeZone,
                  subtitle: l10n.timezoneSubtitle,
                  value: settings.timezoneOverride.isEmpty
                      ? ref.watch(deviceTimeZoneProvider)
                      : settings.timezoneOverride,
                  valueBelow: true,
                  onTap: () => _pickTimeZone(context, ref, settings),
                ),
                SettingsNavRow(
                  icon: Icons.event_outlined,
                  title: l10n.dateFormatLabel,
                  value: _dateFormatLabel(l10n, settings.dateFormat),
                  onTap: () => _pickDateFormat(context, controller, settings.dateFormat),
                ),
                SettingsChoiceRow(
                  icon: Icons.calendar_view_week_outlined,
                  title: l10n.weekStartsOn,
                  choice: SundialSegmented<int>(
                    segments: [
                      SundialSegment(value: DateTime.monday, label: l10n.weekStartMonday),
                      SundialSegment(value: DateTime.saturday, label: l10n.weekStartSaturday),
                      SundialSegment(value: DateTime.sunday, label: l10n.weekStartSunday),
                    ],
                    selected: settings.weekStart,
                    onChanged: controller.setWeekStart,
                    compact: true,
                  ),
                ),
                SettingsNavRow(
                  icon: Icons.view_sidebar_outlined,
                  title: l10n.navigationSide,
                  value: settings.navSide == SundialNavSide.left ? l10n.navLeft : l10n.navRight,
                  onTap: () => _pickNavSide(context, controller, settings.navSide),
                ),
                SettingsSwitchRow(
                  icon: Icons.speed_outlined,
                  title: l10n.performanceMode,
                  subtitle: l10n.performanceModeSubtitle,
                  value: settings.performanceMode,
                  onChanged: controller.setPerformanceMode,
                ),
              ],
            ),
          if (section == SettingsDetailSection.preferences)
            SettingsSection(
              highlight: highlight,
              title: l10n.soundSection,
              children: [
                SettingsSwitchRow(
                  icon: Icons.volume_up_outlined,
                  title: l10n.interactionSounds,
                  subtitle: l10n.interactionSoundsSubtitle,
                  value: settings.soundsEnabled,
                  onChanged: (value) async {
                    await controller.setSoundsEnabled(value);
                    if (value) {
                      ref.read(soundControllerProvider).play(UiSound.toggleOn, force: true);
                    }
                  },
                ),
                SettingsChoiceRow(
                  icon: Icons.graphic_eq,
                  title: l10n.soundPackLabel,
                  choice: SundialSegmented<SundialSoundPack>(
                    segments: [
                      SundialSegment(value: SundialSoundPack.soft, label: l10n.soundPackSoft),
                      SundialSegment(value: SundialSoundPack.aero, label: l10n.soundPackAero),
                    ],
                    selected: settings.soundPack,
                    onChanged: (value) {
                      controller.setSoundPack(value);
                      ref.read(soundControllerProvider).play(UiSound.tap, force: true);
                    },
                    compact: true,
                  ),
                ),
                SettingsChoiceRow(
                  icon: Icons.play_circle_outline,
                  title: l10n.previewSound,
                  choice: OutlinedButton.icon(
                    onPressed: () => ref.read(soundControllerProvider).play(UiSound.tap, force: true),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.previewSound),
                  ),
                ),
                SettingsChoiceRow(
                  icon: Icons.alarm_outlined,
                  title: l10n.alarmSounds,
                  subtitle: l10n.alarmSoundsSubtitle,
                  choice: SundialSegmented<SundialAlarmSound>(
                    segments: [
                      SundialSegment(value: SundialAlarmSound.soft, label: l10n.alarmSoundSoft),
                      SundialSegment(value: SundialAlarmSound.chime, label: l10n.alarmSoundChime),
                      SundialSegment(value: SundialAlarmSound.bright, label: l10n.alarmSoundBright),
                    ],
                    selected: settings.alarmSound,
                    onChanged: (value) {
                      controller.setAlarmSound(value);
                      ref.read(soundControllerProvider).previewAlarm(value);
                      ref.read(reminderCoordinatorProvider).reschedule();
                    },
                    compact: true,
                  ),
                ),
              ],
            ),
          if (section == SettingsDetailSection.preferences)
            SettingsSection(
              highlight: highlight,
              title: l10n.plannerSection,
              children: [
                SettingsSwitchRow(
                  icon: Icons.work_outline,
                  title: l10n.hideWorkSpace,
                  subtitle: l10n.hideWorkSpaceSubtitle,
                  value: settings.hideWorkSpace,
                  onChanged: controller.setHideWorkSpace,
                ),
                SettingsSwitchRow(
                  icon: Icons.schedule_outlined,
                  title: l10n.workHours,
                  subtitle: l10n.workHoursSubtitle,
                  value: settings.workHoursEnabled,
                  onChanged: (value) async {
                    await controller.setWorkHoursEnabled(value);
                    await ref.read(reminderCoordinatorProvider).reschedule();
                  },
                ),
                if (settings.workHoursEnabled)
                  SettingsNavRow(
                    icon: Icons.timelapse_outlined,
                    title: l10n.hoursWindow,
                    value: _windowLabel(context, settings.workHoursStartMinute, settings.workHoursEndMinute),
                    onTap: () => _showHours(
                      context,
                      ref,
                      title: l10n.workHours,
                      start: settings.workHoursStartMinute,
                      end: settings.workHoursEndMinute,
                      onSave: (start, end) async {
                        await controller.setWorkHours(startMinute: start, endMinute: end);
                        await ref.read(reminderCoordinatorProvider).reschedule();
                      },
                    ),
                  ),
                SettingsSwitchRow(
                  icon: Icons.nightlight_outlined,
                  title: l10n.quietHours,
                  subtitle: l10n.quietHoursSubtitle,
                  value: settings.quietHoursEnabled,
                  onChanged: (value) async {
                    await controller.setQuietHoursEnabled(value);
                    await ref.read(reminderCoordinatorProvider).reschedule();
                  },
                ),
                if (settings.quietHoursEnabled)
                  SettingsNavRow(
                    icon: Icons.do_not_disturb_on_outlined,
                    title: l10n.hoursWindow,
                    value: _windowLabel(
                      context,
                      settings.quietHoursStartMinute,
                      settings.quietHoursEndMinute,
                    ),
                    onTap: () => _showHours(
                      context,
                      ref,
                      title: l10n.quietHours,
                      start: settings.quietHoursStartMinute,
                      end: settings.quietHoursEndMinute,
                      onSave: (start, end) async {
                        await controller.setQuietHours(startMinute: start, endMinute: end);
                        await ref.read(reminderCoordinatorProvider).reschedule();
                      },
                    ),
                  ),
                SettingsNavRow(
                  icon: Icons.notifications_outlined,
                  title: l10n.defaultReminders,
                  subtitle: l10n.defaultRemindersSubtitle,
                  value: settings.defaultReminderOffsets.isEmpty
                      ? l10n.notSet
                      : l10n.selectedCount(settings.defaultReminderOffsets.length),
                  onTap: () => _showDefaultReminders(context, ref),
                ),
              ],
            ),
          if (section == SettingsDetailSection.preferences)
            SettingsSection(
              highlight: highlight,
              title: l10n.sleepWindow,
              children: [
                SettingsSwitchRow(
                  icon: Icons.bedtime_outlined,
                  title: l10n.sleepWindow,
                  subtitle: l10n.sleepWindowSubtitle,
                  value: settings.sleepEnabled,
                  onChanged: controller.setSleepEnabled,
                ),
                SettingsNavRow(
                  icon: Icons.timer_outlined,
                  title: l10n.sleepBuffers,
                  subtitle: l10n.sleepBuffersSummary(
                    settings.sleepCommuteMinutes,
                    settings.sleepWindDownMinutes,
                    settings.sleepWakeBufferMinutes,
                  ),
                  onTap: () => _showSleepBuffers(context, ref),
                ),
              ],
            ),
          if (section == SettingsDetailSection.preferences)
            SettingsSection(
              highlight: highlight,
              title: l10n.librarySection,
              children: [
                SettingsNavRow(
                  icon: Icons.sell_outlined,
                  title: l10n.tagsManager,
                  subtitle: l10n.tagsManagerSubtitle,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TagsPage())),
                ),
                SettingsNavRow(
                  icon: Icons.schedule,
                  title: l10n.shiftPatterns,
                  subtitle: l10n.shiftPatternsSubtitle,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const ShiftPatternsPage())),
                ),
                SettingsNavRow(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.homeInventory,
                  subtitle: l10n.homeInventorySubtitle,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const HomeInventoryPage())),
                ),
                SettingsNavRow(
                  icon: Icons.shopping_cart_outlined,
                  title: l10n.shoppingList,
                  subtitle: l10n.shoppingListSubtitle,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const ShoppingListPage())),
                ),
                SettingsNavRow(
                  icon: Icons.build_outlined,
                  title: l10n.maintenance,
                  subtitle: l10n.maintenanceSubtitle,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const MaintenancePage())),
                ),
              ],
            ),
          if (section == SettingsDetailSection.data)
            SettingsSection(
              highlight: highlight,
              title: l10n.dataAndBackup,
              children: [
                SettingsSwitchRow(
                  icon: Icons.backup_outlined,
                  title: l10n.automaticBackups,
                  subtitle: l10n.automaticBackupsSubtitle,
                  value: settings.autoBackupEnabled,
                  onChanged: controller.setAutoBackupEnabled,
                ),
                if (settings.autoBackupEnabled)
                  SettingsNavRow(
                    icon: Icons.history,
                    title: l10n.keepBackups,
                    value: '${settings.autoBackupKeep}',
                    onTap: () => _showKeepBackups(context, ref),
                  ),
                SettingsNavRow(
                  icon: Icons.upload_file_outlined,
                  title: l10n.exportBackup,
                  subtitle: l10n.exportBackupSubtitle,
                  onTap: () => _exportBackup(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.download_outlined,
                  title: l10n.importBackup,
                  subtitle: l10n.importBackupSubtitle,
                  onTap: () => _importBackup(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.event_available_outlined,
                  title: l10n.importCalendar,
                  subtitle: l10n.importCalendarSubtitle,
                  onTap: () => _importCalendar(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.devices_other_outlined,
                  title: l10n.importCompanion,
                  subtitle: l10n.importCompanionSubtitle,
                  onTap: () => _importCompanion(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.fitness_center,
                  title: l10n.gymmaneImport,
                  subtitle: l10n.gymmaneImportSubtitle,
                  onTap: () => _importGymMane(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.table_view_outlined,
                  title: l10n.exportCsv,
                  subtitle: l10n.exportCsvSubtitle,
                  onTap: () => _exportCsv(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.table_view,
                  title: l10n.importCsv,
                  subtitle: l10n.importCsvSubtitle,
                  onTap: () => _importCsv(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.ios_share_outlined,
                  title: l10n.exportCalendar,
                  subtitle: l10n.exportCalendarSubtitle,
                  onTap: () => _exportCalendar(context, ref),
                ),
                SettingsNavRow(
                  icon: Icons.delete_forever_outlined,
                  title: l10n.deleteAllData,
                  subtitle: l10n.deleteAllDataSubtitle,
                  onTap: () => _deleteAllData(context, ref),
                ),
              ],
            ),
          if (section == SettingsDetailSection.about)
            SettingsSection(
              highlight: highlight,
              title: l10n.about,
              children: [
                SettingsNavRow(
                  icon: Icons.info_outline,
                  title: l10n.about,
                  subtitle: l10n.aboutSubtitle,
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
                ),
              ],
            ),
        ],
      ),
    );

    if (embedded) return content;

    return SundialPage(
      title: switch (section) {
        SettingsDetailSection.appearance => l10n.appearanceSection,
        SettingsDetailSection.preferences => l10n.preferencesSection,
        SettingsDetailSection.data => l10n.dataSection,
        SettingsDetailSection.about => l10n.about,
      },
      child: content,
    );
  }

  void _showNotice(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref.read(backupServiceProvider).exportJson();
      final path = await saveBackupFile(json, dialogTitle: l10n.exportBackup);
      if (path == null) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupExported(path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed('$error'))));
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickBackupText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed('$error'))));
      return;
    }
    if (source == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.importBackup),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // A restore replaces the plan. Stop pulls first so a peer cannot read a
      // half-restored database, and restart them once the import commits.
      await ref.read(syncServiceProvider).stop();
      await ref.read(backupServiceProvider).importJson(source);
      await ref.read(settingsProvider.notifier).reload();
      await ref.read(reminderCoordinatorProvider).reschedule();
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupImported)));
    } on BackupVersionException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFuture)));
    } on BackupFormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupInvalid)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed('$error'))));
    } finally {
      await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
    }
  }

  Future<void> _importCalendar(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickIcsText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importCalendarFailed('$error'))));
      return;
    }
    if (source == null || !context.mounted) return;

    final spaceId = await pickImportSpace(context, ref, title: l10n.importCalendarSpace);
    if (spaceId == null) return;

    try {
      final report = await IcsImportService(ref.read(repositoryProvider)).importText(
        source,
        spaceId: spaceId,
        defaultTimeZone: ref.read(deviceTimeZoneProvider),
        fallbackTitle: l10n.importedEvent,
      );
      final skipped = report.duplicates + report.skipped.length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.imported == 0 && report.updated == 0 && skipped == 0
                ? l10n.importCalendarEmpty
                : l10n.importCalendarDone(report.imported, report.updated, skipped),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importCalendarFailed('$error'))));
    }
  }

  Future<void> _importGymMane(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickGymManeText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.gymmaneImportFailed('$error'))));
      return;
    }
    if (source == null) return;

    final spaces = await ref.read(repositoryProvider).watchSpaces().first;
    if (spaces.isEmpty) return;
    var space = spaces.first;
    for (final candidate in spaces) {
      if (candidate.id == 'personal') {
        space = candidate;
        break;
      }
    }
    final timeZone = ref.read(deviceTimeZoneProvider);
    final today = localDateAt(ref.read(nowProvider), timeZone);
    try {
      final report = await GymManeImportService(
        ref.read(repositoryProvider),
      ).importJson(source, spaceId: space.id, today: today, timeZone: timeZone);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.imported == 0 && report.duplicates == 0 && report.skipped == 0
                ? l10n.gymmaneImportEmpty
                : l10n.gymmaneImportDone(report.imported, report.timed, report.allDay, report.skipped),
          ),
        ),
      );
    } on GymManeImportException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.gymmaneImportFailed('$error'))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.gymmaneImportFailed('$error'))));
    }
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await showAppSheet<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: l10n.exportCsv,
        subtitle: l10n.exportCsvSubtitle,
        children: [
          SettingsNavRow(
            icon: Icons.event_note_outlined,
            title: l10n.csvEntries,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _exportCsvEntries(context, ref);
            },
          ),
          SettingsNavRow(
            icon: Icons.shopping_cart_outlined,
            title: l10n.csvShopping,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _exportCsvShopping(context, ref);
            },
          ),
          SettingsNavRow(
            icon: Icons.inventory_2_outlined,
            title: l10n.csvInventory,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _exportCsvInventory(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await showAppSheet<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: l10n.importCsv,
        subtitle: l10n.importCsvSubtitle,
        children: [
          SettingsNavRow(
            icon: Icons.event_note_outlined,
            title: l10n.csvEntries,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _importCsvEntries(context, ref);
            },
          ),
          SettingsNavRow(
            icon: Icons.shopping_cart_outlined,
            title: l10n.csvShopping,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _importCsvShopping(context, ref);
            },
          ),
          SettingsNavRow(
            icon: Icons.inventory_2_outlined,
            title: l10n.csvInventory,
            onTap: () {
              Navigator.of(sheetContext).pop();
              _importCsvInventory(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsvEntries(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final timeZone = ref.read(deviceTimeZoneProvider);
      final today = localDateAt(ref.read(nowProvider), timeZone);
      final csv = await CsvInterchangeService(
        ref.read(repositoryProvider),
      ).exportEntries(start: today.addDays(-30), end: today.addDays(365), viewerTimeZone: timeZone);
      final path = await saveCsvFile(csv, dialogTitle: l10n.exportCsv, fileName: _csvFileName('entries'));
      if (path == null) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExported(path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
    }
  }

  Future<void> _exportCsvShopping(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await CsvInterchangeService(ref.read(repositoryProvider)).exportShopping();
      final path = await saveCsvFile(csv, dialogTitle: l10n.exportCsv, fileName: _csvFileName('shopping'));
      if (path == null) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExported(path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
    }
  }

  Future<void> _exportCsvInventory(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = await CsvInterchangeService(ref.read(repositoryProvider)).exportInventory();
      final path = await saveCsvFile(csv, dialogTitle: l10n.exportCsv, fileName: _csvFileName('inventory'));
      if (path == null) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExported(path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
    }
  }

  Future<void> _importCsvEntries(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickCsvText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
      return;
    }
    if (source == null) return;
    try {
      final report = await CsvInterchangeService(
        ref.read(repositoryProvider),
      ).importEntries(source, defaultTimeZone: ref.read(deviceTimeZoneProvider));
      await ref.read(reminderCoordinatorProvider).reschedule();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.imported == 0 && report.duplicates == 0 && report.skipped == 0
                ? l10n.csvImportEmpty
                : l10n.csvImportDone(report.imported, report.duplicates, report.skipped),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
    }
  }

  Future<void> _importCsvShopping(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickCsvText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
      return;
    }
    if (source == null) return;
    try {
      final report = await CsvInterchangeService(ref.read(repositoryProvider)).importShopping(source);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.imported == 0 && report.duplicates == 0 && report.skipped == 0
                ? l10n.csvImportEmpty
                : l10n.csvImportDone(report.imported, report.duplicates, report.skipped),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
    }
  }

  Future<void> _importCsvInventory(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickCsvText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
      return;
    }
    if (source == null) return;
    try {
      final report = await CsvInterchangeService(ref.read(repositoryProvider)).importInventory(source);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.imported == 0 && report.duplicates == 0 && report.skipped == 0
                ? l10n.csvImportEmpty
                : l10n.csvImportDone(report.imported, report.duplicates, report.skipped),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed('$error'))));
    }
  }

  Future<void> _pickTimeZone(BuildContext context, WidgetRef ref, AppSettings settings) async {
    final l10n = context.l10n;
    final picked = await showTimeZonePicker(
      context,
      selected: settings.timezoneOverride,
      title: l10n.timeZone,
      searchHint: l10n.timezoneSearch,
      deviceLabel: l10n.timezoneDevice,
      deviceZone: ref.read(deviceTimeZoneProvider),
    );
    if (picked == null || !context.mounted) return;
    await ref.read(settingsProvider.notifier).setTimezoneOverride(picked);
    await ref.read(reminderCoordinatorProvider).reschedule();
  }

  Future<void> _pickBackground(
    BuildContext context,
    SettingsController controller,
    SundialBackgroundStyle selected,
  ) async {
    final l10n = context.l10n;
    final picked = await _choose<SundialBackgroundStyle>(
      context,
      title: l10n.background,
      selected: selected,
      options: [
        (SundialBackgroundStyle.dots, l10n.backgroundDots),
        (SundialBackgroundStyle.grid, l10n.backgroundGrid),
        (SundialBackgroundStyle.oled, l10n.backgroundOled),
        (SundialBackgroundStyle.plain, l10n.backgroundPlain),
        (SundialBackgroundStyle.custom, l10n.backgroundCustom),
      ],
    );
    if (picked != null) await controller.setBackgroundStyle(picked);
  }

  Future<void> _pickTextScale(BuildContext context, SettingsController controller, double selected) async {
    final l10n = context.l10n;
    final picked = await _choose<double>(
      context,
      title: l10n.textSize,
      selected: selected,
      options: [
        (0.9, l10n.textSmall),
        (1.0, l10n.textDefault),
        (1.15, l10n.textLarge),
        (1.3, l10n.textExtraLarge),
      ],
    );
    if (picked != null) await controller.setTextScale(picked);
  }

  Future<void> _pickDateFormat(
    BuildContext context,
    SettingsController controller,
    SundialDateFormat selected,
  ) async {
    final l10n = context.l10n;
    final picked = await _choose<SundialDateFormat>(
      context,
      title: l10n.dateFormatLabel,
      selected: selected,
      options: [
        (SundialDateFormat.system, l10n.dateFormatSystem),
        (SundialDateFormat.dmy, l10n.dateFormatDmy),
        (SundialDateFormat.mdy, l10n.dateFormatMdy),
        (SundialDateFormat.ymd, l10n.dateFormatYmd),
      ],
    );
    if (picked != null) await controller.setDateFormat(picked);
  }

  Future<void> _pickNavSide(
    BuildContext context,
    SettingsController controller,
    SundialNavSide selected,
  ) async {
    final l10n = context.l10n;
    final picked = await _choose<SundialNavSide>(
      context,
      title: l10n.navigationSide,
      selected: selected,
      options: [(SundialNavSide.left, l10n.navLeft), (SundialNavSide.right, l10n.navRight)],
    );
    if (picked != null) await controller.setNavSide(picked);
  }

  Future<T?> _choose<T>(
    BuildContext context, {
    required String title,
    required T selected,
    required List<(T, String)> options,
  }) {
    return showAppSheet<T>(
      context: context,
      builder: (context) => AppSheet(
        title: title,
        children: [
          for (final (value, label) in options)
            ListTile(
              title: Text(label),
              trailing: value == selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(context).pop(value),
            ),
        ],
      ),
    );
  }

  String _backgroundLabel(AppLocalizations l10n, SundialBackgroundStyle style) => switch (style) {
    SundialBackgroundStyle.dots => l10n.backgroundDots,
    SundialBackgroundStyle.grid => l10n.backgroundGrid,
    SundialBackgroundStyle.oled => l10n.backgroundOled,
    SundialBackgroundStyle.plain => l10n.backgroundPlain,
    SundialBackgroundStyle.custom => l10n.backgroundCustom,
  };

  String _textScaleLabel(AppLocalizations l10n, double scale) {
    if (scale < 0.95) return l10n.textSmall;
    if (scale < 1.1) return l10n.textDefault;
    if (scale < 1.22) return l10n.textLarge;
    return l10n.textExtraLarge;
  }

  String _dateFormatLabel(AppLocalizations l10n, SundialDateFormat format) => switch (format) {
    SundialDateFormat.system => l10n.dateFormatSystem,
    SundialDateFormat.dmy => l10n.dateFormatDmy,
    SundialDateFormat.mdy => l10n.dateFormatMdy,
    SundialDateFormat.ymd => l10n.dateFormatYmd,
  };

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAllDataQuestion),
        content: Text(l10n.deleteAllDataBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Stop the optional network services first. A failing service must not
    // block the local wipe.
    try {
      await ref.read(syncServiceProvider).stop();
    } catch (_) {}
    try {
      await ref.read(mcpServerProvider).stop();
    } catch (_) {}

    // The database wipe is atomic, so it runs first: if it fails the plan and
    // the automatic backups are both still intact. File cleanup follows and
    // reports a partial result instead of silently claiming success.
    var cleared = true;
    try {
      await ref.read(repositoryProvider).clearAllData();
    } catch (_) {
      cleared = false;
    }
    var filesCleared = false;
    if (cleared) {
      try {
        await ref.read(autoBackupServiceProvider).deleteAll();
        await deleteAllStickerImages();
        filesCleared = true;
      } catch (_) {}
    }
    await ref.read(settingsProvider.notifier).reload();
    ref.invalidate(spacesProvider);
    ref.invalidate(tagsProvider);
    ref.invalidate(contextsProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(habitsProvider);
    ref.invalidate(habitCompletionsProvider);
    ref.invalidate(entriesProvider);
    ref.invalidate(shiftsProvider);
    ref.invalidate(openEntriesProvider);
    ref.invalidate(homeItemsProvider);
    ref.invalidate(shoppingItemsProvider);
    ref.invalidate(identityProvider);
    ref.invalidate(pairedDevicesProvider);
    await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
    if (!context.mounted) return;
    _showNotice(
      context,
      !cleared
          ? l10n.dataDeleteFailed
          : filesCleared
          ? l10n.dataDeleted
          : l10n.dataDeleteIncomplete,
    );
  }

  Future<void> _showKeepBackups(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _KeepBackupsSheet(initial: ref.read(settingsProvider).autoBackupKeep),
    );
  }

  Future<void> _showHours(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int start,
    required int end,
    required Future<void> Function(int start, int end) onSave,
  }) async {
    await showAppSheet<void>(
      context: context,
      builder: (_) => _HoursSheet(title: title, start: start, end: end, onSave: onSave),
    );
  }

  static String _windowLabel(BuildContext context, int start, int end) {
    final localizations = MaterialLocalizations.of(context);
    String label(int minute) =>
        localizations.formatTimeOfDay(TimeOfDay(hour: minute ~/ 60, minute: minute % 60));
    return '${label(start)} – ${label(end)}';
  }

  static String _csvFileName(String kind) {
    final now = DateTime.now();
    return 'sundial-$kind-${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.csv';
  }

  Future<void> _importCompanion(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final String? source;
    try {
      source = await pickCompanionText();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importCompanionFailed('$error'))));
      return;
    }
    if (source == null || !context.mounted) return;

    final spaceId = await pickImportSpace(context, ref, title: l10n.importCalendarSpace);
    if (spaceId == null) return;

    try {
      final report = await CompanionImportService(
        ref.read(repositoryProvider),
      ).importText(source, spaceId: spaceId, defaultTimeZone: ref.read(deviceTimeZoneProvider));
      final skipped = report.duplicates + report.skipped.length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            report.imported == 0 && skipped == 0
                ? l10n.importCompanionEmpty
                : l10n.importCompanionDone(report.imported, skipped),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importCompanionFailed('$error'))));
    }
  }

  Future<void> _exportCalendar(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final timeZone = ref.read(deviceTimeZoneProvider);
      final today = localDateAt(ref.read(nowProvider), timeZone);
      final content = await IcsExportService(
        ref.read(repositoryProvider),
      ).exportRange(start: today.addDays(-30), end: today.addDays(180), viewerTimeZone: timeZone);
      final path = await saveIcsFile(content, dialogTitle: l10n.exportCalendar);
      if (path == null) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.calendarExported(path))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.calendarExportFailed('$error'))));
    }
  }

  Future<void> _showSleepBuffers(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(
      context: context,
      builder: (context) => _SleepBuffersSheet(initial: ref.read(settingsProvider)),
    );
  }

  Future<void> _showDefaultReminders(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(
      context: context,
      builder: (context) => _DefaultRemindersSheet(
        initial: ref.read(settingsProvider).defaultReminderOffsets,
        offsets: _reminderOffsets,
      ),
    );
  }
}

class _SleepBuffersSheet extends ConsumerStatefulWidget {
  const _SleepBuffersSheet({required this.initial});

  final AppSettings initial;

  @override
  ConsumerState<_SleepBuffersSheet> createState() => _SleepBuffersSheetState();
}

class _SleepBuffersSheetState extends ConsumerState<_SleepBuffersSheet> {
  late final TextEditingController _commute;
  late final TextEditingController _windDown;
  late final TextEditingController _wake;

  @override
  void initState() {
    super.initState();
    _commute = TextEditingController(text: '${widget.initial.sleepCommuteMinutes}');
    _windDown = TextEditingController(text: '${widget.initial.sleepWindDownMinutes}');
    _wake = TextEditingController(text: '${widget.initial.sleepWakeBufferMinutes}');
  }

  @override
  void dispose() {
    _commute.dispose();
    _windDown.dispose();
    _wake.dispose();
    super.dispose();
  }

  int _value(TextEditingController controller, int fallback) {
    final parsed = int.tryParse(controller.text.trim());
    return parsed == null || parsed < 0 ? fallback : parsed.clamp(0, 24 * 60);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheet(
      title: l10n.sleepBuffers,
      children: [
        TextField(
          controller: _commute,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.commute),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _windDown,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.windDown),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _wake,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.wakeBuffer),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () async {
            final controller = ref.read(settingsProvider.notifier);
            await controller.setSleepCommuteMinutes(_value(_commute, widget.initial.sleepCommuteMinutes));
            await controller.setSleepWindDownMinutes(_value(_windDown, widget.initial.sleepWindDownMinutes));
            await controller.setSleepWakeBufferMinutes(_value(_wake, widget.initial.sleepWakeBufferMinutes));
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _DefaultRemindersSheet extends ConsumerStatefulWidget {
  const _DefaultRemindersSheet({required this.initial, required this.offsets});

  final List<int> initial;
  final List<int> offsets;

  @override
  ConsumerState<_DefaultRemindersSheet> createState() => _DefaultRemindersSheetState();
}

class _DefaultRemindersSheetState extends ConsumerState<_DefaultRemindersSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initial};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppSheet(
      title: l10n.defaultReminders,
      children: [
        for (final offset in widget.offsets)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _selected.contains(offset),
            title: Text(reminderOffsetLabel(context, offset)),
            onChanged: (selected) => setState(() {
              if (selected == true) {
                _selected.add(offset);
              } else {
                _selected.remove(offset);
              }
            }),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            await ref.read(settingsProvider.notifier).setDefaultReminderOffsets(_selected.toList());
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _KeepBackupsSheet extends ConsumerWidget {
  const _KeepBackupsSheet({required this.initial});

  final int initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return AppSheet(
      title: l10n.keepBackups,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: SundialSegmented<int>(
            segments: const [
              SundialSegment(value: 3, label: '3'),
              SundialSegment(value: 5, label: '5'),
              SundialSegment(value: 10, label: '10'),
              SundialSegment(value: 20, label: '20'),
            ],
            selected: initial,
            onChanged: (value) async {
              await ref.read(settingsProvider.notifier).setAutoBackupKeep(value);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

class _HoursSheet extends StatefulWidget {
  const _HoursSheet({required this.title, required this.start, required this.end, required this.onSave});

  final String title;
  final int start;
  final int end;
  final Future<void> Function(int start, int end) onSave;

  @override
  State<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<_HoursSheet> {
  late int _start = widget.start;
  late int _end = widget.end;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppSheet(
      title: widget.title,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SundialTimeField(
                label: l10n.startTime,
                valueLabel: formatMinuteLabel(context, _start),
                initialMinute: _start,
                clearable: false,
                onChanged: (minute) => setState(() => _start = minute % 1440),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SundialTimeField(
                label: l10n.endTime,
                valueLabel: formatMinuteLabel(context, _end),
                initialMinute: _end,
                clearable: false,
                onChanged: (minute) => setState(() => _end = minute % 1440),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_start, _end);
    if (mounted) Navigator.of(context).pop();
  }
}
