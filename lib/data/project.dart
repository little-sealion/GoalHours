import 'package:isar/isar.dart';

part 'project.g.dart';

/// Project entity stored in Isar.
/// Times are stored in UTC.
@collection
class Project {
  Id id = Isar.autoIncrement;

  late String name;

  /// ARGB color as 0xAARRGGBB
  late int color;

  /// Goal in minutes
  @Index()
  late int goalMinutes;

  /// Sort index for manual ordering in the projects list (ascending)
  @Index()
  int sortIndex = 0;

  late DateTime createdAtUtc;

  @Index()
  bool archived = false;
}
