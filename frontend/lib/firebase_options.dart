// File generated or configured via FlutterFire CLI.
// To connect to your real Firebase project:
// 1. Run: flutterfire configure
// 2. Or replace these options with your Firebase Console project values.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBcBuJUyZNjWmd8oQ6Az8Pc85uX3FeWJqE',
    appId: '1:314791280440:android:849f90fe3457c2561c0bcd',
    messagingSenderId: '314791280440',
    projectId: 'personal-expense-tracker-e03ec',
    storageBucket: 'personal-expense-tracker-e03ec.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBcBuJUyZNjWmd8oQ6Az8Pc85uX3FeWJqE',
    appId: '1:314791280440:ios:849f90fe3457c2561c0bcd',
    messagingSenderId: '123456789012',
    projectId: 'personal-expense-tracker-e03ec',
    storageBucket: 'personal-expense-tracker-app.appspot.com',
    iosBundleId: 'com.example.personalExpenseTracker',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_REPLACE_WITH_YOUR_WEB_FIREBASE_API_KEY',
    appId: '1:123456789012:web:abcdef1234567890',
    messagingSenderId: '123456789012',
    projectId: 'personal-expense-tracker-e03ec',
    authDomain: 'personal-expense-tracker-e03ec.firebaseapp.com',
    storageBucket: 'personal-expense-tracker-app.appspot.com',
  );
}
