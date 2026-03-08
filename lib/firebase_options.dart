// File generated manually from google-services.json for Android
// and Firebase project info for Web.
// DO NOT modify this file manually unless you regenerate Firebase config.

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android config (from google-services.json) ──
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDbyVIjq0foF0s74g_RlZPntGfT9E1eNW8',
    appId: '1:504327412275:android:e8905e30d28e3d6579e146',
    messagingSenderId: '504327412275',
    projectId: 'research-auth-app-88361',
    storageBucket: 'research-auth-app-88361.firebasestorage.app',
  );

  // ── Web config (from Firebase Console - Lavender AI Web app) ──
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDd32pI7D_5iGp098mDdTgTzUi0UCZ1Gis',
    appId: '1:504327412275:web:ba38da1d9a4223a679e146',
    messagingSenderId: '504327412275',
    projectId: 'research-auth-app-88361',
    storageBucket: 'research-auth-app-88361.firebasestorage.app',
    authDomain: 'research-auth-app-88361.firebaseapp.com',
    measurementId: 'G-KD3X9JS6E1',
  );
}
