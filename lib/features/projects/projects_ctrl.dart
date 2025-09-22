import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/project.dart';
import '../../data/project_repo.dart';
import '../../data/session_repo.dart';

/// Repository providers
final projectRepoProvider = Provider<ProjectRepo>((ref) => const ProjectRepo());
final sessionRepoProvider = Provider<SessionRepo>((ref) => const SessionRepo());

/// Domain model with derived progress for display.
class ProjectWithProgress {
  final Project project;
  final int totalMinutes;

  const ProjectWithProgress({required this.project, required this.totalMinutes});

  int get goalMinutes => project.goalMinutes;

  double get progressFraction {
    if (goalMinutes <= 0) return 0;
    return totalMinutes / goalMinutes;
  }
}

/// Streams active (non-archived) projects with aggregated minutes.
final projectsProvider = StreamProvider<List<ProjectWithProgress>>((ref) async* {
  final repo = ref.watch(projectRepoProvider);
  final stream = await repo.watchActive();
  await for (final projects in stream) {
    final totals = <int, int>{};
    // Compute totals serially to keep it simple initially.
    for (final p in projects) {
      totals[p.id] = await repo.totalMinutes(p.id);
    }
    yield [
      for (final p in projects)
        ProjectWithProgress(project: p, totalMinutes: totals[p.id] ?? 0),
    ];
  }
});

/// Per-project detail provider with sessions totals.
final projectDetailProvider = FutureProvider.family<ProjectWithProgress, int>((ref, id) async {
  final repo = ref.watch(projectRepoProvider);
  final p = await repo.get(id);
  if (p == null) throw StateError('Project not found: $id');
  final minutes = await repo.totalMinutes(id);
  return ProjectWithProgress(project: p, totalMinutes: minutes);
});
