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
import 'package:goalhours/monetization/ads.dart';
import 'package:goalhours/monetization/premium_provider.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'dart:io' show Platform;
import 'projects_page.dart' show kShowAdsInDebug; // reuse the debug flag

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key, required this.projectId, this.readOnly = false});

  final int projectId;
  final bool readOnly;

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
        return _ProjectDetailScaffold(project: project, color: color, readOnly: readOnly);
      },
    );
  }
}

class _ProjectDetailScaffold extends StatelessWidget {
  const _ProjectDetailScaffold({required this.project, required this.color, required this.readOnly});

  final Project project;
  final Color color;
  final bool readOnly;

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
              if (!readOnly) ...[
                IconButton(
                  tooltip: 'Add manual entry',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    final seconds = await showManualEntryDialogSeconds(context);
                    if (seconds == null) return;
                    await sessionRepo.addManualEntrySeconds(project.id, seconds);
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
            ],
          ),
          body: Consumer<PremiumController>(
            builder: (context, premium, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                ..._buildGroupedSessions(context, sessions, color, project.id, readOnly: readOnly),
              ],
            ],
          ),
        ),
      );
      },
    );
  }

  List<Widget> _buildGroupedSessions(BuildContext context, List<Session> sessions, Color color, int projectId, {required bool readOnly}) {
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
      items.add(_SessionTile(session: s, color: color, projectId: projectId, readOnly: readOnly));
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
  const _SessionTile({required this.session, required this.color, required this.projectId, required this.readOnly});

  final Session session;
  final Color color;
  final int projectId;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, HH:mm');
    final start = session.startUtc.toLocal();
    final end = session.endUtc?.toLocal();
  final durationSec = session.durationSeconds;
    final isManual = session.isManual;
    final leadingIcon = isManual ? Icons.edit : Icons.timer;
    final timeLabel = end == null
        ? df.format(start)
        : '${df.format(start)} – ${DateFormat('HH:mm').format(end)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Icon(leadingIcon, color: color),
      title: Text(formatHmsFromSeconds(durationSec)),
      subtitle: Text(timeLabel),
      trailing: readOnly
          ? null
          : Wrap(
        spacing: 4,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _editSession(context, session),
          ),
          IconButton(
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
        ],
      ),
    );
  }
}

Future<void> _editSession(BuildContext context, Session orig) async {
  // Only allow editing duration; compute new end = start + duration.
  final currentSec = orig.durationSeconds;
  final hhCtrl = TextEditingController(text: (currentSec ~/ 3600).toString());
  final mmCtrl = TextEditingController(text: ((currentSec % 3600) ~/ 60).toString().padLeft(2, '0'));
  final ssCtrl = TextEditingController(text: (currentSec % 60).toString().padLeft(2, '0'));

  final formKey = GlobalKey<FormState>();

  int? parseDurationSeconds() {
    final h = int.tryParse(hhCtrl.text.trim()) ?? 0;
    final m = int.tryParse(mmCtrl.text.trim()) ?? 0;
    final s = int.tryParse(ssCtrl.text.trim()) ?? 0;
    if (h < 0 || m < 0 || s < 0 || m > 59 || s > 59) return null;
    final total = h * 3600 + m * 60 + s;
    return total > 0 ? total : null;
  }

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Edit duration'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  child: TextFormField(
                    controller: hhCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'HH'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 0) return '>=0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: TextFormField(
                    controller: mmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'MM'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 0 || n > 59) return '0-59';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 64,
                  child: TextFormField(
                    controller: ssCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SS'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v);
                      if (n == null || n < 0 || n > 59) return '0-59';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final secs = parseDurationSeconds();
              if (secs == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Enter a valid duration > 0')));
                return;
              }
              final newEnd = orig.startUtc.add(Duration(seconds: secs));
              // Overlap check (excluding this session), block if any.
              final repo = context.read<SessionRepo>();
              final conflicts = await repo.findOverlaps(
                projectId: orig.projectId,
                excludeId: orig.id,
                startUtc: orig.startUtc,
                endUtc: newEnd,
              );
              if (conflicts.isNotEmpty) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Duration conflicts with another session. Adjust duration.')),
                );
                return;
              }
              final updated = Session()
                ..id = orig.id
                ..projectId = orig.projectId
                ..startUtc = orig.startUtc
                ..endUtc = newEnd
                ..isManual = orig.isManual
                ..manualDurationMinutes = orig.isManual ? secs ~/ 60 : null
                ..manualDurationSeconds = orig.isManual ? secs : null
                ..note = orig.note
                ..createdAtUtc = orig.createdAtUtc;

              try {
                await repo.update(updated);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
