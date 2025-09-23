import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/project.dart';
import '../../data/project_repo.dart';
import '../../data/session.dart';
import '../../data/db.dart';

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

class ProjectsController extends ChangeNotifier {
  ProjectsController(this._repo);

  final ProjectRepo _repo;

  List<ProjectWithProgress> _items = const [];
  List<ProjectWithProgress> get items => _items;

  StreamSubscription<List<Project>>? _sub;
  StreamSubscription<void>? _sessionsSub;

  Future<void> initialize() async {
    _sub?.cancel();
    final stream = await _repo.watchActive();
    _sub = stream.listen((projects) async {
      // Sort by sortIndex ascending for display order. Fallback to createdAtUtc for stability.
      projects.sort((a, b) {
        final c = a.sortIndex.compareTo(b.sortIndex);
        if (c != 0) return c;
        return a.createdAtUtc.compareTo(b.createdAtUtc);
      });
      final totals = <int, int>{};
      for (final p in projects) {
        totals[p.id] = await _repo.totalMinutes(p.id);
      }
      _items = [
        for (final p in projects)
          ProjectWithProgress(project: p, totalMinutes: totals[p.id] ?? 0),
      ];
      notifyListeners();
    });

    // Also watch session changes so progress totals refresh when sessions update
    _sessionsSub?.cancel();
    final isar = await AppDb.instance();
    _sessionsSub = isar.collection<Session>().watchLazy().listen((_) async {
      if (_items.isEmpty) return;
      final projects = [for (final it in _items) it.project];
      final totals = <int, int>{};
      for (final p in projects) {
        totals[p.id] = await _repo.totalMinutes(p.id);
      }
      _items = [
        for (final p in projects)
          ProjectWithProgress(project: p, totalMinutes: totals[p.id] ?? 0),
      ];
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sessionsSub?.cancel();
    super.dispose();
  }

  /// Persist a new order of projects by their ids and refresh list
  Future<void> reorder(List<int> orderedIds) async {
    await _repo.reorder(orderedIds);
    // Re-fetch totals in new order
    final projects = [for (final it in _items) it.project]
      ..sort((a, b) {
        final c = a.sortIndex.compareTo(b.sortIndex);
        if (c != 0) return c;
        return a.createdAtUtc.compareTo(b.createdAtUtc);
      });
    final totals = <int, int>{};
    for (final p in projects) {
      totals[p.id] = await _repo.totalMinutes(p.id);
    }
    _items = [
      for (final p in projects)
        ProjectWithProgress(project: p, totalMinutes: totals[p.id] ?? 0),
    ];
    notifyListeners();
  }
}
