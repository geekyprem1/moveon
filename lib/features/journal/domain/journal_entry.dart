import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final DateTime updatedAt;
  final bool isSynced;
  final bool isDeleted;

  JournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? date,
    DateTime? updatedAt,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'date': date.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'date': Timestamp.fromDate(date),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }

  factory JournalEntry.fromJson(Map<dynamic, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      date: json['date'] is String 
          ? DateTime.parse(json['date']) 
          : (json['date'] as DateTime),
      updatedAt: json['updatedAt'] is String 
          ? DateTime.parse(json['updatedAt']) 
          : (json['updatedAt'] as DateTime),
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  factory JournalEntry.fromFirestore(Map<String, dynamic> json) {
    DateTime entryDate;
    DateTime updateDate;

    if (json['date'] is Timestamp) {
      entryDate = (json['date'] as Timestamp).toDate();
    } else {
      entryDate = DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();
    }

    if (json['updatedAt'] is Timestamp) {
      updateDate = (json['updatedAt'] as Timestamp).toDate();
    } else {
      updateDate = DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now();
    }

    return JournalEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      date: entryDate,
      updatedAt: updateDate,
      isSynced: true, // If it comes from Firestore, it is synced
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }
}
