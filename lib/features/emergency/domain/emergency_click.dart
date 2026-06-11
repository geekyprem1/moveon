import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyClick {
  final String id;
  final DateTime timestamp;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final int hourOfDay; // 0-23

  EmergencyClick({
    required this.id,
    required this.timestamp,
    required this.dayOfWeek,
    required this.hourOfDay,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'dayOfWeek': dayOfWeek,
      'hourOfDay': hourOfDay,
    };
  }

  factory EmergencyClick.fromJson(Map<String, dynamic> json) {
    DateTime? ts;
    if (json['timestamp'] is Timestamp) {
      ts = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      ts = DateTime.tryParse(json['timestamp']);
    }

    return EmergencyClick(
      id: json['id'] as String? ?? '',
      timestamp: ts ?? DateTime.now(),
      dayOfWeek: json['dayOfWeek'] as int? ?? DateTime.now().weekday,
      hourOfDay: json['hourOfDay'] as int? ?? DateTime.now().hour,
    );
  }
}
