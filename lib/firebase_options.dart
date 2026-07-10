import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:web:...',
    messagingSenderId: '...',
    projectId: 'college-reality',
    authDomain: 'college-reality.firebaseapp.com',
    storageBucket: 'college-reality.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:android:...',
    messagingSenderId: '...',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:ios:...',
    messagingSenderId: '...',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:macos:...',
    messagingSenderId: '...',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD...',
    appId: '1:...:windows:...',
    messagingSenderId: '...',
    projectId: 'college-reality',
    storageBucket: 'college-reality.appspot.com',
  );
}
