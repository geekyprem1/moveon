import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../providers/providers.dart';
import '../../../utils/haptic_service.dart';
import '../../journal/domain/journal_entry.dart';
import 'coach_controller.dart';
import 'healing_orb.dart';

class SosExperienceView extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const SosExperienceView({super.key, required this.onClose});

  @override
  ConsumerState<SosExperienceView> createState() => _SosExperienceViewState();
}

class _SosExperienceViewState extends ConsumerState<SosExperienceView> with TickerProviderStateMixin {
  int _currentStep = 0;
  final int _totalSteps = 6;
  
  // Pause countdown timer (Step 2)
  int _pauseSeconds = 10;
  Timer? _pauseTimer;

  // Breathing variables (Step 3)
  int _breathingCountdownSeconds = 60;
  Timer? _breathingCountdownTimer;

  // Input Controllers
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _journalController = TextEditingController();

  String _chosenAlternative = "";

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _breathingCountdownTimer?.cancel();
    _reflectionController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  void _nextStep() {
    ref.read(hapticServiceProvider).selection();
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
      _onStepChanged();
    } else {
      _finishSos();
    }
  }

  void _onStepChanged() {
    if (_currentStep == 1) {
      // Start 10 seconds pause timer
      _pauseSeconds = 10;
      _pauseTimer?.cancel();
      _pauseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_pauseSeconds > 0) {
          setState(() {
            _pauseSeconds--;
          });
        } else {
          _pauseTimer?.cancel();
          _nextStep();
        }
      });
    } else if (_currentStep == 2) {
      // Start 60-second breathing exercise
      _startBreathingCountdown();
    }
  }

  void _startBreathingCountdown() {
    _breathingCountdownSeconds = 60;
    _breathingCountdownTimer?.cancel();
    _breathingCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_breathingCountdownSeconds > 0) {
          _breathingCountdownSeconds--;
        } else {
          _breathingCountdownTimer?.cancel();
          _nextStep();
        }
      });
    });
  }

  Future<void> _finishSos() async {
    ref.read(hapticServiceProvider).heavySuccess();
    
    String? journalId;
    if (_journalController.text.trim().isNotEmpty) {
      final user = ref.read(appUserProvider).value;
      if (user != null) {
        journalId = const Uuid().v4();
        final entry = JournalEntry(
          id: journalId,
          title: "SOS Relief Journal",
          note: _journalController.text.trim(),
          date: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(journalRepositoryProvider).saveJournal(user.uid, entry);
        ref.read(analyticsServiceProvider).logJournalCreated();
      }
    }

    // Save SOS log
    await ref.read(coachControllerProvider.notifier).completeSosLog(
      _reflectionController.text.isNotEmpty ? _reflectionController.text : "No Contact Urge",
      true, // Completed breathing
      journalId,
    );

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(appUserProvider).value;
    final streak = user?.noContactStreak ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF1E161C), // Deep Rose Charcoal
                  Color(0xFF151016), // Deep Amethyst Black
                  Color(0xFF0F0C10), // Midnight Obsidian
                ]
              : const [
                  Color(0xFFFFFDFB), // Warm Ivory
                  Color(0xFFFAF5FA), // Soft Lavender
                  Color(0xFFF6EFF2), // Dusty Rose
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
            color: theme.colorScheme.onSurface,
          ),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / (_totalSteps + 1),
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildStepContent(streak, theme),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_currentStep != 1 && _currentStep != 2) // Step 1 (Pause) and Step 2 (Breathing) proceed automatically
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                    ),
                    onPressed: _nextStep,
                    child: Text(
                      _currentStep == _totalSteps ? "Complete SOS" : "Continue",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(int streak, ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildValidationStep(theme);
      case 1:
        return _buildPauseStep(theme);
      case 2:
        return _buildBreathingStep(theme);
      case 3:
        return _buildReflectionStep(theme);
      case 4:
        return _buildStreakStep(streak, theme);
      case 5:
        return _buildAlternativeStep(theme);
      case 6:
        return _buildJournalStep(theme);
      default:
        return const SizedBox();
    }
  }

  // Step 1: Validate Feelings
  Widget _buildValidationStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite_rounded, size: 64, color: Color(0xFFE57373)),
        const SizedBox(height: 24),
        Text(
          "Let's take a moment.",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "I hear you, and it's completely okay to feel this urge right now. Urges are like waves—they peak, and then they pass. You don't have to fight it; let's just ride it out together.",
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Step 2: Create Pause
  Widget _buildPauseStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, size: 64, color: Color(0xFF64B5F6)),
        const SizedBox(height: 24),
        Text(
          "Creating a Pause",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Let's pause for 10 seconds before making any decisions. Just sit with your hands on your lap, and let this countdown finish.",
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              "$_pauseSeconds",
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step 3: Mindful Breathing
  Widget _buildBreathingStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Mindful Breathing",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          "Synchronize your breath with the expanding and glowing companion orb.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
        
        // Premium Breathing Orb
        const HealingOrb(isMini: false, isTyping: false),
        
        const SizedBox(height: 50),
        Text(
          "Rest your mind • $_breathingCountdownSeconds seconds remaining",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (60 - _breathingCountdownSeconds) / 60.0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  // Step 4: Reflection Question
  Widget _buildReflectionStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(Icons.psychology_outlined, size: 64, color: Color(0xFFFFB74D)),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "Inner Reflection",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "What is this urge trying to tell you? Are you feeling lonely, angry, sad, or just seeking closure?",
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _reflectionController,
          maxLines: 4,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: "I am feeling...",
            fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  // Step 5: Streak Reminder
  Widget _buildStreakStep(int streak, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shield_rounded, size: 70, color: Color(0xFF81C784)),
        const SizedBox(height: 24),
        Text(
          "Protect your progress",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(
                "$streak",
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Days of Space Kept",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Every day of space you give yourself is another day of rewiring triggers and reclaiming your independence. Let's protect this today.",
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Step 6: Alternative Actions
  Widget _buildAlternativeStep(ThemeData theme) {
    final alternatives = [
      {'icon': Icons.local_drink_rounded, 'label': 'Drink a cold glass of water'},
      {'icon': Icons.directions_walk_rounded, 'label': 'Go for a quick 5-min walk'},
      {'icon': Icons.air_rounded, 'label': 'Close your eyes and breathe for 1 min'},
      {'icon': Icons.call_rounded, 'label': 'Call a close friend or family member'},
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.alt_route_rounded, size: 64, color: Color(0xFF4DB6AC)),
        const SizedBox(height: 24),
        Text(
          "Alternative Action",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Instead of texting them, commit to doing one of these supportive activities right now:",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...alternatives.map((alt) {
          final isSelected = _chosenAlternative == alt['label'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _chosenAlternative = alt['label'] as String;
                });
                ref.read(hapticServiceProvider).selection();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      alt['icon'] as IconData,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        alt['label'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // Step 7: Encourage Journaling
  Widget _buildJournalStep(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Icon(Icons.edit_note_rounded, size: 64, color: Color(0xFFBA68C8)),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "Write it out",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "If you have something you desperately want to say to them, type it below instead. This will be safely locked in your journals, and never sent.",
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _journalController,
          maxLines: 6,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: "Dear Ex, I wanted to say...",
            fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}
