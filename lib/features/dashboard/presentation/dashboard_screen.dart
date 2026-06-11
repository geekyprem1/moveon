import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_tasks.dart';
import '../../../providers/providers.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/recovery_calculator.dart';
import '../../../utils/review_prompt_manager.dart';
import '../../auth/domain/app_user.dart';
import '../../emergency/presentation/emergency_dialog.dart';
import '../../mood/domain/mood_entry.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showResetDialog(BuildContext context, WidgetRef ref, AppUser user) {
    final bool hasShield = user.streakShieldsAvailable > 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Streak?'),
          content: Text(
            hasShield
                ? 'Did you break No Contact? You have a Streak Freeze Shield available! Using it will protect your streak so you don’t reset to 0.'
                : 'Did you break No Contact? This will reset your streak to 0 days. Be honest with yourself—it is part of the healing process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (hasShield)
              TextButton(
                onPressed: () async {
                  final success = await ref
                      .read(dashboardControllerProvider.notifier)
                      .useStreakShield();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🛡️ Streak protected by Freeze Shield!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Use Shield',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            TextButton(
              onPressed: () {
                ref.read(dashboardControllerProvider.notifier).resetStreak();
                Navigator.of(context).pop();
              },
              child: Text(
                'Reset to 0',
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

  String _getGreetingMessage(String email) {
    final name = email.split('@').first;
    final displayName = name.isNotEmpty
        ? '${name[0].toUpperCase()}${name.substring(1)}'
        : 'Friend';
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, $displayName';
    } else if (hour < 17) {
      return 'Good Afternoon, $displayName';
    } else {
      return 'Good Evening, $displayName';
    }
  }

  IconData _getStageIcon(String stage) {
    if (stage.contains('Shock')) return Icons.bolt;
    if (stage.contains('Withdrawal')) return Icons.sentiment_very_dissatisfied;
    if (stage.contains('Healing')) return Icons.opacity;
    if (stage.contains('Growth')) return Icons.spa;
    return Icons.wb_sunny;
  }

  String _getMoodMessage(String mood) {
    switch (mood) {
      case 'Terrible':
        return "It's okay to cry. Healing is not linear, and we are right here with you. 🤍";
      case 'Sad':
        return "Take it easy today. You are allowed to feel this pain. It will pass. 🌸";
      case 'Okay':
        return "A calm, neutral day is progress too. You're holding up well. 🍃";
      case 'Better':
        return "You are starting to breathe again. Proud of your steps! ✨";
      case 'Great':
        return "Hold onto this light. You are reclaiming your joy. 🌟";
      default:
        return "Your feelings are valid. Take care of yourself today.";
    }
  }

  int _getCompletedCount(Set<String> completedTasks) {
    int count = 0;
    for (var task in AppTasks.defaultTasks) {
      if (completedTasks.contains(task.id)) {
        count++;
      }
    }
    return count;
  }

  Widget _buildGoalTile(
    BuildContext context,
    WidgetRef ref,
    AppTaskItem task,
    bool isDone,
    ThemeData theme,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: isDone
            ? theme.colorScheme.surfaceContainerHighest.withAlpha(40)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? theme.colorScheme.outline.withAlpha(10)
              : theme.colorScheme.outline.withAlpha(30),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDone
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.primaryContainer.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: Text(
            task.icon,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone
                ? theme.colorScheme.secondary.withAlpha(150)
                : theme.colorScheme.onSurface,
          ),
        ),
        trailing: Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: isDone,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (val) {
              if (val != null) {
                ref.read(dashboardControllerProvider.notifier).toggleTask(task.id, val);
              }
            },
          ),
        ),
      ),
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

          // Trigger shield check and review prompt after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(dashboardControllerProvider.notifier).checkAndRefillShields();

            final journalsCount = ref.read(journalListProvider).value?.length ?? 0;
            ReviewPromptManager.checkAndShow(
              context,
              user: user,
              journalsCount: journalsCount,
              moodLogsCount: moodHistory.length,
            );
          });

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(journalRepositoryProvider).syncJournals(user.uid);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome Greeting Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 16.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreetingMessage(user.email),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Take it one breath at a time today.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Hero Circular Gauge Card
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer.withAlpha(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withAlpha(30),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
                      child: Column(
                        children: [
                          // Circular Meter
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Glow Ring or Background Track
                                SizedBox(
                                  width: 170,
                                  height: 170,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 12,
                                    color: theme.colorScheme.primary.withAlpha(20),
                                  ),
                                ),
                                // Outer Active Progress Ring
                                SizedBox(
                                  width: 170,
                                  height: 170,
                                  child: CircularProgressIndicator(
                                    value: recoveryScore / 100.0,
                                    strokeWidth: 12,
                                    color: scoreColor,
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                // Inner Content (Streak Days)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$streak',
                                      style: theme.textTheme.displayLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: theme.colorScheme.primary,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      streak == 1 ? 'DAY' : 'DAYS',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'STREAK',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 9,
                                        color: theme.colorScheme.secondary.withAlpha(180),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Stage & Progress Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Stage Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scoreColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: scoreColor.withAlpha(100), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStageIcon(stage),
                                      size: 14,
                                      color: scoreColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      stage,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: scoreColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Score Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Score: ${recoveryScore.toInt()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Explanation Text
                          Text(
                            '60% No Contact Streak • 40% Mood Check-ins',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Divider(height: 32, indent: 16, endIndent: 16),

                          // Shield Protection Badge (Premium Style)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: user.streakShieldsAvailable > 0
                                  ? Colors.green.withAlpha(15)
                                  : Colors.grey.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: user.streakShieldsAvailable > 0
                                    ? Colors.green.withAlpha(50)
                                    : Colors.grey.withAlpha(50),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.streakShieldsAvailable > 0
                                      ? Icons.shield
                                      : Icons.shield_outlined,
                                  size: 16,
                                  color: user.streakShieldsAvailable > 0
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.streakShieldsAvailable > 0
                                      ? 'Streak Shield Active (1 Freeze available)'
                                      : 'Shield Used (Recharging in 7 days)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: user.streakShieldsAvailable > 0
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Low-profile Break Link
                          GestureDetector(
                            onTap: () => _showResetDialog(context, ref, user),
                            child: Text(
                              'Broke No Contact? Reset Streak',
                              style: TextStyle(
                                color: theme.colorScheme.error.withAlpha(200),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. Daily Mood Check-In Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(20),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'How is your heart today?',
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
                          if (todayMood.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getMoodMessage(todayMood),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Daily Healing Goals Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(20),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Healing Goals',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_getCompletedCount(completedTasks)} / ${AppTasks.defaultTasks.length} Completed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...AppTasks.defaultTasks.map((task) {
                            final bool isDone = completedTasks.contains(task.id);
                            return _buildGoalTile(context, ref, task, isDone, theme);
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Journal Notes Card (Write to Heal)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: theme.colorScheme.secondary.withAlpha(30),
                        width: 1,
                      ),
                    ),
                    color: theme.colorScheme.secondaryContainer.withAlpha(20),
                    child: InkWell(
                      onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.book_outlined,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Write to Heal',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pour your thoughts into your private journal.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. SOS Safety Net Card (Emergency)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: theme.colorScheme.error.withAlpha(40),
                        width: 1.5,
                      ),
                    ),
                    color: theme.colorScheme.errorContainer.withAlpha(25),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.heart_broken,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Urge to contact your ex? 🆘',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Before you text or call, take a pause. We have exercises, breathing guides, and delay timers ready to help you hold boundaries.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer.withAlpha(200),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(analyticsServiceProvider).logEmergencyClicked();
                              _showEmergencySupport(
                                context,
                                ref,
                                streak,
                                recoveryScore,
                              );
                            },
                            icon: const Icon(Icons.shield_outlined),
                            label: const Text('Open Emergency Toolkit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.errorContainer,
                              foregroundColor: theme.colorScheme.onErrorContainer,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7. Recent Moods Timeline
                  if (moodHistory.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                      child: Text(
                        'Recent Mood Timeline',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: moodHistory.length > 5 ? 5 : moodHistory.length,
                      itemBuilder: (context, index) {
                        final log = moodHistory[index];
                        final isToday = log.id == todayStr;
                        final isLast = index == (moodHistory.length > 5 ? 4 : moodHistory.length - 1);

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline stem/indicator
                            Column(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.getScoreColor(
                                        RecoveryCalculator.getMoodValue(log.mood),
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
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
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 2,
                                    height: 36,
                                    color: theme.colorScheme.outline.withAlpha(30),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Log details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.mood,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    isToday ? 'Today' : DateFormatter.formatDate(log.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ],
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
    final borderCol = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(40);
    final bgCol = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(120)
        : theme.colorScheme.surface;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol, width: isSelected ? 2.0 : 1.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}
