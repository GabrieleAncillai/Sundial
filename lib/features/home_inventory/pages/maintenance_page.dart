import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sundial_core/sundial_core.dart';

import '../../../core/i18n/date_labels.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/icons/sundial_icons.dart';
import '../../../core/time/time_field.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../models/maintenance_log.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_typography.dart';
import '../home_scope.dart';
import '../maintenance_dates.dart';
import '../widgets/gadget_sheet.dart';
import '../widgets/maintenance_actions.dart';

/// Gadgets are maintenance entries whose next date starts from the last real
/// service. The page keeps overdue and upcoming gadgets in one list with a
/// service, reschedule and history action each.
class MaintenancePage extends ConsumerWidget {
  const MaintenancePage({super.key, this.contextId});

  final String? contextId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final today = localDateAt(ref.watch(nowProvider), timeZone);
    final gadgetsState = ref.watch(maintenanceEntriesProvider);
    final allGadgets = gadgetsState.value ?? const <Entry>[];
    final gadgets =
        [
          for (final gadget in allGadgets)
            if (contextId == null || gadget.contextId == contextId) gadget,
        ]..sort((a, b) {
          final aDate = a.date ?? today;
          final bDate = b.date ?? today;
          return aDate.compareTo(bDate);
        });
    final due = [
      for (final gadget in gadgets)
        if (!(gadget.date ?? today).isAfter(today)) gadget,
    ];
    final upcoming = [
      for (final gadget in gadgets)
        if ((gadget.date ?? today).isAfter(today)) gadget,
    ];

    return SundialPage(
      title: l10n.maintenance,
      subtitle: l10n.maintenanceSubtitle,
      floatingAction: gadgets.isEmpty
          ? null
          : SundialAddButton(tooltip: l10n.addGadget, onTap: () => _addGadget(context, ref, today)),
      child: gadgets.isEmpty
          ? ListView(
              children: [
                if (gadgetsState.hasError)
                  SundialNotice(text: l10n.couldNotLoadHome('${gadgetsState.error}')),
                AppEmptyState(
                  icon: Icons.build_circle_outlined,
                  title: l10n.gadgetsEmpty,
                  message: l10n.gadgetsEmptyBody,
                  action: FilledButton.tonalIcon(
                    onPressed: () => _addGadget(context, ref, today),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.addGadget),
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                if (gadgetsState.hasError)
                  SundialNotice(text: l10n.couldNotLoadHome('${gadgetsState.error}')),
                if (due.isNotEmpty) ...[
                  SectionLabel(l10n.maintenanceDue),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    clip: true,
                    child: Column(
                      children: [
                        for (var index = 0; index < due.length; index++) ...[
                          if (index > 0) const Divider(height: 1, indent: 52),
                          _GadgetRow(
                            gadget: due[index],
                            today: today,
                            overdue: (due[index].date ?? today).isBefore(today),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (upcoming.isNotEmpty) ...[
                  SectionLabel(l10n.maintenanceUpcoming),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    clip: true,
                    child: Column(
                      children: [
                        for (var index = 0; index < upcoming.length; index++) ...[
                          if (index > 0) const Divider(height: 1, indent: 52),
                          _GadgetRow(gadget: upcoming[index], today: today, overdue: false),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(l10n.maintenanceSubtitle, style: SundialType.body(12, color: c.textTertiary)),
                ),
              ],
            ),
    );
  }

  Future<void> _addGadget(BuildContext context, WidgetRef ref, LocalDate today) async {
    final homeId = await chooseHomeScope(context, ref, contextId: contextId);
    if (homeId == null || !context.mounted) return;
    await showGadgetEditor(context, homeId: homeId, today: today);
  }
}

class _GadgetRow extends ConsumerWidget {
  const _GadgetRow({required this.gadget, required this.today, required this.overdue});

  final Entry gadget;
  final LocalDate today;
  final bool overdue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final date = gadget.date ?? today;
    final days = date.differenceInDays(today);
    final dueLabel = days < 0
        ? l10n.gadgetOverdueBy(-days)
        : days == 0
        ? l10n.gadgetDueToday
        : l10n.gadgetDueIn(days);
    final interval = gadget.repeatAfterCompletionDays ?? 0;
    final logs = ref.watch(maintenanceLogsProvider(gadget.id)).value ?? const <MaintenanceLog>[];
    final lastServiced = logs.isNotEmpty
        ? l10n.gadgetLastServicedOn(formatShortDate(context, logs.first.performedOn.toDateTime()))
        : gadget.lastCompletedAt == null
        ? l10n.gadgetNeverServiced
        : l10n.gadgetLastServicedOn(formatShortDate(context, maintenanceServiceDate(gadget)!.toDateTime()));
    final time = gadget.allDay || gadget.startMinute == null
        ? l10n.gadgetNoTime
        : gadget.endMinute == null
        ? formatMinuteLabel(context, gadget.startMinute!)
        : l10n.gadgetTimeRange(
            formatMinuteLabel(context, gadget.startMinute!),
            formatMinuteLabel(context, gadget.endMinute!),
          );
    return InkWell(
      onTap: () => _edit(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: overdue ? c.dangerSoft : c.homeSoft,
                borderRadius: BorderRadius.circular(SundialRadii.sm),
              ),
              child: Icon(
                gadget.icon.isEmpty
                    ? (overdue ? Icons.warning_amber_outlined : Icons.build_outlined)
                    : SundialIcons.resolve(gadget.icon, fallback: Icons.build_outlined),
                size: 19,
                color: overdue ? c.danger : c.home,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gadget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(14, weight: FontWeight.w700, color: c.text),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$time · ${l10n.gadgetEveryDays(interval)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(11.5, color: c.textSecondary),
                    ),
                    Text(
                      '$lastServiced · $dueLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SundialType.body(11.5, color: overdue ? c.danger : c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.logService,
              icon: Icon(Icons.check_circle_outline, color: c.home),
              onPressed: () => showLogMaintenanceSheet(context, gadget: gadget, today: today),
            ),
            SundialMenuButton<String>(
              tooltip: l10n.moreActions,
              headerTitle: gadget.title,
              headerCaption: l10n.gadgetEveryDays(interval),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    await _edit(context, ref);
                  case 'reschedule':
                    await showRescheduleMaintenanceSheet(context, gadget: gadget, today: today);
                  case 'history':
                    await showServiceHistorySheet(context, gadget);
                  default:
                    await _delete(context, ref);
                }
              },
              actions: [
                SundialMenuAction(value: 'edit', label: l10n.edit, icon: Icons.edit_outlined),
                SundialMenuAction(
                  value: 'reschedule',
                  label: l10n.reschedule,
                  icon: Icons.event_repeat_rounded,
                ),
                SundialMenuAction(value: 'history', label: l10n.serviceHistory, icon: Icons.history_rounded),
                SundialMenuAction(
                  value: 'delete',
                  label: l10n.delete,
                  icon: Icons.delete_outline_rounded,
                  destructive: true,
                  dividerBefore: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final timeZone = ref.read(deviceTimeZoneProvider);
    final today = localDateAt(ref.read(nowProvider), timeZone);
    final homes = ref.read(contextsProvider('home')).value ?? const <PlannerContext>[];
    final homeId = gadget.contextId ?? (homes.isEmpty ? null : homes.first.id);
    if (homeId == null) return;
    final logs = ref.read(maintenanceLogsProvider(gadget.id)).value ?? const <MaintenanceLog>[];
    await showGadgetEditor(
      context,
      homeId: homeId,
      today: today,
      gadget: gadget,
      lastServiced: logs.isEmpty ? null : logs.first.performedOn,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteEntryQuestion),
        content: Text(l10n.deleteEntryBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).deleteEntry(gadget.id);
    await ref.read(reminderCoordinatorProvider).reschedule();
  }
}
