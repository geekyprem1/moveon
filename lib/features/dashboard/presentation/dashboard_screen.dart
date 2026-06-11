import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_tasks.dart';
import '../../../providers/providers.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/recovery_calculator.dart';
import '../../emergency/presentation/emergency_dialog.dart';
import '../../mood/domain/mood_entry.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Streak?'),
          content: const Text(
            'Did you break No Contact? This will reset your streak to 0 days. Be honest with yourself—it is part of the healing process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(dashboardControllerProvider.notifier).resetStreak();
                Navigator.of(context).pop();
              },
              child: Text(
                'Reset Streak',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencySupport(BuildContext context, WidgetRef ref, int streak, double score) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return EmergencyDialog(
          streakDays: streak,
          recoveryScore: score,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);
    final moodHistoryAsync = ref.watch(moodHistoryProvider);
    final completedTasksAsync = ref.watch(dailyCompletedTasksProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Move On',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => ref.read(dashboardControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('An error occurred: $error'),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found.'));
          }

          final moodHistory = moodHistoryAsync.value ?? [];
          final completedTasks = completedTasksAsync.value ?? {};

          // Calculations
          final int streak = user.noContactStreak;
          final double recoveryScore = RecoveryCalculator.calculateTotalScore(
            streakDays: streak,
            recentMoods: moodHistory,
          );
          final String stage = RecoveryCalculator.getStage(recoveryScore);
          final Color scoreColor = AppColors.getScoreColor(recoveryScore);

          // Find today's mood (if logged)
          final todayStr = DateFormatter.toDateString(DateTime.now());
          final todayMoodEntry = moodHistory.firstWhere(
            (m) => m.id == todayStr,
            orElse: () => MoodEntry(id: '', mood: '', timestamp: DateTime.now()),
          );
          final String todayMood = todayMoodEntry.mood;

          return RefreshIndicator(
            onRefresh: () async {
              // Trigger a sync of journals manually
              await ref.read(journalRepositoryProvider).syncJournals(user.uid);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Streak Progress Card
                  Card(
                    color: theme.colorScheme.primaryContainer.withAlpha(20),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            'NO CONTACT STREAK',
                            style: theme.textTheme.labelMedium?.copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$streak',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                streak == 1 ? 'Day' : 'Days',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _showResetDialog(context, ref),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Broke Contact? Reset'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error.withAlpha(100)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recovery Score Gauge Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recovery Progress',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: scoreColor.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  stage,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: scoreColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${recoveryScore.toInt()}%',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: recoveryScore / 100.0,
                                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                        color: scoreColor,
                                        minHeight: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '60% No Contact Streak • 40% Mood Check-ins',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Daily Mood Check-In Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'How are you feeling today?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MoodOption(
                                emoji: '😭',
                                label: 'Terrible',
                                isSelected: todayMood == 'Terrible',
                                onTap: () => ref
                                    .read(dashboardControllerProvider.notifier)
                                    .selectMood('Terrible'),
                              ),
                              _MoodOption(
                                emoji: '😢',
                                label: 'Sad',
                                isSelected: todayMood == 'Sad',
                                onTap: () => ref
                                    .read(dashboardControllerProvider.notifier)
                                    .selectMood('Sad'),
                              ),
                              _MoodOption(
                                emoji: '😐',
                                label: 'Okay',
                                isSelected: todayMood == 'Okay',
                                onTap: () => ref
                                    .read(dashboardControllerProvider.notifier)
                                    .selectMood('Okay'),
                              ),
                              _MoodOption(
                                emoji: '🙂',
                                label: 'Better',
                                isSelected: todayMood == 'Better',
                                onTap: () => ref
                                    .read(dashboardControllerProvider.notifier)
                                    .selectMood('Better'),
                              ),
                              _MoodOption(
                                emoji: '😁',
                                label: 'Great',
                                isSelected: todayMood == 'Great',
                                onTap: () => ref
                                    .read(dashboardControllerProvider.notifier)
                                    .selectMood('Great'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Daily Tasks Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Healing Goals',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...AppTasks.defaultTasks.map((task) {
                            final bool isDone = completedTasks.contains(task.id);
                            return CheckboxListTile(
                              value: isDone,
                              title: Text(task.title),
                              secondary: Text(task.icon, style: const TextStyle(fontSize: 20)),
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) {
                                if (val != null) {
                                  ref
                                      .read(dashboardControllerProvider.notifier)
                                      .toggleTask(task.id, val);
                                }
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Controls Row: Journal and Emergency
                  Row(
                    children: [
                      // Journal Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/journal'),
                          icon: const Icon(Icons.book_outlined),
                          label: const Text('Journal Notes'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            foregroundColor: theme.colorScheme.onSecondaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Emergency Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showEmergencySupport(
                            context,
                            ref,
                            streak,
                            recoveryScore,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: theme.colorScheme.errorContainer,
                            foregroundColor: theme.colorScheme.onErrorContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I Want To Contact My Ex',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Simple Mood History Header
                  if (moodHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Moods',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moodHistory.length > 5 ? 5 : moodHistory.length,
                      itemBuilder: (context, index) {
                        final log = moodHistory[index];
                        final isToday = log.id == todayStr;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            child: Text(
                              log.mood == 'Terrible'
                                  ? '😭'
                                  : log.mood == 'Sad'
                                      ? '😢'
                                      : log.mood == 'Okay'
                                          ? '😐'
                                          : log.mood == 'Better'
                                              ? '🙂'
                                              : '😁',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            log.mood,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isToday ? 'Today' : DateFormatter.formatDate(log.timestamp),
                          ),
                          trailing: Icon(
                            Icons.check_circle,
                            color: AppColors.getScoreColor(
                              RecoveryCalculator.getMoodValue(log.mood),
                            ),
                            size: 16,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderCol = isSelected ? theme.colorScheme.primary : Colors.transparent;
    final bgCol = isSelected ? theme.colorScheme.primaryContainer.withAlpha(100) : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderCol, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
