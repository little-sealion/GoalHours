import 'package:flutter/foundation.dart';

import '../../data/session.dart';
import '../../data/session_repo.dart';

class TimerController extends ChangeNotifier {
  TimerController(this._repo);

  final SessionRepo _repo;

  Session? _active;
  Session? get active => _active;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> refresh() async {
    _active = await _repo.getActive();
    notifyListeners();
  }

  Future<void> start(int projectId, {String? note}) async {
    _loading = true;
    notifyListeners();
    try {
      _active = await _repo.startTimer(projectId, note: note);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _loading = true;
    notifyListeners();
    try {
      _active = await _repo.stopActive();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
