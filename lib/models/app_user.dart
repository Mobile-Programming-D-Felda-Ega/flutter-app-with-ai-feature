import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore user model for StudyLink AI.
class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.university,
    this.major,
    this.photoUrl,
    this.joinedGroups = const [],
    this.preferences = const UserPreferences(),
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String uid;
  final String name;
  final String email;
  final String? university;
  final String? major;
  final String? photoUrl;
  final List<String> joinedGroups;
  final UserPreferences preferences;
  final DateTime createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      university: data['university'] as String?,
      major: data['major'] as String?,
      photoUrl: data['photoUrl'] as String?,
      joinedGroups: List<String>.from(
        data['joinedGroups'] as List<dynamic>? ?? const [],
      ),
      preferences: UserPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'university': university,
      'major': major,
      'photoUrl': photoUrl,
      'joinedGroups': joinedGroups,
      'preferences': preferences.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? university,
    String? major,
    String? photoUrl,
    List<String>? joinedGroups,
    UserPreferences? preferences,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      university: university ?? this.university,
      major: major ?? this.major,
      photoUrl: photoUrl ?? this.photoUrl,
      joinedGroups: joinedGroups ?? this.joinedGroups,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt,
    );
  }
}

/// User study preferences (synced to Firestore).
class UserPreferences {
  const UserPreferences({
    this.sessionAlerts = true,
    this.profileVisibility = true,
    this.aiMatchmaking = false,
  });

  final bool sessionAlerts;
  final bool profileVisibility;
  final bool aiMatchmaking;

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      sessionAlerts: map['sessionAlerts'] as bool? ?? true,
      profileVisibility: map['profileVisibility'] as bool? ?? true,
      aiMatchmaking: map['aiMatchmaking'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionAlerts': sessionAlerts,
      'profileVisibility': profileVisibility,
      'aiMatchmaking': aiMatchmaking,
    };
  }

  UserPreferences copyWith({
    bool? sessionAlerts,
    bool? profileVisibility,
    bool? aiMatchmaking,
  }) {
    return UserPreferences(
      sessionAlerts: sessionAlerts ?? this.sessionAlerts,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      aiMatchmaking: aiMatchmaking ?? this.aiMatchmaking,
    );
  }
}
