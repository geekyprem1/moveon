import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/providers.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '🔒 Seal in Time Capsule',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This letter will be locked. You will NOT be able to open, read, or edit it until the selected duration ends to protect your emotional distance.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _lockLetter(30),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Lock for 30 Days', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _lockLetter(90),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Lock for 90 Days', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _lockLetter(180),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Lock for 180 Days', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
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
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Letter sealed in Time Capsule for $days days.')),
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
        title: Text(widget.letterId == null ? 'New Unsent Letter' : 'Edit Letter'),
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
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Guidance Text
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'These words are for your own healing, not for them. Write honestly, release fully.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category Selector
                      Text(
                        'Letter Category',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['name'];
                          return ChoiceChip(
                            label: Text('${cat['emoji']} ${cat['name']}'),
                            selected: isSelected,
                            selectedColor: cat['color'].withAlpha(40),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat['name'];
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Title input
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: const InputDecoration(
                          labelText: 'Title / Feeling (e.g. Closure I need)',
                          border: OutlineInputBorder(),
                          hintText: 'Enter title...',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Content Input
                      TextFormField(
                        controller: _contentController,
                        maxLines: 12,
                        minLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Write your heart out...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          hintText: 'Type what you want to say but never send...',
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
                              label: const Text('Time Capsule'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                foregroundColor: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Burn
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _burnLetterAnimation,
                              icon: const Icon(Icons.local_fire_department),
                              label: const Text('Burn Letter'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                backgroundColor: Colors.red.shade900,
                                foregroundColor: Colors.white,
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
