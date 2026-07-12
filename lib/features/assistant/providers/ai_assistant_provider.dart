import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/compare_constants.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/providers/college_provider.dart';
import '../models/ai_assistant_message.dart';
import '../services/ai_assistant_service.dart';

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return AiAssistantService(ref.watch(collegeRepositoryProvider));
});

class AiAssistantState {
  final List<AiAssistantMessage> messages;
  final bool isLoading;
  final String? error;
  final List<String> contextCollegeIds;
  final String? anchorCollegeId;

  const AiAssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.contextCollegeIds = const [],
    this.anchorCollegeId,
  });

  AiAssistantState copyWith({
    List<AiAssistantMessage>? messages,
    bool? isLoading,
    String? error,
    List<String>? contextCollegeIds,
    String? anchorCollegeId,
    bool clearError = false,
  }) {
    return AiAssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      contextCollegeIds: contextCollegeIds ?? this.contextCollegeIds,
      anchorCollegeId: anchorCollegeId ?? this.anchorCollegeId,
    );
  }
}

class AiAssistantNotifier extends StateNotifier<AiAssistantState> {
  final AiAssistantService _service;
  final Ref _ref;

  AiAssistantNotifier(this._service, this._ref)
      : super(const AiAssistantState());

  void setAnchorCollege(String? collegeId) {
    state = state.copyWith(
      anchorCollegeId: collegeId,
      contextCollegeIds: collegeId != null ? [collegeId] : [],
    );
  }

  void addContextCollege(String collegeId) {
    if (state.contextCollegeIds.contains(collegeId)) return;
    final updated = [...state.contextCollegeIds, collegeId]
        .take(CompareConstants.maxColleges)
        .toList();
    state = state.copyWith(contextCollegeIds: updated);
  }

  void clearConversation() {
    state = AiAssistantState(anchorCollegeId: state.anchorCollegeId);
  }

  Future<void> sendMessage(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    final userMessage = AiAssistantMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_user',
      role: AiMessageRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
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
          );
        } else {
          response = await _service.processQuery(
            query: trimmed,
            contextCollegeIds: state.contextCollegeIds,
            userCity: userCity,
            userState: userState,
          );
        }
      } else {
        response = await _service.processQuery(
          query: trimmed,
          contextCollegeIds: state.contextCollegeIds,
          userCity: userCity,
          userState: userState,
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
