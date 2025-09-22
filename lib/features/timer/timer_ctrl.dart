import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/session.dart';
import '../../data/session_repo.dart';

final sessionRepoProvider = Provider<SessionRepo>((ref) => const SessionRepo());

/// Exposes the currently active session (if any).
final activeSessionProvider = FutureProvider<Session?>((ref) async {
  final repo = ref.watch(sessionRepoProvider);
  return repo.getActive();
});

/// Controller for starting/stopping the timer.
class TimerController extends AsyncNotifier<Session?> {
  @override
  Future<Session?> build() async {
    return ref.watch(activeSessionProvider.future);
  }

  Future<void> start(int projectId, {String? note}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sessionRepoProvider);
      return repo.startTimer(projectId, note: note);
    });
  }

  Future<void> stop() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(sessionRepoProvider);
      return repo.stopActive();
    });
  }
}

final timerControllerProvider = AsyncNotifierProvider<TimerController, Session?>(
  TimerController.new,
);
