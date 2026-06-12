import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/haptic_service.dart';
import '../../../providers/providers.dart';
import '../../../utils/recovery_calculator.dart';
import '../domain/coach_message.dart';
import 'coach_controller.dart';
import 'sos_experience_view.dart';
import 'healing_orb.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Rotating Input Placeholders
  final List<String> _placeholders = [
    "Tell me what's hurting today...",
    "What's weighing on your heart?",
    "I'm listening...",
    "Share what's on your mind...",
    "What feels hardest today?",
  ];
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;

  @override
  void initState() {
    super.initState();
    _startPlaceholderRotation();
  }

  void _startPlaceholderRotation() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _placeholderIndex = (_placeholderIndex + 1) % _placeholders.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _reflectionController.dispose();
    _scrollController.dispose();
    _placeholderTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _showLimitReachedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            children: [
              const Icon(Icons.lock_clock_outlined, color: Color(0xFFC76D6A)),
              const SizedBox(width: 12),
              Text(
                "Daily Limit Reached",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "You have used all 20 of your free messages for today. \n\nTake this as an invitation to pause, take a deep breath, and let your emotions settle. Break Coach will be here to guide you again tomorrow.",
            style: TextStyle(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(coachControllerProvider.notifier).clearError();
              },
              child: const Text(
                "Reflect & Close",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getTimeBasedGreetingPrefix() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  String _getQuoteForStage(String stage) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    
    final shockQuotes = [
      "Today is hard. That doesn't mean you're going backward.",
      "Feeling this pain is proof of your capacity to love deeply.",
      "Be gentle with yourself. You are in survival mode right now.",
      "Healing isn't a race. Just focus on getting through the next hour."
    ];
    
    final withdrawalQuotes = [
      "Missing someone doesn't mean you should go back.",
      "Your peace is worth more than a reply.",
      "An urge is just a feeling. It peaks, and then it passes.",
      "Choosing space is choosing yourself."
    ];
    
    final healingQuotes = [
      "Healing is not linear. Be patient with your progress.",
      "Space is where your new self is being built.",
      "You are rebuilding, piece by piece.",
      "Every day of silence is a day of rewiring your heart."
    ];
    
    final growthQuotes = [
      "You are reclaiming your independence, one day at a time.",
      "Growth is uncomfortable, but it is necessary.",
      "The version of you that is coming is stronger than the version that left.",
      "You are learning who you are outside of them."
    ];
    
    final moveOnQuotes = [
      "You are ready for the next chapter. Trust your path.",
      "The best is yet to come.",
      "You have survived the storm. Now, enjoy the calm.",
      "Your heart has healed. You are free."
    ];

    List<String> list;
    switch (stage.toLowerCase()) {
      case 'shock':
        list = shockQuotes;
        break;
      case 'withdrawal':
        list = withdrawalQuotes;
        break;
      case 'healing':
        list = healingQuotes;
        break;
      case 'growth':
        list = growthQuotes;
        break;
      case 'move-on':
      default:
        list = moveOnQuotes;
        break;
    }
    
    return list[dayOfYear % list.length];
  }

  String _getDynamicGreeting(String name, String stage) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final hour = DateTime.now().hour;
    
    final emotionalGreetings = [
      "How are you feeling today, $name?",
      "Let's get through today together.",
      "You don't have to carry this alone, $name.",
      "What's weighing on your heart right now?",
      "Healing starts with honesty, $name.",
      "Tell me what's hurting today.",
      "I'm here. I'm listening."
    ];
    
    if (hour >= 22 || hour < 5) {
      return [
        "Can't sleep, $name? What's on your mind?",
        "Midnight thoughts can be heavy. Let's talk.",
        "I'm here for you, even in the quiet hours."
      ][dayOfYear % 3];
    }
    
    return emotionalGreetings[dayOfYear % emotionalGreetings.length];
  }

  bool _isSosPhrase(String text) {
    final cleanText = text.toLowerCase().trim();
    final sosPhrases = [
      "want to text them",
      "want to text her",
      "want to text him",
      "want to call them",
      "want to call her",
      "want to call him",
      "miss them too much",
      "miss her too much",
      "miss him too much",
      "contact them",
      "contact her",
      "contact him",
      "reach out to them",
      "reach out to her",
      "reach out to him",
      "call my ex",
      "text my ex",
    ];
    return sosPhrases.any((phrase) => cleanText.contains(phrase));
  }

  void _showSosConfirmationDialog(BuildContext context, String originalText, List<CoachMessage> history) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: theme.colorScheme.surface,
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFC76D6A)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Take a Mindful Pause",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: const Text(
            "It sounds like you're experiencing a strong urge to reach out. Let's take a pause together. Would you like to enter SOS Mode to ride out this urge?",
            style: TextStyle(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Proceed with normal chat send
                _sendMessageDirectly(originalText, history);
              },
              child: Text(
                "No, just talk",
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Trigger SOS session
                ref.read(coachControllerProvider.notifier).startNewSession('SOS');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC76D6A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text(
                "Yes, enter SOS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final coachStateAsync = ref.watch(coachControllerProvider);
    final messagesAsync = ref.watch(coachMessagesProvider);
    final userAsync = ref.watch(appUserProvider);

    // Listen for error messages (specifically daily limits)
    ref.listen(coachControllerProvider, (previous, next) {
      next.whenData((data) {
        if (data.errorMessage == 'limit_reached') {
          ref.read(analyticsServiceProvider).logDailyLimitReached();
          _showLimitReachedDialog(context);
        } else if (data.errorMessage != null && data.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data.errorMessage!),
              backgroundColor: theme.colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: theme.colorScheme.onError,
                onPressed: () {
                  ref.read(coachControllerProvider.notifier).clearError();
                },
              ),
            ),
          );
        }
      });
    });

    return coachStateAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text("Failed to initialize Break Coach: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(coachControllerProvider),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
      data: (state) {
        // If active session is in SOS mode, display the full screen SOS view
        if (state.activeSession?.mode == 'SOS') {
          return SosExperienceView(
            onClose: () {
              ref.read(coachControllerProvider.notifier).startNewSession('TALK');
            },
          );
        }

        final user = userAsync.value;
        final userName = user?.name ?? "Prem";
        final streak = user?.noContactStreak ?? 0;
        
        // Calculate recovery stage based on streak and mood history
        final moods = ref.watch(moodHistoryProvider).value ?? [];
        final double score = RecoveryCalculator.calculateTotalScore(
          streakDays: streak,
          recentMoods: moods,
        );
        final stage = RecoveryCalculator.getStage(score);
        final quote = _getQuoteForStage(stage);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuad,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1.0 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF191318), // Dark Sakura
                        Color(0xFF110D12), // Deep Amethyst
                        Color(0xFF0C090D), // Midnight Black
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
                titleSpacing: 16,
                title: Row(
                  children: [
                    // Shrink companion orb and place inside appbar when chatting is active
                    if (messagesAsync.value != null && messagesAsync.value!.isNotEmpty) ...[
                      HealingOrb(isMini: true, isTyping: state.isLoading),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Break Coach",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "Your emotional AI companion",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Remaining mindful sessions count pill
                  Container(
                    margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: state.messagesRemaining <= 5
                          ? theme.colorScheme.errorContainer.withValues(alpha: 0.12)
                          : theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: state.messagesRemaining <= 5
                            ? theme.colorScheme.error.withValues(alpha: 0.3)
                            : theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      "${state.messagesRemaining} mindful sessions left",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: state.messagesRemaining <= 5
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // 1. Daily Reflection Card (if present and not completed)
                  if (state.dailyReflectionQuestion.isNotEmpty && !state.isReflectionCompleted)
                    _buildDailyReflectionCard(state, theme),

                  // 2. Main Chat / Companion stream
                  Expanded(
                    child: messagesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text("Error loading messages: $err")),
                      data: (messages) {
                        if (messages.isEmpty) {
                          return _buildGuidedEmptyState(userName, stage, quote, streak, theme);
                        }

                        // Scroll to bottom on updates
                        _scrollToBottom();

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: messages.length + 1, // Add emotional reinforcement footer
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return _buildEmotionalReinforcementFooter(theme);
                            }
                            
                            final msg = messages[index];
                            final isUser = msg.role == 'user';
                            return _AnimatedMessageBubble(
                              message: msg,
                              isUser: isUser,
                              child: _buildMessageBubble(msg, theme),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 3. Typing / Thought Indicator
                  if (state.isLoading)
                    _buildTypingIndicator(theme),

                  // 4. Custom Chat Input Panel
                  _buildInputPanel(state, messagesAsync.value ?? [], theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Guided Empty State Redesign (Headspace/Calm visual representation)
  Widget _buildGuidedEmptyState(
    String name,
    String stage,
    String quote,
    int streak,
    ThemeData theme,
  ) {
    final timeGreeting = _getTimeBasedGreetingPrefix();
    final greeting = _getDynamicGreeting(name, stage);

    final chips = [
      {
        'label': "💔 I Miss Them",
        'icon': Icons.favorite_border_rounded,
        'prompt': "I miss them so much today, and it feels like the ache won't go away. How can I sit with this feeling without reaching out?"
      },
      {
        'label': "📱 I Want To Text Them",
        'icon': Icons.chat_bubble_outline_rounded,
        'isSos': true
      },
      {
        'label': "😔 Feeling Lonely",
        'icon': Icons.sentiment_dissatisfied_rounded,
        'prompt': "I'm feeling incredibly lonely right now. The silence feels overwhelming. Can we talk about it?"
      },
      {
        'label': "😡 Feeling Angry",
        'icon': Icons.sentiment_very_dissatisfied_rounded,
        'prompt': "I feel so angry about how things ended and how I was treated. How can I release this anger safely?"
      },
      {
        'label': "🧠 Help Me Stop Overthinking",
        'icon': Icons.psychology_outlined,
        'prompt': "I'm stuck in a loop overthinking everything that went wrong. How do I stop my mind from racing?"
      },
      {
        'label': "❤️ I Need Encouragement",
        'icon': Icons.volunteer_activism_outlined,
        'prompt': "I feel discouraged and like I'm making no progress today. Could you share some words of comfort?"
      }
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. Personalization Card
          _PersonalizationCard(
            name: name,
            greetingPrefix: timeGreeting,
            streak: streak,
            stage: stage,
            quote: quote,
          ),
          
          const SizedBox(height: 32),
          
          // 2. Healing Breathing Orb
          const HealingOrb(isMini: false, isTyping: false),
          
          const SizedBox(height: 20),
          
          Text(
            "Feel your breath. I'm listening.",
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 32),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              greeting,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 3. Spaced Quick Action Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: chips.map((chip) {
                final isSos = chip['isSos'] == true;
                return _AnimatedActionChip(
                  label: chip['label'] as String,
                  icon: chip['icon'] as IconData?,
                  isSos: isSos,
                  onPressed: () {
                    if (isSos) {
                      ref.read(hapticServiceProvider).medium();
                      ref.read(coachControllerProvider.notifier).startNewSession('SOS');
                    } else {
                      ref.read(hapticServiceProvider).selection();
                      final promptText = chip['prompt'] as String;
                      _sendMessageDirectly(promptText, []);
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Emotional Reinforcement Footer
  Widget _buildEmotionalReinforcementFooter(ThemeData theme) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final reinforcements = [
      "You showed up for yourself today.",
      "You resisted the urge. That matters.",
      "Progress isn't always visible.",
      "Small steps still count.",
      "Every moment of peace is a step forward.",
      "Be gentle with your healing heart."
    ];
    final text = reinforcements[dayOfYear % reinforcements.length];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.spa_outlined,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.secondary.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Glassmorphic Daily Reflection Prompt Card
  Widget _buildDailyReflectionCard(CoachState state, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 18, color: Color(0xFFC76D8A)),
              const SizedBox(width: 8),
              Text(
                "Daily Healing Reflection",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.dailyReflectionQuestion,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.dailyReflectionPrompt,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reflectionController,
            maxLines: 2,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: "Reflect and write here...",
              filled: true,
              fillColor: theme.colorScheme.surface.withValues(alpha: 0.65),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha(30),
                  width: 0.8,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                final text = _reflectionController.text.trim();
                if (text.isNotEmpty) {
                  ref.read(coachControllerProvider.notifier).submitReflection(text);
                  _reflectionController.clear();
                  ref.read(hapticServiceProvider).success();
                }
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text(
                "Save Reflection",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFC76D8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Chat Message Guidance Card Layout
  Widget _buildMessageBubble(CoachMessage msg, ThemeData theme) {
    final isUser = msg.role == 'user';
    final isDark = theme.brightness == Brightness.dark;
    
    if (isUser) {
      // User bubble remains minimal and clean
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ),
      );
    }

    // AI messages as elegant Guidance Cards
    final cardBgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF1E1720), Color(0xFF140F15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFFDFB), Color(0xFFFAF5FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          gradient: cardBgGradient,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(24),
          ),
          border: Border.all(
            color: const Color(0xFFC76D8A).withValues(alpha: 0.18),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guidance signature tag
            Row(
              children: [
                const Icon(Icons.spa_rounded, color: Color(0xFFC76D8A), size: 14),
                const SizedBox(width: 6),
                Text(
                  "MINDFUL COMPANION",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFC76D8A),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              msg.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55, // Larger line height for maximum readability
                color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmering typing indicator
  Widget _buildTypingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BouncingDots(),
            const SizedBox(width: 12),
            Text(
              "Companion is reflecting...",
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Premium Custom Chat Input panel
  Widget _buildInputPanel(CoachState state, List<CoachMessage> history, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 22, top: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.15)
            : theme.colorScheme.surface.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // SOS Quick Shortcut
            GestureDetector(
              onTap: () {
                ref.read(hapticServiceProvider).medium();
                ref.read(coachControllerProvider.notifier).startNewSession('SOS');
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC76D6A).withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFFC76D6A), size: 22),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: _placeholders[_placeholderIndex],
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surface.withValues(alpha: 0.4)
                      : theme.colorScheme.surface.withValues(alpha: 0.85),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (text) => _sendMessage(text, history),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                onPressed: () => _sendMessage(_messageController.text, history),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String text, List<CoachMessage> history) {
    if (text.trim().isEmpty) return;
    
    // Proactive intercept for SOS keywords
    if (_isSosPhrase(text)) {
      _showSosConfirmationDialog(context, text.trim(), history);
    } else {
      _sendMessageDirectly(text.trim(), history);
    }
  }

  void _sendMessageDirectly(String text, List<CoachMessage> history) {
    ref.read(hapticServiceProvider).light();
    ref.read(coachControllerProvider.notifier).sendMessage(text, history);
    _messageController.clear();
  }
}

// Bouncing Dots Widget for Typing/Thought state
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -6.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.65),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// Animated Scale Action Chips
class _AnimatedActionChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSos;
  final VoidCallback onPressed;

  const _AnimatedActionChip({
    required this.label,
    this.icon,
    this.isSos = false,
    required this.onPressed,
  });

  @override
  State<_AnimatedActionChip> createState() => _AnimatedActionChipState();
}

class _AnimatedActionChipState extends State<_AnimatedActionChip> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: widget.isSos
            ? const LinearGradient(
                colors: [Color(0xFFE57373), Color(0xFFC76D6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: widget.isSos
            ? null
            : (isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.3)
                : theme.colorScheme.surface.withValues(alpha: 0.65)),
        border: Border.all(
          color: widget.isSos
              ? Colors.transparent
              : theme.colorScheme.outline.withValues(alpha: isDark ? 20 : 40),
          width: 0.8,
        ),
        boxShadow: widget.isSos
            ? [
                BoxShadow(
                  color: const Color(0xFFC76D6A).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              size: 16,
              color: widget.isSos ? Colors.white : theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: widget.isSos
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _scale = 0.94;
        });
      },
      onTapUp: (_) {
        setState(() {
          _scale = 1.0;
        });
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() {
          _scale = 1.0;
        });
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: chipContent,
      ),
    );
  }
}

// Custom Premium Personalization Card
class _PersonalizationCard extends StatelessWidget {
  final String name;
  final String greetingPrefix;
  final int streak;
  final String stage;
  final String quote;

  const _PersonalizationCard({
    required this.name,
    required this.greetingPrefix,
    required this.streak,
    required this.stage,
    required this.quote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.2)
            : theme.colorScheme.surface.withValues(alpha: 0.55),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: isDark ? 15 : 35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$greetingPrefix, $name",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFC76D8A).withValues(alpha: 0.12),
                ),
                child: Text(
                  "$streak days of choosing yourself",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFC76D8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                ),
                child: Text(
                  "Recovery Stage: $stage",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// Slide-up fade-in animation for message bubbles
class _AnimatedMessageBubble extends StatelessWidget {
  final CoachMessage message;
  final bool isUser;
  final Widget child;

  const _AnimatedMessageBubble({
    required this.message,
    required this.isUser,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1.0 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
