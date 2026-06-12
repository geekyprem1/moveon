import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../domain/journal_entry.dart';

class JournalRepository {
  final FirebaseFirestore _firestore;
  static const String _boxName = 'journals_box';

  JournalRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Box get _box => Hive.box(_boxName);

  /// Initialize Hive box
  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  /// Get all local journal entries that are not marked as deleted
  List<JournalEntry> getLocalJournals() {
    return _box.values
        .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((entry) => !entry.isDeleted)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  /// Watch local journals (using Hive box stream)
  Stream<List<JournalEntry>> watchLocalJournals() async* {
    yield getLocalJournals();
    await for (final _ in _box.watch()) {
      yield getLocalJournals();
    }
  }

  /// Save / Update Journal entry (Offline-first)
  Future<void> saveJournal(String uid, JournalEntry entry) async {
    // 1. Save to local Hive cache immediately
    final localEntry = entry.copyWith(isSynced: false);
    await _box.put(entry.id, localEntry.toJson());

    // 2. Attempt sync to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(entry.id)
          .set(entry.toFirestoreJson());

      // Update local cache to synced
      final syncedEntry = entry.copyWith(isSynced: true);
      await _box.put(entry.id, syncedEntry.toJson());
    } catch (_) {
      // Sync failed (user is offline). Hive stays marked as isSynced: false
    }
  }

  /// Delete Journal entry (Offline-first)
  Future<void> deleteJournal(String uid, String entryId) async {
    // 1. Check if the entry exists locally
    final raw = _box.get(entryId);
    if (raw == null) return;

    final entry = JournalEntry.fromJson(Map<String, dynamic>.from(raw as Map));

    // 2. Mark as deleted locally to hide from UI
    final deletedEntry = entry.copyWith(isDeleted: true, isSynced: false);
    await _box.put(entryId, deletedEntry.toJson());

    // 3. Attempt sync deletion to Firestore
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('journals')
          .doc(entryId)
          .delete();

      // Deletion synced, we can safely erase from Hive
      await _box.delete(entryId);
    } catch (_) {
      // Offline: keep in Hive with isDeleted: true & isSynced: false to delete later
    }
  }

  /// Sync local offline changes to Firestore, and fetch latest from Firestore
  Future<void> syncJournals(String uid) async {
    // 1. Push unsynced changes to Firestore
    final allLocal = _box.values
        .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    for (var entry in allLocal) {
      if (!entry.isSynced) {
        try {
          if (entry.isDeleted) {
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('journals')
                .doc(entry.id)
                .delete();
            await _box.delete(entry.id);
          } else {
            await _firestore
                .collection('users')
                .doc(uid)
                .collection('journals')
                .doc(entry.id)
                .set(entry.toFirestoreJson());
            await _box.put(entry.id, entry.copyWith(isSynced: true).toJson());
          }
        } catch (_) {
          // Break early if sync fails due to network
          return;
        }
      }
    }

    // 2. Pull down updates from Firestore
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('journals')
          .get();

      final remoteIds = <String>{};
      for (var doc in snapshot.docs) {
        final remoteEntry = JournalEntry.fromFirestore(doc.data());
        remoteIds.add(remoteEntry.id);

        if (!remoteEntry.isDeleted) {
          final localRaw = _box.get(remoteEntry.id);
          if (localRaw != null) {
            final localEntry = JournalEntry.fromJson(Map<String, dynamic>.from(localRaw as Map));
            // Only update local if the local entry is already synced (so we don't overwrite user's unsynced edits)
            if (localEntry.isSynced) {
              await _box.put(remoteEntry.id, remoteEntry.toJson());
            }
          } else {
            // New remote entry
            await _box.put(remoteEntry.id, remoteEntry.toJson());
          }
        } else {
          // Remote marked as deleted, remove locally
          await _box.delete(remoteEntry.id);
        }
      }

      // Remove local items that are synced but don't exist on remote anymore (deleted on another device)
      final syncedLocal = _box.values
          .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((e) => e.isSynced)
          .toList();

      for (var local in syncedLocal) {
        if (!remoteIds.contains(local.id)) {
          await _box.delete(local.id);
        }
      }
    } catch (_) {
      // Network error during pull
    }
  }

  /// Clean Hive box (on logout)
  Future<void> clearCache() async {
    await _box.clear();
  }
}
