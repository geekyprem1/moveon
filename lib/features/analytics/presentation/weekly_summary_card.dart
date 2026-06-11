import 'package:flutter/material.dart';
import '../../mood/domain/mood_entry.dart';
import '../../../utils/recovery_calculator.dart';

class WeeklySummaryCard extends StatelessWidget {
  final List<MoodEntry> moods;

  const WeeklySummaryCard({super.key, required this.moods});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Filter mood entries in the last 7 days and 8-14 days
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    final thisWeekMoods = moods.where((m) => m.timestamp.isAfter(weekAgo)).toList();
    final lastWeekMoods = moods.where((m) => m.timestamp.isAfter(twoWeeksAgo) && m.timestamp.isBefore(weekAgo)).toList();

    double thisWeekAvg = 0.0;
    if (thisWeekMoods.isNotEmpty) {
      thisWeekAvg = thisWeekMoods.map((m) => RecoveryCalculator.getMoodValue(m.mood)).reduce((a, b) => a + b) / thisWeekMoods.length;
    }

    double lastWeekAvg = 0.0;
    if (lastWeekMoods.isNotEmpty) {
      lastWeekAvg = lastWeekMoods.map((m) => RecoveryCalculator.getMoodValue(m.mood)).reduce((a, b) => a + b) / lastWeekMoods.length;
    }

    // Wellness out of 10
    final thisWeekWellness = thisWeekAvg / 10.0;
    final lastWeekWellness = lastWeekAvg / 10.0;

    String trend = "Stable";
    IconData trendIcon = Icons.trending_flat;
    Color trendColor = Colors.grey;

    if (thisWeekMoods.isNotEmpty && lastWeekMoods.isNotEmpty) {
      final diff = thisWeekWellness - lastWeekWellness;
      if (diff > 0.5) {
        trend = "Improving";
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
      } else if (diff < -0.5) {
        trend = "Declining";
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
      }
    }

    String descText = "";
    if (thisWeekMoods.isEmpty) {
      descText = "Check in with your feelings daily to generate your weekly progress metrics and emotional trends.";
    } else {
      descText = "Your emotional wellness averaged ${thisWeekWellness.toStringAsFixed(1)} / 10. ";
      if (lastWeekMoods.isEmpty) {
        descText += "Keep logging next week to compare your emotional trends.";
      } else {
        descText += "This is $trend compared to the previous week's average of ${lastWeekWellness.toStringAsFixed(1)} / 10.";
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Progress Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (thisWeekMoods.isNotEmpty && lastWeekMoods.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(trendIcon, color: trendColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            color: trendColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descText,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: theme.colorScheme.onSurface.withAlpha(200),
              ),
            ),
            if (thisWeekMoods.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricCell(
                    theme,
                    title: 'Mood Checks',
                    value: '${thisWeekMoods.length} / 7 days',
                  ),
                  _buildMetricCell(
                    theme,
                    title: 'Current Stage',
                    value: RecoveryCalculator.getStage(thisWeekAvg),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCell(ThemeData theme, {required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
