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

  Future<AiCollegeDataBundle?> fetchBundle(String collegeId) async {
    if (collegeId.isEmpty) return null;
    final cached = _cache[collegeId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <
            AiAssistantConstants.dataCacheTtl) {
      _log('cache hit for collegeId=$collegeId');
      return cached;
    }

    _log('fetching bundle for collegeId=$collegeId');
    final college = await _colleges.getCollegeById(collegeId);
    if (college == null) {
      _log('no college found for collegeId=$collegeId — cannot ground an answer');
      return null;
    }

    // Every user-generated-content source below is independently resilient:
    // a failure fetching one (e.g. a missing Firestore index, a transient
    // permission/network error) degrades that source to an empty list
    // instead of failing the whole bundle — the assistant should still be
    // able to answer from whatever real data IS available, and the grounded
    // answer builder already renders "not enough verified data yet" when a
    // topic has nothing to say.
    List<ReviewModel> reviews = const [];
    try {
      final reviewPage = await _reviews.getReviewsPage(
        collegeId,
        limit: AiAssistantConstants.maxReviewsPerFetch,
      );
      reviews = reviewPage.reviews.where((r) => r.isPublicVisible).toList();
      _log('fetched ${reviews.length} public reviews');
    } catch (e, st) {
      _log('review fetch failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st, label: '[AiCollegeDataService] reviews');
    }

    final snippets = <AiAnswerSnippet>[];
    try {
      final questions = await _questions.getQuestionsByCollege(
        collegeId,
        limit: AiAssistantConstants.maxQuestionsPerFetch,
      );
      _log('fetched ${questions.length} published questions');
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
          _log('answer fetch failed for questionId=${question.id}: $e');
        }
        if (snippets.length >= AiAssistantConstants.maxVerifiedAnswersTotal) break;
      }
    } catch (e, st) {
      _log('question fetch failed: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st, label: '[AiCollegeDataService] questions');
    }

    List<StudentCommunityPostModel> posts = [];
    try {
      final page = await _communityFeed.fetchFeedPage(
        collegeId: collegeId,
        mode: StudentLifeConstants.feedLatest,
        limit: AiAssistantConstants.maxCommunityPostsPerFetch,
      );
      posts = page.items;
      _log('fetched ${posts.length} community posts');
    } catch (e) {
      _log('community feed fetch failed: $e');
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
    return bundle;
  }

  void clearCache() => _cache.clear();
}
