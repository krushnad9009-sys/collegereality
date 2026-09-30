import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../communication/models/public_guide_profile.dart';
import '../../communication/providers/communication_provider.dart';
import '../../communication/utils/guide_search_matcher.dart';
import '../providers/home_content_provider.dart';
import 'home_featured.dart';
import 'home_featured_service.dart';

final homeFeaturedServiceProvider = Provider<HomeFeaturedService>((ref) {
  return HomeFeaturedService(
    colleges: ref.watch(firestoreCollegeServiceProvider),
    guides: ref.watch(communicationServiceProvider),
  );
});

/// Live curated config (a Super Admin save shows up without a restart).
/// Never errors: an unreadable doc just means "nothing curated".
final homeFeaturedConfigProvider = StreamProvider<HomeFeaturedConfig>((ref) {
  return ref
      .watch(homeFeaturedServiceProvider)
      .watch()
      .handleError((Object e) => debugPrint('[HomeFeatured] config: $e'));
});

/// Home "Top Picks" items + whether they are hand-picked ([curated]) or
/// the automatic fallback.
typedef TopPicks<T> = ({List<T> items, bool curated});

const int _fallbackCount = 8;

final homeTopCollegesProvider =
    FutureProvider<TopPicks<CollegeModel>>((ref) async {
  final config =
      ref.watch(homeFeaturedConfigProvider).valueOrNull ?? HomeFeaturedConfig.empty;
  if (config.collegeIds.isNotEmpty) {
    final curated = await ref
        .watch(homeFeaturedServiceProvider)
        .loadColleges(config.collegeIds);
    if (curated.isNotEmpty) return (items: curated, curated: true);
  }
  // Nothing pinned (or every pinned college is gone): top-rated instead.
  final topRated = await ref.watch(topRatedCollegesProvider.future);
  return (items: topRated.take(_fallbackCount).toList(), curated: false);
});

final homeTopGuidesProvider =
    FutureProvider<TopPicks<PublicGuideProfile>>((ref) async {
  // Guide profiles (public_profiles) are readable only when signed in.
  if (ref.watch(currentUserProvider) == null) {
    return (items: const <PublicGuideProfile>[], curated: false);
  }
  final config =
      ref.watch(homeFeaturedConfigProvider).valueOrNull ?? HomeFeaturedConfig.empty;
  if (config.guideIds.isNotEmpty) {
    final curated = await ref
        .watch(homeFeaturedServiceProvider)
        .loadGuides(config.guideIds);
    if (curated.isNotEmpty) return (items: curated, curated: true);
  }
  // Fallback: online-now first, then best rated -- the directory's order.
  final all = await ref.watch(guidesDirectoryProvider(null).future);
  return (
    items: GuideSearchMatcher.sortByAvailability(all)
        .take(_fallbackCount)
        .toList(),
    curated: false,
  );
});
