import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../domain/coach_message.dart';
import '../domain/coach_session.dart';
import '../domain/coach_usage.dart';

class CoachRepository {
  final FirebaseFirestore _firestore;

  CoachRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Watch active session chat messages (ordered by timestamp)
  Stream<List<CoachMessage>> watchMessages(String sessionId) {
    return _firestore
        .collection('coach_chats')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CoachMessage.fromJson(doc.data()))
          .toList();
    });
  }

  /// Watch user's daily usage limits
  Stream<CoachUsage?> watchUsage(String uid, String dateStr) {
    return _firestore
        .collection('coach_usage')
        .doc('${uid}_$dateStr')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return CoachUsage.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Fetch user's daily usage limits as a Future
  Future<CoachUsage?> getUsage(String uid, String dateStr) async {
    try {
      final doc = await _firestore.collection('coach_usage').doc('${uid}_$dateStr').get();
      if (doc.exists && doc.data() != null) {
        return CoachUsage.fromJson(doc.data()!);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create a new AI coach session
  Future<CoachSession> createSession(String uid, String mode) async {
    final sessionId = const Uuid().v4();
    final session = CoachSession(
      id: sessionId,
      userId: uid,
      createdAt: DateTime.now(),
      mode: mode,
    );
    await _firestore
        .collection('coach_sessions')
        .doc(sessionId)
        .set(session.toJson());
    return session;
  }

  /// Log an SOS trigger event
  Future<void> logSosTrigger({
    required String uid,
    required String reason,
    required bool completedBreathing,
    required int streakDays,
    String? journalEntryId,
  }) async {
    final logId = const Uuid().v4();
    await _firestore.collection('sos_logs').doc(logId).set({
      'id': logId,
      'userId': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'triggerReason': reason,
      'completedBreathing': completedBreathing,
      'streakDays': streakDays,
      'journalEntryId': journalEntryId,
    });
  }

  /// Fetch daily reflection question for a user (or create a simple static prompt list / dynamic logic)
  Future<Map<String, String>> getOrCreateDailyReflectionPrompt(String uid, String dateStr, String recoveryStage, int streak) async {
    final docRef = _firestore.collection('daily_reflections').doc('${uid}_$dateStr');
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      return {
        'question': data['question'] as String? ?? '',
        'healingPrompt': data['healingPrompt'] as String? ?? '',
        'responseContent': data['responseContent'] as String? ?? '',
      };
    }

    // Generate questions/prompts based on recovery stages
    String question;
    String healingPrompt;

    switch (recoveryStage.toLowerCase()) {
      case 'shock':
        question = "What is one feeling you are carrying in your body right now?";
        healingPrompt = "Take 3 deep breaths and write down how your body feels. Letting go of thoughts, just describe the physical sensations.";
        break;
      case 'withdrawal':
        question = "What is a memory of your ex that keeps playing in your head, and what is the reality of it today?";
        healingPrompt = "Write down the memory, but follow it by: 'That was then. Today, I am safe and healing in my own space.'";
        break;
      case 'healing':
        question = "What is one small thing you did for yourself today that brought a tiny bit of peace?";
        healingPrompt = "List three things you appreciate about your own strength in this moment.";
        break;
      case 'growth':
        question = "How has your understanding of yourself shifted since this breakup?";
        healingPrompt = "Write a letter of appreciation to the version of you that survived the first week. Tell them what you know now.";
        break;
      case 'move-on':
        question = "What are you most excited to explore or build in your life in this next chapter?";
        healingPrompt = "Describe a dream or interest you'd like to pursue purely for yourself.";
        break;
      default:
        question = "How are you showing yourself compassion today?";
        healingPrompt = "Write down one self-kindness affirmation.";
    }

    await docRef.set({
      'id': '${uid}_$dateStr',
      'userId': uid,
      'date': dateStr,
      'question': question,
      'healingPrompt': healingPrompt,
      'responseContent': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'question': question,
      'healingPrompt': healingPrompt,
      'responseContent': '',
    };
  }

  /// Save daily reflection response
  Future<void> saveDailyReflectionAnswer(String uid, String dateStr, String answer) async {
    await _firestore.collection('daily_reflections').doc('${uid}_$dateStr').update({
      'responseContent': answer,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
