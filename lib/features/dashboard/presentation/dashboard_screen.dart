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
    if (stage.contains('Shock')) return Icons.bolt_rounded;
    if (stage.contains('Withdrawal')) return Icons.sentiment_very_dissatisfied_rounded;
    if (stage.contains('Healing')) return Icons.opacity_rounded;
    if (stage.contains('Growth')) return Icons.spa_rounded;
    return Icons.wb_sunny_rounded;
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
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: isDone
            ? theme.colorScheme.surfaceContainerHighest.withAlpha(64)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? theme.colorScheme.outline.withAlpha(10)
              : theme.colorScheme.outline.withAlpha(25),
          width: 1,
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDone
                ? theme.colorScheme.surfaceContainerHighest.withAlpha(153)
                : theme.colorScheme.primaryContainer.withAlpha(51),
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
            fontSize: 15,
            fontWeight: isDone ? FontWeight.w400 : FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone
                ? theme.colorScheme.onSurface.withAlpha(102)
                : theme.colorScheme.onSurface,
            letterSpacing: -0.1,
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            ref.read(dashboardControllerProvider.notifier).toggleTask(task.id, !isDone);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDone ? theme.colorScheme.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDone ? theme.colorScheme.primary : theme.colorScheme.outline.withAlpha(102),
                width: 2,
              ),
            ),
            child: isDone
                ? Icon(Icons.check, size: 15, color: theme.colorScheme.onPrimary)
                : null,
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
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
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

          // Split greeting for rich typography styling
          final String greetingText = _getGreetingMessage(user.email);
          final parts = greetingText.split(', ');
          final String greetingPrefix = parts.first;
          final String namePart = parts.length > 1 ? parts.last : 'Friend';

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Welcome Greeting Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 24.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$greetingPrefix,\n',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w300,
                                  color: theme.colorScheme.onSurface.withAlpha(179),
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              TextSpan(
                                text: namePart,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: -1.0,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Take it one breath at a time today.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary.withAlpha(204),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Hero Circular Gauge Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(20),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.primaryContainer.withAlpha(10),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
                      child: Column(
                        children: [
                          // Circular Meter
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer Glow Ring or Background Track
                                SizedBox(
                                  width: 190,
                                  height: 190,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 10,
                                    color: theme.colorScheme.onSurface.withAlpha(13),
                                  ),
                                ),
                                // Outer Active Progress Ring
                                SizedBox(
                                  width: 190,
                                  height: 190,
                                  child: CircularProgressIndicator(
                                    value: recoveryScore / 100.0,
                                    strokeWidth: 10,
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
                                        fontSize: 72,
                                        fontWeight: FontWeight.w200,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: -2,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      streak == 1 ? 'DAY' : 'DAYS',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.secondary.withAlpha(204),
                                        letterSpacing: 3.0,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'STREAK',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 9,
                                        color: theme.colorScheme.secondary.withAlpha(128),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Stage & Progress Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Stage Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: scoreColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: scoreColor.withAlpha(51), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStageIcon(stage),
                                      size: 14,
                                      color: scoreColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      stage,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        color: scoreColor,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Score Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withAlpha(20),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Score: ${recoveryScore.toInt()}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Explanation Text
                          Text(
                            '60% No Contact Streak • 40% Mood Check-ins',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary.withAlpha(153),
                              fontSize: 11,
                              letterSpacing: 0.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(height: 1),
                          ),

                          // Shield Protection Badge (Premium Style)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: user.streakShieldsAvailable > 0
                                  ? Colors.green.withAlpha(13)
                                  : theme.colorScheme.surfaceContainerHighest.withAlpha(77),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: user.streakShieldsAvailable > 0
                                    ? Colors.green.withAlpha(51)
                                    : theme.colorScheme.outline.withAlpha(20),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.streakShieldsAvailable > 0
                                      ? Icons.verified_user_rounded
                                      : Icons.shield_outlined,
                                  size: 16,
                                  color: user.streakShieldsAvailable > 0
                                      ? Colors.green
                                      : theme.colorScheme.secondary.withAlpha(128),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  user.streakShieldsAvailable > 0
                                      ? 'Streak Shield Active (1 Freeze available)'
                                      : 'Shield Used (Recharging in 7 days)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: user.streakShieldsAvailable > 0
                                        ? Colors.green
                                        : theme.colorScheme.secondary.withAlpha(204),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Low-profile Break Link
                          GestureDetector(
                            onTap: () => _showResetDialog(context, ref, user),
                            child: Text(
                              'Broke No Contact? Reset Streak',
                              style: TextStyle(
                                  color: theme.colorScheme.error.withAlpha(204),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  letterSpacing: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Daily Mood Check-In Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(20),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How is your heart today?',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                            const SizedBox(height: 20),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withAlpha(38),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(20),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.favorite_rounded, size: 18, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getMoodMessage(todayMood),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurfaceVariant,
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
                  const SizedBox(height: 24),

                  // 4. Daily Healing Goals Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(20),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Healing Goals',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withAlpha(102),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_getCompletedCount(completedTasks)} / ${AppTasks.defaultTasks.length} Done',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...AppTasks.defaultTasks.map((task) {
                            final bool isDone = completedTasks.contains(task.id);
                            return _buildGoalTile(context, ref, task, isDone, theme);
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Journal Notes Card (Write to Heal)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.secondary.withAlpha(20),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer.withAlpha(102),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.edit_note_rounded,
                                  color: theme.colorScheme.onSecondaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Write to Heal',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pour your thoughts into your private journal.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.secondary.withAlpha(204),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: theme.colorScheme.secondary.withAlpha(153),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. SOS Safety Net Card (Emergency)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.error.withAlpha(31),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        colors: theme.brightness == Brightness.dark
                            ? [
                                theme.colorScheme.errorContainer.withAlpha(20),
                                theme.colorScheme.errorContainer.withAlpha(8),
                              ]
                            : [
                                const Color(0xFFFFF8F6),
                                const Color(0xFFFFF1EE),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.error.withAlpha(5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer.withAlpha(153),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.heart_broken_rounded,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Urge to contact your ex? 🆘',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onErrorContainer,
                                    fontSize: 16,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Before you text or call, take a pause. We have exercises, breathing guides, and delay timers ready to help you hold boundaries.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer.withAlpha(204),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                            icon: const Icon(Icons.favorite_rounded, size: 16),
                            label: const Text(
                              'Open Emergency Toolkit',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.1),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.errorContainer,
                              foregroundColor: theme.colorScheme.onErrorContainer,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 7. Recent Moods Timeline
                  if (moodHistory.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                      child: Text(
                        'Recent Mood Timeline',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.2,
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
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: AppColors.getScoreColor(
                                        RecoveryCalculator.getMoodValue(log.mood),
                                      ).withAlpha(153),
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
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                if (!isLast)
                                  Container(
                                    width: 1.5,
                                    height: 40,
                                    color: theme.colorScheme.outline.withAlpha(31),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 18),
                            // Log details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    log.mood,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isToday ? 'Today' : DateFormatter.formatDate(log.timestamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary.withAlpha(179),
                                      fontSize: 12,
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
    final borderCol = isSelected
        ? theme.colorScheme.primary.withAlpha(128)
        : Colors.transparent;
    final bgCol = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(153)
        : theme.colorScheme.surfaceContainerHighest.withAlpha(77);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 5.0),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: bgCol,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderCol,
                width: isSelected ? 2.0 : 0.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withAlpha(38),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withAlpha(204),
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
