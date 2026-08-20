import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../colleges/repositories/college_repository.dart';
import '../../community_feed/repositories/college_community_feed_repository.dart';
import '../../questions/repositories/question_repository.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/repositories/review_repository.dart';
import '../../student_life/models/student_life_models.dart';
import '../models/ai_college_data_bundle.dart';

/// Fetches and caches college profile + UGC for grounded answers.
class AiCollegeDataService {
  AiCollegeDataService(
    this._colleges,
    this._reviews,
    this._questions,
    this._communityFeed,
  );

  final CollegeRepository _colleges;
  final ReviewRepository _reviews;
  final QuestionRepository _questions;
  final CollegeCommunityFeedRepository _communityFeed;

  final _cache = <String, AiCollegeDataBundle>{};

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AiCollegeDataService] $message');
  }

  /// Formats an exception with its exact Firebase error code when it has
  /// one, so a "FAILED" log line always shows the real, actionable cause
  /// (e.g. `failed-precondition` = missing composite index,
  /// `permission-denied` = security rules) instead of a vague message.
  static String _describe(Object e) {
    if (e is FirebaseException) {
      return 'FirebaseException(code: ${e.code}, plugin: ${e.plugin}, message: ${e.message})';
    }
    return '${e.runtimeType}: $e';
  }

  Future<AiCollegeDataBundle?> fetchBundle(String collegeId) async {
    if (collegeId.isEmpty) return null;
    final cached = _cache[collegeId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <
            AiAssistantConstants.dataCacheTtl) {
      _log('cache hit for collegeId=$collegeId');
      return cached;
    }

    _log('START fetchBundle collegeId=$collegeId');

    _log('START getCollegeById($collegeId)');
    final college = await _colleges.getCollegeById(collegeId);
    if (college == null) {
      _log('SUCCESS getCollegeById -- returned null (not found/inaccessible) for collegeId=$collegeId');
      return null;
    }
    _log('SUCCESS getCollegeById -- "${college.name}"');

    // Every user-generated-content source below is independently resilient:
    // a failure fetching one (e.g. a missing Firestore index, a transient
    // permission/network error) degrades that source to an empty list
    // instead of failing the whole bundle -- the assistant should still be
    // able to answer from whatever real data IS available, and the grounded
    // answer builder already renders "not enough verified data yet" when a
    // topic has nothing to say.
    List<ReviewModel> reviews = const [];
    try {
      _log('START getReviewsPage(collegeId=$collegeId)');
      final reviewPage = await _reviews.getReviewsPage(
        collegeId,
        limit: AiAssistantConstants.maxReviewsPerFetch,
      );
      reviews = reviewPage.reviews.where((r) => r.isPublicVisible).toList();
      _log('SUCCESS getReviewsPage -- ${reviews.length} public reviews');
    } catch (e, st) {
      _log('FAILED getReviewsPage: ${_describe(e)}');
      if (kDebugMode) debugPrintStack(stackTrace: st, label: '[AiCollegeDataService] reviews');
    }

    final snippets = <AiAnswerSnippet>[];
    try {
      _log('START getQuestionsByCollege(collegeId=$collegeId)');
      final questions = await _questions.getQuestionsByCollege(
        collegeId,
        limit: AiAssistantConstants.maxQuestionsPerFetch,
      );
      _log('SUCCESS getQuestionsByCollege -- ${questions.length} published questions');
      for (final question
          in questions.take(AiAssistantConstants.maxQuestionsPerFetch)) {
        try {
          final answers = await _questions.getAnswersForQuestion(
            question.id,
            limit: AiAssistantConstants.maxAnswersPerQuestion,
          );
          for (final answer in answers.where((a) => a.isPublicVisible)) {
            snippets.add(AiAnswerSnippet(answer: answer, question: question));
          }
        } catch (e) {
          _log('FAILED getAnswersForQuestion(questionId=${question.id}): ${_describe(e)}');
        }
        if (snippets.length >= AiAssistantConstants.maxVerifiedAnswersTotal) break;
      }
    } catch (e, st) {
      _log('FAILED getQuestionsByCollege: ${_describe(e)}');
      if (kDebugMode) debugPrintStack(stackTrace: st, label: '[AiCollegeDataService] questions');
    }

    List<StudentCommunityPostModel> posts = [];
    try {
      _log('START fetchFeedPage(collegeId=$collegeId)');
      final page = await _communityFeed.fetchFeedPage(
        collegeId: collegeId,
        mode: StudentLifeConstants.feedLatest,
        limit: AiAssistantConstants.maxCommunityPostsPerFetch,
      );
      posts = page.items;
      _log('SUCCESS fetchFeedPage -- ${posts.length} community posts');
    } catch (e) {
      _log('FAILED fetchFeedPage: ${_describe(e)}');
      posts = [];
    }

    final bundle = AiCollegeDataBundle(
      college: college,
      reviews: reviews,
      verifiedAnswers: snippets.take(AiAssistantConstants.maxVerifiedAnswersTotal).toList(),
      communityPosts: posts,
      fetchedAt: DateTime.now(),
    );
    _cache[collegeId] = bundle;
    _log('SUCCESS fetchBundle collegeId=$collegeId');
    return bundle;
  }

  void clearCache() => _cache.clear();
}
