import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id; // Use date format: yyyy-MM-dd
  final String mood; // Terrible, Sad, Okay, Better, Great
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.mood,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mood': mood,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    DateTime ts;
    if (json['timestamp'] is Timestamp) {
      ts = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      ts = DateTime.parse(json['timestamp']);
    } else {
      ts = DateTime.now();
    }

    return MoodEntry(
      id: json['id'] as String? ?? '',
      mood: json['mood'] as String? ?? 'Okay',
      timestamp: ts,
    );
  }
}
