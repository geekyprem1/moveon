import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/providers.dart';
import '../../../utils/haptic_service.dart';
import '../domain/journal_entry.dart';
import 'journal_controller.dart';

class JournalDetailScreen extends ConsumerStatefulWidget {
  final String? entryId;

  const JournalDetailScreen({super.key, this.entryId});

  @override
  ConsumerState<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends ConsumerState<JournalDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  JournalEntry? _existingEntry;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.entryId != null;
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntry());
    }
  }

  void _loadEntry() {
    final repo = ref.read(journalRepositoryProvider);
    final localEntries = repo.getLocalJournals();
    try {
      final entry = localEntries.firstWhere((e) => e.id == widget.entryId);
      setState(() {
        _existingEntry = entry;
        _titleController.text = entry.title;
        _noteController.text = entry.note;
      });
    } catch (_) {
      // Entry not found, exit screen
      ref.read(activeTabProvider.notifier).state = 1;
      context.go('/');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(journalControllerProvider.notifier);
    bool success;

    if (_isEditMode && _existingEntry != null) {
      success = await controller.updateEntry(
        _existingEntry!,
        _titleController.text,
        _noteController.text,
      );
    } else {
      success = await controller.addEntry(
        _titleController.text,
        _noteController.text,
      );
    }

    if (!mounted) return;

    if (success) {
      ref.read(hapticServiceProvider).medium();
      ref.read(activeTabProvider.notifier).state = 1;
      context.go('/');
    } else {
      final state = ref.read(journalControllerProvider);
      String errorMsg = 'Failed to save entry';
      if (state is AsyncError) {
        errorMsg = state.error.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Journal Note?'),
          content: const Text('Are you sure you want to delete this journal note? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    ref.read(hapticServiceProvider).warning();
    final controller = ref.read(journalControllerProvider.notifier);
    final success = await controller.deleteEntry(widget.entryId!);

    if (!mounted) return;

    if (success) {
      ref.read(activeTabProvider.notifier).state = 1;
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete entry'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(journalControllerProvider);
    final isLoading = controllerState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Note' : 'New Note',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Note',
              color: theme.colorScheme.error,
              onPressed: isLoading ? null : _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Note',
            onPressed: isLoading ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                  child: Column(
                    children: [
                      // Title Text Field
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Title your thoughts',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Note Text Field
                      Expanded(
                        child: TextFormField(
                          controller: _noteController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withAlpha(220),
                          ),
                          decoration: InputDecoration(
                            hintText: 'How are you holding up in this moment? Write freely...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(80),
                              height: 1.6,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please write down some thoughts';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
