import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/unsent_letter.dart';

class LettersRepository {
  final FirebaseFirestore _firestore;

  LettersRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _lettersRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('letters');
  }

  /// Watch active letters (drafts + unlocked letters)
  Stream<List<UnsentLetter>> watchActiveLetters(String uid) {
    return _lettersRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UnsentLetter.fromJson(doc.data()))
          .where((letter) {
            if (letter.status == 'burnt') return false;
            if (letter.status == 'locked') {
              // Only active if the lock duration has expired
              return !letter.isCurrentlyLocked;
            }
            return true; // 'draft' status
          })
          .toList();
    });
  }

  /// Watch locked time capsule letters
  Stream<List<UnsentLetter>> watchLockedLetters(String uid) {
    return _lettersRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UnsentLetter.fromJson(doc.data()))
          .where((letter) => letter.status == 'locked' && letter.isCurrentlyLocked)
          .toList();
    });
  }

  /// Watch burnt (released) letters
  Stream<List<UnsentLetter>> watchBurntLetters(String uid) {
    return _lettersRef(uid)
        .where('status', isEqualTo: 'burnt')
        .orderBy('burntAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UnsentLetter.fromJson(doc.data()))
          .toList();
    });
  }

  /// Save or update a letter
  Future<void> saveLetter(String uid, UnsentLetter letter) async {
    await _lettersRef(uid).doc(letter.id).set(letter.toJson());
  }

  /// Delete a letter (permanently) - optional utility
  Future<void> deleteLetter(String uid, String letterId) async {
    await _lettersRef(uid).doc(letterId).delete();
  }

  /// Burn a letter: sets status to 'burnt' and sets burntAt timestamp
  Future<void> burnLetter(String uid, String letterId) async {
    await _lettersRef(uid).doc(letterId).update({
      'status': 'burnt',
      'burntAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Lock a letter: sets status to 'locked' and sets lockUntil date
  Future<void> lockLetter(String uid, String letterId, DateTime lockUntil) async {
    await _lettersRef(uid).doc(letterId).update({
      'status': 'locked',
      'lockUntil': Timestamp.fromDate(lockUntil),
    });
  }
}
