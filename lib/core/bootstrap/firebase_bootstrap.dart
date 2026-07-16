import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Non-blocking Firebase initialization started from [main] and awaited on splash.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<void>? _initFuture;
  static bool _configured = false;

  static Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  static bool get isInitialized => _configured;

  static Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    _configured = true;
  }
}
