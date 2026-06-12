import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class CoachApiService {
  final FirebaseFunctions _functions;

  CoachApiService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Call the secure Firebase Cloud Function for Break Coach completion
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required String sessionId,
    required Map<String, dynamic> context,
    required List<Map<String, dynamic>> history,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('chatCompletions');
      
      final response = await callable.call(<String, dynamic>{
        'message': message,
        'sessionId': sessionId,
        'context': context,
        'history': history,
      });

      return Map<String, dynamic>.from(response.data as Map);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function Exception: [${e.code}] ${e.message}');
      if (e.code == 'resource-exhausted') {
        throw Exception('limit_reached');
      }
      throw Exception(e.message ?? 'An error occurred during AI processing.');
    } catch (e) {
      debugPrint('Cloud Function General Exception: $e');
      throw Exception('Failed to reach Break Coach. Please check your network connection.');
    }
  }
}
