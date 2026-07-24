import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/answer_model.dart';
import '../models/answer_reply_model.dart';
import '../models/question_model.dart';
import '../services/firestore_question_service.dart';

abstract class QuestionRepository {
  Future<QuestionModel> createQuestion({
    required String collegeId,
    required String collegeName,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String title,
    String body,
    String category,
    List<String> imageUrls,
  });

  Future<QuestionModel?> getQuestionById(String questionId);
  Stream<List<QuestionModel>> watchQuestionsByCollege(String collegeId);
  Future<QuestionPageResult> fetchQuestionsPage({
    required String collegeId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit,
  });
  Future<List<QuestionModel>> getUnansweredQuestions(String collegeId, {int limit});
  Future<List<QuestionModel>> getQuestionsByCollege(String collegeId, {int limit});
  Future<List<QuestionModel>> getAllQuestions({int limit, String? statusFilter});
  Future<void> updateQuestionStatus(String questionId, String status);
  Future<void> deleteQuestion(String questionId);

  Future<AnswerModel> createAnswer({
    required String questionId,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String body,
    List<String> imageUrls,
  });

  Future<AnswerReplyModel> createReply({
    required String questionId,
    required String answerId,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String body,
    String? parentReplyId,
    List<String> imageUrls,
  });

  Stream<List<AnswerModel>> watchAnswers(String questionId);
  Stream<List<AnswerReplyModel>> watchReplies(String questionId, String answerId);
  Future<List<AnswerModel>> getAnswersForQuestion(String questionId, {int limit});
  Future<String?> getUserVote(String questionId, String answerId, String userId);
  Future<void> voteAnswer({
    required String questionId,
    required String answerId,
    required String userId,
    required String vote,
  });
  Future<void> markMostHelpful({
    required String questionId,
    required String answerId,
    required String userId,
  });
  Future<void> acceptAnswer({
    required String questionId,
    required String answerId,
    required String userId,
  });
  Future<void> updateAnswerStatus(String questionId, String answerId, String status);
  Future<void> deleteAnswer(String questionId, String answerId);

  Future<void> reportQuestion({
    required String questionId,
    required String collegeId,
    required String reporterId,
    required String reason,
  });
  Future<void> reportAnswer({
    required String questionId,
    required String answerId,
    required String collegeId,
    required String reporterId,
    required String reason,
  });

  Future<void> blockUser({required String blockerId, required String blockedId});
  Future<List<String>> getBlockedUserIds(String userId);

  Future<bool> isVerifiedStudent(String userId);
  Future<bool> isVerifiedStudentOfCollege(String userId, String collegeId);
  Future<List<Map<String, dynamic>>> getOpenQuestionReports({int limit});
  Future<List<Map<String, dynamic>>> getOpenAnswerReports({int limit});
  Future<void> updateQuestionReportStatus(String reportId, String status);
  Future<void> updateAnswerReportStatus(String reportId, String status);
}

class QuestionRepositoryImpl implements QuestionRepository {
  final FirestoreQuestionService _service;

  QuestionRepositoryImpl(this._service);

  @override
  Future<QuestionModel> createQuestion({
    required String collegeId,
    required String collegeName,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String title,
    String body = '',
    String category = 'admission',
    List<String> imageUrls = const [],
  }) =>
      _service.createQuestion(
        collegeId: collegeId,
        collegeName: collegeName,
        authorId: authorId,
        displayName: displayName,
        isAnonymous: isAnonymous,
        title: title,
        body: body,
        category: category,
        imageUrls: imageUrls,
      );

  @override
  Future<QuestionModel?> getQuestionById(String questionId) =>
      _service.getQuestionById(questionId);

  @override
  Stream<List<QuestionModel>> watchQuestionsByCollege(String collegeId) =>
      _service.watchQuestionsByCollege(collegeId);

  @override
  Future<QuestionPageResult> fetchQuestionsPage({
    required String collegeId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) =>
      _service.fetchQuestionsPage(
        collegeId: collegeId,
        startAfter: startAfter,
        limit: limit,
      );

  @override
  Future<List<QuestionModel>> getUnansweredQuestions(
    String collegeId, {
    int limit = 5,
  }) =>
      _service.getUnansweredQuestions(collegeId, limit: limit);

  @override
  Future<List<QuestionModel>> getQuestionsByCollege(
    String collegeId, {
    int limit = 5,
  }) =>
      _service.getQuestionsByCollege(collegeId, limit: limit);

  @override
  Future<List<QuestionModel>> getAllQuestions({
    int limit = 100,
    String? statusFilter,
  }) =>
      _service.getAllQuestions(limit: limit, statusFilter: statusFilter);

  @override
  Future<void> updateQuestionStatus(String questionId, String status) =>
      _service.updateQuestionStatus(questionId, status);

  @override
  Future<void> deleteQuestion(String questionId) =>
      _service.deleteQuestion(questionId);

  @override
  Future<AnswerModel> createAnswer({
    required String questionId,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String body,
    List<String> imageUrls = const [],
  }) =>
      _service.createAnswer(
        questionId: questionId,
        authorId: authorId,
        displayName: displayName,
        isAnonymous: isAnonymous,
        body: body,
        imageUrls: imageUrls,
      );

  @override
  Future<AnswerReplyModel> createReply({
    required String questionId,
    required String answerId,
    required String authorId,
    required String? displayName,
    required bool isAnonymous,
    required String body,
    String? parentReplyId,
    List<String> imageUrls = const [],
  }) =>
      _service.createReply(
        questionId: questionId,
        answerId: answerId,
        authorId: authorId,
        displayName: displayName,
        isAnonymous: isAnonymous,
        body: body,
        parentReplyId: parentReplyId,
        imageUrls: imageUrls,
      );

  @override
  Stream<List<AnswerModel>> watchAnswers(String questionId) =>
      _service.watchAnswers(questionId);

  @override
  Stream<List<AnswerReplyModel>> watchReplies(
    String questionId,
    String answerId,
  ) =>
      _service.watchReplies(questionId, answerId);

  @override
  Future<List<AnswerModel>> getAnswersForQuestion(
    String questionId, {
    int limit = 3,
  }) =>
      _service.getAnswersForQuestion(questionId, limit: limit);

  @override
  Future<String?> getUserVote(String questionId, String answerId, String userId) =>
      _service.getUserVote(questionId, answerId, userId);

  @override
  Future<void> voteAnswer({
    required String questionId,
    required String answerId,
    required String userId,
    required String vote,
  }) =>
      _service.voteAnswer(
        questionId: questionId,
        answerId: answerId,
        userId: userId,
        vote: vote,
      );

  @override
  Future<void> markMostHelpful({
    required String questionId,
    required String answerId,
    required String userId,
  }) =>
      _service.markMostHelpful(
        questionId: questionId,
        answerId: answerId,
        userId: userId,
      );

  @override
  Future<void> acceptAnswer({
    required String questionId,
    required String answerId,
    required String userId,
  }) =>
      _service.acceptAnswer(
        questionId: questionId,
        answerId: answerId,
        userId: userId,
      );

  @override
  Future<void> updateAnswerStatus(String questionId, String answerId, String status) =>
      _service.updateAnswerStatus(questionId, answerId, status);

  @override
  Future<void> deleteAnswer(String questionId, String answerId) =>
      _service.deleteAnswer(questionId, answerId);

  @override
  Future<void> reportQuestion({
    required String questionId,
    required String collegeId,
    required String reporterId,
    required String reason,
  }) =>
      _service.reportQuestion(
        questionId: questionId,
        collegeId: collegeId,
        reporterId: reporterId,
        reason: reason,
      );

  @override
  Future<void> reportAnswer({
    required String questionId,
    required String answerId,
    required String collegeId,
    required String reporterId,
    required String reason,
  }) =>
      _service.reportAnswer(
        questionId: questionId,
        answerId: answerId,
        collegeId: collegeId,
        reporterId: reporterId,
        reason: reason,
      );

  @override
  Future<void> blockUser({required String blockerId, required String blockedId}) =>
      _service.blockUser(blockerId: blockerId, blockedId: blockedId);

  @override
  Future<List<String>> getBlockedUserIds(String userId) =>
      _service.getBlockedUserIds(userId);

  @override
  Future<bool> isVerifiedStudent(String userId) =>
      _service.isVerifiedStudent(userId);

  @override
  Future<bool> isVerifiedStudentOfCollege(String userId, String collegeId) =>
      _service.isVerifiedStudentOfCollege(userId, collegeId);

  @override
  Future<List<Map<String, dynamic>>> getOpenQuestionReports({int limit = 100}) =>
      _service.getOpenQuestionReports(limit: limit);

  @override
  Future<List<Map<String, dynamic>>> getOpenAnswerReports({int limit = 100}) =>
      _service.getOpenAnswerReports(limit: limit);

  @override
  Future<void> updateQuestionReportStatus(String reportId, String status) =>
      _service.updateQuestionReportStatus(reportId, status);

  @override
  Future<void> updateAnswerReportStatus(String reportId, String status) =>
      _service.updateAnswerReportStatus(reportId, status);
}
