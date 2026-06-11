import 'package:cloud_firestore/cloud_firestore.dart';

class UnsentLetter {
  final String id;
  final String title;
  final String content;
  final String category; // 'Love', 'Anger', 'Regret', 'Closure'
  final String status;   // 'draft', 'burnt', 'locked'
  final DateTime createdAt;
  final DateTime? burntAt;
  final DateTime? lockUntil;

  UnsentLetter({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    required this.createdAt,
    this.burntAt,
    this.lockUntil,
  });

  bool get isCurrentlyLocked {
    if (status != 'locked') return false;
    if (lockUntil == null) return false;
    return DateTime.now().isBefore(lockUntil!);
  }

  UnsentLetter copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? status,
    DateTime? createdAt,
    DateTime? burntAt,
    DateTime? lockUntil,
  }) {
    return UnsentLetter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      burntAt: burntAt ?? this.burntAt,
      lockUntil: lockUntil ?? this.lockUntil,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'burntAt': burntAt != null ? Timestamp.fromDate(burntAt!) : null,
      'lockUntil': lockUntil != null ? Timestamp.fromDate(lockUntil!) : null,
    };
  }

  factory UnsentLetter.fromJson(Map<String, dynamic> json) {
    DateTime? cDate;
    DateTime? bDate;
    DateTime? lDate;

    if (json['createdAt'] is Timestamp) {
      cDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      cDate = DateTime.tryParse(json['createdAt']);
    }

    if (json['burntAt'] is Timestamp) {
      bDate = (json['burntAt'] as Timestamp).toDate();
    } else if (json['burntAt'] is String) {
      bDate = DateTime.tryParse(json['burntAt']);
    }

    if (json['lockUntil'] is Timestamp) {
      lDate = (json['lockUntil'] as Timestamp).toDate();
    } else if (json['lockUntil'] is String) {
      lDate = DateTime.tryParse(json['lockUntil']);
    }

    return UnsentLetter(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? 'Closure',
      status: json['status'] as String? ?? 'draft',
      createdAt: cDate ?? DateTime.now(),
      burntAt: bDate,
      lockUntil: lDate,
    );
  }
}
