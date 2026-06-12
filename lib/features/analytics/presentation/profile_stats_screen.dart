import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../providers/providers.dart';
import '../../../utils/recovery_calculator.dart';
import '../../../utils/haptic_service.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/referral_system_dialog.dart';
import '../../auth/presentation/legal_screens.dart';
import '../../dashboard/presentation/feedback_dialog.dart';
import '../data/achievement_service.dart';
import 'mood_chart.dart';
import 'recovery_timeline.dart';
import 'craving_heatmap.dart';
import 'achievement_share_sheet.dart';
import 'weekly_summary_card.dart';
import 'growth_analytics_dashboard.dart';

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
    final clicksAsync = ref.watch(emergencyClicksProvider);

    final theme = Theme.of(context);
    final user = userAsync.value;
    final isAdmin = user != null &&
        (user.email == 'geekyprem1@gmail.com' || user.email == 'geekyprem4@gmail.com');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Healing Path',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.developer_mode_rounded),
              tooltip: 'Dev Analytics',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GrowthAnalyticsDashboard(),
                  ),
                );
              },
            ),
        ],
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
          final clicks = clicksAsync.value ?? [];

          // Calculations
          final double recoveryScore = RecoveryCalculator.calculateTotalScore(
            streakDays: user.noContactStreak,
            recentMoods: moods,
          );
          final double moodImprovement = RecoveryCalculator.calculateMoodImprovement(
            moods,
            user.initialPainScore ?? 5,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(appUserProvider);
              ref.invalidate(moodHistoryProvider);
              ref.invalidate(journalListProvider);
              ref.invalidate(completedTasksCountProvider);
              ref.invalidate(emergencyClicksProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Header Info Container
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withAlpha(80),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('👤', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.name ?? user.email,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          if (user.name != null && user.name!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary.withAlpha(180),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Breakup Type: ${user.breakupType ?? 'N/A'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary.withAlpha(180),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Referral Code & Invites
                  _buildReferralCard(context, user, theme),
                  const SizedBox(height: 24),

                  // Statistics Grid Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Healing Path',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            children: [
                              _buildStatItem('Days of Space', '${user.noContactStreak} Days', theme.colorScheme.primary, theme),
                              _buildStatItem('Longest Peace', '${user.longestStreak} Days', theme.colorScheme.secondary, theme),
                              _buildStatItem('Reflection Logs', '$journalsCount', theme.colorScheme.tertiary, theme),
                              _buildStatItem('Mood Logs', '${moods.length}', Colors.orange, theme),
                              _buildStatItem('Task Days', '$completedTasksDays', Colors.green, theme),
                              _buildStatItem('Healing Alignment', '${recoveryScore.toInt()}%', AppColors.getScoreColor(recoveryScore), theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Progress Summary Card
                  WeeklySummaryCard(moods: moods),
                  const SizedBox(height: 24),

                  // 1. Recovery Timeline
                  RecoveryTimeline(streakDays: user.noContactStreak),
                  const SizedBox(height: 24),

                  // Sanctuary Wisdom Insights Card
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sanctuary Wisdom',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.1,
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
                            title: 'Longest Peace',
                            desc: 'Your longest Days of Space record is ${user.longestStreak} days.',
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
                  const SizedBox(height: 24),

                  // Mood Charts Section
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mood Analytics',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.1,
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
                          const SizedBox(height: 16),
                          MoodChart(moods: moods, days: _selectedChartDays),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Craving Heatmap Section
                  CravingHeatmap(clicks: clicks),
                  const SizedBox(height: 24),

                  // Settings & GDPR Privacy Card
                  _buildSettingsPrivacyCard(context, ref, user, theme),
                  const SizedBox(height: 24),

                  // Achievement Badges Section
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: theme.colorScheme.outline.withAlpha(15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievements & Milestones',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap any unlocked achievement to share your milestone.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary.withAlpha(180),
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
                              return _buildBadgeWidget(context, badge, isUnlocked, theme);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(20),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.secondary.withAlpha(140),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w300,
              color: color,
              fontSize: 20,
              letterSpacing: 0.5,
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer.withAlpha(80),
            child: Text(icon, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withAlpha(180),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeWidget(BuildContext context, BadgeDefinition badge, bool isUnlocked, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: isUnlocked
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(25),
                  theme.colorScheme.secondary.withAlpha(15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isUnlocked
            ? null
            : theme.colorScheme.onSurface.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? theme.colorScheme.primary.withAlpha(40)
              : theme.colorScheme.outline.withAlpha(10),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AchievementShareSheet(badge: badge),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isUnlocked ? 1.0 : 0.25,
                  child: Text(
                    badge.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
                    color: isUnlocked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary.withAlpha(128),
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCard(BuildContext context, AppUser user, ThemeData theme) {
    final hasReferred = user.referredBy != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Support Recovery Together 🤝',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Invite a friend to unlock the Sakura Theme and a Community Supporter badge.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary.withAlpha(180),
                fontSize: 12,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR REFERRAL CODE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.secondary.withAlpha(150),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.referralCode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy Code',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: user.referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (hasReferred)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Referred by: ${user.referredBy}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => ReferralSystemDialog(user: user),
                  );
                },
                icon: const Icon(Icons.group_add_rounded, size: 18),
                label: const Text('Enter Friend’s Code', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withAlpha(30),
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUserData(BuildContext context, WidgetRef ref, AppUser user) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final firestore = FirebaseFirestore.instance;
      
      // Fetch data
      final journalsSnap = await firestore.collection('users').doc(user.uid).collection('journals').get();
      final lettersSnap = await firestore.collection('users').doc(user.uid).collection('letters').get();
      final moodsSnap = await firestore.collection('users').doc(user.uid).collection('moods').get();
      final clicksSnap = await firestore.collection('users').doc(user.uid).collection('emergency_clicks').get();

      final Map<String, dynamic> data = {
        'profile': user.toJson(),
        'journals': journalsSnap.docs.map((doc) => doc.data()).toList(),
        'letters': lettersSnap.docs.map((doc) => doc.data()).toList(),
        'moods': moodsSnap.docs.map((doc) => doc.data()).toList(),
        'emergency_clicks': clicksSnap.docs.map((doc) => doc.data()).toList(),
      };

      // Convert to pretty JSON string
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      // Create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/moveon_export_${user.uid.substring(0, 5)}.json');
      await tempFile.writeAsString(jsonStr);

      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loader
      }

      // Share it using share_plus
      final xFile = XFile(tempFile.path);
      // ignore: deprecated_member_use
      await Share.shareXFiles([xFile], text: 'Move On Recovery Data Export');
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export data: $e')),
        );
      }
    }
  }

  void _showThemeSelectionDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final latestUserAsync = ref.watch(appUserProvider);
            final latestUser = latestUserAsync.value ?? user;
            final hasSakuraUnlocked = latestUser.unlockedAchievements.contains('referral_supporter');
            final theme = Theme.of(context);

            return AlertDialog(
              title: const Text('Theme Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLOR PALETTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle, color: Color(0xFF673AB7)),
                      title: const Text('Classic Theme'),
                      subtitle: const Text('Calming purple design'),
                      trailing: latestUser.selectedTheme == 'classic'
                           ? Icon(Icons.radio_button_checked, color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_off),
                      onTap: () async {
                        final updatedUser = latestUser.copyWith(selectedTheme: 'classic');
                        await ref.read(authRepositoryProvider).updateUser(updatedUser);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.circle, color: Color(0xFFE91E63)),
                      title: Row(
                        children: [
                          const Text('Sakura Blossom'),
                          if (!hasSakuraUnlocked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock, size: 14, color: Colors.grey),
                          ],
                        ],
                      ),
                      subtitle: const Text('Unlock via referral rewards'),
                      trailing: latestUser.selectedTheme == 'sakura'
                          ? Icon(Icons.radio_button_checked, color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_off),
                      enabled: hasSakuraUnlocked,
                      onTap: () async {
                        final updatedUser = latestUser.copyWith(selectedTheme: 'sakura');
                        await ref.read(authRepositoryProvider).updateUser(updatedUser);
                      },
                    ),
                    const Divider(height: 24),
                    Text(
                      'THEME MODE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.brightness_auto_outlined),
                      title: const Text('System Default'),
                      subtitle: const Text('Follow phone\'s system settings'),
                      trailing: latestUser.themeMode == 'system'
                          ? Icon(Icons.radio_button_checked, color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_off),
                      onTap: () async {
                        final updatedUser = latestUser.copyWith(themeMode: 'system');
                        await ref.read(authRepositoryProvider).updateUser(updatedUser);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.light_mode_outlined),
                      title: const Text('Light Mode'),
                      trailing: latestUser.themeMode == 'light'
                          ? Icon(Icons.radio_button_checked, color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_off),
                      onTap: () async {
                        final updatedUser = latestUser.copyWith(themeMode: 'light');
                        await ref.read(authRepositoryProvider).updateUser(updatedUser);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      trailing: latestUser.themeMode == 'dark'
                          ? Icon(Icons.radio_button_checked, color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_off),
                      onTap: () async {
                        final updatedUser = latestUser.copyWith(themeMode: 'dark');
                        await ref.read(authRepositoryProvider).updateUser(updatedUser);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, AppUser user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account? ⚠️'),
          content: const Text(
            'This action is permanent and GDPR-compliant. It will permanently delete your authentication record and wipe ALL your data, journals, moods, tasks, and letters from our servers. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                ref.read(hapticServiceProvider).warning();
                Navigator.of(context).pop(); // Dismiss first dialog
                
                // Show a loading overlay
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final authRepo = ref.read(authRepositoryProvider);
                  
                  // 1. Wipe Firestore data
                  await authRepo.wipeUserData(user.uid);
                  
                  // 2. Delete Auth Account
                  final firebaseUser = FirebaseAuth.instance.currentUser;
                  if (firebaseUser != null) {
                    await firebaseUser.delete();
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop(); // Dismiss loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account permanently deleted. Goodbye.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Dismiss loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account (Requires fresh login): $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Permanently Delete',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsPrivacyCard(BuildContext context, WidgetRef ref, AppUser user, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha(15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Settings & GDPR Privacy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 12),

            // Theme Selection
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('App Theme'),
              subtitle: Text(
                'Color: ${user.selectedTheme == 'sakura' ? 'Sakura' : 'Classic'} • Mode: ${user.themeMode[0].toUpperCase()}${user.themeMode.substring(1)}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _showThemeSelectionDialog(context, ref, user),
            ),
            const Divider(),

            SwitchListTile(
              secondary: const Icon(Icons.vibration_outlined),
              title: const Text('Premium Haptics'),
              subtitle: const Text('Intentional, calming tactile feedback', style: TextStyle(fontSize: 11)),
              value: user.hapticsEnabled,
              onChanged: (val) async {
                final updatedUser = user.copyWith(hapticsEnabled: val);
                await ref.read(authRepositoryProvider).updateUser(updatedUser);
                if (val) {
                  ref.read(hapticServiceProvider).selection();
                }
              },
            ),
            const Divider(),
            
            // 1. Share Feedback
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Share App Feedback'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => FeedbackDialog(user: user),
                );
              },
            ),
            const Divider(),

            // 2. Export Data (Data Portability)
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export My Data (JSON)'),
              subtitle: const Text('Download all journals, letters, and moods', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => _exportUserData(context, ref, user),
            ),
            const Divider(),

            // 3. Privacy Policy
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => LegalScreens.showPrivacyPolicy(context),
            ),
            const Divider(),

            // 4. Terms of Service
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => LegalScreens.showTermsOfService(context),
            ),
            const Divider(),

            // 5. Delete Account (Right to be Forgotten)
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Delete My Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: const Text('Permanently erase all data from servers', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
              onTap: () => _showDeleteAccountDialog(context, ref, user),
            ),
          ],
        ),
      ),
    );
  }
}
