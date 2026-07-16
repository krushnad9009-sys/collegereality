import 'package:cloud_firestore/cloud_firestore.dart';

/// Guards Firestore seed writes and detects empty collections.
class FirestoreSeedGuard {
  FirestoreSeedGuard._();

  static bool _collegeSeedInProgress = false;
  static bool _collegeSeedCompleted = false;

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

  /// Returns true when a meta bootstrap doc exists.
  static Future<bool> isMetaSeeded(String metaDocId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('_meta')
          .doc(metaDocId)
          .get();
      return doc.exists;
    } on FirebaseException {
      return false;
    }
  }

  /// Prevents duplicate concurrent college seed runs in one session.
  static bool tryBeginCollegeSeed() {
    if (_collegeSeedCompleted || _collegeSeedInProgress) return false;
    _collegeSeedInProgress = true;
    return true;
  }

  static void completeCollegeSeed() {
    _collegeSeedInProgress = false;
    _collegeSeedCompleted = true;
  }

  static void failCollegeSeed() {
    _collegeSeedInProgress = false;
  }

  static bool get collegeSeedCompleted => _collegeSeedCompleted;

  /// Runs a one-time bootstrap seed when the meta doc and sample data are absent.
  static Future<bool> tryBootstrapSeed({
    required String metaDocId,
    required Future<QuerySnapshot<Map<String, dynamic>>> sampleQuery,
    required Future<void> Function() seed,
  }) async {
    if (await isMetaSeeded(metaDocId)) return true;
    if (await hasSampleData(sampleQuery)) {
      try {
        await FirebaseFirestore.instance.collection('_meta').doc(metaDocId).set({
          'seededAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        return true;
      }
      return true;
    }
    try {
      await seed();
      await FirebaseFirestore.instance.collection('_meta').doc(metaDocId).set({
        'seededAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      return true;
    } on FirebaseException {
      return false;
    }
  }
}
