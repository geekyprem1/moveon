import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/haptic_service.dart';

import '../../../providers/providers.dart';
import '../../../utils/date_formatter.dart';
import '../domain/journal_entry.dart';

class JournalListScreen extends ConsumerStatefulWidget {
  const JournalListScreen({super.key});

  @override
  ConsumerState<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends ConsumerState<JournalListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journalsAsync = ref.watch(journalListProvider);
    final user = ref.watch(appUserProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal Notes',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sync Notes',
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Syncing journal entries...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                await ref.read(journalRepositoryProvider).syncJournals(user.uid);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Premium Search Pill Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(102),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(15),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),

          // Journals List
          Expanded(
            child: journalsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading journal: $err')),
              data: (journals) {
                final filtered = journals.where((entry) {
                  if (_searchQuery.isEmpty) return true;
                  return entry.title.toLowerCase().contains(_searchQuery) ||
                      entry.note.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withAlpha(38),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '📝',
                              style: TextStyle(fontSize: 48),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No journal entries yet.'
                                : 'No matches found.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Write down your feelings to process your emotions.'
                                : 'Try searching for something else.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.secondary.withAlpha(180),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _JournalCard(entry: entry);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'journal_fab',
        onPressed: () {
          ref.read(hapticServiceProvider).selection();
          context.go('/journal/new');
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text(
          'New Note',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide(
            color: theme.colorScheme.primary.withAlpha(30),
            width: 1,
          ),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _JournalCard extends ConsumerStatefulWidget {
  final JournalEntry entry;

  const _JournalCard({required this.entry});

  @override
  ConsumerState<_JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends ConsumerState<_JournalCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Limit snippet to 3 lines
    final snippet = widget.entry.note.length > 120
        ? '${widget.entry.note.substring(0, 120)}...'
        : widget.entry.note;

    final double scale = _isPressed ? 0.98 : 1.0;
    final double shadowOpacity = _isPressed ? (isDark ? 0.18 : 0.08) : (isDark ? 0.12 : 0.04);
    final double blurRadius = _isPressed ? 16.0 : 32.0;
    final Offset offset = _isPressed ? const Offset(0, 4) : const Offset(0, 12);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        ref.read(hapticServiceProvider).selection();
        context.go('/journal/edit/${widget.entry.id}');
      },
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.outline.withAlpha(isDark ? 10 : 15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowOpacity),
                blurRadius: blurRadius,
                offset: offset,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Title & Sync Status)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.entry.title.isEmpty ? 'Untitled Entry' : widget.entry.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.entry.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 16,
                      color: widget.entry.isSynced
                          ? theme.colorScheme.primary.withAlpha(150)
                          : theme.colorScheme.secondary.withAlpha(150),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date
                Text(
                  DateFormatter.formatDate(widget.entry.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary.withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Note snippet
                Text(
                  snippet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(204),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
