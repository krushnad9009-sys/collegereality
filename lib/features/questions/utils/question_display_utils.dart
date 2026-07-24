import '../../../core/constants/question_constants.dart';
import '../../../core/utils/public_display_name_utils.dart';
import '../../auth/models/user_model.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';

String buildQuestionSearchText(String title, String body, {String category = ''}) {
  return '${title.trim()} ${body.trim()} $category'.toLowerCase();
}

String normalizeQuestionContent(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String buildAnonymousQuestionAlias(String userId) {
  return buildAnonymousVerifiedStudentAlias(userId);
}

String resolveAuthorDisplayName({
  required String userId,
  required String? displayName,
  required bool isAnonymous,
  UserModel? user,
}) {
  if (user != null) {
    return resolvePublicDisplayNameFromUser(user);
  }

  if (isAnonymous) {
    return buildAnonymousQuestionAlias(userId);
  }
  final trimmed = displayName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return 'Student #${userId.hashCode.abs() % 10000}';
}

String resolveAuthorDisplayNameFromUser(UserModel user) {
  return resolvePublicDisplayNameFromUser(user);
}

bool matchesQuestionSearch(QuestionModel question, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return question.searchText.contains(normalized) ||
      question.title.toLowerCase().contains(normalized) ||
      question.body.toLowerCase().contains(normalized) ||
      QuestionConstants.categoryLabel(question.category)
          .toLowerCase()
          .contains(normalized);
}

List<QuestionModel> filterBlockedAuthors(
  List<QuestionModel> questions,
  Set<String> blockedUserIds,
) {
  if (blockedUserIds.isEmpty) return questions;
  return questions.where((q) => !blockedUserIds.contains(q.authorId)).toList();
}

List<AnswerModel> filterBlockedAnswerAuthors(
  List<AnswerModel> answers,
  Set<String> blockedUserIds,
) {
  if (blockedUserIds.isEmpty) return answers;
  return answers.where((a) => !blockedUserIds.contains(a.authorId)).toList();
}

List<QuestionModel> filterAndSortQuestions({
  required List<QuestionModel> questions,
  required String filter,
  required String searchQuery,
  String category = QuestionConstants.categoryAll,
}) {
  var filtered = questions.where((q) => q.isPublicVisible).toList();

  if (category != QuestionConstants.categoryAll) {
    filtered = filtered.where((q) => q.category == category).toList();
  }

  if (searchQuery.trim().isNotEmpty) {
    filtered =
        filtered.where((q) => matchesQuestionSearch(q, searchQuery)).toList();
  }

  switch (filter) {
    case QuestionConstants.filterMostHelpful:
      filtered = filtered.where((q) => q.mostHelpfulAnswerId != null).toList();
      filtered.sort((a, b) {
        final scoreCompare = b.mostHelpfulScore.compareTo(a.mostHelpfulScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      break;
    case QuestionConstants.filterMostUpvoted:
      filtered.sort((a, b) {
        final scoreCompare = b.topAnswerScore.compareTo(a.topAnswerScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      break;
    case QuestionConstants.filterUnanswered:
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
    if (a.isAccepted != b.isAccepted) {
      return a.isAccepted ? -1 : 1;
    }
    if (a.isMostHelpful != b.isMostHelpful) {
      return a.isMostHelpful ? -1 : 1;
    }
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return b.createdAt.compareTo(a.createdAt);
  });
  return visible;
}

List<QuestionModel> paginateQuestions(
  List<QuestionModel> questions, {
  required int page,
  int pageSize = QuestionConstants.pageSize,
}) {
  final end = (page + 1) * pageSize;
  if (end >= questions.length) return questions;
  return questions.sublist(0, end);
}

bool hasMoreQuestions(
  List<QuestionModel> allFiltered,
  int visibleCount,
) {
  return visibleCount < allFiltered.length;
}
