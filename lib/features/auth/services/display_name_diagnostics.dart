import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Verbose diagnostics for Display Name Firestore failures.
/// Logs are intentionally noisy while this bug is being tracked.
class DisplayNameDiagnostics {
  DisplayNameDiagnostics._();

  static String? get authUid => FirebaseAuth.instance.currentUser?.uid;

  static void logStart({
    required String operation,
    required String firestorePath,
    String? userModelUid,
  }) {
    debugPrint('[DisplayName] ── $operation ──');
    debugPrint('[DisplayName] firestorePath=$firestorePath');
    debugPrint('[DisplayName] authUid=${authUid ?? 'null'}');
    if (userModelUid != null) {
      debugPrint('[DisplayName] userModelUid=$userModelUid');
      if (authUid != null && authUid != userModelUid) {
        debugPrint(
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
    debugPrint('[DisplayName] *** FAILED: $operation ***');
    debugPrint('[DisplayName] exceptionType=${error.runtimeType}');
    debugPrint('[DisplayName] exception=$error');
    if (firestorePath != null) {
      debugPrint('[DisplayName] firestorePath=$firestorePath');
    }
    debugPrint('[DisplayName] authUid=${authUid ?? 'null'}');
    debugPrint('[DisplayName] stackTrace:\n$stack');
  }
}
