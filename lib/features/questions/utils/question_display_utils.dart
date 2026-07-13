import '../models/answer_model.dart';
import '../models/question_model.dart';

String buildQuestionSearchText(String title, String body) {
  return '${title.trim()} ${body.trim()}'.toLowerCase();
}

String buildAnonymousQuestionAlias(String userId) {
  final hash = userId.hashCode.abs() % 10000;
  return 'Anonymous Student #$hash';
}

String resolveAuthorDisplayName({
  required String userId,
  required String? displayName,
  required bool isAnonymous,
}) {
  if (isAnonymous) {
    return buildAnonymousQuestionAlias(userId);
  }
  final trimmed = displayName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return 'Student #${userId.hashCode.abs() % 10000}';
}

bool matchesQuestionSearch(QuestionModel question, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return question.searchText.contains(normalized) ||
      question.title.toLowerCase().contains(normalized) ||
      question.body.toLowerCase().contains(normalized);
}

List<QuestionModel> filterAndSortQuestions({
  required List<QuestionModel> questions,
  required String filter,
  required String searchQuery,
}) {
  var filtered = questions.where((q) => q.isPublicVisible).toList();

  if (searchQuery.trim().isNotEmpty) {
    filtered = filtered.where((q) => matchesQuestionSearch(q, searchQuery)).toList();
  }

  switch (filter) {
    case 'most_helpful':
      filtered = filtered.where((q) => q.mostHelpfulAnswerId != null).toList();
      filtered.sort((a, b) {
        final scoreCompare = b.mostHelpfulScore.compareTo(a.mostHelpfulScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      break;
    case 'unanswered':
      filtered = filtered.where((q) => q.isUnanswered).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    default:
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return filtered;
}

List<AnswerModel> sortAnswers(List<AnswerModel> answers) {
  final visible = answers.where((a) => a.isPublicVisible).toList();
  visible.sort((a, b) {
    if (a.isMostHelpful != b.isMostHelpful) {
      return a.isMostHelpful ? -1 : 1;
    }
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return b.createdAt.compareTo(a.createdAt);
  });
  return visible;
}
