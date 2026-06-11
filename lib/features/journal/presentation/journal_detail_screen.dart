import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/providers.dart';
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
      context.go('/journal');
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
      context.go('/journal');
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

    final controller = ref.read(journalControllerProvider.notifier);
    final success = await controller.deleteEntry(widget.entryId!);

    if (!mounted) return;

    if (success) {
      context.go('/journal');
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
              color: Theme.of(context).colorScheme.error,
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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Title Text Field
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        decoration: const InputDecoration(
                          hintText: 'Title',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const Divider(),

                      // Note Text Field
                      Expanded(
                        child: TextFormField(
                          controller: _noteController,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: const InputDecoration(
                            hintText: 'Write down your thoughts, cravings, or wins...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.grey),
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
