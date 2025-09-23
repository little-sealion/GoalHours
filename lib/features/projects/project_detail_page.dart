import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:goalhours/data/project.dart';
import 'package:goalhours/data/project_repo.dart';
import 'package:goalhours/data/session.dart';
import 'package:goalhours/data/session_repo.dart';
import 'package:goalhours/features/projects/widgets/progress_bar.dart';
import 'package:goalhours/features/timer/manual_entry_dialog.dart';
import 'package:goalhours/features/timer/stopwatch_sheet.dart';
import 'package:goalhours/utils/time_format.dart';

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId});

  final int projectId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProjectRepo>();
    return FutureBuilder<Project?>(
      future: repo.get(projectId),
      builder: (context, snap) {
        final project = snap.data;
        if (project == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final color = Color(project.color);
        return _ProjectDetailScaffold(project: project, color: color);
      },
    );
  }
}

class _ProjectDetailScaffold extends StatelessWidget {
  const _ProjectDetailScaffold({required this.project, required this.color});

  final Project project;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sessionRepo = context.read<SessionRepo>();
    return StreamBuilder<List<Session>>(
      stream: sessionRepo.watchForProject(project.id).asStream().asyncExpand((s) => s),
      builder: (context, snap) {
        final sessions = snap.data ?? const <Session>[];
        final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
        final goal = project.goalMinutes;
        final fraction = goal > 0 ? totalMinutes / goal : 0.0;
        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              IconButton(
                tooltip: 'Add manual entry',
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () async {
                  final minutes = await showManualEntryDialog(context);
                  if (minutes == null) return;
                  await sessionRepo.addManualEntry(project.id, minutes);
                },
              ),
              IconButton(
                tooltip: 'Clock session',
                icon: const Icon(Icons.access_time),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) {
                      final h = MediaQuery.of(ctx).size.height;
                      return SizedBox(
                        height: h * 0.8,
                        child: StopwatchSheet(
                          projectId: project.id,
                          projectName: project.name,
                          accent: color,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Text(
                '${formatHoursMinutes(totalMinutes)} / ${formatHoursMinutes(goal)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              RoughProgressBar(fraction: fraction, color: color),
              const SizedBox(height: 16),
              Text('Sessions', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (sessions.isEmpty)
                Text('No sessions yet', style: Theme.of(context).textTheme.bodyMedium)
              else ...[
                ..._buildGroupedSessions(context, sessions, color, project.id),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedSessions(BuildContext context, List<Session> sessions, Color color, int projectId) {
    final now = DateTime.now();
    final items = <Widget>[];
    String? currentLabel;
    for (final s in sessions) {
      final startLocal = s.startUtc.toLocal();
      final label = _dateLabel(startLocal, now);
      if (label != currentLabel) {
        if (currentLabel != null) items.add(const SizedBox(height: 8));
        items.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ));
        currentLabel = label;
      }
      items.add(_SessionTile(session: s, color: color, projectId: projectId));
    }
    return items;
  }

  String _dateLabel(DateTime d, DateTime now) {
    final dateOnly = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy').format(d);
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.color, required this.projectId});

  final Session session;
  final Color color;
  final int projectId;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, HH:mm');
    final start = session.startUtc.toLocal();
    final end = session.endUtc?.toLocal();
    final duration = session.durationMinutes;
    final isManual = session.isManual;
    final leadingIcon = isManual ? Icons.edit : Icons.timer;
    final timeLabel = end == null
        ? df.format(start)
        : '${df.format(start)} – ${DateFormat('HH:mm').format(end)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Icon(leadingIcon, color: color),
      title: Text(formatHoursMinutes(duration)),
      subtitle: Text(timeLabel),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete',
        onPressed: () async {
          // Capture repo before awaiting to avoid using BuildContext across async gaps
          final repo = context.read<SessionRepo>();
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete session?'),
              content: const Text('This action cannot be undone.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
              ],
            ),
          );
          if (ok != true) return;
          await repo.delete(session.id);
        },
      ),
    );
  }
}
