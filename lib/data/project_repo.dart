import 'dart:async';

import 'package:isar/isar.dart';

import 'db.dart';
import 'project.dart';
import 'session.dart';

class ProjectRepo {
  const ProjectRepo();

  Future<int> add(Project project) async {
    final isar = await AppDb.instance();
    return isar.writeTxn(() => isar.collection<Project>().put(project));
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

  Future<void> delete(int id) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() => isar.collection<Project>().delete(id));
  }

  Future<Project?> get(int id) async {
    final isar = await AppDb.instance();
    return isar.collection<Project>().get(id);
  }

  /// Stream non-archived projects ordered by createdAtUtc.
  Future<Stream<List<Project>>> watchActive() async {
  final isar = await AppDb.instance();
  final query = isar
    .collection<Project>()
    .filter()
    .archivedEqualTo(false)
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
}
