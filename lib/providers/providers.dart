import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/onboarding/data/onboarding_repository.dart';
import '../features/mood/data/mood_repository.dart';
import '../features/mood/domain/mood_entry.dart';
import '../features/journal/data/journal_repository.dart';
import '../features/journal/domain/journal_entry.dart';
import '../features/tasks/data/tasks_repository.dart';
import '../features/notifications/data/notification_service.dart';
import '../features/analytics/data/analytics_service.dart';
import '../utils/date_formatter.dart';

// ==========================================
// 1. Firebase Providers
// ==========================================

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ==========================================
// 2. Repository Providers
// ==========================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthRepository(firebaseAuth: auth, firestore: firestore);
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return OnboardingRepository(firestore: firestore);
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MoodRepository(firestore: firestore);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return JournalRepository(firestore: firestore);
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TasksRepository(firestore: firestore);
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// ==========================================
// 3. State & Stream Providers
// ==========================================

/// Listen to Firebase Auth state shifts
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

/// Listen to AppUser record updates in Firestore
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.watchAppUser(authState.uid);
});

/// Listen to all user mood entries
final moodHistoryProvider = StreamProvider<List<MoodEntry>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return Stream.value([]);

  final moodRepo = ref.watch(moodRepositoryProvider);
  return moodRepo.watchMoodHistory(appUser.uid);
});

/// Listen to local Journal entries in Hive
final journalListProvider = StreamProvider<List<JournalEntry>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return Stream.value([]);

  final journalRepo = ref.watch(journalRepositoryProvider);
  
  // We trigger a background sync whenever the journal list provider is loaded
  // This automatically keeps local and remote in sync.
  ref.read(journalRepositoryProvider).syncJournals(appUser.uid);

  return journalRepo.watchLocalJournals();
});

/// Listen to daily task completions
final dailyCompletedTasksProvider = StreamProvider<Set<String>>((ref) {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return Stream.value({});

  final tasksRepo = ref.watch(tasksRepositoryProvider);
  final String todayStr = DateFormatter.toDateString(DateTime.now());
  return tasksRepo.watchCompletedTasks(appUser.uid, todayStr);
});

/// Fetch count of all tasks documents using count() aggregation
final completedTasksCountProvider = FutureProvider<int>((ref) async {
  final appUser = ref.watch(appUserProvider).value;
  if (appUser == null) return 0;
  final firestore = ref.read(firestoreProvider);
  final snapshot = await firestore
      .collection('users')
      .doc(appUser.uid)
      .collection('tasks')
      .count()
      .get();
  return snapshot.count ?? 0;
});

final activeTabProvider = StateProvider<int>((ref) {
  return 0; // Default to Dashboard (index 0)
});
