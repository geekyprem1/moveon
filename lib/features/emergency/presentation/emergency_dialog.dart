import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_quotes.dart';
import '../../../utils/recovery_calculator.dart';

class EmergencyDialog extends StatelessWidget {
  final int streakDays;
  final double recoveryScore;

  const EmergencyDialog({
    super.key,
    required this.streakDays,
    required this.recoveryScore,
  });

  @override
  Widget build(BuildContext context) {
    final quote = AppQuotes.getRandomQuote();
    final stage = RecoveryCalculator.getStage(recoveryScore);
    final theme = Theme.of(context);
    final scoreColor = AppColors.getScoreColor(recoveryScore);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon & Title
            Row(
              children: [
                const Text(
                  '🕊️',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stay Strong',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // The Quote Box
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.colorScheme.primaryContainer.withAlpha(100),
                ),
              ),
              child: Text(
                '"$quote"',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            Row(
              children: [
                // Streak Stats
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$streakDays',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day Streak',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: theme.dividerTheme.color ?? Colors.grey.shade300,
                ),
                // Recovery score stats
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${recoveryScore.toInt()}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stage: $stage',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Action Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I Will Choose Myself',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
