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

  /// For manual entries: explicit duration in seconds (preferred going forward).
  int? manualDurationSeconds;

  String? note;

  late DateTime createdAtUtc;

  /// Derived duration in seconds.
  int get durationSeconds {
    if (isManual) {
      if (manualDurationSeconds != null) return manualDurationSeconds!.clamp(0, 1 << 31);
      final m = manualDurationMinutes ?? 0;
      return m > 0 ? m * 60 : 0;
    }
    final end = endUtc;
    if (end == null) return 0;
    final sec = end.difference(startUtc).inSeconds;
    return sec < 0 ? 0 : sec;
  }

  /// Derived duration in minutes.
  int get durationMinutes {
    final sec = durationSeconds;
    // For aggregates, keep minutes as floor of seconds/60 to maintain stability.
    return (sec ~/ 60);
  }
}
