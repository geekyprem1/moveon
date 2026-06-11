import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final bool onboarded;
  final DateTime? breakupDate;
  final int? relationshipDurationDays;
  final int? initialPainScore;
  final String? breakupType;
  final DateTime? lastContactDate;
  final int longestStreak;
  final List<String> unlockedAchievements;

  AppUser({
    required this.uid,
    required this.email,
    this.onboarded = false,
    this.breakupDate,
    this.relationshipDurationDays,
    this.initialPainScore,
    this.breakupType,
    this.lastContactDate,
    this.longestStreak = 0,
    this.unlockedAchievements = const [],
  });

  /// Calculate streak in full days based on lastContactDate
  int get noContactStreak {
    if (lastContactDate == null) return 0;

    final today = DateTime.now();
    // Normalize to date-only to calculate clean calendar day differences
    final todayDate = DateTime(today.year, today.month, today.day);
    final contactDate = DateTime(
      lastContactDate!.year,
      lastContactDate!.month,
      lastContactDate!.day,
    );

    final difference = todayDate.difference(contactDate).inDays;
    return difference < 0 ? 0 : difference;
  }

  AppUser copyWith({
    String? uid,
    String? email,
    bool? onboarded,
    DateTime? breakupDate,
    int? relationshipDurationDays,
    int? initialPainScore,
    String? breakupType,
    DateTime? lastContactDate,
    int? longestStreak,
    List<String>? unlockedAchievements,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      onboarded: onboarded ?? this.onboarded,
      breakupDate: breakupDate ?? this.breakupDate,
      relationshipDurationDays: relationshipDurationDays ?? this.relationshipDurationDays,
      initialPainScore: initialPainScore ?? this.initialPainScore,
      breakupType: breakupType ?? this.breakupType,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      longestStreak: longestStreak ?? this.longestStreak,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'onboarded': onboarded,
      'breakupDate': breakupDate != null ? Timestamp.fromDate(breakupDate!) : null,
      'relationshipDurationDays': relationshipDurationDays,
      'initialPainScore': initialPainScore,
      'breakupType': breakupType,
      'lastContactDate': lastContactDate != null ? Timestamp.fromDate(lastContactDate!) : null,
      'longestStreak': longestStreak,
      'unlockedAchievements': unlockedAchievements,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? bDate;
    DateTime? cDate;

    if (json['breakupDate'] is Timestamp) {
      bDate = (json['breakupDate'] as Timestamp).toDate();
    } else if (json['breakupDate'] is String) {
      bDate = DateTime.tryParse(json['breakupDate']);
    }

    if (json['lastContactDate'] is Timestamp) {
      cDate = (json['lastContactDate'] as Timestamp).toDate();
    } else if (json['lastContactDate'] is String) {
      cDate = DateTime.tryParse(json['lastContactDate']);
    }

    return AppUser(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      onboarded: json['onboarded'] as bool? ?? false,
      breakupDate: bDate,
      relationshipDurationDays: json['relationshipDurationDays'] as int?,
      initialPainScore: json['initialPainScore'] as int?,
      breakupType: json['breakupType'] as String?,
      lastContactDate: cDate ?? bDate, // Default last contact to breakup date
      longestStreak: json['longestStreak'] as int? ?? 0,
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
