import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../state/settings_controller.dart';
import '../../settings/widgets/settings_rows.dart';
import '../../sync/pages/devices_page.dart';
import '../mcp_server.dart';

class McpPage extends ConsumerWidget {
  const McpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final identity = ref.watch(identityProvider).value;

    return ManePage(
      title: l10n.mcpEndpoint,
      subtitle: l10n.mcpEndpointSubtitle,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          if (identity == null)
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.identityRequired),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => const DevicesPage())),
                    child: Text(l10n.pairingIdentity),
                  ),
                ],
              ),
            )
          else ...[
            SettingsSection(
              title: l10n.mcpEndpoint,
              children: [
                SettingsSwitchRow(
                  icon: Icons.terminal,
                  title: l10n.mcpEndpoint,
                  subtitle: l10n.mcpEndpointSubtitle,
                  value: settings.mcpEnabled,
                  onChanged: (value) async {
                    await controller.setMcpEnabled(value);
                    await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
                    final error = ref.read(mcpServerProvider).lastError;
                    if (value && error != null) {
                      // A busy or invalid port must not leave the switch on.
                      await controller.setMcpEnabled(false);
                      await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(context.l10n.mcpStartFailed(error))));
                      }
                    }
                  },
                ),
                SettingsSwitchRow(
                  icon: Icons.edit_outlined,
                  title: l10n.mcpWriteTools,
                  subtitle: l10n.mcpWriteToolsSubtitle,
                  value: settings.mcpWritesEnabled,
                  onChanged: settings.mcpEnabled
                      ? (value) async {
                          await controller.setMcpWritesEnabled(value);
                          await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
                        }
                      : null,
                ),
                SettingsNavRow(
                  icon: Icons.settings_ethernet,
                  title: l10n.mcpPort,
                  subtitle: l10n.mcpPortHint,
                  value: '${settings.mcpPort}',
                  onTap: () => _editPort(context, ref, settings.mcpPort),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.mcpToken,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        'http://127.0.0.1:${settings.mcpPort}${McpServer.path}',
                        style: ManeType.body(13, weight: FontWeight.w700, color: context.mc.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.mcpEnabled ? l10n.mcpRunning(settings.mcpPort) : l10n.mcpStopped,
                        style: ManeType.body(
                          11.5,
                          color: settings.mcpEnabled ? context.mc.success : context.mc.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        identity.mcpToken,
                        style: ManeType.body(
                          11.5,
                          color: context.mc.textSecondary,
                        ).copyWith(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.mcpTokenHint, style: ManeType.body(11.5, color: context.mc.textSecondary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: identity.mcpToken));
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                              }
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: Text(l10n.copy),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await ref.read(identityServiceProvider).rotateMcpToken(identity);
                              ref.invalidate(identityProvider);
                              await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
                            },
                            icon: const Icon(Icons.autorenew, size: 18),
                            label: Text(l10n.rotateToken),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.mcpLoopbackHint, style: ManeType.body(11.5, color: context.mc.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.mcpTools,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        'personal.today  work.next_shifts  plan.range\n'
                        'plan.search  plan.get  work.shifts  tags.list\n'
                        'spaces.list  habits.list  time.sessions\n'
                        'home.shopping  home.inventory  sleep.window',
                        style: ManeType.body(
                          11.5,
                          color: context.mc.textSecondary,
                        ).copyWith(fontFamily: 'monospace', height: 1.5),
                      ),
                      if (settings.mcpWritesEnabled) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          'plan.create  plan.update  plan.complete\n'
                          'plan.uncomplete  plan.delete\n'
                          'home.shopping_add  home.shopping_check\n'
                          'habits.check  time.start  time.stop',
                          style: ManeType.body(
                            11.5,
                            color: context.mc.textSecondary,
                          ).copyWith(fontFamily: 'monospace', height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(l10n.mcpToolsHint, style: ManeType.body(11.5, color: context.mc.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editPort(BuildContext context, WidgetRef ref, int current) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: '$current');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.mcpPort),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.mcpPort, helperText: l10n.mcpPortHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.applyPort),
          ),
        ],
      ),
    );
    controller.dispose();
    final parsed = int.tryParse(result?.trim() ?? '');
    if (parsed == null || parsed < 1024 || parsed > 65535) return;
    final previous = ref.read(settingsProvider).mcpPort;
    await ref.read(settingsProvider.notifier).setMcpPort(parsed);
    try {
      await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
    } on Object {
      await ref.read(settingsProvider.notifier).setMcpPort(previous);
      await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mcpPortUnavailable(parsed))));
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.portSaved(parsed))));
  }
}
