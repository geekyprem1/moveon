import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/app_user.dart';
import '../../../providers/providers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BadgeDefinition {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int requiredDays;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.requiredDays,
  });
}

class AchievementService {
  static const List<BadgeDefinition> badges = [
    BadgeDefinition(
      id: '7_days_strong',
      title: '7 Days Strong',
      description: 'Maintained No Contact for 1 week.',
      emoji: '🌱',
      requiredDays: 7,
    ),
    BadgeDefinition(
      id: '30_days_survivor',
      title: '30 Days Survivor',
      description: 'Survived a full month of No Contact.',
      emoji: '🛡️',
      requiredDays: 30,
    ),
    BadgeDefinition(
      id: '60_days_healing',
      title: '60 Days Healing',
      description: 'Reached full target healing timeline.',
      emoji: '🩹',
      requiredDays: 60,
    ),
    BadgeDefinition(
      id: '90_days_warrior',
      title: '90 Days Warrior',
      description: 'Demonstrated exceptional willpower.',
      emoji: '⚔️',
      requiredDays: 90,
    ),
    BadgeDefinition(
      id: '180_days_rebuilt',
      title: '180 Days Rebuilt',
      description: 'Six months of focus and self-rebuilding.',
      emoji: '🧱',
      requiredDays: 180,
    ),
    BadgeDefinition(
      id: '365_days_transformed',
      title: '365 Days Transformed',
      description: 'A full year. You are completely transformed.',
      emoji: '🦋',
      requiredDays: 365,
    ),
    BadgeDefinition(
      id: 'referral_supporter',
      title: 'Community Supporter',
      description: 'Supported a friend with their recovery.',
      emoji: '🤝',
      requiredDays: 0,
    ),
  ];

  static Future<void> checkAndUnlock(WidgetRef ref, AppUser user) async {
    final int currentStreak = user.noContactStreak;
    final List<String> newlyUnlocked = List.from(user.unlockedAchievements);
    bool updated = false;

    // Check longest streak update
    int newLongestStreak = user.longestStreak;
    if (currentStreak > user.longestStreak) {
      newLongestStreak = currentStreak;
      updated = true;
    }

    for (var badge in badges) {
      if (currentStreak >= badge.requiredDays && !newlyUnlocked.contains(badge.id)) {
        newlyUnlocked.add(badge.id);
        updated = true;

        // Log Firebase Analytics event
        ref.read(analyticsServiceProvider).logAchievementUnlocked(badge.id);

        // Trigger milestone local notification
        _triggerMilestoneNotification(badge);
      }
    }

    if (updated) {
      final updatedUser = user.copyWith(
        longestStreak: newLongestStreak,
        unlockedAchievements: newlyUnlocked,
      );
      await ref.read(authRepositoryProvider).updateUser(updatedUser);
    }
  }

  static Future<void> _triggerMilestoneNotification(BadgeDefinition badge) async {
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'achievements_channel',
      'Milestones & Achievements',
      channelDescription: 'Get notified when you unlock new recovery milestones',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await localNotifications.show(
      badge.requiredDays,
      'Achievement Unlocked! ${badge.emoji}',
      'You have earned the "${badge.title}" badge!',
      platformDetails,
    );
  }
}
