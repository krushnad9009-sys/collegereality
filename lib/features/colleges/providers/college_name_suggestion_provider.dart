import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/college_model.dart';
import '../services/college_name_suggestion_service.dart';
import 'college_provider.dart';

/// Looks up college names for a query.
typedef CollegeNameFetcher = Future<List<CollegeModel>> Function(String query);

/// What the search dropdown knows about the current query.
@immutable
class NameSuggestionsState {
  /// The query [colleges] answers (trimmed). Empty when nothing was asked.
  final String query;

  /// Colleges whose NAME matched [query]. While a newer query is still
  /// loading this is the previous answer, which the dropdown narrows locally
  /// so the list never flickers empty between keystrokes.
  final List<CollegeModel> colleges;

  /// A lookup for [query] is in flight.
  final bool isLoading;

  /// The last lookup failed (treated as "no name matches" by the dropdown).
  final bool failed;

  const NameSuggestionsState({
    this.query = '',
    this.colleges = const [],
    this.isLoading = false,
    this.failed = false,
  });

  static const NameSuggestionsState empty = NameSuggestionsState();
}

/// The search dropdown's controller: takes the (already debounced) query text
/// and fetches name matches, guarding against out-of-order responses.
class NameSuggestionsNotifier extends StateNotifier<NameSuggestionsState> {
  final CollegeNameFetcher _fetch;
  int _generation = 0;

  NameSuggestionsNotifier(this._fetch) : super(NameSuggestionsState.empty);

  Future<void> setQuery(String raw) async {
    final query = raw.trim();
    final generation = ++_generation;

    if (query.isEmpty) {
      state = NameSuggestionsState.empty;
      return;
    }
    // Same query already answered: nothing to do.
    if (query == state.query && !state.isLoading && !state.failed) return;

    state = NameSuggestionsState(
      query: query,
      colleges: state.colleges, // keep the previous answer while loading
      isLoading: true,
    );

    try {
      final colleges = await _fetch(query);
      if (!mounted || generation != _generation) return;
      state = NameSuggestionsState(query: query, colleges: colleges);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = NameSuggestionsState(query: query, failed: true);
    }
  }
}

final collegeNameSuggestionServiceProvider =
    Provider<CollegeNameSuggestionService>((ref) {
      return CollegeNameSuggestionService(
        () => ref.read(firestoreCollegeServiceProvider),
      );
    });

/// Auto-disposed with the search screen; the dropdown widget watches it for
/// as long as it is mounted, so it lives exactly as long as the screen.
final collegeNameSuggestionsProvider =
    StateNotifierProvider.autoDispose<
      NameSuggestionsNotifier,
      NameSuggestionsState
    >((ref) {
      // The service (and the Firestore instance behind it) is only touched
      // when a lookup actually runs, inside the notifier's try/catch. So
      // merely showing the search screen can never fail because of it, and a
      // lookup that can't run just degrades to the state/city fallback.
      return NameSuggestionsNotifier(
        (query) =>
            ref.read(collegeNameSuggestionServiceProvider).suggest(query),
      );
    });
