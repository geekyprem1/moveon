import 'package:cloud_firestore/cloud_firestore.dart';

class CoachSession {
  final String id;
  final String userId;
  final DateTime createdAt;
  final String mode; // 'TALK', 'SOS', 'REFLECTION', 'CHECK_IN'

  CoachSession({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'mode': mode,
    };
  }

  factory CoachSession.fromJson(Map<String, dynamic> json) {
    DateTime cat;
    if (json['createdAt'] is Timestamp) {
      cat = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      cat = DateTime.parse(json['createdAt']);
    } else {
      cat = DateTime.now();
    }

    return CoachSession(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      createdAt: cat,
      mode: json['mode'] as String? ?? 'TALK',
    );
  }
}
