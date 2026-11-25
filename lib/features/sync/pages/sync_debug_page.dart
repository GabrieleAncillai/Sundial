import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../sync_clock.dart';
import '../sync_debug_models.dart';

/// Read-only diagnostics for the field-level HLC merge system.
///
/// The page is reached from Settings → Developer and is gated by the
/// device-local `developerOptionsEnabled` preference. It never writes to the
/// change feed or to any replica row.
class SyncDebugPage extends ConsumerStatefulWidget {
  const SyncDebugPage({super.key});

  @override
  ConsumerState<SyncDebugPage> createState() => _SyncDebugPageState();
}

enum _SyncDebugView { changes, fields, tombstones, peers }

class _SyncDebugPageState extends ConsumerState<SyncDebugPage> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  _SyncDebugView _view = _SyncDebugView.changes;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(syncDebugSnapshotProvider);

    return SundialPage(
      title: l10n.syncDebugTitle,
      subtitle: l10n.syncDebugSubtitle,
      actions: [
        GlassIconButton(
          icon: Icons.refresh,
          tooltip: l10n.syncDebugRefresh,
          onTap: () => ref.invalidate(syncDebugSnapshotProvider),
        ),
        GlassIconButton(
          icon: Icons.copy_all_outlined,
          tooltip: l10n.syncDebugCopy,
          onTap: () async {
            final snapshot = ref.read(syncDebugSnapshotProvider).value;
            if (snapshot != null) await _copySnapshot(snapshot);
          },
        ),
      ],
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SundialNotice(text: '$error'),
          ),
        ),
        data: _body,
      ),
    );
  }

  Widget _body(SyncDebugSnapshot snapshot) {
    final l10n = context.l10n;
    final query = _query.trim().toLowerCase();
    final (items, shown, total) = _items(snapshot, query);

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        _DeviceCard(device: snapshot.device, counts: snapshot.counts),
        const SizedBox(height: 12),
        SoftCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: context.mc.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.syncDebugExplainer,
                  style: SundialType.body(12, color: context.mc.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SundialSegmented<_SyncDebugView>(
            segments: [
              SundialSegment(value: _SyncDebugView.changes, label: l10n.syncDebugChanges),
              SundialSegment(value: _SyncDebugView.fields, label: l10n.syncDebugFields),
              SundialSegment(value: _SyncDebugView.tombstones, label: l10n.syncDebugTombstones),
              SundialSegment(value: _SyncDebugView.peers, label: l10n.syncDebugPeers),
            ],
            selected: _view,
            onChanged: (value) {
              setState(() => _view = value);
              if (_scroll.hasClients) _scroll.jumpTo(0);
            },
            compact: true,
          ),
        ),
        const SizedBox(height: 12),
        if (_view != _SyncDebugView.peers) ...[
          SundialSearchField(
            controller: _search,
            hint: l10n.syncDebugFilter,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
        ],
        ...items,
        if (shown > 0 || total > 0) ...[
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.syncDebugShowing(shown, total),
              style: SundialType.body(11, color: context.mc.textTertiary),
            ),
          ),
        ],
      ],
    );
  }

  (List<Widget>, int, int) _items(SyncDebugSnapshot snapshot, String query) {
    final l10n = context.l10n;
    switch (_view) {
      case _SyncDebugView.changes:
        final visible = [
          for (final change in snapshot.changes)
            if (_matches(query, [
              change.entity,
              change.rowKey,
              change.op,
              ...change.versions.keys,
              change.rowJson,
            ]))
              change,
        ];
        if (visible.isEmpty) {
          return (
            [_empty(snapshot.changes.isEmpty ? l10n.syncDebugNoChanges : l10n.syncDebugNoMatches)],
            0,
            snapshot.counts.changes,
          );
        }
        return (
          [for (final change in visible) _ChangeTile(change: change)],
          visible.length,
          query.isEmpty ? snapshot.counts.changes : snapshot.changes.length,
        );
      case _SyncDebugView.fields:
        final visible = [
          for (final field in snapshot.fields)
            if (_matches(query, [field.entity, field.rowKey, field.field, field.version])) field,
        ];
        if (visible.isEmpty) {
          return (
            [_empty(snapshot.fields.isEmpty ? l10n.syncDebugNoFields : l10n.syncDebugNoMatches)],
            0,
            snapshot.counts.fieldVersions,
          );
        }
        final groups = <String, List<SyncDebugFieldVersion>>{};
        for (final field in visible) {
          (groups['${field.entity}\u0000${field.rowKey}'] ??= []).add(field);
        }
        return (
          [for (final group in groups.values) _FieldGroupCard(fields: group)],
          visible.length,
          query.isEmpty ? snapshot.counts.fieldVersions : snapshot.fields.length,
        );
      case _SyncDebugView.tombstones:
        final visible = [
          for (final tombstone in snapshot.tombstones)
            if (_matches(query, [tombstone.entity, tombstone.rowKey, tombstone.version, tombstone.rowJson]))
              tombstone,
        ];
        if (visible.isEmpty) {
          return (
            [_empty(snapshot.tombstones.isEmpty ? l10n.syncDebugNoTombstones : l10n.syncDebugNoMatches)],
            0,
            snapshot.counts.tombstones,
          );
        }
        return (
          [for (final tombstone in visible) _TombstoneCard(tombstone: tombstone)],
          visible.length,
          query.isEmpty ? snapshot.counts.tombstones : snapshot.tombstones.length,
        );
      case _SyncDebugView.peers:
        if (snapshot.peers.isEmpty) return ([_empty(l10n.syncDebugNoPeers)], 0, 0);
        return (
          [for (final peer in snapshot.peers) _PeerCard(peer: peer)],
          snapshot.peers.length,
          snapshot.peers.length,
        );
    }
  }

  Widget _empty(String message) => SoftCard(
    padding: EdgeInsets.zero,
    child: AppEmptyState(icon: Icons.inbox_outlined, title: message, compact: true),
  );

  bool _matches(String query, Iterable<String> values) {
    if (query.isEmpty) return true;
    for (final value in values) {
      if (value.toLowerCase().contains(query)) return true;
    }
    return false;
  }

  Future<void> _copySnapshot(SyncDebugSnapshot snapshot) async {
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(snapshot.toJson())),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.syncDebugCopied)));
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device, required this.counts});

  final SyncDebugDevice device;
  final SyncDebugCounts counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final clock = DateTime.fromMillisecondsSinceEpoch(device.hlcMillis, isUtc: true);
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync, size: 21, color: c.accent),
              const SizedBox(width: 10),
              Text(l10n.syncDebugLocalState, style: SundialType.title(15, color: c.text)),
            ],
          ),
          const SizedBox(height: 10),
          _MetaLine(label: l10n.syncDebugNode, value: device.nodeId),
          _MetaLine(label: l10n.syncDebugDataset, value: device.datasetId),
          _MetaLine(label: l10n.syncDebugEpoch, value: device.epoch),
          _MetaLine(label: l10n.syncDebugClock, value: '${_stamp(clock)} · #${device.hlcCounter}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 22,
            runSpacing: 12,
            children: [
              _Count(value: counts.changes, label: l10n.syncDebugChanges),
              _Count(value: counts.fieldVersions, label: l10n.syncDebugFieldVersions),
              _Count(value: counts.tombstones, label: l10n.syncDebugTombstones),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: SundialType.label(11, color: c.textTertiary)),
          ),
          Expanded(child: SelectableText(value, style: _mono(c, 11))),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: SundialType.headline(20, color: c.text)),
        Text(label, style: SundialType.body(10.5, color: c.textTertiary)),
      ],
    );
  }
}

class _ChangeTile extends StatefulWidget {
  const _ChangeTile({required this.change});

  final SyncDebugChange change;

  @override
  State<_ChangeTile> createState() => _ChangeTileState();
}

class _ChangeTileState extends State<_ChangeTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    final change = widget.change;
    final fields = change.fieldVersions;
    final subtitle = change.isDelete
        ? '${l10n.syncDebugDelete} · ${_stamp(change.createdAt)}'
        : '${l10n.syncDebugUpsert} · ${_stamp(change.createdAt)}'
              ' · ${l10n.syncDebugFieldsChanged(fields.length)}';

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        children: [
          Pressable(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
              child: Row(
                children: [
                  _OpBadge(isDelete: change.isDelete),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${change.entity} · ${_shortId(change.rowKey, 22)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SundialType.body(13.5, weight: FontWeight.w700, color: c.text),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SundialType.body(11, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more, size: 19, color: c.textTertiary),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._versions(l10n),
                  const SizedBox(height: 12),
                  Text(l10n.syncDebugRowPayload, style: SundialType.label(11, color: c.textTertiary)),
                  const SizedBox(height: 5),
                  _JsonBox(text: change.rowJson),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.syncDebugUpdated}: ${_stamp(change.createdAt)}',
                          style: SundialType.body(10.5, color: c.textTertiary),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _copy,
                        icon: const Icon(Icons.copy_outlined, size: 16),
                        label: Text(l10n.syncDebugCopyChange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _versions(AppLocalizations l10n) {
    final change = widget.change;
    if (change.isDelete) {
      final version = change.deletedVersion;
      if (version == null) return const [];
      return [_VersionBlock(label: l10n.syncDebugTombstone, version: version)];
    }
    final entries = change.fieldVersions.entries.toList();
    return [
      for (var index = 0; index < entries.length; index++) ...[
        _VersionBlock(label: entries[index].key, version: entries[index].value),
        if (index < entries.length - 1) const SizedBox(height: 10),
      ],
    ];
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(widget.change.toJson())),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.syncDebugCopiedChange)));
  }
}

class _OpBadge extends StatelessWidget {
  const _OpBadge({required this.isDelete});

  final bool isDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isDelete ? c.dangerSoft : c.successSoft,
        borderRadius: BorderRadius.circular(SundialRadii.xs),
      ),
      child: Icon(
        isDelete ? Icons.delete_outline : Icons.arrow_upward,
        size: 17,
        color: isDelete ? c.danger : c.success,
      ),
    );
  }
}

class _VersionBlock extends StatelessWidget {
  const _VersionBlock({required this.label, required this.version});

  final String label;
  final String version;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SundialType.label(12, color: c.text)),
        const SizedBox(height: 2),
        Text(_hlcCompact(version), style: SundialType.body(11, color: c.textSecondary)),
        const SizedBox(height: 2),
        SelectableText(version, style: _mono(c, 10, color: c.textTertiary)),
      ],
    );
  }
}

class _JsonBox extends StatelessWidget {
  const _JsonBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final pretty = _prettyJson(text);
    final clipped = pretty.length > 3200 ? '${pretty.substring(0, 3200)}\n…' : pretty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(SundialRadii.sm),
        border: Border.all(color: c.border),
      ),
      child: SelectableText(clipped, style: _mono(c, 10.5, color: c.textSecondary)),
    );
  }
}

class _FieldGroupCard extends StatelessWidget {
  const _FieldGroupCard({required this.fields});

  final List<SyncDebugFieldVersion> fields;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final first = fields.first;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${first.entity} · ${_shortId(first.rowKey, 22)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SundialType.body(13.5, weight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < fields.length; index++) ...[
            if (index > 0) Divider(height: 16, color: c.border),
            _FieldLine(field: fields[index]),
          ],
        ],
      ),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({required this.field});

  final SyncDebugFieldVersion field;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(field.field, style: SundialType.label(12.5, color: c.text)),
            ),
            Text(_stamp(field.updatedAt), style: SundialType.body(10, color: c.textTertiary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(_hlcCompact(field.version), style: SundialType.body(10.5, color: c.textSecondary)),
        SelectableText(field.version, style: _mono(c, 10, color: c.textTertiary)),
      ],
    );
  }
}

class _TombstoneCard extends StatelessWidget {
  const _TombstoneCard({required this.tombstone});

  final SyncDebugTombstone tombstone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _OpBadge(isDelete: true),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tombstone.entity} · ${_shortId(tombstone.rowKey, 22)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(13.5, weight: FontWeight.w700, color: c.text),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${l10n.syncDebugUpdated}: ${_stamp(tombstone.updatedAt)}',
                      style: SundialType.body(11, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _VersionBlock(label: l10n.syncDebugTombstone, version: tombstone.version),
        ],
      ),
    );
  }
}

class _PeerCard extends StatelessWidget {
  const _PeerCard({required this.peer});

  final SyncDebugPeer peer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.mc;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_other_outlined, size: 20, color: c.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  peer.peerDeviceId,
                  style: SundialType.body(13.5, weight: FontWeight.w700, color: c.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MetaLine(
            label: l10n.syncDebugDataset,
            value: peer.datasetId.isEmpty ? l10n.notSet : peer.datasetId,
          ),
          _MetaLine(label: l10n.syncDebugEpoch, value: peer.peerEpoch.isEmpty ? l10n.notSet : peer.peerEpoch),
          _MetaLine(label: l10n.syncDebugCursor, value: '${peer.lastPulledSeq}'),
          _MetaLine(
            label: l10n.syncDebugLastSynced,
            value: peer.lastSyncedAt == null ? l10n.neverReached : _stamp(peer.lastSyncedAt!),
          ),
          if (peer.lastError != null) ...[
            const SizedBox(height: 10),
            SundialNotice(text: '${l10n.syncDebugPeerError}: ${peer.lastError}', icon: Icons.error_outline),
          ],
        ],
      ),
    );
  }
}

String _stamp(DateTime value) => _stampFormat.format(value.toLocal());

String _hlcCompact(String raw) {
  final hlc = SyncHlc.tryParse(raw);
  if (hlc == null) return raw;
  final at = DateTime.fromMillisecondsSinceEpoch(hlc.millis, isUtc: true);
  return '${_stamp(at)} · #${hlc.counter} · ${_shortId(hlc.nodeId)}';
}

String _shortId(String value, [int keep = 8]) =>
    value.length <= keep ? value : '${value.substring(0, keep)}…';

String _prettyJson(String raw) {
  if (raw.isEmpty) return '{}';
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
  } on FormatException {
    return raw;
  }
}

TextStyle _mono(SundialColors c, double size, {Color? color}) => SundialType.body(
  size,
  color: color ?? c.text,
).copyWith(fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 0.2);

final _stampFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS', 'en');
