// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyAzYMqItR3_WuTs0I4iMzksH2cPdKtwRi4',
    appId: '1:161693531729:web:59480e49def73b2b288270',
    messagingSenderId: '161693531729',
    projectId: 'onibenn-stopwatch',
    authDomain: 'onibenn-stopwatch.firebaseapp.com',
    storageBucket: 'onibenn-stopwatch.appspot.com',
    measurementId: 'G-0ZSP4TSK1H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrawLFb4QHw4CbUXC3Eun2b1NfFpdlq6E',
    appId: '1:161693531729:android:0044ec4d6d5416ae288270',
    messagingSenderId: '161693531729',
    projectId: 'onibenn-stopwatch',
    storageBucket: 'onibenn-stopwatch.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCxopowNtUOb1FySOYKpT3YhY7OWl689jo',
    appId: '1:161693531729:ios:d496b7f66642bdda288270',
    messagingSenderId: '161693531729',
    projectId: 'onibenn-stopwatch',
    storageBucket: 'onibenn-stopwatch.appspot.com',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCxopowNtUOb1FySOYKpT3YhY7OWl689jo',
    appId: '1:161693531729:ios:d496b7f66642bdda288270',
    messagingSenderId: '161693531729',
    projectId: 'onibenn-stopwatch',
    storageBucket: 'onibenn-stopwatch.appspot.com',
    iosBundleId: 'com.example.flutterApplication2',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAzYMqItR3_WuTs0I4iMzksH2cPdKtwRi4',
    appId: '1:161693531729:web:4ec5760d4162e7fe288270',
    messagingSenderId: '161693531729',
    projectId: 'onibenn-stopwatch',
    authDomain: 'onibenn-stopwatch.firebaseapp.com',
    storageBucket: 'onibenn-stopwatch.appspot.com',
    measurementId: 'G-W3FX120QPM',
  );
}
