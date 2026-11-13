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
    final links = _links(l10n);
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? const <_SettingLink>[]
        : links.where((link) => link.matches(query)).toList();
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

  List<_SettingLink> _links(AppLocalizations l10n) => [
    _SettingLink(
      icon: Icons.palette_outlined,
      title: l10n.appearanceSection,
      subtitle: l10n.appearanceSubtitle,
      keywords: 'theme aero colour color background dots grid oled text size apariencia tema fondo',
      section: SettingsDetailSection.appearance,
    ),
    _SettingLink(
      icon: Icons.tune,
      title: l10n.preferencesSection,
      subtitle: l10n.preferencesSubtitle,
      keywords:
          'language date week start navigation side performance hours quiet reminders sleep categories tags shifts inventory shopping maintenance idioma fecha semana',
      section: SettingsDetailSection.preferences,
    ),
    _SettingLink(
      icon: Icons.storage_outlined,
      title: l10n.dataSection,
      subtitle: l10n.dataSubtitle,
      keywords: 'backup restore import export calendar csv companion delete data copia datos',
      section: SettingsDetailSection.data,
    ),
    _SettingLink(
      icon: Icons.devices_other,
      title: l10n.devicesAndSync,
      subtitle: l10n.devicesAndSyncSubtitle,
      keywords: 'devices sync lan pair nearby network dispositivos sincronizar red',
      route: _SettingRoute.devices,
    ),
    _SettingLink(
      icon: Icons.terminal,
      title: l10n.mcpServer,
      subtitle: l10n.mcpEndpointSubtitle,
      keywords: 'mcp server port tools servidor puerto',
      route: _SettingRoute.mcp,
    ),
    _SettingLink(
      icon: Icons.info_outline,
      title: l10n.about,
      subtitle: l10n.aboutSubtitle,
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
        _pushDetail(context, link.section!);
    }
  }

  void _pushDetail(BuildContext context, SettingsDetailSection section) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SettingsDetailPage(section: section)));
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
