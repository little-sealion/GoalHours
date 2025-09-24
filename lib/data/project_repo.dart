import 'dart:async';

import 'package:isar/isar.dart';

import 'db.dart';
import 'project.dart';
import 'session.dart';

class ProjectRepo {
  const ProjectRepo();

  Future<int> add(Project project) async {
    final isar = await AppDb.instance();
    return isar.writeTxn(() async {
      // Always assign sortIndex for active projects by appending to the end.
      if (!project.archived) {
        final existing = await isar
            .collection<Project>()
            .filter()
            .archivedEqualTo(false)
            .findAll();
        int maxIdx = -1;
        for (final p in existing) {
          if (p.sortIndex > maxIdx) maxIdx = p.sortIndex;
        }
        project.sortIndex = maxIdx + 1;
      }
      return isar.collection<Project>().put(project);
    });
  }

  Future<void> update(Project project) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() => isar.collection<Project>().put(project));
  }

  Future<void> archive(int id) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() async {
      final p = await isar.collection<Project>().get(id);
      if (p != null) {
        p.archived = true;
        await isar.collection<Project>().put(p);
      }
    });
  }

  Future<void> unarchive(int id) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() async {
      final p = await isar.collection<Project>().get(id);
      if (p != null) {
        p.archived = false;
        await isar.collection<Project>().put(p);
      }
    });
  }

  Future<void> delete(int id) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() => isar.collection<Project>().delete(id));
  }

  Future<Project?> get(int id) async {
    final isar = await AppDb.instance();
    return isar.collection<Project>().get(id);
  }

  /// Stream non-archived projects ordered by createdAtUtc (stable base order).
  Future<Stream<List<Project>>> watchActive() async {
  final isar = await AppDb.instance();
  final query = isar
    .collection<Project>()
    .filter()
    .archivedEqualTo(false)
    .sortByCreatedAtUtc();
  return query.watch(fireImmediately: true);
  }

  /// Stream archived projects ordered by createdAtUtc (most recent last).
  Future<Stream<List<Project>>> watchArchived() async {
    final isar = await AppDb.instance();
    final query = isar
        .collection<Project>()
        .filter()
        .archivedEqualTo(true)
        .sortByCreatedAtUtc();
    return query.watch(fireImmediately: true);
  }

  /// Returns total minutes accumulated for the project by summing sessions.
  Future<int> totalMinutes(int projectId) async {
    final isar = await AppDb.instance();
    final sessions = await isar
        .collection<Session>()
        .filter()
        .projectIdEqualTo(projectId)
        .findAll();
    return sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Ensure all active projects have a contiguous sortIndex starting at 0.
  Future<void> normalizeSortOrder() async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() async {
      final list = await isar
          .collection<Project>()
          .filter()
          .archivedEqualTo(false)
          .findAll();
      list.sort((a, b) => (a.sortIndex).compareTo(b.sortIndex));
      for (int i = 0; i < list.length; i++) {
        final p = list[i];
        if (p.sortIndex != i) {
          p.sortIndex = i;
          await isar.collection<Project>().put(p);
        }
      }
    });
  }

  /// Persist a new order given a list of project ids in desired order.
  Future<void> reorder(List<int> orderedIds) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        final p = await isar.collection<Project>().get(orderedIds[i]);
        if (p == null) continue;
        p.sortIndex = i;
        await isar.collection<Project>().put(p);
      }
    });
  }
}
