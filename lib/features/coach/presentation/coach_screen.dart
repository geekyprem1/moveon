import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/haptic_service.dart';
import '../../../providers/providers.dart';
import '../domain/coach_message.dart';
import 'coach_controller.dart';
import 'sos_experience_view.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _reflectionController.dispose();
    _scrollController.dispose();
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
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(coachControllerProvider.notifier).clearError();
              },
              child: const Text("Reflect & Close"),
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

        return Container(
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
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Break Coach",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    "A calm voice when emotions get loud.",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.secondary.withAlpha(200),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                // Display remaining message limit pill
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.messagesRemaining <= 5
                        ? theme.colorScheme.errorContainer.withAlpha(120)
                        : theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: state.messagesRemaining <= 5
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary.withAlpha(50),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    "${state.messagesRemaining} / 20 left",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

                // 2. Chat Message Stream
                Expanded(
                  child: messagesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text("Error loading messages: $err")),
                    data: (messages) {
                      if (messages.isEmpty) {
                        return _buildEmptyState(theme);
                      }

                      // Scroll to bottom on updates
                      _scrollToBottom();

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _buildMessageBubble(msg, theme);
                        },
                      );
                    },
                  ),
                ),

                // 3. Typing Indicator
                if (state.isLoading)
                  _buildTypingIndicator(theme),

                // 4. Input Panel
                _buildInputPanel(state, messagesAsync.value ?? [], theme),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build Daily Reflection Prompt Card
  Widget _buildDailyReflectionCard(CoachState state, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withAlpha(120),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_stories_outlined, size: 20, color: Color(0xFFC76D8A)),
                const SizedBox(width: 8),
                Text(
                  "Daily Healing Prompt",
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              state.dailyReflectionQuestion,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.dailyReflectionPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reflectionController,
              maxLines: 2,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: "Reflect and write here...",
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(coachControllerProvider.notifier).submitReflection(value.trim());
                  _reflectionController.clear();
                }
              },
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Empty Chat State with Tagline & Quick Action Chips
  Widget _buildEmptyState(ThemeData theme) {
    final chips = [
      {'label': "💔 I Miss Them", 'prompt': "I miss my ex and I feel really overwhelmed. How do I navigate this feeling?"},
      {'label': "📱 I Want To Text Them", 'isSos': true},
      {'label': "😔 Feeling Lonely", 'prompt': "I'm feeling very lonely and empty right now. Can we talk?"},
      {'label': "😡 Feeling Angry", 'prompt': "I feel angry about what happened. How do I process this anger?"},
      {'label': "🧠 Help Me Stop Overthinking", 'prompt': "My mind is running in loops thinking about the breakup. How do I quiet my mind?"},
      {'label': "🌱 How Do I Move On?", 'prompt': "I feel stuck. What are the key stages or actions I can take to move on?"},
      {'label': "❤️ I Need Encouragement", 'prompt': "I feel like I'm not making progress. I need some words of encouragement."}
    ];

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withAlpha(20),
                ),
                child: const Icon(Icons.spa_outlined, size: 40, color: Color(0xFFC76D8A)),
              ),
              const SizedBox(height: 24),
              Text(
                "Welcome to Break Coach",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "I'm here to support you, validate your feelings, and keep you strong on your path to healing. Choose a prompt or write whatever is on your mind.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary.withAlpha(180),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: chips.map((chip) {
                  final isSos = chip['isSos'] == true;
                  return ActionChip(
                    label: Text(
                      chip['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSos ? Colors.white : theme.colorScheme.primary,
                      ),
                    ),
                    backgroundColor: isSos 
                        ? const Color(0xFFC76D6A) 
                        : theme.colorScheme.surface.withAlpha(140),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSos ? Colors.transparent : theme.colorScheme.outline.withAlpha(60),
                        width: 0.5,
                      ),
                    ),
                    onPressed: () {
                      if (isSos) {
                        ref.read(coachControllerProvider.notifier).startNewSession('SOS');
                      } else {
                        final promptText = chip['prompt'] as String;
                        _sendMessage(promptText, []);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Message bubble design
  Widget _buildMessageBubble(CoachMessage msg, ThemeData theme) {
    final isUser = msg.role == 'user';
    final bubbleColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface.withAlpha(150);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha(15),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading typing indicator
  Widget _buildTypingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey)),
            ),
            const SizedBox(width: 10),
            Text(
              "Break Coach is writing...",
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }

  // Chat input panel
  Widget _buildInputPanel(CoachState state, List<CoachMessage> history, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(40),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(15),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // SOS Quick-Trigger button
            IconButton(
              icon: const Icon(Icons.shield_outlined, color: Color(0xFFC76D6A)),
              onPressed: () {
                ref.read(coachControllerProvider.notifier).startNewSession('SOS');
              },
              tooltip: "Urgent SOS Mode",
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: "Talk to Break Coach...",
                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withAlpha(100)),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withAlpha(180),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.colorScheme.outline.withAlpha(40)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (text) => _sendMessage(text, history),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
    
    // Play Selection click haptic
    ref.read(hapticServiceProvider).selection();

    ref.read(coachControllerProvider.notifier).sendMessage(text.trim(), history);
    _messageController.clear();
  }
}
