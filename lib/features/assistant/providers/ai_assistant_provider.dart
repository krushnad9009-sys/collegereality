import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/compare_constants.dart';
import '../../../core/utils/firestore_error_utils.dart';
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
  String? _lastQuery;

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

  /// Retries the last failed query without re-adding a duplicate user
  /// message to the conversation.
  Future<void> retryLastQuery() async {
    final query = _lastQuery;
    if (query == null || query.isEmpty || state.isLoading) return;
    await _runQuery(query, addUserMessage: false);
  }

  Future<void> sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || state.isLoading) return;
    await _runQuery(trimmed, addUserMessage: true);
  }

  static const _queryTimeout = Duration(seconds: 20);

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AiAssistant] $message');
  }

  Future<void> _runQuery(String trimmed, {required bool addUserMessage}) async {
    _lastQuery = trimmed;
    final userMessage = AiAssistantMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      role: AiMessageRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
      mode: state.mode,
    );

    state = state.copyWith(
      messages: addUserMessage ? [...state.messages, userMessage] : state.messages,
      isLoading: true,
      clearError: true,
    );

    _log(
      'query started — collegeId=${state.anchorCollegeId ?? '(none)'} '
      'question="$trimmed" mode=${state.mode}',
    );

    try {
      // Personalization only (the user's own college, for city/state
      // ranking bias) — must never take down the whole request. A user
      // whose own collegeId points at a since-removed/inaccessible
      // document used to fail the ENTIRE query here, even though this
      // data has nothing to do with the college actually being asked
      // about.
      String? userCity;
      String? userState;
      try {
        final user = await _ref.read(currentUserDetailProvider.future);
        if (user?.collegeId != null) {
          final college = await _ref.read(
            collegeByIdProvider(user!.collegeId!).future,
          );
          userCity = college?.city;
          userState = college?.state;
        }
      } catch (e) {
        _log('personalization lookup failed (ignored, non-fatal): $e');
      }

      Future<AiAssistantMessage> runPipeline() async {
        if (state.anchorCollegeId != null) {
          final anchor = await _ref.read(
            collegeByIdProvider(state.anchorCollegeId!).future,
          );
          _log(
            anchor == null
                ? 'anchor college ${state.anchorCollegeId} not found — falling back to general query'
                : 'anchor college resolved: ${anchor.name}',
          );
          if (anchor != null) {
            return _service.askAboutCollege(
              college: anchor,
              question: trimmed,
              contextCollegeIds: state.contextCollegeIds,
              userCity: userCity,
              userState: userState,
              mode: state.mode,
            );
          }
        }
        return _service.processQuery(
          query: trimmed,
          contextCollegeIds: state.contextCollegeIds,
          userCity: userCity,
          userState: userState,
          mode: state.mode,
        );
      }

      final response = await runPipeline().timeout(_queryTimeout);
      _log('query succeeded, dataGrounded=${response.dataGrounded}');

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
    } catch (e, st) {
      // Log the RAW error before it gets sanitized for display — this is
      // what actually explains a "Something went wrong" on screen. Never
      // logs secrets/tokens; Firebase/Firestore exceptions don't carry any.
      _log('query FAILED: ${e.runtimeType}: $e');
      if (kDebugMode) debugPrintStack(stackTrace: st, label: '[AiAssistant] _runQuery');

      final isTimeout = e is TimeoutException;
      state = state.copyWith(
        isLoading: false,
        error: isTimeout
            ? 'That took too long to answer. Please try again.'
            : FirestoreErrorUtils.userMessage(e),
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
