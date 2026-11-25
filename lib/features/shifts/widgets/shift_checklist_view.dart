import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/sound/sound_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/shift_checklist.dart';
import '../../../state/providers.dart';

/// The checklist for one shift date. Completions are keyed by item and date,
/// so ticking an item on one shift never changes another shift's checklist.
class ShiftChecklistSection extends ConsumerStatefulWidget {
  const ShiftChecklistSection({
    super.key,
    required this.patternId,
    required this.date,
    required this.slotKey,
    this.dayIndex,
  });

  final String patternId;
  final LocalDate date;
  final String slotKey;

  /// Cycle day of the shift, so per-day checklist items can be filtered.
  final int? dayIndex;

  @override
  ConsumerState<ShiftChecklistSection> createState() => _ShiftChecklistSectionState();
}

class _ShiftChecklistSectionState extends ConsumerState<ShiftChecklistSection> {
  Future<Set<String>>? _doneFuture;

  @override
  void initState() {
    super.initState();
    _doneFuture = _loadDone();
  }

  @override
  void didUpdateWidget(covariant ShiftChecklistSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patternId != widget.patternId ||
        oldWidget.date != widget.date ||
        oldWidget.slotKey != widget.slotKey) {
      setState(() => _doneFuture = _loadDone());
    }
  }

  Future<Set<String>> _loadDone() {
    return ref
        .read(repositoryProvider)
        .readShiftChecklistCompletions(widget.patternId, widget.date, slotKey: widget.slotKey);
  }

  Future<void> _toggle(ShiftChecklistItem item, bool completed) async {
    try {
      await ref
          .read(repositoryProvider)
          .setShiftChecklistCompleted(item.id, widget.date, completed: completed, slotKey: widget.slotKey);
      if (!mounted) return;
      playUiSound(context, completed ? UiSound.check : UiSound.uncheck);
      setState(() => _doneFuture = _loadDone());
    } catch (error) {
      if (!mounted) return;
      playUiSound(context, UiSound.error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotSave('$error'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final items =
        (ref.watch(shiftChecklistItemsProvider(widget.patternId)).value ?? const <ShiftChecklistItem>[])
            .where((item) => item.dayIndex == null || item.dayIndex == widget.dayIndex)
            .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Set<String>>(
      future: _doneFuture,
      builder: (context, snapshot) {
        final done = snapshot.data ?? const <String>{};
        final completed = items.where((item) => done.contains(item.id)).length;

        return Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${context.l10n.shiftChecklist} · '
                '${context.l10n.checklistDone(completed, items.length)}',
                style: SundialType.label(10.5, color: c.textTertiary),
              ),
              for (final item in items)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: done.contains(item.id),
                  title: Text(item.label, style: SundialType.body(13, color: c.text)),
                  onChanged: (value) => _toggle(item, value == true),
                ),
            ],
          ),
        );
      },
    );
  }
}
