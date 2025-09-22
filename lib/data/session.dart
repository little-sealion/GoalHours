import 'package:isar/isar.dart';

part 'session.g.dart';

/// Session entity represents either a manual duration entry or a timer span.
@collection
class Session {
  Id id = Isar.autoIncrement;

  /// Foreign key link to Project.id
  @Index()
  late int projectId;

  /// Start time in UTC. For manual entries, computed as endUtc - manualDuration.
  late DateTime startUtc;

  /// End time in UTC. Null while an active timer is running.
  @Index()
  DateTime? endUtc;

  /// True if the session was a manual entry.
  late bool isManual;

  /// For manual entries: explicit duration in minutes; otherwise null.
  int? manualDurationMinutes;

  String? note;

  late DateTime createdAtUtc;

  /// Derived duration in minutes.
  int get durationMinutes {
    if (isManual) return manualDurationMinutes ?? 0;
    final end = endUtc;
    if (end == null) return 0;
    final minutes = end.difference(startUtc).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }
}
