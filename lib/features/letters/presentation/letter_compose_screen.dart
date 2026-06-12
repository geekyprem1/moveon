import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/providers.dart';
import '../../../utils/haptic_service.dart';
import '../domain/unsent_letter.dart';
import 'burning_animation.dart';

class LetterComposeScreen extends ConsumerStatefulWidget {
  final String? letterId;

  const LetterComposeScreen({super.key, this.letterId});

  @override
  ConsumerState<LetterComposeScreen> createState() => _LetterComposeScreenState();
}

class _LetterComposeScreenState extends ConsumerState<LetterComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Closure';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Love', 'emoji': '❤️', 'color': Colors.pink},
    {'name': 'Anger', 'emoji': '😡', 'color': Colors.red},
    {'name': 'Regret', 'emoji': '🥺', 'color': Colors.amber},
    {'name': 'Closure', 'emoji': '🕊️', 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.letterId != null) {
      _loadLetter();
    }
  }

  void _loadLetter() {
    // Read the letter details
    Future.microtask(() {
      final activeLetters = ref.read(activeLettersProvider).value ?? [];
      final letter = activeLetters.firstWhere((l) => l.id == widget.letterId);
      _titleController.text = letter.title;
      _contentController.text = letter.content;
      setState(() {
        _selectedCategory = letter.category;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final user = ref.read(appUserProvider).value;
      if (user == null) return;

      final id = widget.letterId ?? const Uuid().v4();
      final letter = UnsentLetter(
        id: id,
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        status: 'draft',
        createdAt: DateTime.now(),
      );

      await ref.read(lettersRepositoryProvider).saveLetter(user.uid, letter);
      ref.read(hapticServiceProvider).medium();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Draft saved successfully.')),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTimeCapsuleLockOptions() {
    if (!_formKey.currentState!.validate()) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '🔒 Entrust to Time',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This letter will be locked away in a time capsule. You will not be able to read or edit it until the duration ends, helping you entrust these feelings to time.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary.withAlpha(180),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _lockLetter(30),
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
                  child: const Text('Lock for 30 Days', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _lockLetter(90),
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
                  child: const Text('Lock for 90 Days', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _lockLetter(180),
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
                  child: const Text('Lock for 180 Days', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _lockLetter(int days) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    navigator.pop(); // Close sheet
    setState(() => _isLoading = true);

    try {
      final user = ref.read(appUserProvider).value;
      if (user == null) return;

      final id = widget.letterId ?? const Uuid().v4();
      final unlockDate = DateTime.now().add(Duration(days: days));
      final letter = UnsentLetter(
        id: id,
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        status: 'locked',
        createdAt: DateTime.now(),
        lockUntil: unlockDate,
      );

      await ref.read(lettersRepositoryProvider).saveLetter(user.uid, letter);
      ref.read(hapticServiceProvider).medium();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Letter entrusted to time for $days days.')),
      );
      navigator.pop();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _burnLetterAnimation() {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);

    navigator.push(
      MaterialPageRoute(
        builder: (context) => BurningAnimation(
          title: _titleController.text,
          content: _contentController.text,
          onComplete: () async {
            final user = ref.read(appUserProvider).value;
            if (user != null) {
              final id = widget.letterId ?? const Uuid().v4();
              final letter = UnsentLetter(
                id: id,
                title: _titleController.text,
                content: _contentController.text,
                category: _selectedCategory,
                status: 'burnt',
                createdAt: DateTime.now(),
                burntAt: DateTime.now(),
              );

              try {
                // Save to Firestore
                await ref.read(lettersRepositoryProvider).saveLetter(user.uid, letter);
              } catch (e) {
                debugPrint('Error syncing burnt letter to cloud: $e');
              }
            }
            navigator.pop(); // Pop Burning Screen
            navigator.pop(); // Pop Compose Screen
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.letterId == null ? 'Write an Echo' : 'Edit Echo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Draft',
            onPressed: _isLoading ? null : _saveDraft,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Guidance Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(20),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'These words are for your own healing, not for them. Write honestly, release fully.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category Selector
                      Text(
                        'Letter Category',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['name'];
                          return ChoiceChip(
                            label: Text('${cat['emoji']} ${cat['name']}'),
                            selected: isSelected,
                            selectedColor: cat['color'].withAlpha(isSelected ? 30 : 10),
                            labelStyle: TextStyle(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isSelected 
                                    ? theme.colorScheme.primary.withAlpha(40) 
                                    : theme.colorScheme.outline.withAlpha(15),
                                width: 1,
                              ),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                ref.read(hapticServiceProvider).selection();
                                setState(() {
                                  _selectedCategory = cat['name'];
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Title input
                      TextFormField(
                        controller: _titleController,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title your letter (e.g. Closure I need)',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Content Input
                      TextFormField(
                        controller: _contentController,
                        maxLines: 12,
                        minLines: 6,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: theme.colorScheme.onSurface.withAlpha(220),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your heart out. Let it all flow here...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(80),
                            height: 1.6,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please write something before choosing an action';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons Row
                      Row(
                        children: [
                          // Lock (Time Capsule)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showTimeCapsuleLockOptions,
                              icon: const Icon(Icons.lock_clock),
                              label: const Text('Entrust to Time'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                foregroundColor: theme.colorScheme.onSecondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                  side: BorderSide(
                                    color: theme.colorScheme.secondary.withAlpha(20),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Burn
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _burnLetterAnimation,
                              icon: const Icon(Icons.local_fire_department),
                              label: const Text('Release to Fire'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                backgroundColor: theme.colorScheme.errorContainer,
                                foregroundColor: theme.colorScheme.onErrorContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                  side: BorderSide(
                                    color: theme.colorScheme.error.withAlpha(20),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
