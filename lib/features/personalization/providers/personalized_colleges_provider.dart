import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../home/providers/home_content_provider.dart';
import '../services/college_recommendation_service.dart';
import 'user_preferences_provider.dart';

const int kPersonalizedFeedSize = 10;

/// A Home carousel's contents plus how they were chosen, so the UI can label
/// a global fallback honestly instead of calling it "picked for you".
class PersonalizedFeed {
  final List<CollegeModel> colleges;

  /// True when [colleges] matched the user's stored preference; false when
  /// this is the global top-rated fallback.
  final bool isPersonalized;

  /// The preference that was matched ("Arts", "Maharashtra"); null on fallback.
  final String? matchedOn;

  const PersonalizedFeed({
    required this.colleges,
    this.isPersonalized = false,
    this.matchedOn,
  });

  static const PersonalizedFeed empty = PersonalizedFeed(colleges: []);
}

final collegeRecommendationServiceProvider =
    Provider<CollegeRecommendationService>((ref) {
      return CollegeRecommendationService(
        ref.watch(firestoreCollegeServiceProvider),
      );
    });

/// "Recommended Colleges" — colleges whose `category` equals the user's
/// `preferredCategory`, best-rated first. With no preference (or no matching
/// colleges, or a failed query) it degrades to the global top-rated list,
/// which itself always resolves (Firestore → cache → bundled seed).
final recommendedCollegesProvider = FutureProvider<PersonalizedFeed>((
  ref,
) async {
  // Same startup deferral as homeFeaturedCollegesProvider: no college reads
  // until Home has painted.
  if (!ref.watch(homeContentReadyProvider)) return PersonalizedFeed.empty;

  final category = ref.watch(
    userPreferencesProvider.select((p) => p.preferredCategory),
  );

  if (category != null) {
    try {
      final colleges = await ref
          .watch(collegeRecommendationServiceProvider)
          .topRatedInCategory(category, limit: kPersonalizedFeedSize);
      if (colleges.isNotEmpty) {
        return PersonalizedFeed(
          colleges: colleges,
          isPersonalized: true,
          matchedOn: category,
        );
      }
    } catch (_) {
      // Fall through to the global list: a broken personalised query must
      // never leave the section empty.
    }
  }
  return PersonalizedFeed(
    colleges: await ref.watch(topRatedCollegesProvider.future),
  );
});

/// "Colleges Near You" — colleges whose `state` matches the user's
/// `preferredState`, best-rated first.
///
/// Returns an empty feed (the section hides itself) when the state is
/// unknown or has no colleges. The global fallback for an unknown state is
/// the Trending carousel already on Home directly above this section; a
/// second copy of that list under a "near you" heading would be misleading.
final collegesNearYouProvider = FutureProvider<PersonalizedFeed>((ref) async {
  if (!ref.watch(homeContentReadyProvider)) return PersonalizedFeed.empty;

  final state = ref.watch(
    userPreferencesProvider.select((p) => p.preferredState),
  );
  if (state == null) return PersonalizedFeed.empty;

  try {
    final colleges = await ref
        .watch(collegeRecommendationServiceProvider)
        .topRatedInState(state, limit: kPersonalizedFeedSize);
    if (colleges.isEmpty) return PersonalizedFeed.empty;
    return PersonalizedFeed(
      colleges: colleges,
      isPersonalized: true,
      matchedOn: state,
    );
  } catch (_) {
    return PersonalizedFeed.empty;
  }
});
