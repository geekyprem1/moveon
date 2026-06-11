import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../mood/domain/mood_entry.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../utils/date_formatter.dart';

class DashboardController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  DashboardController(this._ref) : super(const AsyncValue.data(null));

  /// Log today's mood
  Future<void> selectMood(String moodName) async {
    final user = _ref.read(appUserProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final dateStr = DateFormatter.toDateString(DateTime.now());
      final entry = MoodEntry(
        id: dateStr,
        mood: moodName,
        timestamp: DateTime.now(),
      );

      final moodRepo = _ref.read(moodRepositoryProvider);
      await moodRepo.logMood(user.uid, entry);

      // Log Analytics Event
      _ref.read(analyticsServiceProvider).logMoodCheckIn(moodName);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle task completion for today
  Future<void> toggleTask(String taskId, bool completed) async {
    final user = _ref.read(appUserProvider).value;
    if (user == null) return;

    try {
      final tasksRepo = _ref.read(tasksRepositoryProvider);
      final dateStr = DateFormatter.toDateString(DateTime.now());
      await tasksRepo.toggleTask(user.uid, dateStr, taskId, completed);

      // Log Analytics Event if task completed
      if (completed) {
        _ref.read(analyticsServiceProvider).logTaskCompleted(taskId);
      }
    } catch (_) {
      // Fail silently for task toggling (optimistic UX)
    }
  }

  /// Reset the streak (user reports contact with Ex)
  Future<void> resetStreak() async {
    final user = _ref.read(appUserProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final updatedUser = user.copyWith(
        lastContactDate: DateTime.now(),
      );
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.updateUser(updatedUser);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _ref.read(authControllerProvider.notifier).logout();
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, AsyncValue<void>>((ref) {
  return DashboardController(ref);
});
