import 'package:cloud_firestore/cloud_firestore.dart';

class CoachUsage {
  final String id; // userId_yyyy-MM-dd
  final String userId;
  final String date; // yyyy-MM-dd
  final int messagesToday;
  final int totalMessages;
  final DateTime lastActiveDate;

  CoachUsage({
    required this.id,
    required this.userId,
    required this.date,
    this.messagesToday = 0,
    this.totalMessages = 0,
    required this.lastActiveDate,
  });

  int get messagesRemaining => 20 - messagesToday;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'messagesToday': messagesToday,
      'totalMessages': totalMessages,
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
    };
  }

  factory CoachUsage.fromJson(Map<String, dynamic> json) {
    DateTime lad;
    if (json['lastActiveDate'] is Timestamp) {
      lad = (json['lastActiveDate'] as Timestamp).toDate();
    } else if (json['lastActiveDate'] is String) {
      lad = DateTime.parse(json['lastActiveDate']);
    } else {
      lad = DateTime.now();
    }

    return CoachUsage(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      messagesToday: json['messagesToday'] as int? ?? 0,
      totalMessages: json['totalMessages'] as int? ?? 0,
      lastActiveDate: lad,
    );
  }
}
