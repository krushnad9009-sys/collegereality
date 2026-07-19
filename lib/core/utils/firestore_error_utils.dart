import 'package:cloud_firestore/cloud_firestore.dart';

/// User-facing copy when Firestore quota is exceeded and no cache exists.
const String kFirestoreQuotaUserMessage =
    'College data is temporarily unavailable. Please try again later.';

class FirestoreQuotaException implements Exception {
  final String message;

  const FirestoreQuotaException([this.message = kFirestoreQuotaUserMessage]);

  @override
  String toString() => message;
}

class FirestoreErrorUtils {
  FirestoreErrorUtils._();

  static bool isQuotaExceeded(FirebaseException error) {
    return error.code == 'resource-exhausted';
  }

  static bool isQuotaExceededError(Object error) {
    if (error is FirestoreQuotaException) return true;
    if (error is FirebaseException) return isQuotaExceeded(error);
    final text = error.toString().toLowerCase();
    return text.contains('resource-exhausted') ||
        text.contains('quota exceeded');
  }

  static bool isUserFacingQuotaMessage(String message) {
    return message == kFirestoreQuotaUserMessage ||
        message.contains('temporarily unavailable');
  }
}
