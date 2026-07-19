import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/firestore_quota_guard.dart';
import '../../features/colleges/providers/college_provider.dart';
import '../../features/home/providers/home_content_provider.dart';

/// Whether Firestore requests are blocked due to quota exhaustion.
final firestoreQuotaBlockedProvider = StateProvider<bool>((ref) {
  return FirestoreQuotaGuard.instance.isBlocked;
});

/// Side-effect provider: wires quota recovery probe + auto-refresh.
/// Watch from HomeScreen only — do not watch from providers it invalidates.
final firestoreQuotaCoordinatorProvider = Provider<void>((ref) {
  FirestoreQuotaGuard.instance.setProbe(() async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) return;

    final repository = ref.read(collegeRepositoryProvider);
    await repository.getCollegeCount();
    FirestoreQuotaGuard.instance.markRecovered();
    ref.read(firestoreQuotaBlockedProvider.notifier).state = false;

    ref.invalidate(featuredCollegesProvider);
    ref.invalidate(homeFeaturedCollegesProvider);
    ref.invalidate(trendingCollegesProvider);
    ref.invalidate(topRatedCollegesProvider);
    ref.invalidate(collegeCountProvider);
    ref.invalidate(collegeDirectoryMetaProvider);
    ref.invalidate(collegeSearchPageProvider);
    ref.invalidate(collegeAutocompleteProvider);
    ref.invalidate(homePlacementHighlightsProvider);
  });

  FirestoreQuotaGuard.instance.addRecoveryListener(() {
    ref.read(firestoreQuotaBlockedProvider.notifier).state = false;
    ref.invalidate(featuredCollegesProvider);
    ref.invalidate(homeFeaturedCollegesProvider);
    ref.invalidate(trendingCollegesProvider);
    ref.invalidate(topRatedCollegesProvider);
    ref.invalidate(collegeCountProvider);
    ref.invalidate(collegeSearchPageProvider);
    ref.invalidate(collegeAutocompleteProvider);
    ref.invalidate(homePlacementHighlightsProvider);
  });

  FirestoreQuotaGuard.instance.addBlockedListener(() {
    ref.read(firestoreQuotaBlockedProvider.notifier).state = true;
  });

  ref.onDispose(() {
    FirestoreQuotaGuard.instance.setProbe(() async {});
  });
});
