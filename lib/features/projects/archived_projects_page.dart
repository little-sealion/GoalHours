import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goalhours/data/project.dart';
import 'package:goalhours/data/project_repo.dart';
import 'package:goalhours/utils/time_format.dart';
import 'package:goalhours/features/projects/project_detail_page.dart';

class ArchivedProjectsPage extends StatelessWidget {
  const ArchivedProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ProjectRepo>();
    return FutureBuilder<Stream<List<Project>>>(
      future: repo.watchArchived(),
      builder: (context, snap) {
        final stream = snap.data;
        if (stream == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return StreamBuilder<List<Project>>(
          stream: stream,
          builder: (context, snap2) {
            final items = snap2.data ?? const <Project>[];
            return Scaffold(
              appBar: AppBar(title: const Text('Archived')),
              body: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = items[i];
                  return _ArchivedRow(project: p);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(project.name),
      subtitle: Text('Goal: ${formatHoursMinutes(project.goalMinutes)}'),
      trailing: TextButton.icon(
        onPressed: () async {
          await context.read<ProjectRepo>().unarchive(project.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unarchived "${project.name}"')),
          );
        },
        icon: const Icon(Icons.unarchive_outlined),
        label: const Text('Unarchive'),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDetailPage(projectId: project.id, readOnly: true),
          ),
        );
      },
    );
  }
}
