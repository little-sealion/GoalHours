import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:goalhours/features/projects/projects_ctrl.dart';
import 'package:goalhours/features/projects/widgets/progress_bar.dart';
import 'package:goalhours/utils/time_format.dart';
import 'package:goalhours/data/session_repo.dart';
import 'package:goalhours/features/timer/manual_entry_dialog.dart';
import 'package:goalhours/features/timer/timer_ctrl.dart';
import 'package:goalhours/features/timer/stopwatch_sheet.dart';

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
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          FloatingActionButton(
            onPressed: () => context.push('/edit'),
            child: const Icon(Icons.add),
          ),
          // Global timer chip when active
          Consumer<TimerController>(
            builder: (context, timer, _) {
              final active = timer.active;
              if (active == null) return const SizedBox.shrink();
              final start = active.startUtc.toLocal();
              final now = DateTime.now();
              final elapsed = now.difference(start);
              String mmss(Duration d) {
                final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                final h = d.inHours;
                return h > 0 ? '$h:$m:$s' : '$m:$s';
              }
              return Positioned(
                right: 80,
                bottom: 8,
                child: ActionChip(
                  label: Text('⏱ ${mmss(elapsed)}  Stop'),
                  onPressed: () => context.read<TimerController>().stop(),
                ),
              );
            },
          ),
        ],
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
    final timer = context.watch<TimerController>();
    final isActive = timer.active?.projectId == project.id;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left-side stacked actions: manual add (+) and clock start/stop
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              tooltip: 'Add manual time',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                final sessionRepo = context.read<SessionRepo>();
                final minutes = await showManualEntryDialog(context);
                if (minutes == null) return;
                await sessionRepo.addManualEntry(project.id, minutes);
              },
            ),
            IconButton(
              icon: const Icon(Icons.access_time, size: 20),
              tooltip: 'Clock session',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    final h = MediaQuery.of(ctx).size.height;
                    return SizedBox(
                      height: h * 0.8, // cover most of the screen
                      child: StopwatchSheet(
                        projectId: project.id,
                        projectName: project.name,
                        accent: Color(project.color),
                      ),
                    );
                  },
                );
              },
            ),
          ],
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
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Running',
                        style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]
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
