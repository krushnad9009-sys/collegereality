import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../colleges/repositories/college_repository.dart';
import '../../community_feed/repositories/college_community_feed_repository.dart';
import '../../questions/repositories/question_repository.dart';
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

  Future<AiCollegeDataBundle?> fetchBundle(String collegeId) async {
    if (collegeId.isEmpty) return null;
    final cached = _cache[collegeId];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) <
            AiAssistantConstants.dataCacheTtl) {
      return cached;
    }

    final college = await _colleges.getCollegeById(collegeId);
    if (college == null) return null;

    final reviewPage = await _reviews.getReviewsPage(
      collegeId,
      limit: AiAssistantConstants.maxReviewsPerFetch,
    );
    final reviews =
        reviewPage.reviews.where((r) => r.isPublicVisible).toList();

    final questions = await _questions.getQuestionsByCollege(
      collegeId,
      limit: AiAssistantConstants.maxQuestionsPerFetch,
    );
    final snippets = <AiAnswerSnippet>[];
    for (final question in questions.take(AiAssistantConstants.maxQuestionsPerFetch)) {
      final answers = await _questions.getAnswersForQuestion(
        question.id,
        limit: AiAssistantConstants.maxAnswersPerQuestion,
      );
      for (final answer in answers.where((a) => a.isPublicVisible)) {
        snippets.add(AiAnswerSnippet(answer: answer, question: question));
      }
      if (snippets.length >= AiAssistantConstants.maxVerifiedAnswersTotal) break;
    }

    List<StudentCommunityPostModel> posts = [];
    try {
      final page = await _communityFeed.fetchFeedPage(
        collegeId: collegeId,
        mode: StudentLifeConstants.feedLatest,
        limit: AiAssistantConstants.maxCommunityPostsPerFetch,
      );
      posts = page.items;
    } catch (_) {
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
