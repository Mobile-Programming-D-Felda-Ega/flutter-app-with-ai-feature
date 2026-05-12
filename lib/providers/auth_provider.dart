import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/user_service.dart';

/// Provides authentication state and auto-creates Firestore user doc on login.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  StreamSubscription<User?>? _subscription;
  User? _firebaseUser;
  bool _isLoading = true;

  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isLoading => _isLoading;
  String get uid => _firebaseUser?.uid ?? '';

  void _onAuthChanged(User? user) async {
    _firebaseUser = user;
    _isLoading = false;

    // Ensure Firestore user document exists
    if (user != null) {
      await UserService.instance.ensureUserDocument(
        uid: user.uid,
        name: user.displayName ?? user.email?.split('@').first ?? '',
        email: user.email ?? '',
      );
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
