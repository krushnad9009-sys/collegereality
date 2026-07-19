import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';

/// Logs admission-seeker interest in talking to verified students/alumni.
class StudentChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> logIntent({
    required String collegeId,
    required String collegeName,
    required String seekerId,
    String seekerName = '',
    required String action,
    String? peerId,
    String? peerName,
  }) async {
    if (seekerId.isEmpty || collegeId.isEmpty) return;

    final id = _uuid.v4();
    await _firestore
        .collection(FirestoreConstants.studentChatIntentsCollection)
        .doc(id)
        .set({
      'id': id,
      'collegeId': collegeId.trim(),
      'collegeName': collegeName,
      'seekerId': seekerId,
      'seekerName': seekerName,
      'peerId': peerId,
      'peerName': peerName,
      'action': action,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
