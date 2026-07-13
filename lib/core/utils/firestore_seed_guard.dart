import 'package:cloud_firestore/cloud_firestore.dart';

/// Prevents permission-denied errors when non-admin clients hit seed helpers.
class FirestoreSeedGuard {
  FirestoreSeedGuard._();

  /// Returns true when seed data already exists (safe to read).
  static Future<bool> hasSampleData(
    Future<QuerySnapshot<Map<String, dynamic>>> sampleQuery,
  ) async {
    try {
      final snap = await sampleQuery;
      return snap.docs.isNotEmpty;
    } on FirebaseException {
      return false;
    }
  }

  /// Client apps must not write seed batches — only admins deploy seed data.
  static Future<void> skipClientSeedWrites() async {}
}
