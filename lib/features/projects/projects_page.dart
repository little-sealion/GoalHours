import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:goalhours/features/projects/projects_ctrl.dart';
import 'package:goalhours/features/projects/widgets/progress_bar.dart';
import 'package:goalhours/utils/time_format.dart';
import 'package:goalhours/data/session_repo.dart';
import 'package:goalhours/features/timer/manual_entry_dialog.dart';
import 'package:goalhours/features/timer/timer_ctrl.dart';
import 'package:goalhours/features/timer/stopwatch_sheet.dart';
import 'package:goalhours/data/project_repo.dart';
import 'package:goalhours/monetization/premium_provider.dart';
import 'package:goalhours/monetization/ads.dart';

// Enable ads in debug/profile for testing with: --dart-define=SHOW_ADS_IN_DEBUG=true
const bool kShowAdsInDebug = bool.fromEnvironment('SHOW_ADS_IN_DEBUG', defaultValue: false);

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoalHours'),
        actions: [
          IconButton(
            tooltip: 'Archived',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => context.push('/archived'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer2<ProjectsController, PremiumController>(
          builder: (context, ctrl, premium, __) {
            final items = ctrl.items;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top banner ad (debug via SHOW_ADS_IN_DEBUG, or release). Hidden for premium users.
                if ((kReleaseMode || kShowAdsInDebug) && !premium.isPremium) ...[
                  Center(
                    child: BannerAdContainer(
                      unitId: Platform.isIOS && kReleaseMode
                          ? 'ca-app-pub-3438016031573205/5097401397'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'My Goals',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text('Projects will appear here', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else ...[
                  Expanded(
                    child: ReorderableListView.builder(
                      // Add bottom padding so the last row doesn't get covered by the FAB
                      padding: const EdgeInsets.only(bottom: 120),
                      itemCount: items.length,
                      onReorder: (oldIndex, newIndex) async {
                        // Adjust newIndex when moving down
                        if (newIndex > oldIndex) newIndex -= 1;
                        final reordered = List<ProjectWithProgress>.from(items);
                        final moved = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, moved);
                        // Persist order by ids
                        final ids = [for (final it in reordered) it.project.id];
                        await context.read<ProjectsController>().reorder(ids);
                      },
                      itemBuilder: (context, index) {
                        final it = items[index];
                        return Padding(
                          key: ValueKey('project-${it.project.id}'),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ProjectRow(
                            key: ValueKey('row-${it.project.id}'),
                            item: it,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Consumer3<ProjectsController, PremiumController, TimerController>(
        builder: (context, ctrl, premium, timer, _) {
          final atCap = !premium.isPremium && ctrl.items.length >= 3;
          final mq = MediaQuery.of(context);
          // Banner is at the top now; no extra bottom offset needed.
          final bottomOffset = 16.0 + mq.padding.bottom;

          String hms(Duration d) {
            final h = d.inHours.toString().padLeft(2, '0');
            final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
            final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
            return '$h:$m:$s';
          }

          return Padding(
            padding: EdgeInsets.only(bottom: bottomOffset, right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (timer.active != null) ...[
                  Builder(builder: (_) {
                    final start = timer.active!.startUtc.toLocal();
                    final elapsed = DateTime.now().difference(start);
                    return ActionChip(
                      label: Text('⏱ ${hms(elapsed)}  Stop'),
                      onPressed: () => context.read<TimerController>().stop(),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
                FloatingActionButton(
                  onPressed: atCap
                      ? () async {
                          await showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Limit reached'),
                              content: const Text('Free version allows up to 3 projects. Go Premium to create more.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                              ],
                            ),
                          );
                        }
                      : () => context.push('/edit'),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({super.key, required this.item});

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
    return InkWell(
      onTap: () => context.push('/project/${project.id}'),
      child: Row(
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
                final seconds = await showManualEntryDialogSeconds(context);
                if (seconds == null) return;
                await sessionRepo.addManualEntrySeconds(project.id, seconds);
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
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (value) async {
            if (value == 'edit') {
              if (context.mounted) context.push('/edit/${project.id}');
            } else if (value == 'archive') {
              final repo = context.read<ProjectRepo>();
              await repo.archive(project.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Archived "${project.name}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () async {
                      await repo.unarchive(project.id);
                    },
                  ),
                ),
              );
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'archive', child: Text('Archive')),
          ],
        ),
      ],
    ));
  }
}
