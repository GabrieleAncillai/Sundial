import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../mcp/pages/mcp_page.dart';
import '../../sync/pages/devices_page.dart';
import '../widgets/settings_rows.dart';
import 'about_page.dart';
import 'settings_detail_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final entries = _entries(l10n);
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <_SettingLink>[]
        : entries.where((entry) => entry.matches(query)).toList();
    final pairedCount = ref.watch(pairedDevicesProvider).value?.length ?? 0;

    return ManePage(
      title: l10n.settings,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          ManeSearchField(
            controller: _search,
            hint: l10n.settingsSearch,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 16),
          if (query.isNotEmpty) ...[
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(l10n.noSettingsFound, style: TextStyle(color: context.mc.textSecondary)),
              )
            else
              SettingsSection(
                title: l10n.settingsSearch,
                children: [
                  for (final link in matches)
                    SettingsNavRow(
                      icon: link.icon,
                      title: link.title,
                      subtitle: link.subtitle,
                      onTap: () => _open(context, link),
                    ),
                ],
              ),
          ] else ...[
            SettingsSection(
              title: l10n.generalSection,
              children: [
                SettingsNavRow(
                  icon: Icons.palette_outlined,
                  title: l10n.appearanceSection,
                  subtitle: l10n.appearanceSubtitle,
                  onTap: () => _pushDetail(context, SettingsDetailSection.appearance),
                ),
                SettingsNavRow(
                  icon: Icons.tune,
                  title: l10n.preferencesSection,
                  subtitle: l10n.preferencesSubtitle,
                  onTap: () => _pushDetail(context, SettingsDetailSection.preferences),
                ),
                SettingsNavRow(
                  icon: Icons.storage_outlined,
                  title: l10n.dataSection,
                  subtitle: l10n.dataSubtitle,
                  onTap: () => _pushDetail(context, SettingsDetailSection.data),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.onlineSection,
              children: [
                SettingsSwitchRow(
                  icon: Icons.language,
                  title: l10n.onlineEnable,
                  subtitle: l10n.onlineEnableSubtitle,
                  value: settings.onlineEnabled,
                  onChanged: (value) async {
                    await controller.setOnlineEnabled(value);
                    await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
                    if (value && context.mounted) {
                      final identity = await ref.read(repositoryProvider).readIdentity();
                      if (identity == null && context.mounted) {
                        _notice(context, l10n.identityRequired);
                      }
                    }
                  },
                ),
                if (settings.onlineEnabled) ...[
                  SettingsNavRow(
                    icon: Icons.devices_other,
                    title: l10n.devicesAndSync,
                    subtitle: l10n.devicesAndSyncSubtitle,
                    value: '$pairedCount',
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => const DevicesPage())),
                  ),
                  SettingsNavRow(
                    icon: Icons.terminal,
                    title: l10n.mcpServer,
                    subtitle: l10n.mcpEndpointSubtitle,
                    value: settings.mcpEnabled ? l10n.on : l10n.off,
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const McpPage())),
                  ),
                ],
              ],
            ),
            SettingsSection(
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
        ],
      ),
    );
  }

  List<_SettingLink> _entries(AppLocalizations l10n) => [
    _SettingLink(
      icon: Icons.palette_outlined,
      title: l10n.theme,
      subtitle: l10n.appearanceSection,
      keywords: 'theme system light dark aero tema',
      section: SettingsDetailSection.appearance,
    ),
    _SettingLink(
      icon: Icons.wallpaper_outlined,
      title: l10n.background,
      subtitle: l10n.appearanceSection,
      keywords: 'background dots grid oled custom plain fondo',
      section: SettingsDetailSection.appearance,
    ),
    _SettingLink(
      icon: Icons.format_size,
      title: l10n.textSize,
      subtitle: l10n.appearanceSection,
      keywords: 'text size font scale tamano texto',
      section: SettingsDetailSection.appearance,
    ),
    _SettingLink(
      icon: Icons.language,
      title: l10n.language,
      subtitle: l10n.preferencesSection,
      keywords: 'language english spanish idioma',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.volume_up_outlined,
      title: l10n.interactionSounds,
      subtitle: l10n.preferencesSection,
      keywords: 'sound interaction tap toggle confirm back error sonido',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.notifications_active_outlined,
      title: l10n.alarmSounds,
      subtitle: l10n.preferencesSection,
      keywords: 'alarm reminder sound alarma recordatorio',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.event_outlined,
      title: l10n.dateFormatLabel,
      subtitle: l10n.preferencesSection,
      keywords: 'date format fecha formato',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.public,
      title: l10n.timeZone,
      subtitle: l10n.preferencesSection,
      keywords: 'time zone iana city offset zona horaria',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.today_outlined,
      title: l10n.weekStartsOn,
      subtitle: l10n.preferencesSection,
      keywords: 'week start monday sunday semana',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.speed,
      title: l10n.performanceMode,
      subtitle: l10n.preferencesSection,
      keywords: 'performance blur motion rendimiento',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.view_sidebar_outlined,
      title: l10n.navigationSide,
      subtitle: l10n.preferencesSection,
      keywords: 'navigation side rail left right navegacion',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.notifications_outlined,
      title: l10n.defaultReminders,
      subtitle: l10n.preferencesSection,
      keywords: 'default reminders lead recordatorios',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.work_outline,
      title: l10n.workHours,
      subtitle: l10n.preferencesSection,
      keywords: 'work hours visibilidad trabajo horario',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.bedtime_outlined,
      title: l10n.quietHours,
      subtitle: l10n.preferencesSection,
      keywords: 'quiet hours silence silencio',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.nightlight_outlined,
      title: l10n.sleepWindow,
      subtitle: l10n.preferencesSection,
      keywords: 'sleep window commute wind down buffers sueno descanso',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.file_upload_outlined,
      title: l10n.exportBackup,
      subtitle: l10n.dataSection,
      keywords: 'export backup copia exportar',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.file_download_outlined,
      title: l10n.importBackup,
      subtitle: l10n.dataSection,
      keywords: 'import restore backup restaurar importar',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.history,
      title: l10n.automaticBackups,
      subtitle: l10n.dataSection,
      keywords: 'automatic backups rotation copias automaticas',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.calendar_month_outlined,
      title: l10n.importCalendar,
      subtitle: l10n.dataSection,
      keywords: 'import calendar ics importar calendario',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.calendar_today_outlined,
      title: l10n.exportCalendar,
      subtitle: l10n.dataSection,
      keywords: 'export calendar ics exportar calendario',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.table_chart_outlined,
      title: l10n.exportCsv,
      subtitle: l10n.dataSection,
      keywords: 'export csv exportar',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.table_view_outlined,
      title: l10n.importCsv,
      subtitle: l10n.dataSection,
      keywords: 'import csv importar',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.delete_forever_outlined,
      title: l10n.deleteAllData,
      subtitle: l10n.dataSection,
      keywords: 'delete all data erase borrar datos',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.devices_other,
      title: l10n.devicesAndSync,
      subtitle: l10n.onlineSection,
      keywords: 'devices sync lan pair nearby network dispositivos sincronizar red',
      route: _SettingRoute.devices,
    ),
    _SettingLink(
      icon: Icons.terminal,
      title: l10n.mcpServer,
      subtitle: l10n.onlineSection,
      keywords: 'mcp server port tools servidor puerto',
      route: _SettingRoute.mcp,
    ),
    _SettingLink(
      icon: Icons.info_outline,
      title: l10n.about,
      subtitle: l10n.about,
      keywords: 'about license version credits acerca licencia',
      route: _SettingRoute.about,
    ),
  ];

  void _open(BuildContext context, _SettingLink link) {
    switch (link.route) {
      case _SettingRoute.devices:
        if (!ref.read(settingsProvider).onlineEnabled) {
          _notice(context, context.l10n.onlineEnableSubtitle);
          return;
        }
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DevicesPage()));
      case _SettingRoute.mcp:
        if (!ref.read(settingsProvider).onlineEnabled) {
          _notice(context, context.l10n.onlineEnableSubtitle);
          return;
        }
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const McpPage()));
      case _SettingRoute.about:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutPage()));
      case _SettingRoute.detail:
        _pushDetail(context, link.section!, highlight: link.title);
    }
  }

  void _pushDetail(BuildContext context, SettingsDetailSection section, {String? highlight}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsDetailPage(section: section, highlight: highlight),
      ),
    );
  }

  void _notice(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _SettingRoute { devices, mcp, about, detail }

class _SettingLink {
  const _SettingLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.keywords,
    this.section,
    this.route = _SettingRoute.detail,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String keywords;
  final SettingsDetailSection? section;
  final _SettingRoute route;

  bool matches(String query) =>
      title.toLowerCase().contains(query) ||
      subtitle.toLowerCase().contains(query) ||
      keywords.toLowerCase().contains(query);
}
