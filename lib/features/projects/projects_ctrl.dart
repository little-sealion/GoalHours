import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/project.dart';
import '../../data/project_repo.dart';

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

  Future<void> initialize() async {
    _sub?.cancel();
    final stream = await _repo.watchActive();
    _sub = stream.listen((projects) async {
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
    super.dispose();
  }
}
