import 'dart:async';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart' as pp;

import 'project.dart';
import 'session.dart';

class AppDb {
  AppDb._();

  static Isar? _isar;

  static Future<Isar> instance() async {
    // Return existing instance if already opened
    final existing = _isar ?? Isar.getInstance();
    if (existing != null) {
      _isar = existing;
      return existing;
    }
    // Open a new instance with our schemas in the app support directory.
    final dir = await pp.getApplicationSupportDirectory();
    _isar = await Isar.open(
      [ProjectSchema, SessionSchema],
      inspector: false,
      directory: dir.path,
    );
    return _isar!;
  }

  static Future<void> close() async {
    final db = _isar ?? Isar.getInstance();
    if (db != null) {
      await db.close();
      _isar = null;
    }
  }
}
