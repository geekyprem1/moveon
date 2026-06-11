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
          title: const Row(
            children: [
              Text('🔒'),
              SizedBox(width: 8),
              Text('Capsule Sealed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This letter is locked in a time capsule to help you resist the urge to contact your ex.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'UNLOCKS ON',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unlockStr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Will Wait'),
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
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.red.shade900.withAlpha(120), width: 1.5),
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        letter.category.toUpperCase(),
                        style: TextStyle(
                          color: Colors.red.shade300,
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
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      letter.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade300,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
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
            style: TextStyle(fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.all(12.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final letter = list[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          letter.title.isEmpty ? 'Untitled Letter' : letter.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          letter.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            letter.category == 'Love'
                                ? '❤️'
                                : letter.category == 'Anger'
                                    ? '😡'
                                    : letter.category == 'Regret'
                                        ? '🥺'
                                        : '🕊️',
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LetterComposeScreen(letterId: letter.id),
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
                  padding: const EdgeInsets.all(12.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final letter = list[index];
                    final duration = letter.lockUntil!.difference(DateTime.now());
                    return Card(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                      child: ListTile(
                        title: Text(
                          'Time Capsule (Sealed)',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          _formatDuration(duration),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.lock, color: Colors.white),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showLockedDialog(context, letter),
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
                  padding: const EdgeInsets.all(12.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final letter = list[index];
                    final dateStr = DateFormat.yMMMMd().format(letter.burntAt ?? letter.createdAt);
                    return Card(
                      color: Colors.red.shade900.withValues(alpha: 0.15),
                      child: ListTile(
                        title: Text(
                          letter.title.isEmpty ? 'Burnt Letter' : letter.title,
                          style: TextStyle(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text('Burnt on $dateStr'),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: Text('🔥', style: TextStyle(fontSize: 18)),
                        ),
                        trailing: const Icon(Icons.visibility, size: 18),
                        onTap: () => _showBurntLetterDetail(context, letter),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'letters_fab',
          child: const Icon(Icons.add),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LetterComposeScreen()),
          ),
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(buttonText),
            ),
          ],
        ],
      ),
    );
  }
}
