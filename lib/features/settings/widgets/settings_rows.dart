import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/ui_kit.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// A row that settings search can scroll to by [title].
abstract interface class SettingsTitledRow {
  String get title;
}

class SettingsSection extends StatefulWidget {
  const SettingsSection({super.key, required this.title, required this.children, this.highlight});

  final String title;
  final List<Widget> children;

  /// Row title to scroll to and briefly flash after the first frame. Set by
  /// settings search so a result lands on the exact row, not just the page.
  final String? highlight;

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  final _keys = <int, GlobalKey>{};
  Timer? _timer;
  int? _flashing;

  @override
  void initState() {
    super.initState();
    _scheduleHighlight();
  }

  @override
  void didUpdateWidget(SettingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlight != widget.highlight) _scheduleHighlight();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleHighlight() {
    final query = widget.highlight?.trim().toLowerCase();
    if (query == null || query.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var index = 0; index < widget.children.length; index++) {
        final child = widget.children[index];
        if (child is! SettingsTitledRow) continue;
        if (!(child as SettingsTitledRow).title.toLowerCase().contains(query)) continue;
        final context = _keys[index]?.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: 0.2,
          );
        }
        setState(() => _flashing = index);
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _flashing = null);
        });
        break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final rows = <Widget>[];
    for (var index = 0; index < widget.children.length; index++) {
      if (index > 0) rows.add(Divider(height: 1, indent: 58, color: c.border));
      final key = _keys[index] ??= GlobalKey(debugLabel: 'setting-row-$index');
      rows.add(
        AnimatedContainer(
          key: key,
          duration: const Duration(milliseconds: 180),
          color: _flashing == index ? c.accentSoft : Colors.transparent,
          child: widget.children[index],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(widget.title),
          SoftCard(
            padding: const EdgeInsets.symmetric(vertical: 2),
            clip: true,
            radius: 20,
            child: Column(children: rows),
          ),
        ],
      ),
    );
  }
}

class SettingsNavRow extends StatelessWidget implements SettingsTitledRow {
  const SettingsNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
  });

  final IconData icon;
  @override
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        child: Row(
          children: [
            _SettingsIcon(icon: icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ManeType.body(14, weight: FontWeight.w700, color: c.text),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ManeType.body(11.5, color: c.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(value!, style: ManeType.label(11.5, color: c.textTertiary)),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 19, color: c.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingsSwitchRow extends StatelessWidget implements SettingsTitledRow {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  @override
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: Row(
          children: [
            _SettingsIcon(icon: icon),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ManeType.body(14, weight: FontWeight.w700, color: c.text),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!, style: ManeType.body(11.5, color: c.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            TinySwitch(value: value, onChanged: onChanged, semanticLabel: title),
          ],
        ),
      ),
    );
  }
}

class SettingsChoiceRow extends StatelessWidget implements SettingsTitledRow {
  const SettingsChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.choice,
  });

  final IconData icon;
  @override
  final String title;
  final String? subtitle;
  final Widget choice;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SettingsIcon(icon: icon),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ManeType.body(14, weight: FontWeight.w700, color: c.text),
                    ),
                    if (subtitle != null) Text(subtitle!, style: ManeType.body(11.5, color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: choice),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 17, color: c.accent),
    );
  }
}
