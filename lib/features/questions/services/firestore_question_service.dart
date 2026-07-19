import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/question_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../social/services/moderation_service.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../utils/question_display_utils.dart';

class FirestoreQuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _moderationService = ModerationService();

  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection(FirestoreConstants.collegeQuestionsCollection);

  Future<Map<String, dynamic>?> _userData(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .get();
    return doc.data();
  }

  Future<bool> isVerifiedStudent(String userId) async {
    final data = await _userData(userId);
    if (data == null) return false;
    final badge = data['verificationBadge'] as String?;
    final status = data['verificationStatus'] as String?;
    return VerificationConstants.isApprovedStudentOrAlumni(badge, status);
  }

  Future<bool> isVerifiedStudentOfCollege(String userId, String collegeId) async {
    final data = await _userData(userId);
    if (data == null) return false;
    final badge = data['verificationBadge'] as String?;
    final status = data['verificationStatus'] as String?;
    if (!VerificationConstants.isApprovedStudentOrAlumni(badge, status)) {
      return false;
    }
    final userCollegeId = (data['collegeId'] as String?)?.trim();
    return userCollegeId != null && userCollegeId == collegeId.trim();
  }

  Future<QuestionModel> createQuestion({
    required String collegeId,
    required String collegeName,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String title,
    String body = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw QuestionFirestoreException(message: 'Question title is required.');
    }
    if (trimmedTitle.length > QuestionConstants.maxTitleLength) {
      throw QuestionFirestoreException(
        message: 'Title must be at most ${QuestionConstants.maxTitleLength} characters.',
      );
    }

    final isVerified = await isVerifiedStudent(authorId);
    final id = _uuid.v4();
    final now = DateTime.now();
    final question = QuestionModel(
      id: id,
      collegeId: collegeId.trim(),
      collegeName: collegeName.trim(),
      authorId: authorId,
      authorDisplayName: resolveAuthorDisplayName(
        userId: authorId,
        displayName: displayName,
        isAnonymous: isAnonymous,
      ),
      isAnonymous: isAnonymous,
      isAuthorVerified: isVerified,
      title: trimmedTitle,
      body: body.trim(),
      searchText: buildQuestionSearchText(trimmedTitle, body),
      status: QuestionConstants.statusPublished,
      createdAt: now,
      updatedAt: now,
    );

    await _questions.doc(id).set(question.toJson());
    return question;
  }

  Future<QuestionModel?> getQuestionById(String questionId) async {
    final doc = await _questions.doc(questionId).get();
    if (!doc.exists) return null;
    return QuestionModel.fromJson(doc.data()!, docId: doc.id);
  }

  Stream<List<QuestionModel>> watchQuestionsByCollege(String collegeId) {
    return _questions
        .where('collegeId', isEqualTo: collegeId.trim())
        .where('status', isEqualTo: QuestionConstants.statusPublished)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuestionModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    });
  }

  Future<List<QuestionModel>> getAllQuestions({
    int limit = 100,
    String? statusFilter,
  }) async {
    Query<Map<String, dynamic>> query =
        _questions.orderBy('createdAt', descending: true);
    if (statusFilter != null) {
      query = query.where(
        'status',
        isEqualTo: QuestionModel.normalizeStatus(statusFilter),
      );
    }
    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => QuestionModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  Future<void> updateQuestionStatus(String questionId, String status) async {
    await _questions.doc(questionId).update({
      'status': QuestionModel.normalizeStatus(status),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteQuestion(String questionId) async {
    final answers = await _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .get();
    final batch = _firestore.batch();
    for (final doc in answers.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_questions.doc(questionId));
    await batch.commit();
  }

  Future<AnswerModel> createAnswer({
    required String questionId,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String body,
  }) async {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      throw QuestionFirestoreException(message: 'Answer cannot be empty.');
    }
    if (trimmedBody.length > QuestionConstants.maxAnswerLength) {
      throw QuestionFirestoreException(
        message: 'Answer must be at most ${QuestionConstants.maxAnswerLength} characters.',
      );
    }

    final question = await getQuestionById(questionId);
    if (question == null) {
      throw QuestionFirestoreException(message: 'Question not found.');
    }
    if (!question.isPublicVisible) {
      throw QuestionFirestoreException(message: 'Question is not available.');
    }

    final canAnswer = await isVerifiedStudentOfCollege(
      authorId,
      question.collegeId,
    );
    if (!canAnswer) {
      throw QuestionFirestoreException(
        message: 'Only verified students of this college can answer.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final answer = AnswerModel(
      id: id,
      questionId: questionId,
      collegeId: question.collegeId,
      authorId: authorId,
      authorDisplayName: resolveAuthorDisplayName(
        userId: authorId,
        displayName: displayName,
        isAnonymous: isAnonymous,
      ),
      isAnonymous: isAnonymous,
      isVerifiedStudent: true,
      body: trimmedBody,
      status: QuestionConstants.statusPublished,
      createdAt: now,
      updatedAt: now,
    );

    final answerRef = _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(id);
    final questionRef = _questions.doc(questionId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(answerRef, answer.toJson());
      transaction.update(questionRef, {
        'answerCount': FieldValue.increment(1),
        'updatedAt': now.toIso8601String(),
      });
    });

    return answer;
  }

  Stream<List<AnswerModel>> watchAnswers(String questionId) {
    return _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .where('status', isEqualTo: QuestionConstants.statusPublished)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnswerModel.fromJson(doc.data(), docId: doc.id))
          .toList();
    });
  }

  Future<String?> getUserVote(String questionId, String answerId, String userId) async {
    final doc = await _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(answerId)
        .collection(FirestoreConstants.answerVotesSubcollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['vote'] as String?;
  }

  Future<void> voteAnswer({
    required String questionId,
    required String answerId,
    required String userId,
    required String vote,
  }) async {
    if (vote != QuestionConstants.voteUp &&
        vote != QuestionConstants.voteDown) {
      throw QuestionFirestoreException(message: 'Invalid vote type.');
    }

    final voteRef = _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(answerId)
        .collection(FirestoreConstants.answerVotesSubcollection)
        .doc(userId);
    final answerRef = _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(answerId);

    await _firestore.runTransaction((transaction) async {
      final existingVote = await transaction.get(voteRef);
      final answerSnap = await transaction.get(answerRef);
      if (!answerSnap.exists) {
        throw QuestionFirestoreException(message: 'Answer not found.');
      }

      var upDelta = 0;
      var downDelta = 0;

      if (existingVote.exists) {
        final previous = existingVote.data()?['vote'] as String?;
        if (previous == vote) {
          transaction.delete(voteRef);
          if (vote == QuestionConstants.voteUp) {
            upDelta = -1;
          } else {
            downDelta = -1;
          }
        } else {
          transaction.update(voteRef, {
            'vote': vote,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          if (vote == QuestionConstants.voteUp) {
            upDelta = 1;
            downDelta = -1;
          } else {
            upDelta = -1;
            downDelta = 1;
          }
        }
      } else {
        transaction.set(voteRef, {
          'userId': userId,
          'vote': vote,
          'createdAt': DateTime.now().toIso8601String(),
        });
        if (vote == QuestionConstants.voteUp) {
          upDelta = 1;
        } else {
          downDelta = 1;
        }
      }

      if (upDelta == 0 && downDelta == 0) return;

      final data = answerSnap.data()!;
      final newUp = ((data['upvoteCount'] as num?)?.toInt() ?? 0) + upDelta;
      final newDown = ((data['downvoteCount'] as num?)?.toInt() ?? 0) + downDelta;

      transaction.update(answerRef, {
        'upvoteCount': newUp.clamp(0, 999999),
        'downvoteCount': newDown.clamp(0, 999999),
        'score': newUp - newDown,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> markMostHelpful({
    required String questionId,
    required String answerId,
    required String userId,
  }) async {
    final question = await getQuestionById(questionId);
    if (question == null) {
      throw QuestionFirestoreException(message: 'Question not found.');
    }
    if (question.authorId != userId) {
      throw QuestionFirestoreException(
        message: 'Only the question author can mark the most helpful answer.',
      );
    }

    final answersSnap = await _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .get();

    AnswerModel? target;
    for (final doc in answersSnap.docs) {
      if (doc.id == answerId) {
        target = AnswerModel.fromJson(doc.data(), docId: doc.id);
        break;
      }
    }
    if (target == null) {
      throw QuestionFirestoreException(message: 'Answer not found.');
    }

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();

    for (final doc in answersSnap.docs) {
      final isTarget = doc.id == answerId;
      batch.update(doc.reference, {
        'isMostHelpful': isTarget,
        'updatedAt': now,
      });
    }

    batch.update(_questions.doc(questionId), {
      'mostHelpfulAnswerId': answerId,
      'mostHelpfulScore': target.score,
      'updatedAt': now,
    });

    await batch.commit();
  }

  Future<void> updateAnswerStatus(String questionId, String answerId, String status) async {
    await _questions
        .doc(questionId)
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(answerId)
        .update({
      'status': AnswerModel.normalizeStatus(status),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteAnswer(String questionId, String answerId) async {
    final questionRef = _questions.doc(questionId);
    final answerRef = questionRef
        .collection(FirestoreConstants.questionAnswersSubcollection)
        .doc(answerId);

    await _firestore.runTransaction((transaction) async {
      final questionSnap = await transaction.get(questionRef);
      final answerSnap = await transaction.get(answerRef);
      if (!answerSnap.exists) return;

      transaction.delete(answerRef);

      if (questionSnap.exists) {
        final data = questionSnap.data()!;
        final count = (data['answerCount'] as num?)?.toInt() ?? 0;
        final wasMostHelpful = data['mostHelpfulAnswerId'] == answerId;
        final updates = <String, dynamic>{
          'answerCount': (count - 1).clamp(0, 999999),
          'updatedAt': DateTime.now().toIso8601String(),
        };
        if (wasMostHelpful) {
          updates['mostHelpfulAnswerId'] = null;
          updates['mostHelpfulScore'] = 0;
        }
        transaction.update(questionRef, updates);
      }
    });
  }

  Future<void> reportQuestion({
    required String questionId,
    required String collegeId,
    required String reporterId,
    required String reason,
  }) async {
    await _firestore
        .collection(FirestoreConstants.questionReportsCollection)
        .add({
      'type': QuestionConstants.reportTypeQuestion,
      'questionId': questionId,
      'collegeId': collegeId.trim(),
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': QuestionConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _moderationService.incrementQuestionReportCount(questionId);
  }

  Future<void> reportAnswer({
    required String questionId,
    required String answerId,
    required String collegeId,
    required String reporterId,
    required String reason,
  }) async {
    await _firestore.collection(FirestoreConstants.answerReportsCollection).add({
      'type': QuestionConstants.reportTypeAnswer,
      'questionId': questionId,
      'answerId': answerId,
      'collegeId': collegeId.trim(),
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': QuestionConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getOpenQuestionReports({int limit = 100}) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.questionReportsCollection)
        .where('status', isEqualTo: QuestionConstants.reportStatusOpen)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getOpenAnswerReports({int limit = 100}) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.answerReportsCollection)
        .where('status', isEqualTo: QuestionConstants.reportStatusOpen)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();
  }

  Future<void> updateQuestionReportStatus(String reportId, String status) async {
    await _firestore
        .collection(FirestoreConstants.questionReportsCollection)
        .doc(reportId)
        .update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateAnswerReportStatus(String reportId, String status) async {
    await _firestore
        .collection(FirestoreConstants.answerReportsCollection)
        .doc(reportId)
        .update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

class QuestionFirestoreException implements Exception {
  final String message;
  QuestionFirestoreException({required this.message});
  @override
  String toString() => message;
}
