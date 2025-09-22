import 'dart:async';

import 'package:isar/isar.dart';

import 'db.dart';
import 'session.dart';

class SessionRepo {
  const SessionRepo();

  /// Returns the current active session (endUtc == null) if any.
  Future<Session?> getActive() async {
    final isar = await AppDb.instance();
    return isar
        .collection<Session>()
        .filter()
        .endUtcIsNull()
        .findFirst();
  }

  /// Start a new timer session for the given project.
  /// Throws StateError if another active session exists.
  Future<Session> startTimer(int projectId, {String? note}) async {
    final isar = await AppDb.instance();
    final now = DateTime.now().toUtc();
    return isar.writeTxn<Session>(() async {
      final active = await getActive();
      if (active != null) {
        throw StateError('An active session is already running.');
      }
      final s = Session()
        ..projectId = projectId
        ..startUtc = now
        ..endUtc = null
        ..isManual = false
        ..manualDurationMinutes = null
        ..note = note
        ..createdAtUtc = now;
      final id = await isar.collection<Session>().put(s);
      s.id = id;
      return s;
    });
  }

  /// Stop the currently active timer by setting endUtc to now.
  /// Returns the updated session, or null if no active session.
  Future<Session?> stopActive() async {
    final isar = await AppDb.instance();
    final now = DateTime.now().toUtc();
    return isar.writeTxn<Session?>(() async {
      final active = await getActive();
      if (active == null) return null;
      active.endUtc = now;
      await isar.collection<Session>().put(active);
      return active;
    });
  }

  /// Add a manual duration entry of [minutes]. Optional [end] defaults to now (UTC).
  Future<Session> addManualEntry(int projectId, int minutes, {String? note, DateTime? end}) async {
    if (minutes <= 0) {
      throw ArgumentError.value(minutes, 'minutes', 'Must be > 0');
    }
    final isar = await AppDb.instance();
    final endUtc = (end ?? DateTime.now()).toUtc();
    final startUtc = endUtc.subtract(Duration(minutes: minutes));
    final now = DateTime.now().toUtc();
    return isar.writeTxn<Session>(() async {
      final s = Session()
        ..projectId = projectId
        ..startUtc = startUtc
        ..endUtc = endUtc
        ..isManual = true
        ..manualDurationMinutes = minutes
        ..note = note
        ..createdAtUtc = now;
      final id = await isar.collection<Session>().put(s);
      s.id = id;
      return s;
    });
  }

  /// Watch sessions for a project ordered by startUtc descending.
  Future<Stream<List<Session>>> watchForProject(int projectId) async {
    final isar = await AppDb.instance();
    final q = isar
        .collection<Session>()
        .filter()
        .projectIdEqualTo(projectId)
        .sortByStartUtcDesc();
    return q.watch(fireImmediately: true);
  }

  /// Delete a session by id.
  Future<void> delete(int id) async {
    final isar = await AppDb.instance();
    await isar.writeTxn(() => isar.collection<Session>().delete(id));
  }
}
