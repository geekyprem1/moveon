import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/mood_entry.dart';

class MoodRepository {
  final FirebaseFirestore _firestore;

  MoodRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Log user mood for a specific day
  Future<void> logMood(String uid, MoodEntry entry) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .doc(entry.id) // Doc ID is 'yyyy-MM-dd' to ensure one per day
        .set(entry.toJson());
  }

  /// Get mood check-in for a specific day
  Future<MoodEntry?> getMoodForDay(String uid, String dateStr) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('moods')
          .doc(dateStr)
          .get();
      if (doc.exists && doc.data() != null) {
        return MoodEntry.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Watch mood history list (Stream)
  Stream<List<MoodEntry>> watchMoodHistory(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MoodEntry.fromJson(doc.data())).toList();
    });
  }

  /// Fetch mood history list (Future)
  Future<List<MoodEntry>> getMoodHistory(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => MoodEntry.fromJson(doc.data())).toList();
  }
}
