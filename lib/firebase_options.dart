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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return web;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCo3lhM89dSdcZhSBqdeIZbC1UkFr8ESBg',
    appId: '1:244446156099:web:bb6c7e0dabe7a5efbf0bf6',
    messagingSenderId: '244446156099',
    projectId: 'college-reality',
    authDomain: 'college-reality.firebaseapp.com',
    storageBucket: 'college-reality.firebasestorage.app',
    measurementId: 'G-641KD4M03V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCF11KTKt0yHRon2McwwYvIRtIgO4qYJ8U',
    appId: '1:244446156099:android:0471c18323c4bdf5bf0bf6',
    messagingSenderId: '244446156099',
    projectId: 'college-reality',
    storageBucket: 'college-reality.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMF-xYgHtAx4zV17uAI2BAs183GoO3Kdg',
    appId: '1:244446156099:ios:34c193b0e798f5f0bf0bf6',
    messagingSenderId: '244446156099',
    projectId: 'college-reality',
    storageBucket: 'college-reality.firebasestorage.app',
    iosBundleId: 'com.example.collegeRealityIndia',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAMF-xYgHtAx4zV17uAI2BAs183GoO3Kdg',
    appId: '1:244446156099:ios:34c193b0e798f5f0bf0bf6',
    messagingSenderId: '244446156099',
    projectId: 'college-reality',
    storageBucket: 'college-reality.firebasestorage.app',
    iosBundleId: 'com.example.collegeRealityIndia',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCo3lhM89dSdcZhSBqdeIZbC1UkFr8ESBg',
    appId: '1:244446156099:web:e8ebbd6d74d629bdbf0bf6',
    messagingSenderId: '244446156099',
    projectId: 'college-reality',
    authDomain: 'college-reality.firebaseapp.com',
    storageBucket: 'college-reality.firebasestorage.app',
    measurementId: 'G-HHS55JNP74',
  );
}
