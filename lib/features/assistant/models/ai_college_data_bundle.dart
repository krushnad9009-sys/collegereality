import '../../colleges/models/college_model.dart';
import '../../student_life/models/student_life_models.dart';
import '../../questions/models/answer_model.dart';
import '../../questions/models/question_model.dart';
import '../../reviews/models/review_model.dart';

class AiAnswerSnippet {
  final AnswerModel answer;
  final QuestionModel question;

  const AiAnswerSnippet({required this.answer, required this.question});
}

class AiCollegeDataBundle {
  final CollegeModel college;
  final List<ReviewModel> reviews;
  final List<AiAnswerSnippet> verifiedAnswers;
  final List<StudentCommunityPostModel> communityPosts;
  final DateTime fetchedAt;

  const AiCollegeDataBundle({
    required this.college,
    this.reviews = const [],
    this.verifiedAnswers = const [],
    this.communityPosts = const [],
    required this.fetchedAt,
  });

  bool get hasUserContent =>
      reviews.isNotEmpty ||
      verifiedAnswers.isNotEmpty ||
      communityPosts.isNotEmpty;
}
