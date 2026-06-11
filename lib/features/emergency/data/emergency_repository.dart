import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/emergency_click.dart';
import '../domain/sos_completion.dart';

class EmergencyRepository {
  final FirebaseFirestore _firestore;

  EmergencyRepository({required FirebaseFirestore firestore}) : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _clicksRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('emergency_clicks');
  }

  CollectionReference<Map<String, dynamic>> _completionsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('sos_completions');
  }

  /// Log emergency button click
  Future<void> logEmergencyClick(String uid, EmergencyClick click) async {
    await _clicksRef(uid).doc(click.id).set(click.toJson());
  }

  /// Watch emergency clicks stream
  Stream<List<EmergencyClick>> watchEmergencyClicks(String uid) {
    return _clicksRef(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => EmergencyClick.fromJson(doc.data()))
          .toList();
    });
  }

  /// Log SOS exercise completion
  Future<void> logSosCompletion(String uid, SosCompletion completion) async {
    await _completionsRef(uid).doc(completion.id).set(completion.toJson());
  }

  /// Watch SOS completions stream
  Stream<List<SosCompletion>> watchSosCompletions(String uid) {
    return _completionsRef(uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SosCompletion.fromJson(doc.data()))
          .toList();
    });
  }
}
