import 'dart:async';
import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_quotes.dart';

class EmergencyDialog extends StatefulWidget {
  final int streakDays;
  final double recoveryScore;

  const EmergencyDialog({
    super.key,
    required this.streakDays,
    required this.recoveryScore,
  });

  @override
  State<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends State<EmergencyDialog> {
  late final String _prompt;

  static const List<String> _journalPrompts = [
    "Write down three reasons why contacting them today might hurt your healing.",
    "What boundaries do you need to hold onto to protect your self-respect?",
    "If you could tell yourself one thing 6 months from now about this moment, what would it be?",
    "List the toxic patterns or values you two did not share.",
    "What are you feeling right now? Write it down completely to release it."
  ];

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _prompt = _journalPrompts[now.millisecondsSinceEpoch % _journalPrompts.length];
  }

  @override
  Widget build(BuildContext context) {
    final quote = AppQuotes.getRandomQuote();
    final theme = Theme.of(context);
    final scoreColor = AppColors.getScoreColor(widget.recoveryScore);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Row(
                children: [
                  const Text('🕊️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency Toolkit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Box Breathing Widget
              const _BoxBreathingWidget(),
              const SizedBox(height: 16),

              // 2. Statistics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat('Streak', '${widget.streakDays} Days', theme.colorScheme.primary, theme),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat('Recovery', '${widget.recoveryScore.toInt()}%', scoreColor, theme),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Motivational Quote
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primaryContainer.withAlpha(50),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REMINDER',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$quote"',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Therapeutic Journal Prompt
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JOURNAL PROMPT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.tertiary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _prompt,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Will Stay Strong',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxBreathingWidget extends StatefulWidget {
  const _BoxBreathingWidget();

  @override
  State<_BoxBreathingWidget> createState() => _BoxBreathingWidgetState();
}

class _BoxBreathingWidgetState extends State<_BoxBreathingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  Timer? _timer;
  int _secondsLeft = 4;
  int _phase = 0; // 0: In, 1: Hold (Full), 2: Out, 3: Hold (Empty)

  final List<String> _actions = ["Breathe In", "Hold", "Breathe Out", "Hold"];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _sizeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initial phase setup: Breathe In starts immediately
    _animationController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          // Switch phase
          _phase = (_phase + 1) % 4;
          _secondsLeft = 4;

          // Manage animations per phase
          if (_phase == 0) {
            _animationController.forward(from: 0.0);
          } else if (_phase == 1) {
            _animationController.value = 1.0;
          } else if (_phase == 2) {
            _animationController.reverse(from: 1.0);
          } else if (_phase == 3) {
            _animationController.value = 0.0;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = _actions[_phase];

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _sizeAnimation,
              builder: (context, child) {
                final double size = 70.0 * _sizeAnimation.value;
                return Container(
                  height: 70,
                  alignment: Alignment.center,
                  child: Container(
                    height: size,
                    width: size,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(60),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$_secondsLeft',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              action,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              '4-4-4-4 Box Breathing Guide',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}
