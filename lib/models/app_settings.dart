import 'package:flutter/material.dart';
import 'package:sundial_core/sundial_core.dart';

import '../core/i18n/l10n.dart';
import 'app_icon_style.dart';
import 'visual_style.dart';

abstract final class SettingsKeys {
  static const themeMode = 'themeMode';
  static const locale = 'locale';
  static const weekStart = 'weekStart';
  static const hideWorkSpace = 'hideWorkSpace';
  static const defaultReminderOffsets = 'defaultReminderOffsets';
  static const syncEnabled = 'syncEnabled';
  static const mcpEnabled = 'mcpEnabled';
  static const mcpWritesEnabled = 'mcpWritesEnabled';
  static const sleepEnabled = 'sleepEnabled';
  static const sleepCommuteMinutes = 'sleepCommuteMinutes';
  static const sleepWindDownMinutes = 'sleepWindDownMinutes';
  static const sleepWakeBufferMinutes = 'sleepWakeBufferMinutes';
  static const autoBackupEnabled = 'autoBackupEnabled';
  static const autoBackupKeep = 'autoBackupKeep';
  static const workHoursEnabled = 'workHoursEnabled';
  static const workHoursStart = 'workHoursStart';
  static const workHoursEnd = 'workHoursEnd';
  static const quietHoursEnabled = 'quietHoursEnabled';
  static const quietHoursStart = 'quietHoursStart';
  static const quietHoursEnd = 'quietHoursEnd';

  static const visualStyle = 'visualStyle';

  /// Device-local launcher icon choice. Never synced or backed up.
  static const appIconStyle = 'appIconStyle';

  /// Legacy key. Read only to migrate installs that predate named styles.
  static const themeVariant = 'themeVariant';
  static const colorScheme = 'colorScheme';
  static const backgroundStyle = 'backgroundStyle';
  static const backgroundCustomColor = 'backgroundCustomColor';
  static const textScale = 'textScale';
  static const navSide = 'navSide';
  static const dateFormat = 'dateFormat';
  static const performanceMode = 'performanceMode';
  static const onlineEnabled = 'onlineEnabled';
  static const mcpPort = 'mcpPort';
  static const soundsEnabled = 'soundsEnabled';
  static const soundPack = 'soundPack';
  static const alarmSound = 'alarmSound';
  static const timezoneOverride = 'timezoneOverride';
  static const developerOptions = 'developerOptions';
}

enum SundialAccentScheme { sage, ocean, sunset, violet, mono }

enum SundialBackgroundStyle { dots, grid, oled, plain, custom }

enum SundialNavSide { left, right }

enum SundialDateFormat { system, dmy, mdy, ymd }

enum SundialSoundPack { soft, aero }

enum SundialAlarmSound { soft, chime, bright }

/// App-wide preferences. Persisted in the `setting_records` table.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.weekStart = DateTime.monday,
    this.hideWorkSpace = false,
    this.defaultReminderOffsets = const <int>[10, 60],
    this.syncEnabled = false,
    this.mcpEnabled = false,
    this.mcpWritesEnabled = false,
    this.sleepEnabled = true,
    this.sleepCommuteMinutes = 30,
    this.sleepWindDownMinutes = 60,
    this.sleepWakeBufferMinutes = 30,
    this.autoBackupEnabled = false,
    this.autoBackupKeep = 5,
    this.workHoursEnabled = false,
    this.workHoursStartMinute = 9 * 60,
    this.workHoursEndMinute = 17 * 60,
    this.quietHoursEnabled = false,
    this.quietHoursStartMinute = 22 * 60,
    this.quietHoursEndMinute = 7 * 60,
    this.visualStyle = SundialVisualStyle.classic,
    this.appIconStyle = AppIconStyle.classic,
    this.accentScheme = SundialAccentScheme.sage,
    this.backgroundStyle = SundialBackgroundStyle.dots,
    this.backgroundCustomColor = 0xFFF6F4EF,
    this.textScale = 1,
    this.navSide = SundialNavSide.left,
    this.dateFormat = SundialDateFormat.system,
    this.performanceMode = false,
    this.onlineEnabled = false,
    this.mcpPort = 8765,
    this.soundsEnabled = false,
    this.soundPack = SundialSoundPack.aero,
    this.alarmSound = SundialAlarmSound.chime,
    this.timezoneOverride = '',
    this.developerOptionsEnabled = false,
  });

  final ThemeMode themeMode;

  /// Null follows the system language.
  final Locale? locale;

  /// ISO weekday (1 = Monday) the week starts on.
  final int weekStart;

  final bool hideWorkSpace;

  /// Minutes before an occurrence pre-selected when a new entry is created.
  final List<int> defaultReminderOffsets;

  final bool syncEnabled;
  final bool mcpEnabled;
  final bool mcpWritesEnabled;

  final bool sleepEnabled;
  final int sleepCommuteMinutes;
  final int sleepWindDownMinutes;
  final int sleepWakeBufferMinutes;

  /// Writes a rotating JSON copy into the app's local backup folder.
  final bool autoBackupEnabled;
  final int autoBackupKeep;

  /// When enabled, Work entries leave the aggregate screens outside this
  /// window. Work deadlines stay visible, and search always finds them.
  final bool workHoursEnabled;
  final int workHoursStartMinute;
  final int workHoursEndMinute;

  /// Local notifications are not scheduled inside this window.
  final bool quietHoursEnabled;
  final int quietHoursStartMinute;
  final int quietHoursEndMinute;

  final SundialVisualStyle visualStyle;
  final AppIconStyle appIconStyle;
  final SundialAccentScheme accentScheme;
  final SundialBackgroundStyle backgroundStyle;
  final int backgroundCustomColor;
  final double textScale;
  final SundialNavSide navSide;
  final SundialDateFormat dateFormat;

  /// Reduces blur, shadows and long animations on low-end devices.
  final bool performanceMode;

  /// Master switch for LAN sync and the local MCP endpoint.
  final bool onlineEnabled;
  final int mcpPort;

  /// Short interaction blips. Off by default so a first launch stays quiet.
  final bool soundsEnabled;
  final SundialSoundPack soundPack;

  /// Sound played by scheduled reminders.
  final SundialAlarmSound alarmSound;

  /// IANA zone used for new timed entries. Empty follows the device zone.
  final String timezoneOverride;

  /// Reveals local diagnostic tools such as the sync debug log. Device-local
  /// and never synced.
  final bool developerOptionsEnabled;

  Duration get commute => Duration(minutes: sleepCommuteMinutes);
  Duration get windDown => Duration(minutes: sleepWindDownMinutes);
  Duration get wakeBuffer => Duration(minutes: sleepWakeBufferMinutes);

  ThemeMode get resolvedThemeMode {
    // OLED paints black behind the content; a light palette would become
    // unreadable, so OLED is always a dark surface.
    if (backgroundStyle == SundialBackgroundStyle.oled) return ThemeMode.dark;
    return themeMode;
  }

  bool get canUseNetwork => onlineEnabled;

  bool isWorkTime(DateTime instant, String timeZone) {
    if (!workHoursEnabled) return true;
    return isMinuteInWindow(localMinuteAt(instant, timeZone), workHoursStartMinute, workHoursEndMinute);
  }

  bool isQuietTime(DateTime instant, String timeZone) {
    if (!quietHoursEnabled) return false;
    return isMinuteInWindow(localMinuteAt(instant, timeZone), quietHoursStartMinute, quietHoursEndMinute);
  }

  factory AppSettings.fromMap(Map<String, String> values) {
    final localeValue = values[SettingsKeys.locale];
    final weekStartValue = int.tryParse(values[SettingsKeys.weekStart] ?? '');
    final offsets = <int>[];
    final rawOffsets = values[SettingsKeys.defaultReminderOffsets];
    if (rawOffsets != null) {
      for (final part in rawOffsets.split(',')) {
        final value = int.tryParse(part.trim());
        if (value != null && value >= 0 && !offsets.contains(value)) offsets.add(value);
      }
      offsets.sort();
    }

    return AppSettings(
      themeMode: _themeMode(values),
      visualStyle: _visualStyle(values),
      appIconStyle: AppIconStyle.fromName(values[SettingsKeys.appIconStyle]),
      accentScheme: _accentScheme(values[SettingsKeys.colorScheme]),
      backgroundStyle: _backgroundStyle(values[SettingsKeys.backgroundStyle]),
      backgroundCustomColor: int.tryParse(values[SettingsKeys.backgroundCustomColor] ?? '') ?? 0xFFF6F4EF,
      textScale: _textScale(values[SettingsKeys.textScale]),
      navSide: values[SettingsKeys.navSide] == 'right' ? SundialNavSide.right : SundialNavSide.left,
      dateFormat: _dateFormat(values[SettingsKeys.dateFormat]),
      performanceMode: values[SettingsKeys.performanceMode] == 'true',
      soundsEnabled: values[SettingsKeys.soundsEnabled] == 'true',
      soundPack: _soundPack(values[SettingsKeys.soundPack]),
      alarmSound: _alarmSound(values[SettingsKeys.alarmSound]),
      timezoneOverride: _timezone(values[SettingsKeys.timezoneOverride]),
      // The master switch is authoritative once written. Legacy rows without
      // it keep the old derived behaviour so existing installs stay online.
      onlineEnabled: values.containsKey(SettingsKeys.onlineEnabled)
          ? values[SettingsKeys.onlineEnabled] == 'true'
          : (values[SettingsKeys.syncEnabled] == 'true' || values[SettingsKeys.mcpEnabled] == 'true'),
      mcpPort: _mcpPort(values[SettingsKeys.mcpPort]),
      locale: localeValue == null || localeValue.isEmpty || localeValue == 'system'
          ? null
          : localeForCode(localeValue),
      weekStart: weekStartValue == 6 || weekStartValue == 7 ? weekStartValue! : DateTime.monday,
      hideWorkSpace: values[SettingsKeys.hideWorkSpace] == 'true',
      defaultReminderOffsets: rawOffsets == null ? const <int>[10, 60] : offsets,
      syncEnabled: values[SettingsKeys.syncEnabled] == 'true',
      mcpEnabled: values[SettingsKeys.mcpEnabled] == 'true',
      mcpWritesEnabled: values[SettingsKeys.mcpWritesEnabled] == 'true',
      sleepEnabled: values[SettingsKeys.sleepEnabled] != 'false',
      sleepCommuteMinutes: _minutes(values[SettingsKeys.sleepCommuteMinutes], 30),
      sleepWindDownMinutes: _minutes(values[SettingsKeys.sleepWindDownMinutes], 60),
      sleepWakeBufferMinutes: _minutes(values[SettingsKeys.sleepWakeBufferMinutes], 30),
      autoBackupEnabled: values[SettingsKeys.autoBackupEnabled] == 'true',
      autoBackupKeep: _keep(values[SettingsKeys.autoBackupKeep]),
      workHoursEnabled: values[SettingsKeys.workHoursEnabled] == 'true',
      workHoursStartMinute: _minutes(values[SettingsKeys.workHoursStart], 9 * 60),
      workHoursEndMinute: _minutes(values[SettingsKeys.workHoursEnd], 17 * 60),
      quietHoursEnabled: values[SettingsKeys.quietHoursEnabled] == 'true',
      quietHoursStartMinute: _minutes(values[SettingsKeys.quietHoursStart], 22 * 60),
      quietHoursEndMinute: _minutes(values[SettingsKeys.quietHoursEnd], 7 * 60),
      developerOptionsEnabled: values[SettingsKeys.developerOptions] == 'true',
    );
  }

  static int _keep(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 1) return 5;
    return parsed.clamp(1, 20);
  }

  static ThemeMode _themeMode(Map<String, String> values) {
    final explicit = values[SettingsKeys.themeMode];
    if (explicit != null) {
      return switch (explicit) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    }
    // Legacy rows used `themeVariant` for both brightness and the Aero flag.
    return switch (values[SettingsKeys.themeVariant]) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'aero' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  static SundialVisualStyle _visualStyle(Map<String, String> values) {
    final explicit = values[SettingsKeys.visualStyle];
    if (explicit != null) {
      for (final style in SundialVisualStyle.values) {
        if (style.name == explicit) return style;
      }
    }
    // Aero used to be a theme variant. Preserve that choice on upgrade.
    return values[SettingsKeys.themeVariant] == 'aero' ? SundialVisualStyle.aero : SundialVisualStyle.classic;
  }

  static SundialAccentScheme _accentScheme(String? value) {
    for (final scheme in SundialAccentScheme.values) {
      if (scheme.name == value) return scheme;
    }
    return SundialAccentScheme.sage;
  }

  static SundialBackgroundStyle _backgroundStyle(String? value) {
    for (final style in SundialBackgroundStyle.values) {
      if (style.name == value) return style;
    }
    return SundialBackgroundStyle.dots;
  }

  static SundialDateFormat _dateFormat(String? value) {
    for (final format in SundialDateFormat.values) {
      if (format.name == value) return format;
    }
    return SundialDateFormat.system;
  }

  static SundialSoundPack _soundPack(String? value) {
    for (final pack in SundialSoundPack.values) {
      if (pack.name == value) return pack;
    }
    return SundialSoundPack.aero;
  }

  static SundialAlarmSound _alarmSound(String? value) {
    for (final sound in SundialAlarmSound.values) {
      if (sound.name == value) return sound;
    }
    return SundialAlarmSound.chime;
  }

  static String _timezone(String? value) {
    final zone = value?.trim() ?? '';
    return zone.isEmpty || !isKnownTimeZone(zone) ? '' : zone;
  }

  static double _textScale(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return 1;
    return parsed.clamp(0.85, 1.35);
  }

  static int _mcpPort(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed < 1024 || parsed > 65535) return 8765;
    return parsed;
  }

  static int _minutes(String? value, int fallback) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 0 ? fallback : parsed;
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool clearLocale = false,
    int? weekStart,
    bool? hideWorkSpace,
    List<int>? defaultReminderOffsets,
    bool? syncEnabled,
    bool? mcpEnabled,
    bool? mcpWritesEnabled,
    bool? sleepEnabled,
    int? sleepCommuteMinutes,
    int? sleepWindDownMinutes,
    int? sleepWakeBufferMinutes,
    bool? autoBackupEnabled,
    int? autoBackupKeep,
    bool? workHoursEnabled,
    int? workHoursStartMinute,
    int? workHoursEndMinute,
    bool? quietHoursEnabled,
    int? quietHoursStartMinute,
    int? quietHoursEndMinute,
    SundialVisualStyle? visualStyle,
    AppIconStyle? appIconStyle,
    SundialAccentScheme? accentScheme,
    SundialBackgroundStyle? backgroundStyle,
    int? backgroundCustomColor,
    double? textScale,
    SundialNavSide? navSide,
    SundialDateFormat? dateFormat,
    bool? performanceMode,
    bool? onlineEnabled,
    int? mcpPort,
    bool? soundsEnabled,
    SundialSoundPack? soundPack,
    SundialAlarmSound? alarmSound,
    String? timezoneOverride,
    bool? developerOptionsEnabled,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: clearLocale ? null : (locale ?? this.locale),
    weekStart: weekStart ?? this.weekStart,
    hideWorkSpace: hideWorkSpace ?? this.hideWorkSpace,
    defaultReminderOffsets: defaultReminderOffsets ?? this.defaultReminderOffsets,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    mcpEnabled: mcpEnabled ?? this.mcpEnabled,
    mcpWritesEnabled: mcpWritesEnabled ?? this.mcpWritesEnabled,
    sleepEnabled: sleepEnabled ?? this.sleepEnabled,
    sleepCommuteMinutes: sleepCommuteMinutes ?? this.sleepCommuteMinutes,
    sleepWindDownMinutes: sleepWindDownMinutes ?? this.sleepWindDownMinutes,
    sleepWakeBufferMinutes: sleepWakeBufferMinutes ?? this.sleepWakeBufferMinutes,
    autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    autoBackupKeep: autoBackupKeep ?? this.autoBackupKeep,
    workHoursEnabled: workHoursEnabled ?? this.workHoursEnabled,
    workHoursStartMinute: workHoursStartMinute ?? this.workHoursStartMinute,
    workHoursEndMinute: workHoursEndMinute ?? this.workHoursEndMinute,
    quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
    quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
    visualStyle: visualStyle ?? this.visualStyle,
    appIconStyle: appIconStyle ?? this.appIconStyle,
    accentScheme: accentScheme ?? this.accentScheme,
    backgroundStyle: backgroundStyle ?? this.backgroundStyle,
    backgroundCustomColor: backgroundCustomColor ?? this.backgroundCustomColor,
    textScale: textScale ?? this.textScale,
    navSide: navSide ?? this.navSide,
    dateFormat: dateFormat ?? this.dateFormat,
    performanceMode: performanceMode ?? this.performanceMode,
    onlineEnabled: onlineEnabled ?? this.onlineEnabled,
    mcpPort: mcpPort ?? this.mcpPort,
    soundsEnabled: soundsEnabled ?? this.soundsEnabled,
    soundPack: soundPack ?? this.soundPack,
    alarmSound: alarmSound ?? this.alarmSound,
    timezoneOverride: timezoneOverride ?? this.timezoneOverride,
    developerOptionsEnabled: developerOptionsEnabled ?? this.developerOptionsEnabled,
  );
}
