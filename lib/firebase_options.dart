// File generated using FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return macos;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '1056446356536',
    projectId: 'somineapp-57b41',
    authDomain: 'somineapp-57b41.firebaseapp.com',
    storageBucket: 'somineapp-57b41.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: '1056446356536',
    projectId: 'somineapp-57b41',
    storageBucket: 'somineapp-57b41.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDcAvjMV0cNFSTou1c-mn7FWNAuFwy4ZTg',
    appId: '1:1056446356536:ios:d2b30d496af6296922dacd',
    messagingSenderId: '1056446356536',
    projectId: 'somineapp-57b41',
    storageBucket: 'somineapp-57b41.firebasestorage.app',
    iosBundleId: 'com.somine.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDcAvjMV0cNFSTou1c-mn7FWNAuFwy4ZTg',
    appId: '1:1056446356536:ios:d2b30d496af6296922dacd',
    messagingSenderId: '1056446356536',
    projectId: 'somineapp-57b41',
    storageBucket: 'somineapp-57b41.firebasestorage.app',
    iosBundleId: 'com.somine.app',
  );
}

