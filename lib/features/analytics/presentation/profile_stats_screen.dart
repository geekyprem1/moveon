import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/providers.dart';
import '../../../utils/recovery_calculator.dart';
import '../data/achievement_service.dart';
import 'mood_chart.dart';

class ProfileStatsScreen extends ConsumerStatefulWidget {
  const ProfileStatsScreen({super.key});

  @override
  ConsumerState<ProfileStatsScreen> createState() => _ProfileStatsScreenState();
}

class _ProfileStatsScreenState extends ConsumerState<ProfileStatsScreen> {
  int _selectedChartDays = 7;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(appUserProvider);
    final moodsAsync = ref.watch(moodHistoryProvider);
    final journalsAsync = ref.watch(journalListProvider);
    final completedTasksCountAsync = ref.watch(completedTasksCountProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recovery Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User profile not found'));
          }

          final moods = moodsAsync.value ?? [];
          final journalsCount = journalsAsync.value?.length ?? 0;
          final completedTasksDays = completedTasksCountAsync.value ?? 0;

          // Calculations
          final double recoveryScore = RecoveryCalculator.calculateTotalScore(
            streakDays: user.noContactStreak,
            recentMoods: moods,
          );
          final double moodImprovement = RecoveryCalculator.calculateMoodImprovement(
            moods,
            user.initialPainScore ?? 5,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Header Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          child: Text('👤', style: TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.email,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Breakup Type: ${user.breakupType ?? 'N/A'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Statistics Grid Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Statistics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _buildStatItem('Streak', '${user.noContactStreak} Days', theme.colorScheme.primary, theme),
                            _buildStatItem('Longest Streak', '${user.longestStreak} Days', theme.colorScheme.secondary, theme),
                            _buildStatItem('Journal Notes', '$journalsCount', theme.colorScheme.tertiary, theme),
                            _buildStatItem('Mood Logs', '${moods.length}', Colors.orange, theme),
                            _buildStatItem('Task Days', '$completedTasksDays', Colors.green, theme),
                            _buildStatItem('Recovery %', '${recoveryScore.toInt()}%', AppColors.getScoreColor(recoveryScore), theme),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Recovery Insights Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recovery Insights',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInsightItem(
                          icon: '📈',
                          title: 'Mood Improvement',
                          desc: moodImprovement > 0
                              ? 'Your mood improved by ${moodImprovement.toInt()}% since onboarding.'
                              : moodImprovement < 0
                                  ? 'Your mood is down by ${moodImprovement.abs().toInt()}% compared to starting wellness.'
                                  : 'Mood trend is stable. Continue checking in daily.',
                          theme: theme,
                        ),
                        _buildInsightItem(
                          icon: '💪',
                          title: 'Healing Activity',
                          desc: 'You completed self-care tasks on $completedTasksDays different days.',
                          theme: theme,
                        ),
                        _buildInsightItem(
                          icon: '🔥',
                          title: 'Longest Streak',
                          desc: 'Your longest No Contact record is ${user.longestStreak} days.',
                          theme: theme,
                        ),
                        _buildInsightItem(
                          icon: '🌟',
                          title: 'Strongest Period',
                          desc: moods.isEmpty
                              ? 'Log your mood to see your strongest recovery period.'
                              : 'Your recent average wellness score is ${((RecoveryCalculator.calculateMoodScore(moods)) / 10).toStringAsFixed(1)} / 10.',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Mood Charts Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mood Analytics',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 7, label: Text('7d')),
                                ButtonSegment(value: 30, label: Text('30d')),
                              ],
                              selected: {_selectedChartDays},
                              onSelectionChanged: (Set<int> newSelection) {
                                setState(() {
                                  _selectedChartDays = newSelection.first;
                                });
                              },
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MoodChart(moods: moods, days: _selectedChartDays),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Achievement Badges Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements & Milestones',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: AchievementService.badges.length,
                          itemBuilder: (context, index) {
                            final badge = AchievementService.badges[index];
                            final isUnlocked = user.unlockedAchievements.contains(badge.id);
                            return _buildBadgeWidget(badge, isUnlocked, theme);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required String icon,
    required String title,
    required String desc,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer.withAlpha(80),
            child: Text(icon, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeWidget(BadgeDefinition badge, bool isUnlocked, ThemeData theme) {
    final double opacity = isUnlocked ? 1.0 : 0.35;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? theme.colorScheme.primaryContainer.withAlpha(40) 
            : theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked 
              ? theme.colorScheme.primary.withAlpha(100) 
              : Colors.transparent,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 36,
                  color: isUnlocked ? null : Colors.grey,
                ).copyWith(color: isUnlocked ? null : Colors.grey.withValues(alpha: opacity)),
              ),
              if (!isUnlocked)
                const Icon(
                  Icons.lock,
                  color: Colors.white70,
                  size: 20,
                  shadows: [],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isUnlocked 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.secondary.withValues(alpha: opacity),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
