import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/question_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/answer_model.dart';
import '../models/answer_reply_model.dart';
import '../models/question_model.dart';
import '../repositories/question_repository.dart';
import '../services/firestore_question_service.dart';
import '../services/question_cache_service.dart';
import '../services/question_storage_service.dart';
import '../utils/question_display_utils.dart';

final firestoreQuestionServiceProvider = Provider<FirestoreQuestionService>((ref) {
  return FirestoreQuestionService();
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl(ref.watch(firestoreQuestionServiceProvider));
});

final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return {};
  final ids = await ref.read(questionRepositoryProvider).getBlockedUserIds(authUser.uid);
  return ids.toSet();
});

final isVerifiedForCollegeAnswerProvider =
    FutureProvider.family<bool, String>((ref, collegeId) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return false;
  return ref.read(questionRepositoryProvider).isVerifiedStudentOfCollege(
        authUser.uid,
        collegeId,
      );
});

final collegeQuestionsProvider =
    StreamProvider.family<List<QuestionModel>, String>((ref, collegeId) {
  return ref.watch(questionRepositoryProvider).watchQuestionsByCollege(collegeId);
});

final unansweredQuestionsProvider =
    FutureProvider.family<List<QuestionModel>, String>((ref, collegeId) {
  return ref.read(questionRepositoryProvider).getUnansweredQuestions(collegeId);
});

class QuestionListFilterNotifier extends StateNotifier<QuestionListState> {
  QuestionListFilterNotifier() : super(const QuestionListState());

  void setFilter(String filter) => state = state.copyWith(filter: filter);
  void setCategory(String category) => state = state.copyWith(category: category);
  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void showMore() => state = state.copyWith(visibleCount: state.visibleCount + QuestionConstants.pageSize);
  void resetPagination() => state = state.copyWith(visibleCount: QuestionConstants.pageSize);
}

class QuestionListState {
  final String filter;
  final String category;
  final String searchQuery;
  final int visibleCount;

  const QuestionListState({
    this.filter = QuestionConstants.filterLatest,
    this.category = QuestionConstants.categoryAll,
    this.searchQuery = '',
    this.visibleCount = QuestionConstants.pageSize,
  });

  QuestionListState copyWith({
    String? filter,
    String? category,
    String? searchQuery,
    int? visibleCount,
  }) {
    return QuestionListState(
      filter: filter ?? this.filter,
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }
}

final questionListFilterProvider =
    StateNotifierProvider.family<QuestionListFilterNotifier, QuestionListState, String>(
  (ref, collegeId) => QuestionListFilterNotifier(),
);

final mergedCollegeQuestionsProvider =
    Provider.family<AsyncValue<List<QuestionModel>>, String>((ref, collegeId) {
  final normalizedId = collegeId.trim();
  final streamAsync = ref.watch(collegeQuestionsProvider(normalizedId));
  final optimistic =
      ref.watch(optimisticQuestionsProvider)[normalizedId] ?? const [];

  return streamAsync.when(
    data: (streamQuestions) {
      if (optimistic.isEmpty) {
        QuestionCacheService.saveCollegeQuestions(normalizedId, streamQuestions);
        return AsyncValue.data(streamQuestions);
      }
      final byId = {for (final q in streamQuestions) q.id: q};
      for (final q in optimistic) {
        byId.putIfAbsent(q.id, () => q);
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      QuestionCacheService.saveCollegeQuestions(normalizedId, merged);
      return AsyncValue.data(merged);
    },
    loading: () => optimistic.isEmpty
        ? const AsyncValue.loading()
        : AsyncValue.data(optimistic),
    error: (error, stack) => optimistic.isEmpty
        ? AsyncValue.error(error, stack)
        : AsyncValue.data(optimistic),
  );
});

final displayedCollegeQuestionsProvider =
    Provider.family<AsyncValue<DisplayedQuestionsResult>, String>((ref, collegeId) {
  final mergedAsync = ref.watch(mergedCollegeQuestionsProvider(collegeId));
  final filterState = ref.watch(questionListFilterProvider(collegeId));
  final blockedAsync = ref.watch(blockedUserIdsProvider);

  return mergedAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (questions) {
      final blocked = blockedAsync.valueOrNull ?? {};
      final filtered = filterAndSortQuestions(
        questions: filterBlockedAuthors(questions, blocked),
        filter: filterState.filter,
        searchQuery: filterState.searchQuery,
        category: filterState.category,
      );
      final visible = paginateQuestions(
        filtered,
        page: 0,
        pageSize: filterState.visibleCount,
      );
      return AsyncValue.data(
        DisplayedQuestionsResult(
          questions: visible,
          totalFiltered: filtered.length,
          hasMore: hasMoreQuestions(filtered, filterState.visibleCount),
        ),
      );
    },
  );
});

class DisplayedQuestionsResult {
  final List<QuestionModel> questions;
  final int totalFiltered;
  final bool hasMore;

  const DisplayedQuestionsResult({
    required this.questions,
    required this.totalFiltered,
    required this.hasMore,
  });
}

final questionByIdProvider =
    FutureProvider.family<QuestionModel?, String>((ref, questionId) {
  return ref.watch(questionRepositoryProvider).getQuestionById(questionId);
});

final questionAnswersProvider =
    StreamProvider.family<List<AnswerModel>, String>((ref, questionId) {
  return ref.watch(questionRepositoryProvider).watchAnswers(questionId);
});

final sortedQuestionAnswersProvider =
    Provider.family<AsyncValue<List<AnswerModel>>, String>((ref, questionId) {
  final blocked = ref.watch(blockedUserIdsProvider).valueOrNull ?? {};
  return ref.watch(questionAnswersProvider(questionId)).whenData((answers) {
    return filterBlockedAnswerAuthors(sortAnswers(answers), blocked);
  });
});

final answerRepliesProvider = StreamProvider.family<
    List<AnswerReplyModel>,
    ({String questionId, String answerId})>((ref, params) {
  return ref
      .watch(questionRepositoryProvider)
      .watchReplies(params.questionId, params.answerId);
});

final answerVoteProvider =
    FutureProvider.family<String?, ({String questionId, String answerId})>(
  (ref, params) async {
    final authUser = ref.watch(authStateProvider).valueOrNull;
    if (authUser == null) return null;
    return ref.read(questionRepositoryProvider).getUserVote(
          params.questionId,
          params.answerId,
          authUser.uid,
        );
  },
);

class OptimisticQuestionsNotifier
    extends StateNotifier<Map<String, List<QuestionModel>>> {
  OptimisticQuestionsNotifier() : super(const {});

  void addQuestion(String collegeId, QuestionModel question) {
    final key = collegeId.trim();
    final existing = state[key] ?? [];
    state = {
      ...state,
      key: [question, ...existing.where((q) => q.id != question.id)],
    };
  }
}

final optimisticQuestionsProvider =
    StateNotifierProvider<OptimisticQuestionsNotifier, Map<String, List<QuestionModel>>>(
  (ref) => OptimisticQuestionsNotifier(),
);

final allQuestionsAdminProvider =
    FutureProvider.family<List<QuestionModel>, String?>((ref, statusFilter) {
  return ref.watch(questionRepositoryProvider).getAllQuestions(
        limit: 200,
        statusFilter: statusFilter,
      );
});

final openQuestionReportsAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(questionRepositoryProvider).getOpenQuestionReports();
});

final openAnswerReportsAdminProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(questionRepositoryProvider).getOpenAnswerReports();
});

final questionStorageServiceProvider = Provider<QuestionStorageService>((ref) {
  return QuestionStorageService();
});
