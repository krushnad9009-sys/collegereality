import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/college_local_cache.dart';
import '../../../core/cache/firestore_quota_guard.dart';
import '../../../core/data/college_offline_resolver.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/providers/college_provider.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/providers/review_provider.dart';
import '../../careers/models/careers_models.dart';
import '../../careers/providers/careers_provider.dart';

/// Trending colleges — always returns data (Firestore → cache → bundled seed).
final trendingCollegesProvider =
    FutureProvider<List<CollegeModel>>((ref) async {
  try {
    if (!FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      try {
        await ref.watch(collegeDataReadyProvider.future);
        final featured = await ref.watch(homeFeaturedCollegesProvider.future);
        if (featured.isNotEmpty) {
          final trending = featured.take(12).toList();
          await CollegeLocalCache.saveTrending(trending);
          return trending;
        }
        final colleges = await ref.watch(featuredCollegesProvider.future);
        if (colleges.isNotEmpty) {
          final trending = colleges.take(12).toList();
          await CollegeLocalCache.saveTrending(trending);
          return trending;
        }
      } catch (_) {}
    }
    return await CollegeOfflineResolver.trendingColleges();
  } catch (_) {
    return CollegeOfflineResolver.trendingColleges();
  }
});

/// Top-rated colleges — always returns data (Firestore → cache → bundled seed).
final topRatedCollegesProvider = FutureProvider<List<CollegeModel>>((ref) async {
  try {
    if (!FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      try {
        await ref.watch(collegeDataReadyProvider.future);
        final colleges = await ref.watch(featuredCollegesProvider.future);
        if (colleges.isNotEmpty) {
          final sorted = [...colleges]
            ..sort(
              (a, b) => b.aggregatedRatings.overall
                  .compareTo(a.aggregatedRatings.overall),
            );
          final topRated = sorted.take(8).toList();
          await CollegeLocalCache.saveTopRated(topRated);
          return topRated;
        }
      } catch (_) {}
    }
    return await CollegeOfflineResolver.topRatedColleges();
  } catch (_) {
    return CollegeOfflineResolver.topRatedColleges();
  }
});

/// Recent published student reviews for home feed.
final homeRecentReviewsProvider =
    FutureProvider<List<ReviewModel>>((ref) async {
  final repo = ref.watch(reviewRepositoryProvider);
  final reviews = await repo.getAllReviews(
    limit: 24,
    statusFilter: ReviewModel.statusPublished,
  );
  return reviews.where((r) => r.isPublicVisible).take(6).toList();
});

/// Alumni profiles for success stories strip.
final homeAlumniStoriesProvider =
    FutureProvider<List<AlumniProfileModel>>((ref) async {
  final alumni = await ref.watch(alumniProfilesProvider.future);
  return alumni.take(6).toList();
});

/// Colleges with strongest placement stats.
final homePlacementHighlightsProvider =
    FutureProvider<List<CollegeModel>>((ref) async {
  if (!FirestoreQuotaGuard.instance.shouldBlockRequest()) {
    try {
      await ref.watch(collegeDataReadyProvider.future);
      final source = await ref.watch(featuredCollegesProvider.future);
      if (source.isNotEmpty) {
        final sorted = [...source]
          ..sort(
            (a, b) => b.placements.averagePackageLpa
                .compareTo(a.placements.averagePackageLpa),
          );
        final withPlacements = sorted
            .where((c) => c.placements.averagePackageLpa > 0)
            .take(5)
            .toList();
        if (withPlacements.isNotEmpty) return withPlacements;
        return sorted.take(5).toList();
      }
    } catch (_) {}
  }
  final offline = await CollegeOfflineResolver.featuredColleges(limit: 20);
  final sorted = [...offline]
    ..sort(
      (a, b) =>
          b.placements.averagePackageLpa.compareTo(a.placements.averagePackageLpa),
    );
  return sorted.take(5).toList();
});
