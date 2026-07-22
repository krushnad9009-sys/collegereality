import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/compare_constants.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../../community_feed/providers/college_community_feed_provider.dart';
import '../../questions/providers/question_provider.dart';
import '../../reviews/providers/review_provider.dart';
import '../models/ai_assistant_message.dart';
import '../models/ai_topic.dart';
import '../services/ai_assistant_service.dart';
import '../services/ai_college_data_service.dart';
import '../services/ai_conversation_store.dart';

final aiCollegeDataServiceProvider = Provider<AiCollegeDataService>((ref) {
  return AiCollegeDataService(
    ref.watch(collegeRepositoryProvider),
    ref.watch(reviewRepositoryProvider),
    ref.watch(questionRepositoryProvider),
    ref.watch(collegeCommunityFeedRepositoryProvider),
  );
});

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService(
    ref.watch(collegeRepositoryProvider),
    ref.watch(aiCollegeDataServiceProvider),
  );
});

class AiAssistantState {
  final List<AiAssistantMessage> messages;
  final bool isLoading;
  final String? error;
  final List<String> contextCollegeIds;
  final String? anchorCollegeId;
  final AiAssistantMode mode;
  final bool historyLoaded;

  const AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.contextCollegeIds = const [],
    this.anchorCollegeId,
    this.mode = AiAssistantMode.chat,
    this.historyLoaded = false,
  });

  AiAssistantState copyWith({
    List<AiAssistantMessage>? messages,
    bool? isLoading,
    String? error,
    List<String>? contextCollegeIds,
    String? anchorCollegeId,
    AiAssistantMode? mode,
    bool? historyLoaded,
    bool clearError = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      contextCollegeIds: contextCollegeIds ?? this.contextCollegeIds,
      anchorCollegeId: anchorCollegeId ?? this.anchorCollegeId,
      mode: mode ?? this.mode,
      historyLoaded: historyLoaded ?? this.historyLoaded,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  AiAssistantNotifier(this._service, this._ref)
      : super(const AiAssistantState()) {
    _loadHistory();
  }

  final AiAssistantService _service;
  final Ref _ref;

  Future<void> _loadHistory() async {
    final saved = await AiConversationStore.load();
    if (saved.isNotEmpty) {
      state = state.copyWith(messages: saved, historyLoaded: true);
    } else {
      state = state.copyWith(historyLoaded: true);
    }
  }

  Future<void> _persistHistory() async {
    final trimmed = state.messages.length > AiAssistantConstants.maxConversationTurns * 2
        ? state.messages.sublist(
            state.messages.length - AiAssistantConstants.maxConversationTurns * 2,
          )
        : state.messages;
    await AiConversationStore.save(trimmed);
  }

  void setAnchorCollege(String? collegeId) {
    state = state.copyWith(
      anchorCollegeId: collegeId,
      contextCollegeIds: collegeId != null ? [collegeId] : [],
    );
  }

  void setMode(AiAssistantMode mode) {
    state = state.copyWith(mode: mode);
  }

  void addContextCollege(String collegeId) {
    if (state.contextCollegeIds.contains(collegeId)) return;
    final updated = [...state.contextCollegeIds, collegeId]
        .take(CompareConstants.maxColleges)
        .toList();
    state = state.copyWith(contextCollegeIds: updated);
  }

  Future<void> clearConversation() async {
    state = AiAssistantState(
      anchorCollegeId: state.anchorCollegeId,
      mode: state.mode,
      historyLoaded: true,
    );
    await AiConversationStore.clear();
  }

  Future<void> sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = AiAssistantMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      role: AiMessageRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
      mode: state.mode,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      clearError: true,
    );

    try {
      final user = await _ref.read(currentUserDetailProvider.future);
      String? userCity;
      String? userState;
      if (user?.collegeId != null) {
        final college = await _ref.read(
          collegeByIdProvider(user!.collegeId!).future,
        );
        userCity = college?.city;
        userState = college?.state;
      }

      AiAssistantMessage response;
      if (state.anchorCollegeId != null) {
        final anchor = await _ref.read(
          collegeByIdProvider(state.anchorCollegeId!).future,
        );
        if (anchor != null) {
          response = await _service.askAboutCollege(
            college: anchor,
            question: trimmed,
            contextCollegeIds: state.contextCollegeIds,
            userCity: userCity,
            userState: userState,
            mode: state.mode,
          );
        } else {
          response = await _service.processQuery(
            query: trimmed,
            contextCollegeIds: state.contextCollegeIds,
            userCity: userCity,
            userState: userState,
            mode: state.mode,
          );
        }
      } else {
        response = await _service.processQuery(
          query: trimmed,
          contextCollegeIds: state.contextCollegeIds,
          userCity: userCity,
          userState: userState,
          mode: state.mode,
        );
      }

      final newContextIds = <String>{
        ...state.contextCollegeIds,
        ...response.recommendations.map((r) => r.college.id),
        if (response.comparison != null)
          ...response.comparison!.colleges.map((c) => c.id),
      }.take(CompareConstants.maxColleges).toList();

      state = state.copyWith(
        messages: [...state.messages, response],
        isLoading: false,
        contextCollegeIds: newContextIds,
      );
      await _persistHistory();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final aiAssistantProvider =
    StateNotifierProvider<AiAssistantNotifier, AiAssistantState>((ref) {
  return AiAssistantNotifier(
    ref.watch(aiAssistantServiceProvider),
    ref,
  );
});
