import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Verbose diagnostics for Display Name Firestore failures.
/// Logs are intentionally noisy while this bug is being tracked, but are
/// debug-only — nothing here is emitted in a release build.
class DisplayNameDiagnostics {
  DisplayNameDiagnostics._();

  static void _d(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static String? get authUid => FirebaseAuth.instance.currentUser?.uid;

  static void logStart({
    required String operation,
    required String firestorePath,
    String? userModelUid,
  }) {
    _d('[DisplayName] ── $operation ──');
    _d('[DisplayName] firestorePath=$firestorePath');
    _d('[DisplayName] authUid=${authUid ?? 'null'}');
    if (userModelUid != null) {
      _d('[DisplayName] userModelUid=$userModelUid');
      if (authUid != null && authUid != userModelUid) {
        _d(
          '[DisplayName] WARNING: auth UID and user model UID do not match',
        );
      }
    }
  }

  static void logFailure(
    Object error,
    StackTrace stack, {
    required String operation,
    String? firestorePath,
  }) {
    _d('[DisplayName] *** FAILED: $operation ***');
    _d('[DisplayName] exceptionType=${error.runtimeType}');
    _d('[DisplayName] exception=$error');
    if (firestorePath != null) {
      _d('[DisplayName] firestorePath=$firestorePath');
    }
    _d('[DisplayName] authUid=${authUid ?? 'null'}');
    _d('[DisplayName] stackTrace:\n$stack');
  }
}
