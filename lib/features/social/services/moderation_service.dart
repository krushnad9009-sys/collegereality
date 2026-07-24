import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/constants/social_constants.dart';
import '../../../core/constants/student_life_constants.dart';
import '../utils/moderation_utils.dart';

class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> incrementMessageReportCount(String messageId) async {
    final ref = _firestore
        .collection(FirestoreConstants.communityMessagesCollection)
        .doc(messageId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = (snap.data()?['reportCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      final updates = <String, dynamic>{
        'reportCount': next,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (shouldAutoHide(next)) {
        updates['status'] = SocialConstants.contentStatusHidden;
        updates['moderationFlag'] = SocialConstants.moderationFlagReported;
      }
      tx.update(ref, updates);
    });
  }

  Future<void> incrementPostReportCount(String postId) async {
    final ref = _firestore
        .collection(FirestoreConstants.studentCommunityPostsCollection)
        .doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = (snap.data()?['reportCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      final updates = <String, dynamic>{
        'reportCount': next,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (shouldAutoHide(next)) {
        updates['status'] = StudentLifeConstants.statusHidden;
        updates['moderationFlag'] = SocialConstants.moderationFlagReported;
      }
      tx.update(ref, updates);
    });
  }

  Future<void> incrementQuestionReportCount(String questionId) async {
    final ref = _firestore
        .collection(FirestoreConstants.collegeQuestionsCollection)
        .doc(questionId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = (snap.data()?['reportCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      final updates = <String, dynamic>{
        'reportCount': next,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (shouldAutoHide(next)) {
        updates['status'] = QuestionConstants.statusHidden;
        updates['moderationFlag'] = SocialConstants.moderationFlagReported;
      }
      tx.update(ref, updates);
    });
  }

  Future<List<Map<String, dynamic>>> fetchAutoHiddenMessages({int limit = 50}) async {
    final snap = await _firestore
        .collection(FirestoreConstants.communityMessagesCollection)
        .where('status', isEqualTo: SocialConstants.contentStatusHidden)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> fetchSpamFlaggedMessages({int limit = 50}) async {
    final snap = await _firestore
        .collection(FirestoreConstants.communityMessagesCollection)
        .where('moderationFlag', isEqualTo: SocialConstants.moderationFlagSpam)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  Future<void> restoreMessage(String messageId) async {
    await _firestore
        .collection(FirestoreConstants.communityMessagesCollection)
        .doc(messageId)
        .update({
      'status': SocialConstants.contentStatusVisible,
      'moderationFlag': FieldValue.delete(),
      'reportCount': 0,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> hideMessageAsSpam(String messageId) async {
    await _firestore
        .collection(FirestoreConstants.communityMessagesCollection)
        .doc(messageId)
        .update({
      'status': SocialConstants.contentStatusHidden,
      'moderationFlag': SocialConstants.moderationFlagSpam,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> incrementAnswerReportCount(
    String questionId,
    String answerId,
  ) async {
    final ref = _firestore
        .collection(FirestoreConstants.collegeQuestionsCollection)
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(answerId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final current = (snap.data()?['reportCount'] as num?)?.toInt() ?? 0;
      final next = current + 1;
      final updates = <String, dynamic>{
        'reportCount': next,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      if (shouldAutoHide(next)) {
        updates['status'] = QuestionConstants.statusHidden;
        updates['moderationFlag'] = SocialConstants.moderationFlagReported;
      }
      tx.update(ref, updates);
    });
  }
}
