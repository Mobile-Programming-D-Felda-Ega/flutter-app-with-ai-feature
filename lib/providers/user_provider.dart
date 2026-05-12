import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/study_group.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';

/// Provides the current user's Firestore profile and joined groups.
class UserProvider extends ChangeNotifier {
  String? _uid;
  StreamSubscription? _userSubscription;

  AppUser? _appUser;
  List<StudyGroup> _joinedGroups = [];
  bool _isLoading = false;

  AppUser? get appUser => _appUser;
  List<StudyGroup> get joinedGroups => _joinedGroups;
  bool get isLoading => _isLoading;
  List<String> get joinedGroupIds => _appUser?.joinedGroups ?? [];
  UserPreferences get preferences =>
      _appUser?.preferences ?? const UserPreferences();

  /// Start listening to a user's Firestore document.
  void listenToUser(String uid) {
    if (_uid == uid) return; // Already listening
    _uid = uid;
    _userSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _userSubscription = UserService.instance.userStream(uid).listen(
      (user) async {
        _appUser = user;
        _isLoading = false;

        // Refresh joined groups when the list changes
        if (user != null && user.joinedGroups.isNotEmpty) {
          _joinedGroups =
              await GroupService.instance.getJoinedGroups(user.joinedGroups);
        } else {
          _joinedGroups = [];
        }

        notifyListeners();
      },
      onError: (e) {
        debugPrint('UserProvider stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop listening (on logout).
  void clear() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _uid = null;
    _appUser = null;
    _joinedGroups = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Join a group.
  Future<void> joinGroup(String groupId) async {
    if (_uid == null) return;
    await GroupService.instance.joinGroup(groupId: groupId, uid: _uid!);
    // The Firestore stream will auto-update _appUser.joinedGroups
  }

  /// Leave a group.
  Future<void> leaveGroup(String groupId) async {
    if (_uid == null) return;
    await GroupService.instance.leaveGroup(groupId: groupId, uid: _uid!);
  }

  /// Update user preferences.
  Future<void> updatePreferences(UserPreferences prefs) async {
    if (_uid == null) return;
    await UserService.instance.updatePreferences(uid: _uid!, preferences: prefs);
  }

  /// Update user profile.
  Future<void> updateProfile({
    String? name,
    String? university,
    String? major,
  }) async {
    if (_uid == null) return;
    await UserService.instance.updateProfile(
      uid: _uid!,
      name: name,
      university: university,
      major: major,
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
