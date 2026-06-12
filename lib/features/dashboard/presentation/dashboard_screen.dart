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
import '../../../utils/haptic_service.dart';
import 'celebration_overlay.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showResetDialog(BuildContext context, WidgetRef ref, AppUser user) {
    final bool hasShield = user.streakShieldsAvailable > 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Begin Anew?'),
          content: Text(
            hasShield
                ? 'Have you chosen to create space today, or did you reach out? You have a Compassion Cushion available. Applying grace will protect your Days of Space.'
                : 'Have you chosen to create space today, or did you reach out? Starting fresh is not a failure—it is a gentle continuation of your healing spiral. Be honest with your heart.',
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
                          content: Text('🌸 Days of Space protected by Compassion Cushion.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Apply Grace',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            TextButton(
              onPressed: () {
                ref.read(hapticServiceProvider).warning();
                ref.read(dashboardControllerProvider.notifier).resetStreak();
                Navigator.of(context).pop();
              },
              child: Text(
                'Start Fresh',
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

  String _getGreetingMessage(String? name, String email) {
    final String displayName;
    if (name != null && name.trim().isNotEmpty) {
      displayName = name.trim();
    } else {
      String username = email.split('@').first;
      // Remove trailing numbers (e.g. geekyprem4 -> geekyprem)
      username = username.replaceAll(RegExp(r'\d+$'), '');
      // Replace dots, underscores, dashes with space
      username = username.replaceAll(RegExp(r'[._-]'), ' ').trim();
      // Capitalize each word
      displayName = username.isNotEmpty
          ? username.split(' ').map((word) {
              if (word.isEmpty) return '';
              return '${word[0].toUpperCase()}${word.substring(1)}';
            }).join(' ')
          : 'Friend';
    }

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



  Widget _buildCategoryHeader(BuildContext context, String title, String emoji, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 14.0, bottom: 8.0),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.secondary.withAlpha(200),
              letterSpacing: 1.5,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionReward(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.amber.withAlpha(80),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(25),
            Colors.amber.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'A Moment of Grace',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Text('✨', style: TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You held space for your Heart, Mind, and Body today. Healing is not about speed; it is about these small, brave choices. Rest deeply.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
            ? theme.colorScheme.primaryContainer.withAlpha(15)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone
              ? theme.colorScheme.primary.withAlpha(25)
              : theme.colorScheme.onSurface.withAlpha(10),
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDone
                ? theme.colorScheme.primaryContainer.withAlpha(50)
                : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
            shape: BoxShape.circle,
          ),
          child: Text(
            task.icon,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDone
                ? theme.colorScheme.onSurface.withAlpha(120)
                : theme.colorScheme.onSurface,
            letterSpacing: -0.1,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            task.healingInsight,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(isDone ? 100 : 150),
            ),
          ),
        ),
        trailing: GestureDetector(
          onTap: () {
            final nextState = !isDone;
            
            // Check if this completes all daily tasks (success haptic + overlay)
            bool completesAll = false;
            final dailyTasks = ref.read(dailyCompletedTasksProvider).value ?? {};
            final date = DateTime.now();
            final todayRituals = AppTasks.getDailyRituals(date);
            
            if (nextState) {
              final prospectiveCompleted = Set<String>.from(dailyTasks)..add(task.id);
              final todayIds = todayRituals.map((r) => r.id).toSet();
              if (todayIds.every((id) => prospectiveCompleted.contains(id))) {
                completesAll = true;
              }
            }

            if (completesAll) {
              ref.read(hapticServiceProvider).success();
              // Show celebration overlay
              final user = ref.read(appUserProvider).value;
              final currentXp = user?.healingXp ?? 0;
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black.withAlpha(220),
                  pageBuilder: (context, _, __) => CelebrationOverlay(
                    currentXp: currentXp + 5, // Account for this completion
                    onDismiss: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            } else {
              ref.read(hapticServiceProvider).medium();
            }

            ref.read(dashboardControllerProvider.notifier).toggleTask(task.id, nextState);
            if (nextState) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text('+5 Healing XP Earned (${task.completedVerb}!)'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  width: 280,
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isDone
                ? Container(
                    key: const ValueKey('done'),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withAlpha(80), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 12, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          task.completedVerb,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: const ValueKey('undone'),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                  ),
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

    // Listen to dashboard state errors
    ref.listen<AsyncValue<void>>(dashboardControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        },
      );
    });

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

          final todayRituals = AppTasks.getDailyRituals(DateTime.now());
          int completedCount = 0;
          for (var task in todayRituals) {
            if (completedTasks.contains(task.id)) {
              completedCount++;
            }
          }

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
          final String greetingText = _getGreetingMessage(user.name, user.email);
          final parts = greetingText.split(', ');
          final String greetingPrefix = parts.first;
          final String namePart = parts.length > 1 ? parts.last : 'Friend';

          final bool isDark = theme.brightness == Brightness.dark;

          // Dynamic Next Milestone Math
          String nextMilestoneName = '3 Days Strong';
          int daysRemaining = 3 - streak;
          if (streak >= 3 && streak < 7) {
            nextMilestoneName = '7 Days Strong';
            daysRemaining = 7 - streak;
          } else if (streak >= 7 && streak < 14) {
            nextMilestoneName = '14 Days Strong';
            daysRemaining = 14 - streak;
          } else if (streak >= 14 && streak < 30) {
            nextMilestoneName = '30 Days Strong';
            daysRemaining = 30 - streak;
          } else if (streak >= 30 && streak < 60) {
            nextMilestoneName = '60 Days Strong';
            daysRemaining = 60 - streak;
          } else if (streak >= 60 && streak < 90) {
            nextMilestoneName = '90 Days Strong';
            daysRemaining = 90 - streak;
          } else if (streak >= 90) {
            nextMilestoneName = '120 Days Strong';
            daysRemaining = 120 - streak;
          }

          // SOS Card explicit colors to prevent low-contrast fallback bugs
          final Color sosBg = isDark
              ? const Color(0xFF2C1E21) // deep dark warm brown/red
              : const Color(0xFFFFF5F3); // soft warm peach

          final Color sosBorder = isDark
              ? const Color(0xFF5C3F43) // dark warm red border
              : const Color(0xFFF9DEDC); // light warm red border

          final Color sosTitle = isDark
              ? const Color(0xFFFFB4AB) // light warm red
              : const Color(0xFF601410); // deep warm burgundy

          final Color sosDesc = isDark
              ? const Color(0xFFFFDAD6) // soft peach-white
              : const Color(0xFF801815); // rich dark red

          final Color sosIconBg = isDark
              ? const Color(0xFF442B2D)
              : const Color(0xFFF9DEDC);

          final Color sosIconColor = isDark
              ? const Color(0xFFFFB4AB)
              : const Color(0xFFB3261E);

          final Color sosBtnBg = isDark
              ? const Color(0xFFB3261E) // red button
              : const Color(0xFFB3261E);

          final Color sosBtnText = Colors.white;

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
                  // 1. Welcome Greeting Header (Calm/Stoic Warm greeting style)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 28.0, top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greetingPrefix 👋',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: theme.colorScheme.onSurface.withAlpha(179),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          namePart,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Welcome to your sanctuary. Take it one breath at a time.",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary.withAlpha(204),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Hero Progress Ring & Recovery Card Container
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withAlpha(15),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surface,
                          theme.colorScheme.primaryContainer.withAlpha(5),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 24.0),
                      child: Column(
                        children: [
                          _StreakProgressRing(
                            streak: streak,
                            recoveryScore: recoveryScore,
                            scoreColor: scoreColor,
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
                                  'Peace Index: ${recoveryScore.toInt()}%',
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

                          // Dynamic Next Milestone Card (motivating visual support)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withAlpha(51),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(15),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NEXT MILESTONE',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.secondary.withAlpha(180),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        nextMilestoneName,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  daysRemaining > 0 
                                      ? '$daysRemaining ${daysRemaining == 1 ? 'day' : 'days'} left'
                                      : 'Unlocked!',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
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
                                      ? 'Compassion Cushion Active (1 Grace available)'
                                      : 'Cushion Recharging (Restoring in 7 days)',
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

                  // 3. Daily Mood Check-In Card (Stoic style selector)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
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
                                onTap: () {
                                  ref.read(hapticServiceProvider).selection();
                                  ref.read(dashboardControllerProvider.notifier).selectMood('Terrible');
                                },
                              ),
                              _MoodOption(
                                emoji: '😢',
                                label: 'Sad',
                                isSelected: todayMood == 'Sad',
                                onTap: () {
                                  ref.read(hapticServiceProvider).selection();
                                  ref.read(dashboardControllerProvider.notifier).selectMood('Sad');
                                },
                              ),
                              _MoodOption(
                                emoji: '😐',
                                label: 'Okay',
                                isSelected: todayMood == 'Okay',
                                onTap: () {
                                  ref.read(hapticServiceProvider).selection();
                                  ref.read(dashboardControllerProvider.notifier).selectMood('Okay');
                                },
                              ),
                              _MoodOption(
                                emoji: '🙂',
                                label: 'Better',
                                isSelected: todayMood == 'Better',
                                onTap: () {
                                  ref.read(hapticServiceProvider).selection();
                                  ref.read(dashboardControllerProvider.notifier).selectMood('Better');
                                },
                              ),
                              _MoodOption(
                                emoji: '😁',
                                label: 'Great',
                                isSelected: todayMood == 'Great',
                                onTap: () {
                                  ref.read(hapticServiceProvider).selection();
                                  ref.read(dashboardControllerProvider.notifier).selectMood('Great');
                                },
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

                  // 4. Daily Healing Goals Card (Polished task checklist)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
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
                                "Today's Healing Journey",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withAlpha(102),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '✨ ${user.healingXp} XP',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: todayRituals.isEmpty ? 0 : completedCount / todayRituals.length,
                              minHeight: 8,
                              backgroundColor: theme.colorScheme.onSurface.withAlpha(15),
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$completedCount of ${todayRituals.length} Completed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary.withAlpha(200),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${((todayRituals.isEmpty ? 0 : completedCount / todayRituals.length) * 100).toInt()}% Complete',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          // Milestone Emotional Message
                          if (completedCount > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withAlpha(15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text('🌸', style: TextStyle(fontSize: 14)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      completedCount == 1
                                          ? 'You showed up for yourself today.'
                                          : completedCount == 2
                                              ? 'Healing happens through small steps.'
                                              : 'Today, you chose yourself. ✨',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          // Heart Tasks
                          _buildCategoryHeader(context, 'Heart', '💖', theme),
                          ...todayRituals
                              .where((task) => task.category == 'Heart')
                              .map((task) {
                            final bool isDone = completedTasks.contains(task.id);
                            return _buildGoalTile(context, ref, task, isDone, theme);
                          }),
                          const SizedBox(height: 8),
                          // Mind Tasks
                          _buildCategoryHeader(context, 'Mind', '🧠', theme),
                          ...todayRituals
                              .where((task) => task.category == 'Mind')
                              .map((task) {
                            final bool isDone = completedTasks.contains(task.id);
                            return _buildGoalTile(context, ref, task, isDone, theme);
                          }),
                          const SizedBox(height: 8),
                          // Body Tasks
                          _buildCategoryHeader(context, 'Body', '🌿', theme),
                          ...todayRituals
                              .where((task) => task.category == 'Body')
                              .map((task) {
                            final bool isDone = completedTasks.contains(task.id);
                            return _buildGoalTile(context, ref, task, isDone, theme);
                          }),
                          // Completion Reward Card
                          if (completedCount == todayRituals.length && todayRituals.isNotEmpty)
                            _buildCompletionReward(context, theme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. Journal Notes Card (Write to Heal Card)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                        borderRadius: BorderRadius.circular(28),
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

                  // 6. SOS Safety Net Card (Emergency Sanctuary Card)
                  Container(
                    decoration: BoxDecoration(
                      color: sosBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: sosBorder.withAlpha(80),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
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
                                  color: sosIconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.heart_broken_rounded,
                                  color: sosIconColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Seeking Stillness? 🤍',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: sosTitle,
                                    fontSize: 16,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Before you reach out, take a slow breath. Let this urge pass like a wave. We are here to hold this space with you.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: sosDesc,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(hapticServiceProvider).light();
                              ref.read(analyticsServiceProvider).logEmergencyClicked();
                              _showEmergencySupport(
                                context,
                                ref,
                                streak,
                                recoveryScore,
                              );
                            },
                            icon: Icon(Icons.favorite_rounded, size: 16, color: sosBtnText),
                            label: const Text(
                              'Enter the Sanctuary',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.1),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: sosBtnBg,
                              foregroundColor: sosBtnText,
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
                        'Your Emotional Flow',
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
        ? theme.colorScheme.primary.withAlpha(120)
        : theme.colorScheme.onSurface.withAlpha(15);
    final bgCol = isSelected
        ? theme.colorScheme.primaryContainer.withAlpha(120)
        : theme.colorScheme.surfaceContainerHighest.withAlpha(45);

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
                width: isSelected ? 1.5 : 1.0,
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

class _StreakProgressRing extends StatefulWidget {
  final int streak;
  final double recoveryScore;
  final Color scoreColor;

  const _StreakProgressRing({
    required this.streak,
    required this.recoveryScore,
    required this.scoreColor,
  });

  @override
  State<_StreakProgressRing> createState() => _StreakProgressRingState();
}

class _StreakProgressRingState extends State<_StreakProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft glowing backdrop
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.scoreColor.withAlpha(25),
                    widget.scoreColor.withAlpha(5),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            // Custom Painter Sunrise Illustration
            Container(
              width: 172,
              height: 172,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: _SanctuarySunrisePainter(
                  primaryColor: widget.scoreColor,
                  secondaryColor: theme.colorScheme.secondary,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
            ),
            SizedBox(
              width: 190,
              height: 190,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 8,
                color: theme.colorScheme.onSurface.withAlpha(15),
              ),
            ),
            SizedBox(
              width: 190,
              height: 190,
              child: CircularProgressIndicator(
                value: widget.recoveryScore / 100.0,
                strokeWidth: 8,
                color: widget.scoreColor,
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.streak}',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 88,
                    fontWeight: FontWeight.w100,
                    color: theme.colorScheme.primary,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.streak == 1 ? 'DAY' : 'DAYS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.secondary.withAlpha(200),
                    letterSpacing: 4.0,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'OF SPACE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 8,
                    color: theme.colorScheme.secondary.withAlpha(120),
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SanctuarySunrisePainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  _SanctuarySunrisePainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Draw glowing sun in center/back
    final sunCenter = Offset(size.width / 2, size.height * 0.65);
    final sunPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          primaryColor.withAlpha(70),
          secondaryColor.withAlpha(15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: size.width * 0.45));
    canvas.drawCircle(sunCenter, size.width * 0.45, sunPaint);

    // 2. Draw background hill path
    final bgHillPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.6, size.width * 0.75, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.8, size.width, size.height * 0.7)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = secondaryColor.withAlpha(20);
    canvas.drawPath(bgHillPath, paint);

    // 3. Draw foreground hill path
    final fgHillPath = Path()
      ..moveTo(0, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.75, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = primaryColor.withAlpha(30);
    canvas.drawPath(fgHillPath, paint);

    // 4. Draw a tiny bird or wave ripples for peace
    final birdPaint = Paint()
      ..color = primaryColor.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Bird 1
    final bird1Path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.33, size.height * 0.37, size.width * 0.36, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.39, size.height * 0.37, size.width * 0.42, size.height * 0.4);
    canvas.drawPath(bird1Path, birdPaint);

    // Bird 2
    final bird2Path = Path()
      ..moveTo(size.width * 0.65, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.67, size.height * 0.33, size.width * 0.69, size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.71, size.height * 0.33, size.width * 0.73, size.height * 0.35);
    canvas.drawPath(bird2Path, birdPaint);
  }

  @override
  bool shouldRepaint(covariant _SanctuarySunrisePainter oldDelegate) => false;
}
