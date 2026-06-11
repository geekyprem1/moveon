import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_quotes.dart';
import '../../../providers/providers.dart';
import '../domain/emergency_click.dart';
import '../domain/sos_completion.dart';

class EmergencyDialog extends ConsumerStatefulWidget {
  final int streakDays;
  final double recoveryScore;

  const EmergencyDialog({
    super.key,
    required this.streakDays,
    required this.recoveryScore,
  });

  @override
  ConsumerState<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends ConsumerState<EmergencyDialog> {
  late final String _prompt;
  int _activeExerciseIndex = 0; // 0: Menu, 1: Box Breathing, 2: 4-7-8 Breathing, 3: Grounding, 4: 60s Delay, 5: Calming Sounds
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingSound; // 'rain' or 'white_noise' or null

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

    // Log the emergency button click
    Future.microtask(() {
      final user = ref.read(appUserProvider).value;
      if (user != null) {
        final repo = ref.read(emergencyRepositoryProvider);
        final click = EmergencyClick(
          id: const Uuid().v4(),
          timestamp: DateTime.now(),
          dayOfWeek: DateTime.now().weekday,
          hourOfDay: DateTime.now().hour,
        );
        repo.logEmergencyClick(user.uid, click);
      }
    });

    // Configure audioplayer looping
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(String soundType, String streamUrl) async {
    try {
      if (_currentPlayingSound == soundType) {
        await _audioPlayer.stop();
        setState(() {
          _currentPlayingSound = null;
        });
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(streamUrl));
        setState(() {
          _currentPlayingSound = soundType;
        });
        _logSosCompletion(soundType == 'rain' ? 'sound_rain' : 'sound_white_noise');
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _logSosCompletion(String exerciseId) {
    final user = ref.read(appUserProvider).value;
    if (user != null) {
      final repo = ref.read(emergencyRepositoryProvider);
      final completion = SosCompletion(
        id: const Uuid().v4(),
        exerciseId: exerciseId,
        timestamp: DateTime.now(),
      );
      repo.logSosCompletion(user.uid, completion);
      
      // Update completion notifier to refresh stats in real-time
      ref.invalidate(sosCompletionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = AppColors.getScoreColor(widget.recoveryScore);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row
                Row(
                  children: [
                    const Text('🕊️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeExerciseIndex == 0 ? 'Emergency Toolkit' : 'SOS Exercise',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_activeExerciseIndex != 0)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _activeExerciseIndex = 0;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active view based on index
                if (_activeExerciseIndex == 0) ...[
                  // 1. Statistics Grid
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

                  // 2. Motivational Quote
                  _buildPanel(
                    theme,
                    title: 'REMINDER',
                    content: '"${AppQuotes.getRandomQuote()}"',
                    titleColor: theme.colorScheme.secondary,
                    isItalic: true,
                  ),
                  const SizedBox(height: 12),

                  // 3. Therapeutic Journal Prompt
                  _buildPanel(
                    theme,
                    title: 'JOURNAL PROMPT',
                    content: _prompt,
                    titleColor: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(height: 20),

                  // 4. SOS Exercises Grid Menu
                  Text(
                    'Calm the Craving',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.6,
                    children: [
                      _buildExerciseMenuItem(
                        icon: '🌬️',
                        title: 'Box Breathing',
                        onTap: () => setState(() => _activeExerciseIndex = 1),
                        theme: theme,
                      ),
                      _buildExerciseMenuItem(
                        icon: '🎈',
                        title: '4-7-8 Breathing',
                        onTap: () => setState(() => _activeExerciseIndex = 2),
                        theme: theme,
                      ),
                      _buildExerciseMenuItem(
                        icon: '🧘',
                        title: 'Grounding 5-4-3-2-1',
                        onTap: () => setState(() => _activeExerciseIndex = 3),
                        theme: theme,
                      ),
                      _buildExerciseMenuItem(
                        icon: '⏱️',
                        title: '60s Delay Timer',
                        onTap: () => setState(() => _activeExerciseIndex = 4),
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Calming Sounds Quick Bar
                  _buildCalmingSoundsPanel(theme),
                  const SizedBox(height: 24),

                  // Close button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
                ] else if (_activeExerciseIndex == 1) ...[
                  // Box Breathing
                  _BoxBreathingWidget(
                    isBoxType: true,
                    onComplete: () => _logSosCompletion('breathing_box'),
                  ),
                ] else if (_activeExerciseIndex == 2) ...[
                  // 4-7-8 Breathing
                  _BoxBreathingWidget(
                    isBoxType: false,
                    onComplete: () => _logSosCompletion('breathing_4_7_8'),
                  ),
                ] else if (_activeExerciseIndex == 3) ...[
                  // Grounding
                  _GroundingWidget(
                    onComplete: () => _logSosCompletion('grounding_54321'),
                  ),
                ] else if (_activeExerciseIndex == 4) ...[
                  // 60s Delay
                  _DelayTimerWidget(
                    onComplete: () => _logSosCompletion('delay_60s'),
                  ),
                ],
              ],
            ),
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

  Widget _buildPanel(
    ThemeData theme, {
    required String title,
    required String content,
    required Color titleColor,
    bool isItalic = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.surfaceContainerHighest,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: isItalic ? FontStyle.italic : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(20),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalmingSoundsPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🎵'),
              const SizedBox(width: 8),
              Text(
                'Relaxing Ambience',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleSound(
                    'rain',
                    'https://www.soundjay.com/nature/sounds/rain-07.mp3',
                  ),
                  icon: Icon(
                    _currentPlayingSound == 'rain' ? Icons.stop : Icons.play_arrow,
                    size: 16,
                  ),
                  label: const Text('Rain Loop', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _currentPlayingSound == 'rain'
                        ? theme.colorScheme.primaryContainer
                        : null,
                    foregroundColor: _currentPlayingSound == 'rain'
                        ? theme.colorScheme.onPrimaryContainer
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleSound(
                    'white_noise',
                    'https://www.soundjay.com/misc/sounds/white-noise-01.mp3',
                  ),
                  icon: Icon(
                    _currentPlayingSound == 'white_noise' ? Icons.stop : Icons.play_arrow,
                    size: 16,
                  ),
                  label: const Text('White Noise', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _currentPlayingSound == 'white_noise'
                        ? theme.colorScheme.secondaryContainer
                        : null,
                    foregroundColor: _currentPlayingSound == 'white_noise'
                        ? theme.colorScheme.onSecondaryContainer
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Breathing Widget (Box Breathing & 4-7-8 Breathing)
// ----------------------------------------------------
class _BoxBreathingWidget extends StatefulWidget {
  final bool isBoxType; // true: Box (4-4-4-4), false: 4-7-8
  final VoidCallback onComplete;

  const _BoxBreathingWidget({
    required this.isBoxType,
    required this.onComplete,
  });

  @override
  State<_BoxBreathingWidget> createState() => _BoxBreathingWidgetState();
}

class _BoxBreathingWidgetState extends State<_BoxBreathingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;
  Timer? _timer;
  int _secondsLeft = 4;
  int _phase = 0; // Box: In, Hold, Out, Hold. 4-7-8: In, Hold, Out.
  int _cyclesCompleted = 0;

  // Configuration
  late final List<String> _actions;
  late final List<int> _durations;

  @override
  void initState() {
    super.initState();

    if (widget.isBoxType) {
      _actions = ["Breathe In", "Hold", "Breathe Out", "Hold"];
      _durations = [4, 4, 4, 4];
    } else {
      _actions = ["Breathe In", "Hold (Full)", "Exhale"];
      _durations = [4, 7, 8];
    }

    _secondsLeft = _durations[0];

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _durations[0]),
    );

    _sizeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

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
          _phase = (_phase + 1) % _actions.length;
          _secondsLeft = _durations[_phase];

          if (_phase == 0) {
            _cyclesCompleted++;
            if (_cyclesCompleted == 2) {
              widget.onComplete(); // Log completion event
            }
          }

          // Restart animation for phase
          _animationController.duration = Duration(seconds: _secondsLeft);
          if (widget.isBoxType) {
            if (_phase == 0) {
              _animationController.forward(from: 0.0);
            } else if (_phase == 1) {
              _animationController.value = 1.0;
            } else if (_phase == 2) {
              _animationController.reverse(from: 1.0);
            } else if (_phase == 3) {
              _animationController.value = 0.0;
            }
          } else {
            // 4-7-8
            if (_phase == 0) {
              _animationController.forward(from: 0.0);
            } else if (_phase == 1) {
              _animationController.value = 1.0;
            } else if (_phase == 2) {
              _animationController.reverse(from: 1.0);
            }
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _sizeAnimation,
            builder: (context, child) {
              final double size = 90.0 * _sizeAnimation.value;
              return Container(
                height: 90,
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
          const SizedBox(height: 12),
          Text(
            action,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isBoxType ? '4-4-4-4 Box Breathing' : '4-7-8 Breathing Technique',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Cycles Completed: $_cyclesCompleted',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Grounding Widget (5-4-3-2-1 Technique)
// ----------------------------------------------------
class _GroundingWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const _GroundingWidget({required this.onComplete});

  @override
  State<_GroundingWidget> createState() => _GroundingWidgetState();
}

class _GroundingWidgetState extends State<_GroundingWidget> {
  int _currentStep = 5; // Countdown steps: 5, 4, 3, 2, 1
  final List<List<bool>> _checkedItems = List.generate(6, (i) => List.filled(6, false));
  bool _isCompleted = false;

  final List<Map<String, dynamic>> _stepData = [
    {}, // Placeholder
    {
      'title': 'Taste 1 thing',
      'instruction': 'Identify 1 thing you can taste right now, or notice the current taste in your mouth.',
      'count': 1,
    },
    {
      'title': 'Smell 2 things',
      'instruction': 'Notice 2 distinct scents around you (coffee, soap, fresh air, fabric).',
      'count': 2,
    },
    {
      'title': 'Hear 3 sounds',
      'instruction': 'Close your eyes and listen. Identify 3 separate sounds (cars, wind, clock, hum).',
      'count': 3,
    },
    {
      'title': 'Feel 4 textures',
      'instruction': 'Touch 4 textures around you (clothes, wood grain, cold metal, warm skin).',
      'count': 4,
    },
    {
      'title': 'See 5 things',
      'instruction': 'Look around your environment. Identify 5 physical objects.',
      'count': 5,
    },
  ];

  void _nextStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
      widget.onComplete(); // Log completion
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isCompleted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text('✅', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Grounding Complete',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your nervous system has checked back into the present moment. The craving has lost some power.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final data = _stepData[_currentStep];
    final int count = data['count'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            data['title'],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data['instruction'],
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 12),
          // Checkboxes
          ...List.generate(count, (index) {
            return CheckboxListTile(
              value: _checkedItems[_currentStep][index],
              title: Text('Found item #${index + 1}', style: const TextStyle(fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  _checkedItems[_currentStep][index] = val ?? false;
                });
              },
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkedItems[_currentStep].take(count).contains(false) ? null : _nextStep,
            child: Text(_currentStep > 1 ? 'Next Step' : 'Done'),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 60-Second Delay Timer Widget
// ----------------------------------------------------
class _DelayTimerWidget extends StatefulWidget {
  final VoidCallback onComplete;

  const _DelayTimerWidget({required this.onComplete});

  @override
  State<_DelayTimerWidget> createState() => _DelayTimerWidgetState();
}

class _DelayTimerWidgetState extends State<_DelayTimerWidget> {
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isFinished = false;

  final List<String> _distractions = [
    "Breathing deeply... triggers pass in waves.",
    "Your future self will thank you for waiting.",
    "Postponing contact resets the craving cycle.",
    "You are worthy of moving forward. Keep waiting.",
    "You have survived 100% of your hardest cravings so far."
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _isFinished = true;
          _timer?.cancel();
          widget.onComplete(); // Log completion
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String prompt = _distractions[(_secondsLeft ~/ 12) % _distractions.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _secondsLeft / 60.0,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: theme.colorScheme.error,
                ),
                Text(
                  '$_secondsLeft',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isFinished ? 'Craving Delay Completed!' : 'Resist Urges For One Minute',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isFinished ? theme.colorScheme.primary : theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prompt,
            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
