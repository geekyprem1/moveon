import 'package:cloud_firestore/cloud_firestore.dart';

class CoachMessage {
  final String id;
  final String sessionId;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isSos;

  CoachMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isSos = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSos': isSos,
    };
  }

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    if (json['timestamp'] is Timestamp) {
      ts = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      ts = DateTime.parse(json['timestamp']);
    } else {
      ts = DateTime.now();
    }

    return CoachMessage(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      timestamp: ts,
      isSos: json['isSos'] as bool? ?? false,
    );
  }
}
