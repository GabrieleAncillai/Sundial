import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../../../models/local_identity.dart';
import '../../../models/paired_device.dart';
import '../../../state/providers.dart';
import '../../../state/settings_controller.dart';
import '../device_certificate.dart';
import '../identity_service.dart';
import '../pairing_request.dart';
import '../peer_discovery.dart';
import '../sync_models.dart';
import '../sync_service.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final identity = ref.watch(identityProvider);
    final paired = ref.watch(pairedDevicesProvider).value ?? const <PairedDevice>[];

    return SundialPage(
      title: l10n.devices,
      subtitle: l10n.devicesSubtitle,
      actions: [
        GlassIconButton(
          icon: Icons.refresh,
          tooltip: l10n.refreshDevices,
          onTap: () => ref.read(syncServiceProvider).refresh(),
        ),
      ],
      child: identity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (value) {
          if (value == null) return _IdentitySetup(onCreated: () => ref.invalidate(identityProvider));
          return _DevicesBody(identity: value, devices: paired);
        },
      ),
    );
  }
}

class _IdentitySetup extends ConsumerStatefulWidget {
  const _IdentitySetup({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_IdentitySetup> createState() => _IdentitySetupState();
}

class _IdentitySetupState extends ConsumerState<_IdentitySetup> {
  late final TextEditingController _username;
  late final TextEditingController _deviceName;
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController();
    _deviceName = TextEditingController(text: IdentityService.defaultDeviceName());
  }

  @override
  void dispose() {
    _username.dispose();
    _deviceName.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(identityServiceProvider)
          .create(username: _username.text, deviceName: _deviceName.text, pin: _pin.text);
      widget.onCreated();
      await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.identityCreated)));
      setState(() => _busy = false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Text(l10n.pairingIdentity, style: SundialType.headline(20, color: context.mc.text)),
        const SizedBox(height: 6),
        Text(l10n.pairingIdentitySubtitle, style: SundialType.body(13, color: context.mc.textSecondary)),
        const SizedBox(height: 20),
        TextField(
          controller: _username,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.username, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _deviceName,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.deviceName, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.pin,
            helperText: l10n.pinHint,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.createIdentity),
        ),
      ],
    );
  }
}

class _DevicesBody extends ConsumerWidget {
  const _DevicesBody({required this.identity, required this.devices});

  final LocalIdentity identity;
  final List<PairedDevice> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sync = ref.watch(syncServiceProvider);
    return ValueListenableBuilder<SyncState>(
      valueListenable: sync.state,
      builder: (context, state, _) {
        final pairedIds = {for (final device in devices) device.id};
        final known = [
          for (final device in state.roster.values)
            if (!pairedIds.contains(device.deviceId)) device,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            _IdentityCard(identity: identity, state: state),
            const SizedBox(height: 14),
            SoftCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lan_outlined, size: 21, color: context.mc.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.syncExplainer,
                      style: SundialType.body(12, color: context.mc.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.pairDevice, style: SundialType.title(16, color: context.mc.text)),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => const PairDevicePage())),
                  icon: const Icon(Icons.add_link, size: 18),
                  label: Text(l10n.pair),
                ),
              ],
            ),
            if (!state.discoveryAvailable && state.running)
              SundialNotice(text: l10n.discoveryUnavailable, tone: SundialNoticeTone.warning),
            const SizedBox(height: 12),
            if (devices.isEmpty)
              SoftCard(
                padding: EdgeInsets.zero,
                child: AppEmptyState(
                  icon: Icons.devices_other_outlined,
                  title: l10n.noPairedDevices,
                  message: l10n.noPairedDevicesHint,
                  compact: true,
                ),
              )
            else
              for (final device in devices)
                _PairedDeviceCard(device: device, peer: state.peers[device.id] ?? const PeerSyncState()),
            if (known.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(l10n.knownDevicesTitle, style: SundialType.title(16, color: context.mc.text)),
              const SizedBox(height: 4),
              Text(l10n.knownDevicesBody, style: SundialType.body(12, color: context.mc.textSecondary)),
              const SizedBox(height: 10),
              for (final device in known) _KnownDeviceCard(device: device),
            ],
          ],
        );
      },
    );
  }
}

class _IdentityCard extends ConsumerWidget {
  const _IdentityCard({required this.identity, required this.state});

  final LocalIdentity identity;
  final SyncState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(SundialRadii.sm),
                ),
                child: Icon(Icons.devices, size: 19, color: c.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.thisDevice, style: SundialType.label(10.5, color: c.textTertiary)),
                    Text(
                      '${identity.username} · ${identity.deviceName}',
                      style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${l10n.identityFingerprint}: ${shortFingerprint(fingerprintOfPemSync(identity.certificatePem))}',
            style: SundialType.body(11, color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            state.running ? l10n.serverOnPort(state.port) : l10n.serverOff,
            style: SundialType.body(11, color: state.running ? c.success : c.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            children: [
              TextButton(onPressed: () => _editProfile(context, ref), child: Text(l10n.editIdentity)),
              TextButton(onPressed: () => _changePin(context, ref), child: Text(l10n.changePin)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final username = TextEditingController(text: identity.username);
    final deviceName = TextEditingController(text: identity.deviceName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editIdentity),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: username,
              decoration: InputDecoration(labelText: l10n.username),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deviceName,
              decoration: InputDecoration(labelText: l10n.deviceName),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.save)),
        ],
      ),
    );
    if (saved == true) {
      await ref
          .read(identityServiceProvider)
          .updateProfile(identity, username: username.text, deviceName: deviceName.text);
      ref.invalidate(identityProvider);
      await ref.read(syncServiceProvider).restart();
      await ref.read(serviceCoordinatorProvider).apply(ref.read(settingsProvider));
    }
    username.dispose();
    deviceName.dispose();
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = TextEditingController();
    final next = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.changePin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.currentPin),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: next,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.newPin, helperText: l10n.pinHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.save)),
        ],
      ),
    );
    if (saved == true) {
      final service = ref.read(identityServiceProvider);
      if (await service.verifyPin(identity, current.text)) {
        await service.changePin(identity, next.text);
        ref.invalidate(identityProvider);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pairingFailed(l10n.pin))));
      }
    }
    current.dispose();
    next.dispose();
  }
}

class _PairedDeviceCard extends ConsumerWidget {
  const _PairedDeviceCard({required this.device, required this.peer});

  final PairedDevice device;
  final PeerSyncState peer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lastSeen = device.lastSeenAt == null
        ? l10n.neverReached
        : l10n.lastSeen(
            '${formatFullDate(context, device.lastSeenAt!.toLocal())} '
            '${DateFormat.Hm(locale).format(device.lastSeenAt!.toLocal())}',
          );
    final busy = peer.pulling || peer.replacing;

    final (status, statusColor) = switch (peer) {
      PeerSyncState(replacing: true) => (l10n.syncStatusReplacing, c.accent),
      PeerSyncState(pulling: true) => (l10n.syncStatusPulling, c.accent),
      PeerSyncState(lastError: final error?) => (l10n.syncStatusError(error), c.danger),
      PeerSyncState(lastPullAt: final at?) => (
        l10n.syncStatusLast(
          '${formatFullDate(context, at.toLocal())} ${DateFormat.Hm(locale).format(at.toLocal())}',
        ),
        c.textSecondary,
      ),
      _ => (l10n.syncStatusNever, c.textTertiary),
    };

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.workSoft,
                  borderRadius: BorderRadius.circular(SundialRadii.xs),
                ),
                child: Icon(Icons.phone_android, size: 18, color: c.work),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  device.name,
                  style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GlassIconButton(
                icon: Icons.refresh,
                tooltip: l10n.refreshDevices,
                size: 32,
                onTap: busy ? null : () => ref.read(syncServiceProvider).refreshDevice(device.id),
              ),
              const SizedBox(width: 6),
              GlassIconButton(
                icon: Icons.link_off,
                tooltip: l10n.unpair,
                size: 32,
                onTap: busy ? null : () => _confirmUnpair(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${device.username} · ${device.host.isEmpty ? '' : '${device.host}:${device.port}'}',
            style: SundialType.body(11.5, color: c.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(lastSeen, style: SundialType.body(11, color: c.textTertiary)),
          const SizedBox(height: 4),
          Text(status, style: SundialType.body(11.5, color: statusColor)),
          if (peer.needsSource && !peer.replacing) ...[
            const SizedBox(height: 10),
            Text(
              l10n.differentPlanTitle,
              style: SundialType.body(12.5, weight: FontWeight.w700, color: c.text),
            ),
            const SizedBox(height: 2),
            Text(l10n.differentPlanBody(device.name), style: SundialType.body(11.5, color: c.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _confirmReplace(context, ref),
                  icon: const Icon(Icons.swap_horiz, size: 17),
                  label: Text(l10n.usePeerPlan(device.name)),
                ),
                TextButton(onPressed: () => _explainKeepingPlan(context), child: Text(l10n.keepThisPlan)),
              ],
            ),
          ] else if (!peer.replacing) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _confirmReplace(context, ref),
              icon: const Icon(Icons.swap_horiz, size: 17),
              label: Text(l10n.replaceFromDevice(device.name)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReplace(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final pin = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.replaceWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.replaceWarningBody(device.name)),
            const SizedBox(height: 14),
            TextField(
              controller: pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.replacePinLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.replaceAction),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      pin.dispose();
      return;
    }
    try {
      await ref.read(syncServiceProvider).replaceFromPeer(device.id, pin.text);
      messenger.showSnackBar(SnackBar(content: Text(l10n.replaceDone)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.replaceFailed('$error'))));
    } finally {
      pin.dispose();
    }
  }

  Future<void> _explainKeepingPlan(BuildContext context) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.keepThisPlan),
        content: Text(l10n.keepThisPlanNote(device.name)),
        actions: [FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.close))],
      ),
    );
  }

  Future<void> _confirmUnpair(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unpairQuestion),
        content: Text(l10n.unpairBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.unpair)),
        ],
      ),
    );
    if (confirmed == true) await ref.read(syncServiceProvider).unpair(device.id);
  }
}

class _KnownDeviceCard extends StatelessWidget {
  const _KnownDeviceCard({required this.device});

  final SyncKnownDevice device;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.accentSoft,
              borderRadius: BorderRadius.circular(SundialRadii.xs),
            ),
            child: Icon(Icons.devices_other, size: 18, color: c.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.knownDeviceFingerprint(shortFingerprint(device.certificateFingerprint)),
                  style: SundialType.body(11, color: c.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PairDevicePage())),
            child: Text(l10n.pair),
          ),
        ],
      ),
    );
  }
}

class PairDevicePage extends ConsumerStatefulWidget {
  const PairDevicePage({super.key});

  @override
  ConsumerState<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends ConsumerState<PairDevicePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final identity = ref.watch(identityProvider).value;
    if (identity == null) {
      return SundialPage(
        title: l10n.pairDevice,
        child: Center(child: Text(l10n.identityRequired)),
      );
    }
    return _PairTabs();
  }
}

class _PairTabs extends StatefulWidget {
  const _PairTabs();

  @override
  State<_PairTabs> createState() => _PairTabsState();
}

class _PairTabsState extends State<_PairTabs> {
  bool _manual = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SundialPage(
      title: l10n.pairDevice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SundialSegmented<bool>(
              segments: [
                SundialSegment(value: false, label: l10n.nearbyDevices),
                SundialSegment(value: true, label: l10n.manualAddress),
              ],
              selected: _manual,
              onChanged: (value) => setState(() => _manual = value),
              compact: true,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: IndexedStack(
              index: _manual ? 1 : 0,
              children: const [_NearbyPairingTab(), _ManualPairingTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyPairingTab extends ConsumerStatefulWidget {
  const _NearbyPairingTab();

  @override
  ConsumerState<_NearbyPairingTab> createState() => _NearbyPairingTabState();
}

class _NearbyPairingTabState extends ConsumerState<_NearbyPairingTab> {
  DiscoveredPeer? _selected;
  bool _busy = false;
  bool _searching = true;
  Timer? _searchTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _armSearchTimer();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  /// mDNS has no "scan finished" event. Show the animation for a bounded time,
  /// then fall back to the no-results card while discovery keeps listening.
  void _armSearchTimer() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _searching = false);
    });
  }

  Future<void> _send() async {
    final peer = _selected;
    if (peer == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(syncServiceProvider)
          .requestPairing(host: peer.host, port: peer.port, displayName: peer.deviceName);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _error = null;
      _searching = true;
    });
    _armSearchTimer();
    await ref.read(syncServiceProvider).restart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final sync = ref.watch(syncServiceProvider);
    return ValueListenableBuilder<SyncState>(
      valueListenable: sync.state,
      builder: (context, state, _) {
        final pairing = state.pairing;
        if (pairing.lastPairedDeviceName != null) {
          return _PairingDoneCard(
            name: pairing.lastPairedDeviceName!,
            datasetMatches: pairing.lastPairedDatasetMatches,
            onDone: () {
              ref.read(syncServiceProvider).clearPairingResult();
              Navigator.of(context).pop();
            },
          );
        }
        if (pairing.outgoing != null) {
          return _PairingWaitCard(
            outgoing: pairing.outgoing!,
            onCancel: () => ref.read(syncServiceProvider).cancelOutgoingPairing(),
          );
        }
        if (pairing.error != null) {
          return _PairingErrorCard(
            message: pairingErrorText(context, pairing.error!),
            onDismiss: () => ref.read(syncServiceProvider).cancelOutgoingPairing(),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.nearbyDevices, style: SundialType.title(15, color: c.text)),
                ),
                IconButton(
                  onPressed: _searching ? null : _refresh,
                  tooltip: l10n.refreshDevices,
                  icon: _searching
                      ? SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: c.accent),
                        )
                      : const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (state.discovered.isEmpty)
              SoftCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  children: [
                    if (_searching && state.running && state.discoveryAvailable)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(strokeWidth: 2.8, color: c.accent),
                      )
                    else
                      Icon(Icons.wifi_find, size: 34, color: c.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      _searching && state.discoveryAvailable ? l10n.scanningDevices : l10n.noNearbyDevices,
                      textAlign: TextAlign.center,
                      style: SundialType.body(13, weight: FontWeight.w600, color: c.textSecondary),
                    ),
                    if (_searching && state.discoveryAvailable) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.searchingNearbyHint,
                        textAlign: TextAlign.center,
                        style: SundialType.body(11.5, color: c.textTertiary),
                      ),
                    ],
                    if (!state.discoveryAvailable) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.discoveryUnavailable,
                        textAlign: TextAlign.center,
                        style: SundialType.body(11.5, color: c.warning),
                      ),
                    ],
                  ],
                ),
              )
            else
              SoftCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                clip: true,
                child: Column(
                  children: [
                    for (var index = 0; index < state.discovered.length; index++) ...[
                      if (index > 0) const Divider(height: 1, indent: 54),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c.accentSoft,
                            borderRadius: BorderRadius.circular(SundialRadii.sm),
                          ),
                          child: Icon(Icons.devices_other, size: 19, color: c.accent),
                        ),
                        title: Text(state.discovered[index].deviceName),
                        subtitle: Text(state.discovered[index].host),
                        trailing: _selected?.fingerprint == state.discovered[index].fingerprint
                            ? Icon(Icons.check_circle, color: c.accent)
                            : null,
                        onTap: () => setState(() => _selected = state.discovered[index]),
                      ),
                    ],
                  ],
                ),
              ),
            if (_selected != null) ...[
              const SizedBox(height: 18),
              Text(l10n.pairWithDevice(_selected!.deviceName), style: SundialType.title(15, color: c.text)),
              const SizedBox(height: 6),
              Text(l10n.sendPairingRequestHint, style: SundialType.body(12, color: c.textSecondary)),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: SundialType.body(12, color: c.danger)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _busy ? null : _send,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.sendPairingRequest),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ManualPairingTab extends ConsumerStatefulWidget {
  const _ManualPairingTab();

  @override
  ConsumerState<_ManualPairingTab> createState() => _ManualPairingTabState();
}

class _ManualPairingTabState extends ConsumerState<_ManualPairingTab> {
  final _host = TextEditingController();
  final _port = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    if (host.isEmpty || port == null || port <= 0 || port > 65535) {
      setState(() => _error = context.l10n.invalidHostPort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(syncServiceProvider).requestPairing(host: host, port: port, displayName: host);
    } on Object catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final sync = ref.watch(syncServiceProvider);
    return ValueListenableBuilder<SyncState>(
      valueListenable: sync.state,
      builder: (context, state, _) {
        final pairing = state.pairing;
        if (pairing.lastPairedDeviceName != null) {
          return _PairingDoneCard(
            name: pairing.lastPairedDeviceName!,
            datasetMatches: pairing.lastPairedDatasetMatches,
            onDone: () {
              ref.read(syncServiceProvider).clearPairingResult();
              Navigator.of(context).pop();
            },
          );
        }
        if (pairing.outgoing != null) {
          return _PairingWaitCard(
            outgoing: pairing.outgoing!,
            onCancel: () => ref.read(syncServiceProvider).cancelOutgoingPairing(),
          );
        }
        if (pairing.error != null) {
          return _PairingErrorCard(
            message: pairingErrorText(context, pairing.error!),
            onDismiss: () => ref.read(syncServiceProvider).cancelOutgoingPairing(),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(l10n.manualAddressHint, style: SundialType.body(12, color: c.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _host,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l10n.address, hintText: l10n.hostHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.port, hintText: '44321'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _send(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: SundialType.body(12, color: c.danger)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _send,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.sendPairingRequest),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PairingWaitCard extends StatelessWidget {
  const _PairingWaitCard({required this.outgoing, required this.onCancel});

  final OutgoingPairingRequest outgoing;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        SoftCard(
          child: Column(
            children: [
              Icon(Icons.link, size: 42, color: c.accent),
              const SizedBox(height: 14),
              Text(l10n.pairingWith(outgoing.displayName), style: SundialType.title(17, color: c.text)),
              const SizedBox(height: 14),
              Text(l10n.pairingRequestCode, style: SundialType.label(11, color: c.textTertiary)),
              const SizedBox(height: 4),
              Text(
                outgoing.displayCode,
                style: SundialType.title(34, color: c.text).copyWith(letterSpacing: 5),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.pairingRequestCodeHint,
                textAlign: TextAlign.center,
                style: SundialType.body(12, color: c.textSecondary),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l10n.waitingForApproval(outgoing.displayName),
                      style: SundialType.body(13, color: c.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l10n.pairingExpires, style: SundialType.body(11.5, color: c.textTertiary)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onCancel, child: Text(l10n.cancel)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PairingDoneCard extends StatelessWidget {
  const _PairingDoneCard({required this.name, required this.datasetMatches, required this.onDone});

  final String name;
  final bool? datasetMatches;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        SoftCard(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 46, color: c.success),
              const SizedBox(height: 14),
              Text(l10n.pairingSucceeded(name), style: SundialType.title(17, color: c.text)),
              if (datasetMatches == false) ...[
                const SizedBox(height: 10),
                Text(
                  l10n.pairingPlanDifferent,
                  textAlign: TextAlign.center,
                  style: SundialType.body(12, color: c.warning),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(onPressed: onDone, child: Text(l10n.close)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PairingErrorCard extends StatelessWidget {
  const _PairingErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        SoftCard(
          child: Column(
            children: [
              Icon(Icons.link_off, size: 42, color: c.danger),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: SundialType.body(13, color: c.danger),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: onDismiss, child: Text(l10n.tryAgain)),
            ],
          ),
        ),
      ],
    );
  }
}

String pairingErrorText(BuildContext context, String error) {
  final l10n = context.l10n;
  switch (error) {
    case 'pairing_rejected':
      return l10n.pairingRequestRejected;
    case 'pairing_expired':
      return l10n.pairingRequestExpired;
    case 'pairing_failed':
    case 'pairing_already_completed':
      return l10n.pairingFailedGeneric;
    default:
      return error;
  }
}
