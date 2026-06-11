import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  OnboardingController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> submitOnboarding({
    required String name,
    required DateTime breakupDate,
    required int relationshipDurationDays,
    required int initialPainScore,
    required String breakupType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final appUserAsync = _ref.read(appUserProvider);
      final uid = appUserAsync.value?.uid;

      if (uid == null) {
        throw Exception('User is not authenticated');
      }

      final onboardingRepo = _ref.read(onboardingRepositoryProvider);
      await onboardingRepo.submitOnboarding(
        uid: uid,
        name: name,
        breakupDate: breakupDate,
        relationshipDurationDays: relationshipDurationDays,
        initialPainScore: initialPainScore,
        breakupType: breakupType,
      );

      // Trigger notifications registration after onboarding completes
      final notificationService = _ref.read(notificationServiceProvider);
      await notificationService.requestPermissions();
      await notificationService.scheduleDailyReminders();

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(ref);
});
