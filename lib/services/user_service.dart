import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Firestore CRUD operations for user documents.
class UserService {
  UserService._();
  static final instance = UserService._();

  final _users = FirebaseFirestore.instance.collection('users');

  /// Create a user document after registration.
  Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
  }) async {
    final doc = _users.doc(uid);
    final snapshot = await doc.get();

    // Don't overwrite existing user data
    if (snapshot.exists) return;

    final user = AppUser(
      uid: uid,
      name: name,
      email: email,
    );
    await doc.set(user.toFirestore());
  }

  /// Ensure user document exists (called on login for Google/Apple sign-in).
  Future<void> ensureUserDocument({
    required String uid,
    required String name,
    required String email,
  }) async {
    final doc = _users.doc(uid);
    final snapshot = await doc.get();
    if (!snapshot.exists) {
      await createUserDocument(uid: uid, name: name, email: email);
    }
  }

  /// Get user document once.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Real-time user stream.
  Stream<AppUser?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  /// Update user profile fields.
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? university,
    String? major,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (university != null) updates['university'] = university;
    if (major != null) updates['major'] = major;
    if (updates.isNotEmpty) {
      await _users.doc(uid).set(updates, SetOptions(merge: true));
    }
  }

  /// Update user preferences.
  Future<void> updatePreferences({
    required String uid,
    required UserPreferences preferences,
  }) async {
    await _users.doc(uid).set({
      'preferences': preferences.toMap(),
    }, SetOptions(merge: true));
  }

  /// Add a group to the user's joinedGroups list.
  Future<void> addJoinedGroup(String uid, String groupId) async {
    await _users.doc(uid).set({
      'joinedGroups': FieldValue.arrayUnion([groupId]),
    }, SetOptions(merge: true));
  }

  /// Remove a group from the user's joinedGroups list.
  Future<void> removeJoinedGroup(String uid, String groupId) async {
    await _users.doc(uid).set({
      'joinedGroups': FieldValue.arrayRemove([groupId]),
    }, SetOptions(merge: true));
  }
}
