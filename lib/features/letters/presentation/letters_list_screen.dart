import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers/providers.dart';
import '../domain/unsent_letter.dart';
import 'letter_compose_screen.dart';

class LettersListScreen extends ConsumerWidget {
  const LettersListScreen({super.key});

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Expired';
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    return '${days}d ${hours}h left';
  }

  void _showLockedDialog(BuildContext context, UnsentLetter letter) {
    final theme = Theme.of(context);
    final unlockStr = DateFormat.yMMMMd().add_jm().format(letter.lockUntil!);
    final duration = letter.lockUntil!.difference(DateTime.now());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text('🔒', style: TextStyle(color: theme.colorScheme.primary)),
              const SizedBox(width: 8),
              const Text('Capsule Sealed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This letter is locked in a time capsule to help you resist the urge to contact your ex.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withAlpha(200),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(20),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'UNLOCKS ON',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.secondary.withAlpha(180),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      unlockStr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(duration),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'I Will Wait',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBurntLetterDetail(BuildContext context, UnsentLetter letter) {
    final theme = Theme.of(context);
    final burntStr = DateFormat.yMMMMd().add_jm().format(letter.burntAt ?? letter.createdAt);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.0),
          ),
          backgroundColor: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(
                color: theme.colorScheme.error.withAlpha(30),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🕊️ Released Emotion',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withAlpha(50),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        letter.category.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Burnt on $burntStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      letter.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(200),
                        fontStyle: FontStyle.italic,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    foregroundColor: theme.colorScheme.onSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: theme.colorScheme.outline.withAlpha(15),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeLettersProvider);
    final lockedAsync = ref.watch(lockedLettersProvider);
    final burntAsync = ref.watch(burntLettersProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Letters I’ll Never Send',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drafts', icon: Icon(Icons.edit_document)),
              Tab(text: 'Time Capsule', icon: Icon(Icons.lock_clock)),
              Tab(text: 'Released', icon: Icon(Icons.local_fire_department)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Active Drafts
            activeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyState(
                    context,
                    emoji: '📝',
                    title: 'No active drafts',
                    subtitle: 'Feel the urge to call or text your ex? Put those heavy words down here instead.',
                    buttonText: 'Write A Letter',
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LetterComposeScreen()),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final letter = list[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
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
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28.0),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LetterComposeScreen(letterId: letter.id),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.colorScheme.primaryContainer.withAlpha(120),
                                  child: Text(
                                    letter.category == 'Love'
                                        ? '❤️'
                                        : letter.category == 'Anger'
                                            ? '😡'
                                            : letter.category == 'Regret'
                                                ? '🥺'
                                                : '🕊️',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        letter.title.isEmpty ? 'Untitled Letter' : letter.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        letter.content,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Locked Capsules
            lockedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyState(
                    context,
                    emoji: '🔒',
                    title: 'No sealed letters',
                    subtitle: 'Lock a letter in the time capsule to lock away emotional triggers until you are ready to process them.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final letter = list[index];
                    final duration = letter.lockUntil!.difference(DateTime.now());
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28.0),
                          onTap: () => _showLockedDialog(context, letter),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: theme.colorScheme.secondaryContainer.withAlpha(120),
                                  child: Icon(
                                    Icons.lock_outline_rounded,
                                    color: theme.colorScheme.onSecondaryContainer,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Time Capsule',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: -0.1,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDuration(duration),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant.withAlpha(128)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Released (Burnt Archive)
            burntAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
              data: (list) {
                if (list.isEmpty) {
                  return _buildEmptyState(
                    context,
                    emoji: '🔥',
                    title: 'Release emotional baggage',
                    subtitle: 'Write down anger or regret, and burn the letter. Letting go of thoughts is the first step of healing.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final letter = list[index];
                    final dateStr = DateFormat.yMMMMd().format(letter.burntAt ?? letter.createdAt);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withAlpha(30),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: theme.colorScheme.error.withAlpha(15),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28.0),
                          onTap: () => _showBurntLetterDetail(context, letter),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.black12,
                                  child: Text('🔥', style: TextStyle(fontSize: 20)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        letter.title.isEmpty ? 'Released Letter' : letter.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          letterSpacing: -0.1,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Released on $dateStr',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.secondary.withAlpha(180),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.visibility_outlined, size: 16, color: theme.colorScheme.error.withAlpha(180)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'letters_fab',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LetterComposeScreen()),
          ),
          icon: const Icon(Icons.edit_rounded),
          label: const Text(
            'Write Letter',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
            side: BorderSide(
              color: theme.colorScheme.primary.withAlpha(30),
              width: 1,
            ),
          ),
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary.withAlpha(180),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
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
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
