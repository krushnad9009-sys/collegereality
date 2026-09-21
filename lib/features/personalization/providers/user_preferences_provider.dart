import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/college_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/user_provider.dart';
import '../../colleges/utils/college_search_utils.dart';
import '../models/user_preferences.dart';

/// Holds the user's college-interest tags and is the single place that
/// records them.
///
/// State is updated optimistically (so Home reflects a click the moment the
/// user comes back to it) and then persisted to the owner's `users` doc.
/// Guests have no doc, so for them preferences live for the session only.
/// Persisting is best-effort: it must never block or fail a search.
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final Ref _ref;

  UserPreferencesNotifier(this._ref, UserPreferences initial) : super(initial);

  /// Re-seeds from the stored user doc (sign-in, sign-out, profile reload).
  void syncFromUser(UserModel? user) {
    state = UserPreferences.fromUser(user);
  }

  /// Search-screen hook: call once per executed search with the raw filters.
  ///
  /// Category comes from the resolved search intent, so it counts whether the
  /// user picked a Faculty filter, a Course filter ("B.Tech" → Engineering),
  /// tapped a Home stream tile (which deep-links `?category=`), or typed
  /// "MBA Bangalore". State is only taken from the explicit State filter --
  /// one free-text search for another state shouldn't move "Near You".
  void recordSearch({
    String? query,
    String? state,
    String? course,
    String? category,
  }) {
    final intent = CollegeSearchUtils.resolveSearchIntent(
      query: query,
      state: state,
      course: course,
      category: category,
    );
    recordCategory(
      intent.category ?? CollegeConstants.categoryForCourse(course),
    );
    final selectedState = UserPreferences.usableState(state);
    if (selectedState != null) recordState(selectedState);
  }

  /// Counts one interaction with a stream and refreshes the favourite.
  void recordCategory(String? rawCategory) {
    final category = CollegeConstants.clampToAllowed(
      rawCategory,
      CollegeConstants.collegeCategories,
    );
    // 'General' is the catch-all bucket for uncategorised colleges, not a
    // stream anyone is "interested in".
    if (category == null || category == 'General') return;

    final next = state.withCategoryInteraction(category);
    state = next;
    _persist(
      (uid) => _ref
          .read(userRepositoryProvider)
          .recordCategoryInteraction(
            uid,
            category: category,
            preferredCategory: next.preferredCategory!,
          ),
    );
  }

  /// Remembers a state the user explicitly selected.
  void recordState(String rawState) {
    final selected = UserPreferences.usableState(rawState);
    if (selected == null) return;
    if (selected.toLowerCase() == state.preferredState?.toLowerCase()) return;

    state = state.withState(selected);
    _persist(
      (uid) =>
          _ref.read(userRepositoryProvider).updatePreferredState(uid, selected),
    );
  }

  void _persist(Future<void> Function(String uid) write) {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    Future<void>.sync(() => write(uid)).catchError((Object e) {
      debugPrint('UserPreferences: could not persist preference: $e');
    });
  }
}

final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
      final notifier = UserPreferencesNotifier(
        ref,
        UserPreferences.fromUser(
          ref.read(currentUserDetailProvider).valueOrNull,
        ),
      );
      ref.listen<AsyncValue<UserModel?>>(currentUserDetailProvider, (_, next) {
        // Only fresh data: a loading/refreshing state carries the previous value
        // and would wipe a preference recorded moments ago.
        if (next is AsyncData<UserModel?>) notifier.syncFromUser(next.value);
      });
      return notifier;
    });
