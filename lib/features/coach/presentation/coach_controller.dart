import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../../providers/providers.dart';
import '../../../utils/haptic_service.dart';
import '../../../utils/recovery_calculator.dart';
import '../data/coach_api_service.dart';
import '../data/coach_repository.dart';
import '../domain/coach_message.dart';
import '../domain/coach_session.dart';
import '../domain/coach_usage.dart';

// Providers for data layer
final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return CoachRepository(firestore: firestore);
});

final coachApiServiceProvider = Provider<CoachApiService>((ref) {
  return CoachApiService();
});

// State classes for the controller
class CoachState {
  final CoachSession? activeSession;
  final bool isLoading;
  final String? errorMessage;
  final int messagesRemaining;
  final String dailyReflectionQuestion;
  final String dailyReflectionPrompt;
  final bool isReflectionCompleted;

  CoachState({
    this.activeSession,
    this.isLoading = false,
    this.errorMessage,
    this.messagesRemaining = 20,
    this.dailyReflectionQuestion = '',
    this.dailyReflectionPrompt = '',
    this.isReflectionCompleted = false,
  });

  CoachState copyWith({
    CoachSession? activeSession,
    bool? isLoading,
    String? errorMessage,
    int? messagesRemaining,
    String? dailyReflectionQuestion,
    String? dailyReflectionPrompt,
    bool? isReflectionCompleted,
  }) {
    return CoachState(
      activeSession: activeSession ?? this.activeSession,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      messagesRemaining: messagesRemaining ?? this.messagesRemaining,
      dailyReflectionQuestion: dailyReflectionQuestion ?? this.dailyReflectionQuestion,
      dailyReflectionPrompt: dailyReflectionPrompt ?? this.dailyReflectionPrompt,
      isReflectionCompleted: isReflectionCompleted ?? this.isReflectionCompleted,
    );
  }
}

class CoachController extends StateNotifier<AsyncValue<CoachState>> {
  final Ref _ref;
  final CoachRepository _repository;
  final CoachApiService _apiService;

  CoachController(this._ref)
      : _repository = _ref.read(coachRepositoryProvider),
        _apiService = _ref.read(coachApiServiceProvider),
        super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref.read(appUserProvider.future);
      if (user == null) {
        state = AsyncValue.error('User not logged in', StackTrace.current);
        return;
      }

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final usage = await _repository.getUsage(user.uid, todayStr);
      final int remaining = usage != null ? (20 - usage.messagesToday) : 20;

      // Start a default talk session
      final session = await _repository.createSession(user.uid, 'TALK');

      // Load daily reflection
      final moods = _ref.read(moodHistoryProvider).value ?? [];
      final score = RecoveryCalculator.calculateTotalScore(
        streakDays: user.noContactStreak,
        recentMoods: moods,
      );
      final stage = RecoveryCalculator.getStage(score);
      final reflection = await _repository.getOrCreateDailyReflectionPrompt(
        user.uid,
        todayStr,
        stage,
        user.noContactStreak,
      );

      state = AsyncValue.data(CoachState(
        activeSession: session,
        messagesRemaining: remaining,
        dailyReflectionQuestion: reflection['question'] ?? '',
        dailyReflectionPrompt: reflection['healingPrompt'] ?? '',
        isReflectionCompleted: (reflection['responseContent'] ?? '').isNotEmpty,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Send message in TALK or SOS mode
  Future<void> sendMessage(String text, List<CoachMessage> messageHistory) async {
    final currentState = state.value;
    if (currentState == null || currentState.activeSession == null) return;
    
    final usage = await _repository.getUsage(_ref.read(appUserProvider).value?.uid ?? '', DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final int remainingMsgs = usage != null ? (20 - usage.messagesToday) : 20;
    
    if (remainingMsgs <= 0) {
      _ref.read(hapticServiceProvider).warning();
      state = AsyncValue.data(currentState.copyWith(
        messagesRemaining: 0,
        errorMessage: 'limit_reached',
      ));
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoading: true, errorMessage: null));
    _ref.read(hapticServiceProvider).selection();

    try {
      final user = _ref.read(appUserProvider).value;
      final moods = _ref.read(moodHistoryProvider).value ?? [];
      final journals = _ref.read(journalListProvider).value ?? [];
      final completedTasks = await _ref.read(completedTasksCountProvider.future);

      if (user == null) throw Exception('User authentication lost');

      final double score = RecoveryCalculator.calculateTotalScore(
        streakDays: user.noContactStreak,
        recentMoods: moods,
      );
      final stage = RecoveryCalculator.getStage(score);
      final currentMood = moods.isNotEmpty ? moods.first.mood : "Okay";

      // Build context payload
      final Map<String, dynamic> contextMap = {
        'daysNoContact': user.noContactStreak,
        'recoveryStage': stage,
        'recoveryScore': score.toInt(),
        'currentMood': currentMood,
        'longestStreak': user.longestStreak,
        'healingTasksCompleted': completedTasks,
        'totalJournalEntries': journals.length,
      };

      // Format history maps for payload
      final List<Map<String, dynamic>> historyPayload = messageHistory.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();

      // Trigger function
      final result = await _apiService.sendChatMessage(
        message: text,
        sessionId: currentState.activeSession!.id,
        context: contextMap,
        history: historyPayload,
      );

      final int remaining = result['messagesRemaining'] as int? ?? 20;

      // Haptic feedback on AI reply received
      _ref.read(hapticServiceProvider).light();

      // Update state
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        messagesRemaining: remaining,
      ));

      // Log analytics event
      _ref.read(analyticsServiceProvider).logCoachMessageSent();
    } catch (e) {
      String errStr = e.toString().replaceAll('Exception: ', '');
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        errorMessage: errStr,
      ));
    }
  }

  /// Create a new session (e.g. restart chat)
  Future<void> startNewSession(String mode) async {
    final currentState = state.value;
    if (currentState == null) return;
    
    final user = _ref.read(appUserProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    try {
      final session = await _repository.createSession(user.uid, mode);
      
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final usage = await _repository.getUsage(user.uid, todayStr);
      final int remaining = usage != null ? (20 - usage.messagesToday) : 20;

      state = AsyncValue.data(currentState.copyWith(
        activeSession: session,
        messagesRemaining: remaining,
        errorMessage: null,
      ));
      
      if (mode == 'SOS') {
        _ref.read(hapticServiceProvider).light(); // Soft impact for SOS
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Save daily reflection answer
  Future<void> submitReflection(String answer) async {
    final currentState = state.value;
    if (currentState == null) return;

    final user = _ref.read(appUserProvider).value;
    if (user == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _repository.saveDailyReflectionAnswer(user.uid, todayStr, answer);
      
      _ref.read(hapticServiceProvider).medium(); // Medium feedback for completion

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        isReflectionCompleted: true,
      ));
      
      _ref.read(analyticsServiceProvider).logReflectionCompleted();
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        errorMessage: 'Failed to submit reflection: ${e.toString()}',
      ));
    }
  }

  /// Log SOS completion details
  Future<void> completeSosLog(String reason, bool completedBreathing, String? journalEntryId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final user = _ref.read(appUserProvider).value;
    if (user == null) return;

    try {
      await _repository.logSosTrigger(
        uid: user.uid,
        reason: reason,
        completedBreathing: completedBreathing,
        streakDays: user.noContactStreak,
        journalEntryId: journalEntryId,
      );
      
      _ref.read(analyticsServiceProvider).logSosTriggered();
    } catch (e) {
      debugPrint("Error logging SOS completion: $e");
    }
  }

  void clearError() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(errorMessage: null));
    }
  }
}

// Exposed provider
final coachControllerProvider =
    StateNotifierProvider<CoachController, AsyncValue<CoachState>>((ref) {
  return CoachController(ref);
});

// Messages stream provider based on active session
final coachMessagesProvider = StreamProvider<List<CoachMessage>>((ref) {
  final coachState = ref.watch(coachControllerProvider).value;
  if (coachState == null || coachState.activeSession == null) {
    return Stream.value([]);
  }
  return ref.read(coachRepositoryProvider).watchMessages(coachState.activeSession!.id);
});

// Stream for user usage limits
final coachUsageProvider = StreamProvider<CoachUsage?>((ref) {
  final user = ref.watch(appUserProvider).value;
  if (user == null) return Stream.value(null);
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.read(coachRepositoryProvider).watchUsage(user.uid, todayStr);
});
