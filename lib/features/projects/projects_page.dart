import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:goalhours/features/projects/projects_ctrl.dart';
import 'package:goalhours/features/projects/widgets/progress_bar.dart';
import 'package:goalhours/utils/time_format.dart';
import 'package:goalhours/data/session_repo.dart';
import 'package:goalhours/features/timer/manual_entry_dialog.dart';

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GoalHours')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<ProjectsController>(
          builder: (context, ctrl, _) {
            final items = ctrl.items;
            return ListView(
              children: [
                Text(
                  'My Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Projects will appear here', style: Theme.of(context).textTheme.bodyMedium),
                ] else ...[
                  for (final it in items) ...[
                    _ProjectRow(item: it),
                    const SizedBox(height: 16),
                  ]
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/edit'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.item});

  final ProjectWithProgress item;

  @override
  Widget build(BuildContext context) {
    final project = item.project;
    final total = item.totalMinutes;
    final goal = item.goalMinutes;
    final fraction = goal > 0 ? total / goal : 0.0;
    final color = Color(project.color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Add time manually icon (placeholder action)
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            final minutes = await showManualEntryDialog(context);
            if (minutes == null) return;
            final sessionRepo = context.read<SessionRepo>();
            await sessionRepo.addManualEntry(project.id, minutes);
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(project.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    formatHoursMinutes(total),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    ' / ${formatHoursMinutes(goal)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              RoughProgressBar(
                fraction: fraction,
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
