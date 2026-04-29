import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android and iOS in this project.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD7TjscZ-3DzRkrxbtVrRc1awWsWLoNBWc',
    appId: '1:435744242488:web:dcc84cedc4f248a46cdfcd',
    messagingSenderId: '435744242488',
    projectId: 'auth-modul-study-group-finder',
    storageBucket: 'auth-modul-study-group-finder.firebasestorage.app',
    authDomain: 'auth-modul-study-group-finder.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD7TjscZ-3DzRkrxbtVrRc1awWsWLoNBWc',
    appId: '1:435744242488:android:dcc84cedc4f248a46cdfcd',
    messagingSenderId: '435744242488',
    projectId: 'auth-modul-study-group-finder',
    storageBucket: 'auth-modul-study-group-finder.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBlMvjxLIAOGEB2US9XC7ahME2G1Qd4YVQ',
    appId: '1:435744242488:ios:34f4f75c4de990086cdfcd',
    messagingSenderId: '435744242488',
    projectId: 'auth-modul-study-group-finder',
    storageBucket: 'auth-modul-study-group-finder.firebasestorage.app',
    iosBundleId: 'com.example.studyGroupFinder',
  );
}
