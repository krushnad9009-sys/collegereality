import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/answer_model.dart';
import '../models/question_model.dart';
import '../repositories/question_repository.dart';
import '../services/firestore_question_service.dart';
import '../utils/question_display_utils.dart';

final firestoreQuestionServiceProvider = Provider<FirestoreQuestionService>((ref) {
  return FirestoreQuestionService();
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepositoryImpl(ref.watch(firestoreQuestionServiceProvider));
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

class QuestionListFilterNotifier extends StateNotifier<QuestionListState> {
  QuestionListFilterNotifier() : super(const QuestionListState());

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

class QuestionListState {
  final String filter;
  final String searchQuery;

  const QuestionListState({
    this.filter = 'latest',
    this.searchQuery = '',
  });

  QuestionListState copyWith({String? filter, String? searchQuery}) {
    return QuestionListState(
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
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
        return AsyncValue.data(streamQuestions);
      }
      final byId = {for (final q in streamQuestions) q.id: q};
      for (final q in optimistic) {
        byId.putIfAbsent(q.id, () => q);
      }
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
    Provider.family<AsyncValue<List<QuestionModel>>, String>((ref, collegeId) {
  final mergedAsync = ref.watch(mergedCollegeQuestionsProvider(collegeId));
  final filterState = ref.watch(questionListFilterProvider(collegeId));

  return mergedAsync.whenData((questions) {
    return filterAndSortQuestions(
      questions: questions,
      filter: filterState.filter,
      searchQuery: filterState.searchQuery,
    );
  });
});

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
  return ref.watch(questionAnswersProvider(questionId)).whenData(sortAnswers);
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

  void syncWithStream(String collegeId, List<QuestionModel> streamQuestions) {
    final key = collegeId.trim();
    final pending = state[key];
    if (pending == null || pending.isEmpty) return;
    final streamIds = streamQuestions.map((q) => q.id).toSet();
    final remaining = pending.where((q) => !streamIds.contains(q.id)).toList();
    if (remaining.isEmpty) {
      final next = Map<String, List<QuestionModel>>.from(state);
      next.remove(key);
      state = next;
    } else if (remaining.length != pending.length) {
      state = {...state, key: remaining};
    }
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
