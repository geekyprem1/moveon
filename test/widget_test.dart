import 'package:flutter_test/flutter_test.dart';
import 'package:move_on/utils/recovery_calculator.dart';
import 'package:move_on/features/mood/domain/mood_entry.dart';

void main() {
  group('RecoveryCalculator Tests', () {
    test('calculateStreakScore returns correct percentages', () {
      expect(RecoveryCalculator.calculateStreakScore(0), 0.0);
      expect(RecoveryCalculator.calculateStreakScore(30), 50.0);
      expect(RecoveryCalculator.calculateStreakScore(60), 100.0);
      expect(RecoveryCalculator.calculateStreakScore(90), 100.0); // Capped at 100
    });

    test('calculateMoodScore returns correct averages', () {
      final moodsEmpty = <MoodEntry>[];
      expect(RecoveryCalculator.calculateMoodScore(moodsEmpty), 60.0); // Defaults to Okay (60)

      final moods = [
        MoodEntry(id: '1', mood: 'Great', timestamp: DateTime.now()), // 100
        MoodEntry(id: '2', mood: 'Okay', timestamp: DateTime.now()),  // 60
        MoodEntry(id: '3', mood: 'Sad', timestamp: DateTime.now()),   // 40
      ];
      // Average should be (100 + 60 + 40) / 3 = 66.666...
      expect(RecoveryCalculator.calculateMoodScore(moods), closeTo(66.66, 0.1));
    });

    test('calculateTotalScore combines streak and mood weights', () {
      // 0 streak, empty mood
      // Streak Contribution = 0 * 0.6 = 0
      // Mood Contribution = 60 * 0.4 = 24
      // Total = 24
      expect(
        RecoveryCalculator.calculateTotalScore(
          streakDays: 0,
          recentMoods: [],
        ),
        24.0,
      );

      // 30 day streak (50%), great moods (100%)
      // Streak Contribution = 50 * 0.6 = 30
      // Mood Contribution = 100 * 0.4 = 40
      // Total = 70
      final perfectMoods = [
        MoodEntry(id: '1', mood: 'Great', timestamp: DateTime.now()),
      ];
      expect(
        RecoveryCalculator.calculateTotalScore(
          streakDays: 30,
          recentMoods: perfectMoods,
        ),
        70.0,
      );
    });

    test('getStage maps scores to emotional stages correctly', () {
      expect(RecoveryCalculator.getStage(10), 'Shock');
      expect(RecoveryCalculator.getStage(30), 'Withdrawal');
      expect(RecoveryCalculator.getStage(50), 'Healing');
      expect(RecoveryCalculator.getStage(70), 'Growth');
      expect(RecoveryCalculator.getStage(90), 'Move-On');
    });
  });
}
