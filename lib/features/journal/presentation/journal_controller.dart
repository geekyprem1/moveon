import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../providers/providers.dart';
import '../domain/journal_entry.dart';

class JournalController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  static const _uuid = Uuid();

  JournalController(this._ref) : super(const AsyncValue.data(null));

  /// Create a new journal entry
  Future<bool> addEntry(String title, String note) async {
    final user = _ref.read(appUserProvider).value;
    if (user == null) return false;

    state = const AsyncValue.loading();
    try {
      final entry = JournalEntry(
        id: _uuid.v4(),
        title: title.trim(),
        note: note.trim(),
        date: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
        isDeleted: false,
      );

      final repo = _ref.read(journalRepositoryProvider);
      await repo.saveJournal(user.uid, entry);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Update an existing journal entry
  Future<bool> updateEntry(JournalEntry existing, String title, String note) async {
    final user = _ref.read(appUserProvider).value;
    if (user == null) return false;

    state = const AsyncValue.loading();
    try {
      final updated = existing.copyWith(
        title: title.trim(),
        note: note.trim(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      final repo = _ref.read(journalRepositoryProvider);
      await repo.saveJournal(user.uid, updated);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a journal entry
  Future<bool> deleteEntry(String entryId) async {
    final user = _ref.read(appUserProvider).value;
    if (user == null) return false;

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(journalRepositoryProvider);
      await repo.deleteJournal(user.uid, entryId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final journalControllerProvider =
    StateNotifierProvider<JournalController, AsyncValue<void>>((ref) {
  return JournalController(ref);
});
