import '../features/mood/domain/mood_entry.dart';

class RecoveryCalculator {
  RecoveryCalculator._();

  /// Constants
  static const int targetStreakDays = 60;

  /// Map mood string to numeric score
  static double getMoodValue(String mood) {
    switch (mood.toLowerCase()) {
      case 'terrible':
        return 20.0;
      case 'sad':
        return 40.0;
      case 'okay':
        return 60.0;
      case 'better':
        return 80.0;
      case 'great':
        return 100.0;
      default:
        return 60.0; // Default to Okay
    }
  }

  /// Map score back to stage name
  static String getStage(double score) {
    if (score <= 20) return "Shock";
    if (score <= 40) return "Withdrawal";
    if (score <= 60) return "Healing";
    if (score <= 80) return "Growth";
    return "Move-On";
  }

  /// Calculate Streak Score Contribution (60%)
  static double calculateStreakScore(int streakDays) {
    if (streakDays <= 0) return 0.0;
    final double rawStreakScore = (streakDays / targetStreakDays) * 100.0;
    return rawStreakScore > 100.0 ? 100.0 : rawStreakScore;
  }

  /// Calculate Mood Score Contribution (40%)
  /// We average the mood scores for the last 7 days (or whatever logs we have).
  /// If logs are empty, default to 60.0 (Okay).
  static double calculateMoodScore(List<MoodEntry> recentMoods) {
    if (recentMoods.isEmpty) return 60.0;

    // Filter last 7 entries
    final int count = recentMoods.length > 7 ? 7 : recentMoods.length;
    final List<MoodEntry> last7 = recentMoods.sublist(0, count);

    double total = 0.0;
    for (var m in last7) {
      total += getMoodValue(m.mood);
    }
    return total / count;
  }

  /// Calculate Total Recovery Score (0-100)
  static double calculateTotalScore({
    required int streakDays,
    required List<MoodEntry> recentMoods,
  }) {
    final double streakContribution = calculateStreakScore(streakDays) * 0.60;
    final double moodContribution = calculateMoodScore(recentMoods) * 0.40;
    final double total = streakContribution + moodContribution;
    return total > 100.0 ? 100.0 : (total < 0.0 ? 0.0 : total);
  }

  /// Calculate mood improvement percentage relative to starting pain score
  static double calculateMoodImprovement(List<MoodEntry> recentMoods, int initialPainScore) {
    if (recentMoods.isEmpty) return 0.0;

    // Convert pain score (0-10) to wellness rating (0-10)
    final double initialWellness = (10 - initialPainScore).toDouble();

    // Map current mood score average (0-100) to wellness rating (0-10)
    final double currentMoodScore = calculateMoodScore(recentMoods);
    final double currentWellness = currentMoodScore / 10.0;

    if (initialWellness <= 0.0) {
      // If starting wellness was 0, calculate relative to 10
      return (currentWellness / 10.0) * 100.0;
    }

    final double improvement = ((currentWellness - initialWellness) / initialWellness) * 100.0;
    return improvement;
  }
}
