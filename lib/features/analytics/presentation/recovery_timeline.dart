import 'package:flutter/material.dart';

class RecoveryTimeline extends StatelessWidget {
  final int streakDays;

  const RecoveryTimeline({super.key, required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Milestone definitions
    final List<Map<String, dynamic>> milestones = [
      {'days': 0, 'title': 'Breakup Day', 'desc': 'The start of your healing journey.'},
      {'days': 7, 'title': '7 Days Strong', 'desc': 'First week of emotional distance.'},
      {'days': 30, 'title': '30 Days Survivor', 'desc': 'One month of rewiring habit triggers.'},
      {'days': 60, 'title': '60 Days Healing', 'desc': 'Two months of detachment and clarity.'},
      {'days': 90, 'title': '90 Days Warrior', 'desc': 'Three months of emotional safety.'},
      {'days': 180, 'title': '180 Days Rebuilt', 'desc': 'Half a year of self-discovery.'},
      {'days': 365, 'title': '365 Days Transformed', 'desc': 'One full year of total release.'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recovery Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Day $streakDays',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tracks your progression milestones since starting No Contact.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),

            // Stepper timeline list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: milestones.length,
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                final int mDays = milestone['days'];
                final bool isCompleted = streakDays >= mDays;
                
                // Determine if this is the active in-progress milestone
                bool isInProgress = false;
                if (index > 0) {
                  final int prevDays = milestones[index - 1]['days'];
                  isInProgress = streakDays > prevDays && streakDays < mDays;
                } else if (streakDays == 0 && index == 0) {
                  isInProgress = true;
                }

                return _buildTimelineStep(
                  context,
                  title: milestone['title'],
                  desc: milestone['desc'],
                  days: mDays,
                  isCompleted: isCompleted,
                  isInProgress: isInProgress,
                  isLast: index == milestones.length - 1,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required String title,
    required String desc,
    required int days,
    required bool isCompleted,
    required bool isInProgress,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    
    // Node style
    final Color nodeColor = isCompleted
        ? theme.colorScheme.primary
        : isInProgress
            ? theme.colorScheme.secondary
            : theme.colorScheme.surfaceContainerHighest;

    final Widget nodeIcon = isCompleted
        ? const Icon(Icons.check, size: 14, color: Colors.white)
        : isInProgress
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              )
            : const Icon(Icons.lock, size: 12, color: Colors.grey);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? theme.colorScheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: nodeColor,
                    width: 2,
                  ),
                ),
                child: Center(child: nodeIcon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? theme.colorScheme.onSurface
                              : isInProgress
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.secondary.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        days == 0 ? 'Day 0' : '$days Days',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isCompleted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isCompleted
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                  if (isInProgress) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: streakDays / days.toDouble(),
                        minHeight: 4,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day $streakDays of $days days completed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
