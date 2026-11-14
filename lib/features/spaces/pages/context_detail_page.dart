import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/mane_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../screens/entry_editor.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../entries/widgets/task_card.dart';
import '../../home_inventory/pages/home_inventory_page.dart';
import '../../home_inventory/pages/maintenance_page.dart';
import '../../home_inventory/pages/shopping_list_page.dart';
import '../../shifts/pages/shift_pattern_editor_page.dart';
import '../widgets/context_editor.dart';
import '../widgets/habit_widgets.dart';
import '../widgets/project_editor.dart';
import '../widgets/space_controls.dart';

class ContextDetailPage extends ConsumerWidget {
  const ContextDetailPage({super.key, required this.spaceId, required this.contextId});

  final String spaceId;
  final String contextId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final today = localDateAt(ref.watch(nowProvider), timeZone);
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final space = spaces.where((item) => item.id == spaceId).firstOrNull ?? fallbackSpaces.first;
    final contexts = ref.watch(contextsProvider(spaceId)).value ?? const <PlannerContext>[];
    final item = contexts.where((candidate) => candidate.id == contextId).firstOrNull;
    if (item == null) {
      return ManePage(title: l10n.context, child: const SizedBox.shrink());
    }

    final projects = ref.watch(contextProjectsProvider(contextId)).value ?? const <Project>[];
    final tasks = (ref.watch(openEntriesProvider(today)).value ?? const <Entry>[])
        .where((entry) => entry.spaceId == spaceId && entry.contextId == contextId)
        .toList();
    final isWork = spaceId == 'work';
    final isPersonal = spaceId == 'personal';
    final recommended = isWork
        ? ManeIcons.workRecommended
        : isPersonal
        ? ManeIcons.personalRecommended
        : ManeIcons.homeRecommended;
    final accents = Color(item.colorValue);

    return ManePage(
      title: item.name,
      subtitle: space.name,
      actions: [
        GlassIconButton(
          icon: Icons.edit_outlined,
          tooltip: isWork
              ? l10n.editJob
              : isPersonal
              ? l10n.editPerson
              : l10n.editHome,
          onTap: () => showContextEditor(
            context,
            spaceId: spaceId,
            existing: item,
            title: isWork
                ? l10n.editJob
                : isPersonal
                ? l10n.editPerson
                : l10n.editHome,
            recommendedIcons: recommended,
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          Row(
            children: [
              ContextAvatar(
                icon: item.icon,
                colorValue: item.colorValue,
                imagePath: item.imagePath,
                size: 72,
                radius: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description.isNotEmpty)
                      Text(item.description, style: ManeType.body(13, color: c.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill(text: l10n.taskCount(tasks.length), color: accents),
                        _Pill(text: l10n.projectCount(projects.length), color: accents),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => showEntryEditor(
              context,
              initialDate: today,
              initialSpaceId: spaceId,
              initialUnitId: contextId,
              spaces: spaces,
            ),
            icon: const Icon(Icons.add_task, size: 18),
            label: Text(l10n.addTaskFor(item.name)),
          ),
          if (isWork) ...[
            const SizedBox(height: 22),
            SectionLabel(l10n.shifts),
            const SizedBox(height: 8),
            _ShiftsSection(contextId: contextId),
            const SizedBox(height: 22),
            _ProjectsBlock(
              spaceId: spaceId,
              contexts: contexts,
              contextId: contextId,
              recommendedIcons: recommended,
            ),
          ],
          if (!isWork && !isPersonal) ...[
            const SizedBox(height: 22),
            SectionLabel(l10n.householdSection),
            const SizedBox(height: 8),
            _LinkRow(
              icon: Icons.inventory_2_outlined,
              title: l10n.homeInventory,
              subtitle: l10n.homeInventorySubtitle,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => HomeInventoryPage(contextId: contextId))),
            ),
            const SizedBox(height: 8),
            _LinkRow(
              icon: Icons.shopping_cart_outlined,
              title: l10n.shoppingList,
              subtitle: l10n.shoppingListSubtitle,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => ShoppingListPage(contextId: contextId))),
            ),
            const SizedBox(height: 8),
            _LinkRow(
              icon: Icons.build_outlined,
              title: l10n.gadgetsSection,
              subtitle: l10n.maintenanceSubtitle,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => MaintenancePage(contextId: contextId))),
            ),
            const SizedBox(height: 22),
            _ProjectsBlock(
              spaceId: spaceId,
              contexts: contexts,
              contextId: contextId,
              recommendedIcons: recommended,
            ),
          ],
          if (isPersonal) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: SectionLabel(l10n.habitsSection)),
                TextButton.icon(
                  onPressed: () =>
                      showHabitEditor(context, contextId: contextId, recommendedIcons: recommended),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addHabit),
                ),
              ],
            ),
            _HabitsSection(contextId: contextId, recommendedIcons: recommended),
            const SizedBox(height: 22),
            _ProjectsBlock(
              spaceId: spaceId,
              contexts: contexts,
              contextId: contextId,
              recommendedIcons: recommended,
            ),
          ],
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 22),
            SectionLabel(l10n.openTasks),
            const SizedBox(height: 8),
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(entry: task),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShiftsSection extends ConsumerWidget {
  const _ShiftsSection({required this.contextId});

  final String contextId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final patterns = (ref.watch(shiftPatternsProvider).value ?? const <ShiftPattern>[])
        .where((pattern) => pattern.contextId == contextId)
        .toList();
    final c = context.mc;
    if (patterns.isEmpty) {
      return _LinkRow(
        icon: Icons.schedule,
        title: l10n.newShiftPattern,
        subtitle: l10n.shiftPatternsSubtitle,
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => ShiftPatternEditorPage(contextId: contextId))),
      );
    }
    return Column(
      children: [
        for (final pattern in patterns)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LinkRow(
              icon: Icons.schedule,
              title: pattern.name,
              subtitle: '${l10n.cycleLengthValue(pattern.cycleDays)} · ${pattern.timeZone}',
              color: c.work,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => ShiftPatternEditorPage(pattern: pattern))),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => ShiftPatternEditorPage(contextId: contextId))),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.newShiftPattern),
          ),
        ),
      ],
    );
  }
}

class _ProjectsBlock extends StatelessWidget {
  const _ProjectsBlock({
    required this.spaceId,
    required this.contexts,
    required this.contextId,
    required this.recommendedIcons,
  });

  final String spaceId;
  final List<PlannerContext> contexts;
  final String contextId;
  final List<String> recommendedIcons;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(l10n.projectsSection)),
            TextButton.icon(
              onPressed: () => showProjectEditor(
                context,
                spaceId: spaceId,
                title: l10n.newProject,
                contextId: contextId,
                contexts: contexts,
                recommendedIcons: recommendedIcons,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addProject),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ProjectsSection(spaceId: spaceId, contextIds: contexts, projectContextId: contextId),
      ],
    );
  }
}

class _ProjectsSection extends ConsumerWidget {
  const _ProjectsSection({required this.spaceId, required this.contextIds, required this.projectContextId});

  final String spaceId;
  final List<PlannerContext> contextIds;
  final String projectContextId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final projects = ref.watch(contextProjectsProvider(projectContextId)).value ?? const <Project>[];
    if (projects.isEmpty) {
      return Text(l10n.noProjectsHint, style: ManeType.body(12, color: context.mc.textTertiary));
    }
    final isWork = spaceId == 'work';
    final isPersonal = spaceId == 'personal';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final project in projects)
          Pressable(
            onTap: () => showProjectEditor(
              context,
              spaceId: spaceId,
              title: l10n.editProject,
              project: project,
              contexts: contextIds,
              recommendedIcons: isWork
                  ? ManeIcons.workRecommended
                  : isPersonal
                  ? ManeIcons.personalRecommended
                  : ManeIcons.homeRecommended,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(9, 8, 13, 8),
              decoration: BoxDecoration(
                color: context.mc.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.mc.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ContextAvatar(
                    icon: project.icon,
                    colorValue: project.colorValue,
                    imagePath: project.imagePath,
                    size: 30,
                    radius: 9,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: ManeType.body(12.5, weight: FontWeight.w700, color: context.mc.text),
                      ),
                      if (project.description.isNotEmpty)
                        Text(
                          project.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ManeType.body(10.5, color: context.mc.textTertiary),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HabitsSection extends ConsumerWidget {
  const _HabitsSection({required this.contextId, required this.recommendedIcons});

  final String contextId;
  final List<String> recommendedIcons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = (ref.watch(habitsProvider('personal')).value ?? const <Habit>[])
        .where((habit) => habit.contextId == contextId)
        .toList();
    if (habits.isEmpty) {
      return Text(context.l10n.noTasksHint, style: ManeType.body(12, color: context.mc.textTertiary));
    }
    return Column(
      children: [
        for (final habit in habits)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: HabitCard(
              habit: habit,
              recommendedIcons: recommendedIcons,
              onEdit: () => showHabitEditor(
                context,
                habit: habit,
                contextId: habit.contextId,
                recommendedIcons: recommendedIcons,
              ),
            ),
          ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (color ?? c.accent).withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color ?? c.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ManeType.body(13.5, weight: FontWeight.w700, color: c.text),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ManeType.body(11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 19, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(text, style: ManeType.label(10.5, color: color)),
    );
  }
}
