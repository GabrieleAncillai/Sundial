import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/layout/sundial_layout.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../models/app_settings.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../mcp/pages/mcp_page.dart';
import '../../sync/pages/devices_page.dart';
import '../widgets/settings_rows.dart';
import 'about_page.dart';
import 'settings_detail_page.dart';

/// Mirrors the shell breakpoint in `lib/app/app_shell.dart`.
const _desktopBreakpoint = 900.0;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _search = TextEditingController();
  String _query = '';
  _DesktopSettingsSection _desktopSection = _DesktopSettingsSection.appearance;
  String? _desktopHighlight;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _desktopBreakpoint) return _mobile(context);
        return _desktop(context);
      },
    );
  }

  Widget _mobile(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final entries = _entries(l10n);
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <_SettingLink>[]
        : entries.where((entry) => entry.matches(query)).toList();
    final pairedCount = ref.watch(pairedDevicesProvider).value?.length ?? 0;

    return SundialPage(
      title: l10n.settings,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          SundialSearchField(
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
            _onlineSection(context, l10n, settings, pairedCount),
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

  Widget _desktop(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final entries = _entries(l10n);
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <_SettingLink>[]
        : entries.where((entry) => entry.matches(query)).toList();
    final pairedCount = ref.watch(pairedDevicesProvider).value?.length ?? 0;

    final sidebar = _SettingsSidebar(
      searchController: _search,
      searchHint: l10n.settingsSearch,
      onSearchChanged: (value) => setState(() => _query = value),
      searching: query.isNotEmpty,
      matches: matches,
      selected: _desktopSection,
      onlineEnabled: settings.onlineEnabled,
      onSelected: _selectDesktopSection,
      onOpenLink: _openDesktopLink,
      onBack: () => Navigator.of(context).maybePop(),
    );
    final pane = Expanded(
      child: SundialContentPane(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _paneHeader(context, l10n),
            Expanded(child: _paneBody(context, l10n, settings, pairedCount)),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: settings.navSide == SundialNavSide.right
                  ? [pane, const SizedBox(width: 22), sidebar]
                  : [sidebar, const SizedBox(width: 22), pane],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paneHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_desktopSection.title(l10n), style: SundialType.headline(27, color: context.mc.text)),
          const SizedBox(height: 3),
          Text(_desktopSection.subtitle(l10n), style: SundialType.body(13, color: context.mc.textSecondary)),
        ],
      ),
    );
  }

  Widget _paneBody(BuildContext context, AppLocalizations l10n, AppSettings settings, int pairedCount) {
    switch (_desktopSection) {
      case _DesktopSettingsSection.online:
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_onlineSection(context, l10n, settings, pairedCount, highlight: _desktopHighlight)],
          ),
        );
      case _DesktopSettingsSection.about:
        return const AboutPage(embedded: true);
      case _DesktopSettingsSection.appearance:
      case _DesktopSettingsSection.preferences:
      case _DesktopSettingsSection.data:
        return SettingsDetailPage(
          section: _desktopSection.detail!,
          highlight: _desktopHighlight,
          embedded: true,
        );
    }
  }

  Widget _onlineSection(
    BuildContext context,
    AppLocalizations l10n,
    AppSettings settings,
    int pairedCount, {
    String? highlight,
  }) {
    final controller = ref.read(settingsProvider.notifier);
    return SettingsSection(
      highlight: highlight,
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
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DevicesPage())),
          ),
          SettingsNavRow(
            icon: Icons.terminal,
            title: l10n.mcpServer,
            subtitle: l10n.mcpEndpointSubtitle,
            value: settings.mcpEnabled ? l10n.on : l10n.off,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const McpPage())),
          ),
        ],
      ],
    );
  }

  List<_SettingLink> _entries(AppLocalizations l10n) => [
    _SettingLink(
      icon: Icons.palette_outlined,
      title: l10n.style,
      subtitle: l10n.appearanceSection,
      keywords: 'style classic aero frutiger tema estilo',
      section: SettingsDetailSection.appearance,
    ),
    _SettingLink(
      icon: Icons.brightness_6_outlined,
      title: l10n.brightness,
      subtitle: l10n.appearanceSection,
      keywords: 'brightness system light dark theme brillo claro oscuro',
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

  void _selectDesktopSection(_DesktopSettingsSection section) {
    if (section == _desktopSection) return;
    setState(() {
      _desktopSection = section;
      _desktopHighlight = null;
    });
  }

  void _openDesktopLink(_SettingLink link) {
    switch (link.route) {
      case _SettingRoute.devices:
      case _SettingRoute.mcp:
        if (!ref.read(settingsProvider).onlineEnabled) {
          _notice(context, context.l10n.onlineEnableSubtitle);
          return;
        }
        setState(() {
          _desktopSection = _DesktopSettingsSection.online;
          _desktopHighlight = link.title;
        });
      case _SettingRoute.about:
        setState(() {
          _desktopSection = _DesktopSettingsSection.about;
          _desktopHighlight = null;
        });
      case _SettingRoute.detail:
        setState(() {
          _desktopSection = _DesktopSettingsSection.fromDetail(link.section!);
          _desktopHighlight = link.title;
        });
    }
  }

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

class _SettingsSidebar extends StatelessWidget {
  const _SettingsSidebar({
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.searching,
    required this.matches,
    required this.selected,
    required this.onlineEnabled,
    required this.onSelected,
    required this.onOpenLink,
    required this.onBack,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final bool searching;
  final List<_SettingLink> matches;
  final _DesktopSettingsSection selected;
  final bool onlineEnabled;
  final ValueChanged<_DesktopSettingsSection> onSelected;
  final ValueChanged<_SettingLink> onOpenLink;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return Container(
      width: kSidebarWidth,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: c.navBg,
        borderRadius: BorderRadius.circular(SundialRadii.lg),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              children: [
                _SidebarBackButton(onTap: onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.settings,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SundialType.headline(21, color: c.text),
                  ),
                ),
              ],
            ),
          ),
          SundialSearchField(controller: searchController, hint: searchHint, onChanged: onSearchChanged),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                if (searching) ...[
                  SectionLabel(l10n.settingsSearch),
                  if (matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                      child: Text(
                        l10n.noSettingsFound,
                        style: SundialType.body(12.5, color: c.textSecondary),
                      ),
                    )
                  else
                    for (final link in matches)
                      _SidebarRow(
                        icon: link.icon,
                        title: link.title,
                        subtitle: link.subtitle,
                        onTap: () => onOpenLink(link),
                      ),
                ] else ...[
                  _SidebarRow(
                    icon: Icons.palette_outlined,
                    title: l10n.appearanceSection,
                    selected: selected == _DesktopSettingsSection.appearance,
                    onTap: () => onSelected(_DesktopSettingsSection.appearance),
                  ),
                  _SidebarRow(
                    icon: Icons.tune,
                    title: l10n.preferencesSection,
                    selected: selected == _DesktopSettingsSection.preferences,
                    onTap: () => onSelected(_DesktopSettingsSection.preferences),
                  ),
                  _SidebarRow(
                    icon: Icons.storage_outlined,
                    title: l10n.dataSection,
                    selected: selected == _DesktopSettingsSection.data,
                    onTap: () => onSelected(_DesktopSettingsSection.data),
                  ),
                  const _SidebarDivider(),
                  _SidebarRow(
                    icon: Icons.language,
                    title: l10n.onlineSection,
                    value: onlineEnabled ? l10n.on : l10n.off,
                    selected: selected == _DesktopSettingsSection.online,
                    onTap: () => onSelected(_DesktopSettingsSection.online),
                  ),
                  const _SidebarDivider(),
                  _SidebarRow(
                    icon: Icons.info_outline,
                    title: l10n.about,
                    selected: selected == _DesktopSettingsSection.about,
                    onTap: () => onSelected(_DesktopSettingsSection.about),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarBackButton extends StatelessWidget {
  const _SidebarBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      semanticButton: true,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.surface,
          border: Border.all(color: c.border),
        ),
        child: Icon(Icons.chevron_left, size: 21, color: c.text),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Divider(height: 1, color: context.mc.border),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.selected = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final twoLines = subtitle != null;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: twoLines ? 8 : 10),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(SundialRadii.sm),
            border: Border.all(color: selected ? c.accent.withValues(alpha: 0.30) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? c.accent : c.textSecondary),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(
                        13.5,
                        weight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? c.accent : c.text,
                      ),
                    ),
                    if (twoLines) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SundialType.body(10.5, color: c.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Text(value!, style: SundialType.label(10.5, color: c.textTertiary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _DesktopSettingsSection {
  appearance,
  preferences,
  data,
  online,
  about;

  SettingsDetailSection? get detail => switch (this) {
    _DesktopSettingsSection.appearance => SettingsDetailSection.appearance,
    _DesktopSettingsSection.preferences => SettingsDetailSection.preferences,
    _DesktopSettingsSection.data => SettingsDetailSection.data,
    _DesktopSettingsSection.online => null,
    _DesktopSettingsSection.about => null,
  };

  static _DesktopSettingsSection fromDetail(SettingsDetailSection section) => switch (section) {
    SettingsDetailSection.appearance => _DesktopSettingsSection.appearance,
    SettingsDetailSection.preferences => _DesktopSettingsSection.preferences,
    SettingsDetailSection.data => _DesktopSettingsSection.data,
    SettingsDetailSection.about => _DesktopSettingsSection.about,
  };

  String title(AppLocalizations l10n) => switch (this) {
    _DesktopSettingsSection.appearance => l10n.appearanceSection,
    _DesktopSettingsSection.preferences => l10n.preferencesSection,
    _DesktopSettingsSection.data => l10n.dataSection,
    _DesktopSettingsSection.online => l10n.onlineSection,
    _DesktopSettingsSection.about => l10n.about,
  };

  String subtitle(AppLocalizations l10n) => switch (this) {
    _DesktopSettingsSection.appearance => l10n.appearanceSubtitle,
    _DesktopSettingsSection.preferences => l10n.preferencesSubtitle,
    _DesktopSettingsSection.data => l10n.dataSubtitle,
    _DesktopSettingsSection.online => l10n.onlineSubtitle,
    _DesktopSettingsSection.about => l10n.aboutSubtitle,
  };
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

  bool matches(String query) {
    final haystack = '$title $subtitle $keywords'.toLowerCase();
    final tokens = query.toLowerCase().split(RegExp(r'\s+')).where((token) => token.isNotEmpty);
    return tokens.every(haystack.contains);
  }
}
