import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  AnalyticsService();

  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logMoodCheckIn(String mood) async {
    try {
      await _analytics.logEvent(
        name: 'mood_check_in',
        parameters: {'mood': mood},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logJournalCreated() async {
    try {
      await _analytics.logEvent(name: 'journal_created');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logTaskCompleted(String taskId) async {
    try {
      await _analytics.logEvent(
        name: 'task_completed',
        parameters: {'task_id': taskId},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logEmergencyClicked() async {
    try {
      await _analytics.logEvent(name: 'emergency_clicked');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  Future<void> logAchievementUnlocked(String achievementId) async {
    try {
      await _analytics.logEvent(
        name: 'achievement_unlocked',
        parameters: {'achievement_id': achievementId},
      );
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
