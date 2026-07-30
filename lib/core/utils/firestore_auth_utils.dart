import 'package:firebase_auth/firebase_auth.dart';

class FirestoreAuthException implements Exception {
  final String message;

  const FirestoreAuthException(this.message);

  @override
  String toString() => message;
}

/// Ensures Firebase Auth is ready before Firestore reads/writes.
class FirestoreAuthUtils {
  FirestoreAuthUtils._();

  static const String notSignedInMessage =
      'Please sign in again to continue.';

  /// Waits for a signed-in user and refreshes the ID token for Firestore.
  static Future<User> ensureAuthenticated({String? expectedUid}) async {
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;

    user ??= await auth.authStateChanges().firstWhere(
          (candidate) => candidate != null,
          orElse: () => null,
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );

    if (user == null) {
      throw const FirestoreAuthException(notSignedInMessage);
    }

    if (expectedUid != null && user.uid != expectedUid) {
      throw const FirestoreAuthException(
        'Account mismatch. Please sign in again.',
      );
    }

    await user.getIdToken(true);
    return user;
  }
}
