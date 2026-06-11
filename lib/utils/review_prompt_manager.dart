import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/domain/app_user.dart';

class ReviewPromptManager {
  ReviewPromptManager._();

  static const String _prefKey = 'has_prompted_review';

  static Future<void> checkAndShow(
    BuildContext context, {
    required AppUser user,
    required int journalsCount,
    required int moodLogsCount,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool(_prefKey) ?? false;

      if (hasPrompted) return;

      final bool meetStreak = user.noContactStreak >= 7;
      final bool meetJournals = journalsCount >= 3;
      final bool meetMoods = moodLogsCount >= 5;

      if (meetStreak || meetJournals || meetMoods) {
        if (!context.mounted) return;
        _showReviewDialog(context, prefs);
      }
    } catch (_) {}
  }

  static void _showReviewDialog(BuildContext context, SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enjoying Move On? 🌟'),
          content: const Text(
            'Your healing journey is important to us. If you find Move On helpful, please take a moment to rate us. It helps other people find support and recovery resources too!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () async {
                await prefs.setBool(_prefKey, true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Don\'t Ask Again',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                await prefs.setBool(_prefKey, true);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you! Redirecting to App Store...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                'Rate Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
