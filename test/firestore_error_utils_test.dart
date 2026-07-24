import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/utils/firestore_auth_utils.dart';
import 'package:college_reality_india/core/utils/firestore_error_utils.dart';

void main() {
  group('FirestoreErrorUtils', () {
    test('detects permission-denied FirebaseException', () {
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );

      expect(FirestoreErrorUtils.isPermissionDenied(error), isTrue);
      expect(
        FirestoreErrorUtils.userMessage(error),
        kFirestorePermissionUserMessage,
      );
    });

    test('permission exception includes firestore path', () {
      final error = FirestoreErrorUtils.permissionException(
        collectionPath: 'users',
        documentPath: 'abc123',
      );

      expect(error.firestorePath, 'users/abc123');
    });

    test('maps auth errors to sign-in message', () {
      expect(
        FirestoreErrorUtils.userMessage(
          const FirestoreAuthException(FirestoreAuthUtils.notSignedInMessage),
        ),
        FirestoreAuthUtils.notSignedInMessage,
      );
    });
  });
}
