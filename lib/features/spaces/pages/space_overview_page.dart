import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mane_core/mane_core.dart';

import '../../../core/i18n/l10n.dart';
import '../../../core/icons/mane_icons.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../../state/providers.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../entries/widgets/task_card.dart';
import '../../home_inventory/pages/home_inventory_page.dart';
import '../../home_inventory/pages/maintenance_page.dart';
import '../../home_inventory/pages/shopping_list_page.dart';
import '../widgets/context_editor.dart';
import '../widgets/habit_widgets.dart';
import '../widgets/project_editor.dart';
import '../widgets/space_controls.dart';
import 'context_detail_page.dart';

class SpaceOverviewPage extends ConsumerWidget {
  const SpaceOverviewPage({super.key, required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.mc;
    final timeZone = ref.watch(deviceTimeZoneProvider);
    final today = localDateAt(ref.watch(nowProvider), timeZone);
    final spaces = ref.watch(spacesProvider).value ?? fallbackSpaces;
    final space = spaces.where((item) => item.id == spaceId).firstOrNull ?? fallbackSpaces.first;
    final contexts = ref.watch(contextsProvider(spaceId)).value ?? const <PlannerContext>[];
    final projects = ref.watch(projectsProvider(spaceId)).value ?? const <Project>[];
    final habits = ref.watch(habitsProvider(spaceId)).value ?? const <Habit>[];
    final tasks = (ref.watch(openEntriesProvider(today)).value ?? const <Entry>[])
        .where((entry) => entry.spaceId == spaceId)
        .toList();
    final isPersonal = spaceId == 'personal';
    final isWork = spaceId == 'work';
    final title = isWork
        ? l10n.jobs
        : isPersonal
        ? l10n.peopleAndGroups
        : l10n.homes;
    final subtitle = isWork
        ? l10n.jobSummary
        : isPersonal
        ? l10n.personalSummary
        : l10n.homeSummary;
    final addTitle = isWork
        ? l10n.newJob
        : isPersonal
        ? l10n.newPerson
        : l10n.newHome;
    final recommended = isWork
        ? ManeIcons.workRecommended
        : isPersonal
        ? ManeIcons.personalRecommended
        : ManeIcons.homeRecommended;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(space.colorValue).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isWork
                    ? Icons.work_outline
                    : isPersonal
                    ? Icons.people_outline
                    : Icons.home_outlined,
                color: Color(space.colorValue),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: ManeType.headline(26, color: c.text)),
                  Text(subtitle, style: ManeType.body(12.5, color: c.textSecondary)),
                ],
              ),
            ),
            GlassIconButton(
              icon: Icons.add,
              tooltip: addTitle,
              onTap: () => showContextEditor(
                context,
                spaceId: spaceId,
                title: addTitle,
                recommendedIcons: recommended,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CountPill(icon: Icons.widgets_outlined, label: l10n.taskCount(tasks.length)),
            _CountPill(icon: Icons.folder_outlined, label: l10n.projectCount(projects.length)),
            if (isPersonal) _CountPill(icon: Icons.repeat, label: l10n.habitCount(habits.length)),
          ],
        ),
        const SizedBox(height: 18),
        if (contexts.isEmpty)
          SoftCard(
            padding: EdgeInsets.zero,
            child: AppEmptyState(
              icon: isWork
                  ? Icons.work_outline
                  : isPersonal
                  ? Icons.people_outline
                  : Icons.home_outlined,
              title: isWork
                  ? l10n.noJobs
                  : isPersonal
                  ? l10n.noPeople
                  : l10n.noHomes,
              message: isWork
                  ? l10n.noJobsHint
                  : isPersonal
                  ? l10n.noPeopleHint
                  : l10n.noHomesHint,
              action: FilledButton.tonalIcon(
                onPressed: () => showContextEditor(
                  context,
                  spaceId: spaceId,
                  title: addTitle,
                  recommendedIcons: recommended,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addFirstContext),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 980
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final item in contexts)
                    SizedBox(
                      width: width,
                      child: _ContextCard(
                        item: item,
                        taskCount: tasks.where((task) => task.contextId == item.id).length,
                        projectCount: projects.where((project) => project.contextId == item.id).length,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ContextDetailPage(spaceId: spaceId, contextId: item.id),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: SectionLabel(l10n.projectsSection)),
            TextButton.icon(
              onPressed: () => showProjectEditor(
                context,
                spaceId: spaceId,
                title: l10n.newProject,
                contexts: contexts,
                recommendedIcons: recommended,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addProject),
            ),
          ],
        ),
        if (projects.isEmpty)
          Text(l10n.noProjectsHint, style: ManeType.body(12, color: c.textTertiary))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final project in projects)
                _ProjectChip(
                  project: project,
                  onTap: () => showProjectEditor(
                    context,
                    spaceId: spaceId,
                    title: l10n.editProject,
                    project: project,
                    contexts: contexts,
                    recommendedIcons: recommended,
                  ),
                ),
            ],
          ),
        if (tasks.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionLabel(l10n.openTasks),
          const SizedBox(height: 8),
          for (final task in tasks.take(6))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskCard(entry: task, compact: true),
            ),
        ],
        if (isPersonal) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: SectionLabel(l10n.habitsSection)),
              TextButton.icon(
                onPressed: () => showHabitEditor(context, recommendedIcons: recommended),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addHabit),
              ),
            ],
          ),
          if (habits.isEmpty)
            Text(l10n.noHabitsHint, style: ManeType.body(12, color: c.textTertiary))
          else
            for (final habit in habits)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HabitCard(
                  habit: habit,
                  recommendedIcons: recommended,
                  onEdit: () => showHabitEditor(
                    context,
                    habit: habit,
                    contextId: habit.contextId,
                    recommendedIcons: recommended,
                  ),
                ),
              ),
        ],
        if (!isWork && !isPersonal) ...[
          const SizedBox(height: 22),
          SectionLabel(l10n.householdSection),
          const SizedBox(height: 8),
          _QuickLink(
            icon: Icons.inventory_2_outlined,
            title: l10n.homeInventory,
            subtitle: l10n.homeInventorySubtitle,
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const HomeInventoryPage())),
          ),
          const SizedBox(height: 8),
          _QuickLink(
            icon: Icons.shopping_cart_outlined,
            title: l10n.shoppingList,
            subtitle: l10n.shoppingListSubtitle,
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ShoppingListPage())),
          ),
          const SizedBox(height: 8),
          _QuickLink(
            icon: Icons.build_outlined,
            title: l10n.gadgetsSection,
            subtitle: l10n.maintenanceSubtitle,
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MaintenancePage())),
          ),
        ],
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: ManeType.label(10.5, color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.item,
    required this.taskCount,
    required this.projectCount,
    required this.onTap,
  });

  final PlannerContext item;
  final int taskCount;
  final int projectCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final accent = Color(item.colorValue);
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.13), c.surface],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ContextAvatar(
                  icon: item.icon,
                  colorValue: item.colorValue,
                  imagePath: item.imagePath,
                  size: 48,
                  radius: 15,
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: accent),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ManeType.title(16, color: c.text),
            ),
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ManeType.body(11.5, color: c.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              '${context.l10n.taskCount(taskCount)} · ${context.l10n.projectCount(projectCount)}',
              style: ManeType.label(9.5, color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
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
            Text(
              project.name,
              style: ManeType.body(12.5, weight: FontWeight.w700, color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 19, color: c.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ManeType.body(13, weight: FontWeight.w700, color: c.text),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ManeType.body(10.5, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}
