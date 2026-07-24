import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firestore_auth_utils.dart';

/// User-facing copy when Firestore quota is exceeded and no cache exists.
const String kFirestoreQuotaUserMessage =
    'College data is temporarily unavailable. Please try again later.';

const String kFirestorePermissionUserMessage =
    'You do not have permission to save this change. Please sign in again and retry.';

class FirestoreQuotaException implements Exception {
  final String message;

  const FirestoreQuotaException([this.message = kFirestoreQuotaUserMessage]);

  @override
  String toString() => message;
}

class FirestorePermissionException implements Exception {
  final String message;
  final String? collectionPath;
  final String? documentPath;

  const FirestorePermissionException({
    this.message = kFirestorePermissionUserMessage,
    this.collectionPath,
    this.documentPath,
  });

  String get firestorePath {
    if (collectionPath == null) return 'unknown';
    if (documentPath == null || documentPath!.isEmpty) {
      return collectionPath!;
    }
    return '$collectionPath/$documentPath';
  }

  @override
  String toString() => message;
}

class FirestoreErrorUtils {
  FirestoreErrorUtils._();

  static bool isQuotaExceeded(FirebaseException error) {
    return error.code == 'resource-exhausted';
  }

  static bool isPermissionDenied(FirebaseException error) {
    return error.code == 'permission-denied';
  }

  static bool isQuotaExceededError(Object error) {
    if (error is FirestoreQuotaException) return true;
    if (error is FirebaseException) return isQuotaExceeded(error);
    final text = error.toString().toLowerCase();
    return text.contains('resource-exhausted') ||
        text.contains('quota exceeded');
  }

  static bool isPermissionDeniedError(Object error) {
    if (error is FirestorePermissionException) return true;
    if (error is FirestoreAuthException) return true;
    if (error is FirebaseException) return isPermissionDenied(error);
    final text = error.toString().toLowerCase();
    return text.contains('permission-denied') ||
        text.contains('missing or insufficient permissions');
  }

  static bool isUserFacingQuotaMessage(String message) {
    return message == kFirestoreQuotaUserMessage ||
        message.contains('temporarily unavailable');
  }

  static String userMessage(Object error) {
    if (error is FirestorePermissionException) return error.message;
    if (error is FirestoreAuthException) return error.message;
    if (error is FirestoreQuotaException) return error.message;
    if (error is FirebaseException) {
      if (isPermissionDenied(error)) return kFirestorePermissionUserMessage;
      if (isQuotaExceeded(error)) return kFirestoreQuotaUserMessage;
      return error.message ?? 'Something went wrong. Please try again.';
    }

    final text = error.toString();
    if (isPermissionDeniedError(error)) {
      return kFirestorePermissionUserMessage;
    }
    if (isQuotaExceededError(error)) {
      return kFirestoreQuotaUserMessage;
    }
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  static FirestorePermissionException permissionException({
    required String collectionPath,
    String? documentPath,
    String? message,
  }) {
    return FirestorePermissionException(
      message: message ?? kFirestorePermissionUserMessage,
      collectionPath: collectionPath,
      documentPath: documentPath,
    );
  }

  static Object rethrowAsUserFacing(
    Object error, {
    String? collectionPath,
    String? documentPath,
  }) {
    if (error is FirestorePermissionException ||
        error is FirestoreAuthException ||
        error is FirestoreQuotaException) {
      return error;
    }

    if (error is FirebaseException && isPermissionDenied(error)) {
      throw permissionException(
        collectionPath: collectionPath ?? 'unknown',
        documentPath: documentPath,
      );
    }

    if (error is FirebaseException && isQuotaExceeded(error)) {
      throw FirestoreQuotaException();
    }

    return error;
  }
}
