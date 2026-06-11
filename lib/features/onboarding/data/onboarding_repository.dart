import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingRepository {
  final FirebaseFirestore _firestore;

  OnboardingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submits the onboarding data to Firestore
  Future<void> submitOnboarding({
    required String uid,
    required String name,
    required DateTime breakupDate,
    required int relationshipDurationDays,
    required int initialPainScore,
    required String breakupType,
  }) async {
    final Map<String, dynamic> data = {
      'onboarded': true,
      'name': name,
      'breakupDate': Timestamp.fromDate(breakupDate),
      'relationshipDurationDays': relationshipDurationDays,
      'initialPainScore': initialPainScore,
      'breakupType': breakupType,
      'lastContactDate': Timestamp.fromDate(breakupDate), // Initialize streak starting from breakup date
    };

    await _firestore.collection('users').doc(uid).update(data);
  }
}
