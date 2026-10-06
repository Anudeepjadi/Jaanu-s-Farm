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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDW772fNPtYnIYsGXzhAFQhNLM3MK5H0uM',
    appId: '1:911601653251:web:placeholder', // You need to replace this with your actual Web App ID
    messagingSenderId: '911601653251',
    projectId: 'jaanu-s-farm',
    authDomain: 'jaanu-s-farm.firebaseapp.com',
    storageBucket: 'jaanu-s-farm.firebasestorage.app',
    databaseURL: 'https://jaanu-s-farm-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDW772fNPtYnIYsGXzhAFQhNLM3MK5H0uM',
    appId: '1:911601653251:android:c9b57d3182ba8026076036',
    messagingSenderId: '911601653251',
    projectId: 'jaanu-s-farm',
    storageBucket: 'jaanu-s-farm.firebasestorage.app',
    databaseURL: 'https://jaanu-s-farm-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
