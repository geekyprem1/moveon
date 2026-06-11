import 'package:cloud_firestore/cloud_firestore.dart';

class SosCompletion {
  final String id;
  final String exerciseId;
  final DateTime timestamp;

  SosCompletion({
    required this.id,
    required this.exerciseId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exerciseId': exerciseId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SosCompletion.fromJson(Map<String, dynamic> json) {
    DateTime? ts;
    if (json['timestamp'] is Timestamp) {
      ts = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      ts = DateTime.tryParse(json['timestamp']);
    }

    return SosCompletion(
      id: json['id'] as String? ?? '',
      exerciseId: json['exerciseId'] as String? ?? '',
      timestamp: ts ?? DateTime.now(),
    );
  }
}
