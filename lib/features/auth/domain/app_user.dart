import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? name;
  final bool onboarded;
  final DateTime? breakupDate;
  final int? relationshipDurationDays;
  final int? initialPainScore;
  final String? breakupType;
  final DateTime? lastContactDate;
  final int longestStreak;
  final List<String> unlockedAchievements;
  final int streakShieldsAvailable;
  final DateTime? lastShieldResetDate;
  final String referralCode;
  final String? referredBy;
  final String selectedTheme;
  final String themeMode;
  final int healingXp;
  final bool hapticsEnabled;
  final DateTime createdAt;
  final DateTime lastActiveAt;

  AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.onboarded = false,
    this.breakupDate,
    this.relationshipDurationDays,
    this.initialPainScore,
    this.breakupType,
    this.lastContactDate,
    this.longestStreak = 0,
    this.healingXp = 0,
    this.unlockedAchievements = const [],
    this.streakShieldsAvailable = 1,
    this.lastShieldResetDate,
    String? referralCode,
    this.referredBy,
    this.selectedTheme = 'classic',
    this.themeMode = 'system',
    this.hapticsEnabled = true,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  })  : referralCode = referralCode ?? 'MOVEON-${uid.length >= 5 ? uid.substring(0, 5).toUpperCase() : uid.toUpperCase()}',
        createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

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
    String? name,
    bool? onboarded,
    DateTime? breakupDate,
    int? relationshipDurationDays,
    int? initialPainScore,
    String? breakupType,
    DateTime? lastContactDate,
    int? longestStreak,
    int? healingXp,
    List<String>? unlockedAchievements,
    int? streakShieldsAvailable,
    DateTime? lastShieldResetDate,
    String? referralCode,
    String? referredBy,
    String? selectedTheme,
    String? themeMode,
    bool? hapticsEnabled,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      onboarded: onboarded ?? this.onboarded,
      breakupDate: breakupDate ?? this.breakupDate,
      relationshipDurationDays: relationshipDurationDays ?? this.relationshipDurationDays,
      initialPainScore: initialPainScore ?? this.initialPainScore,
      breakupType: breakupType ?? this.breakupType,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      longestStreak: longestStreak ?? this.longestStreak,
      healingXp: healingXp ?? this.healingXp,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      streakShieldsAvailable: streakShieldsAvailable ?? this.streakShieldsAvailable,
      lastShieldResetDate: lastShieldResetDate ?? this.lastShieldResetDate,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      themeMode: themeMode ?? this.themeMode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'onboarded': onboarded,
      'breakupDate': breakupDate != null ? Timestamp.fromDate(breakupDate!) : null,
      'relationshipDurationDays': relationshipDurationDays,
      'initialPainScore': initialPainScore,
      'breakupType': breakupType,
      'lastContactDate': lastContactDate != null ? Timestamp.fromDate(lastContactDate!) : null,
      'longestStreak': longestStreak,
      'healingXp': healingXp,
      'unlockedAchievements': unlockedAchievements,
      'streakShieldsAvailable': streakShieldsAvailable,
      'lastShieldResetDate': lastShieldResetDate != null ? Timestamp.fromDate(lastShieldResetDate!) : null,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'selectedTheme': selectedTheme,
      'themeMode': themeMode,
      'hapticsEnabled': hapticsEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    DateTime? bDate;
    DateTime? cDate;
    DateTime? sResetDate;
    DateTime? cAt;
    DateTime? lActive;

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

    if (json['lastShieldResetDate'] is Timestamp) {
      sResetDate = (json['lastShieldResetDate'] as Timestamp).toDate();
    } else if (json['lastShieldResetDate'] is String) {
      sResetDate = DateTime.tryParse(json['lastShieldResetDate']);
    }

    if (json['createdAt'] is Timestamp) {
      cAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      cAt = DateTime.tryParse(json['createdAt']);
    }

    if (json['lastActiveAt'] is Timestamp) {
      lActive = (json['lastActiveAt'] as Timestamp).toDate();
    } else if (json['lastActiveAt'] is String) {
      lActive = DateTime.tryParse(json['lastActiveAt']);
    }

    final uidStr = json['uid'] as String? ?? '';

    return AppUser(
      uid: uidStr,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      onboarded: json['onboarded'] as bool? ?? false,
      breakupDate: bDate,
      relationshipDurationDays: json['relationshipDurationDays'] as int?,
      initialPainScore: json['initialPainScore'] as int?,
      breakupType: json['breakupType'] as String?,
      lastContactDate: cDate ?? bDate, // Default last contact to breakup date
      longestStreak: json['longestStreak'] as int? ?? 0,
      healingXp: json['healingXp'] as int? ?? 0,
      unlockedAchievements: (json['unlockedAchievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      streakShieldsAvailable: json['streakShieldsAvailable'] as int? ?? 1,
      lastShieldResetDate: sResetDate,
      referralCode: json['referralCode'] as String? ?? 
          'MOVEON-${uidStr.length >= 5 ? uidStr.substring(0, 5).toUpperCase() : uidStr.toUpperCase()}',
      referredBy: json['referredBy'] as String?,
      selectedTheme: json['selectedTheme'] as String? ?? 'classic',
      themeMode: json['themeMode'] as String? ?? 'system',
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      createdAt: cAt,
      lastActiveAt: lActive,
    );
  }
}
