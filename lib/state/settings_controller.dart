import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../core/i18n/l10n.dart';
import '../models/app_icon_style.dart';
import '../models/app_settings.dart';
import '../models/visual_style.dart';
import '../services/planner_repository.dart';
import 'providers.dart';

/// Overridden in `main()` with the values read from the database.
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(initialSettingsProvider);

  PlannerRepository get _repository => ref.read(repositoryProvider);

  /// Re-reads settings after a backup import replaced the table.
  Future<void> reload() async {
    final values = await _repository.readSettings();
    state = AppSettings.fromMap(values);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    await _repository.writeSetting(SettingsKeys.themeMode, value.name);
  }

  Future<void> setVisualStyle(SundialVisualStyle value) async {
    state = state.copyWith(
      visualStyle: value,
      soundPack: value == SundialVisualStyle.aero ? SundialSoundPack.aero : state.soundPack,
    );
    await _repository.writeSetting(SettingsKeys.visualStyle, value.name);
    if (value == SundialVisualStyle.aero) {
      await _repository.writeSetting(SettingsKeys.soundPack, SundialSoundPack.aero.name);
    }
  }

  Future<void> setAppIconStyle(AppIconStyle value) async {
    state = state.copyWith(appIconStyle: value);
    await _repository.writeSetting(SettingsKeys.appIconStyle, value.name);
  }

  Future<void> setAccentScheme(SundialAccentScheme value) async {
    state = state.copyWith(accentScheme: value);
    await _repository.writeSetting(SettingsKeys.colorScheme, value.name);
  }

  Future<void> setBackgroundStyle(SundialBackgroundStyle value) async {
    state = state.copyWith(backgroundStyle: value);
    await _repository.writeSetting(SettingsKeys.backgroundStyle, value.name);
  }

  Future<void> setBackgroundCustomColor(int value) async {
    state = state.copyWith(backgroundCustomColor: value);
    await _repository.writeSetting(SettingsKeys.backgroundCustomColor, '$value');
  }

  Future<void> setTextScale(double value) async {
    final scale = value.clamp(0.85, 1.35);
    state = state.copyWith(textScale: scale);
    await _repository.writeSetting(SettingsKeys.textScale, '$scale');
  }

  Future<void> setNavSide(SundialNavSide value) async {
    state = state.copyWith(navSide: value);
    await _repository.writeSetting(SettingsKeys.navSide, value.name);
  }

  Future<void> setDateFormat(SundialDateFormat value) async {
    state = state.copyWith(dateFormat: value);
    await _repository.writeSetting(SettingsKeys.dateFormat, value.name);
  }

  Future<void> setPerformanceMode(bool value) async {
    state = state.copyWith(performanceMode: value);
    await _repository.writeSetting(SettingsKeys.performanceMode, '$value');
  }

  Future<void> setOnlineEnabled(bool value) async {
    state = state.copyWith(onlineEnabled: value);
    await _repository.writeSetting(SettingsKeys.onlineEnabled, '$value');
  }

  Future<void> setMcpPort(int value) async {
    final port = value.clamp(1024, 65535);
    state = state.copyWith(mcpPort: port);
    await _repository.writeSetting(SettingsKeys.mcpPort, '$port');
  }

  Future<void> setSoundsEnabled(bool value) async {
    state = state.copyWith(soundsEnabled: value);
    await _repository.writeSetting(SettingsKeys.soundsEnabled, '$value');
  }

  Future<void> setSoundPack(SundialSoundPack value) async {
    state = state.copyWith(soundPack: value);
    await _repository.writeSetting(SettingsKeys.soundPack, value.name);
  }

  Future<void> setAlarmSound(SundialAlarmSound value) async {
    state = state.copyWith(alarmSound: value);
    await _repository.writeSetting(SettingsKeys.alarmSound, value.name);
  }

  Future<void> setDeveloperOptionsEnabled(bool value) async {
    state = state.copyWith(developerOptionsEnabled: value);
    await _repository.writeSetting(SettingsKeys.developerOptions, '$value');
  }

  /// Empty selects the device zone. Unknown zones are ignored so a stale or
  /// imported value cannot break scheduling.
  Future<void> setTimezoneOverride(String value) async {
    final zone = value.trim();
    if (zone.isNotEmpty && !isKnownTimeZone(zone)) return;
    state = state.copyWith(timezoneOverride: zone);
    await _repository.writeSetting(SettingsKeys.timezoneOverride, zone);
  }

  Future<void> setLocale(Locale? value) async {
    state = value == null ? state.copyWith(clearLocale: true) : state.copyWith(locale: value);
    await _repository.writeSetting(SettingsKeys.locale, localeCode(value));
  }

  Future<void> setWeekStart(int day) async {
    if (day != DateTime.monday && day != DateTime.saturday && day != DateTime.sunday) return;
    state = state.copyWith(weekStart: day);
    await _repository.writeSetting(SettingsKeys.weekStart, '$day');
  }

  Future<void> setHideWorkSpace(bool value) async {
    state = state.copyWith(hideWorkSpace: value);
    await _repository.writeSetting(SettingsKeys.hideWorkSpace, '$value');
  }

  Future<void> setDefaultReminderOffsets(List<int> offsets) async {
    final clean = offsets.where((value) => value >= 0).toSet().toList()..sort();
    state = state.copyWith(defaultReminderOffsets: clean);
    await _repository.writeSetting(SettingsKeys.defaultReminderOffsets, clean.join(','));
  }

  Future<void> setSyncEnabled(bool value) async {
    state = state.copyWith(syncEnabled: value);
    await _repository.writeSetting(SettingsKeys.syncEnabled, '$value');
  }

  Future<void> setMcpEnabled(bool value) async {
    state = state.copyWith(mcpEnabled: value);
    await _repository.writeSetting(SettingsKeys.mcpEnabled, '$value');
  }

  Future<void> setMcpWritesEnabled(bool value) async {
    state = state.copyWith(mcpWritesEnabled: value);
    await _repository.writeSetting(SettingsKeys.mcpWritesEnabled, '$value');
  }

  Future<void> setSleepEnabled(bool value) async {
    state = state.copyWith(sleepEnabled: value);
    await _repository.writeSetting(SettingsKeys.sleepEnabled, '$value');
  }

  Future<void> setSleepCommuteMinutes(int value) async {
    state = state.copyWith(sleepCommuteMinutes: _cleanMinutes(value));
    await _repository.writeSetting(SettingsKeys.sleepCommuteMinutes, '${_cleanMinutes(value)}');
  }

  Future<void> setSleepWindDownMinutes(int value) async {
    state = state.copyWith(sleepWindDownMinutes: _cleanMinutes(value));
    await _repository.writeSetting(SettingsKeys.sleepWindDownMinutes, '${_cleanMinutes(value)}');
  }

  Future<void> setSleepWakeBufferMinutes(int value) async {
    state = state.copyWith(sleepWakeBufferMinutes: _cleanMinutes(value));
    await _repository.writeSetting(SettingsKeys.sleepWakeBufferMinutes, '${_cleanMinutes(value)}');
  }

  Future<void> setAutoBackupEnabled(bool value) async {
    state = state.copyWith(autoBackupEnabled: value);
    await _repository.writeSetting(SettingsKeys.autoBackupEnabled, '$value');
  }

  Future<void> setAutoBackupKeep(int value) async {
    final keep = value.clamp(1, 20);
    state = state.copyWith(autoBackupKeep: keep);
    await _repository.writeSetting(SettingsKeys.autoBackupKeep, '$keep');
  }

  Future<void> setWorkHoursEnabled(bool value) async {
    state = state.copyWith(workHoursEnabled: value);
    await _repository.writeSetting(SettingsKeys.workHoursEnabled, '$value');
  }

  Future<void> setWorkHours({required int startMinute, required int endMinute}) async {
    state = state.copyWith(
      workHoursStartMinute: _cleanMinutes(startMinute),
      workHoursEndMinute: _cleanMinutes(endMinute),
    );
    await _repository.writeSetting(SettingsKeys.workHoursStart, '${_cleanMinutes(startMinute)}');
    await _repository.writeSetting(SettingsKeys.workHoursEnd, '${_cleanMinutes(endMinute)}');
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    state = state.copyWith(quietHoursEnabled: value);
    await _repository.writeSetting(SettingsKeys.quietHoursEnabled, '$value');
  }

  Future<void> setQuietHours({required int startMinute, required int endMinute}) async {
    state = state.copyWith(
      quietHoursStartMinute: _cleanMinutes(startMinute),
      quietHoursEndMinute: _cleanMinutes(endMinute),
    );
    await _repository.writeSetting(SettingsKeys.quietHoursStart, '${_cleanMinutes(startMinute)}');
    await _repository.writeSetting(SettingsKeys.quietHoursEnd, '${_cleanMinutes(endMinute)}');
  }

  int _cleanMinutes(int value) => value.clamp(0, 24 * 60);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
