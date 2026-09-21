import '../../../core/constants/college_constants.dart';
import '../../auth/models/user_model.dart';
import '../../onboarding/services/onboarding_location_resolver.dart'
    show kLocationNotProvided;

/// What we know about the signed-in (or guest) user's college interests.
/// Drives the Home "Recommended for You" / "Colleges Near You" feeds.
class UserPreferences {
  /// State to surface colleges from: the one the user picked, else the one
  /// detected at onboarding. Null when neither is known.
  final String? preferredState;

  /// The stream (Engineering, Arts, ...) the user has searched for most.
  final String? preferredCategory;

  /// Searches/clicks per stream — the source of truth for
  /// [preferredCategory] (see [withCategoryInteraction]).
  final Map<String, int> categoryCounts;

  const UserPreferences({
    this.preferredState,
    this.preferredCategory,
    this.categoryCounts = const {},
  });

  static const UserPreferences empty = UserPreferences();

  bool get hasState => preferredState != null;
  bool get hasCategory => preferredCategory != null;
  bool get isEmpty => !hasState && !hasCategory;

  /// Builds preferences from the stored user doc. Falls back to the location
  /// detected at onboarding (`state`) for accounts that pre-date
  /// `preferredState`; the 'Not Provided' sentinel never counts as a state.
  factory UserPreferences.fromUser(UserModel? user) {
    if (user == null) return empty;
    return UserPreferences(
      preferredState:
          usableState(user.preferredState) ?? usableState(user.state),
      preferredCategory: CollegeConstants.clampToAllowed(
        user.preferredCategory,
        CollegeConstants.collegeCategories,
      ),
      categoryCounts: user.categoryInteractionCounts,
    );
  }

  /// Returns [state] trimmed, or null if it is blank or the onboarding
  /// 'Not Provided' sentinel.
  static String? usableState(String? state) {
    final trimmed = state?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == kLocationNotProvided) {
      return null;
    }
    return trimmed;
  }

  /// Registers one interaction with [category] and recomputes the favourite.
  /// The most-searched stream wins; on a tie the one just used wins, so a
  /// user switching interests isn't stuck behind an old, equally-counted one.
  UserPreferences withCategoryInteraction(String category) {
    final counts = {...categoryCounts};
    counts[category] = (counts[category] ?? 0) + 1;
    var best = category;
    counts.forEach((name, count) {
      if (count > counts[best]!) best = name;
    });
    return UserPreferences(
      preferredState: preferredState,
      preferredCategory: best,
      categoryCounts: counts,
    );
  }

  UserPreferences withState(String state) => UserPreferences(
    preferredState: state,
    preferredCategory: preferredCategory,
    categoryCounts: categoryCounts,
  );
}
