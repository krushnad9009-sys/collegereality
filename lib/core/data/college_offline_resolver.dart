import '../../features/colleges/models/college_model.dart';
import '../cache/college_local_cache.dart';
import '../cache/firestore_quota_guard.dart';
import 'college_bundled_data_source.dart';

/// Resolves college lists for home/search when Firestore is unavailable.
class CollegeOfflineResolver {
  CollegeOfflineResolver._();

  static Future<bool> hasOfflineData() async {
    if (await CollegeLocalCache.loadFeatured() case final local?) {
      if (local.isNotEmpty) return true;
    }
    final bundled = await CollegeBundledDataSource.loadAll();
    return bundled.length >= CollegeBundledDataSource.minimumFallbackCount;
  }

  static Future<List<CollegeModel>> featuredColleges({int limit = 24}) async {
    if (!FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      final local = await CollegeLocalCache.loadFeatured();
      if (local != null && local.isNotEmpty) {
        return local.length <= limit ? local : local.take(limit).toList();
      }
    } else {
      final local = await CollegeLocalCache.loadFeatured();
      if (local != null && local.isNotEmpty) {
        return local.length <= limit ? local : local.take(limit).toList();
      }
    }

    final bundled =
        await CollegeBundledDataSource.featuredFallback(limit: limit);
    await CollegeLocalCache.saveFeatured(bundled);
    return bundled;
  }

  static Future<List<CollegeModel>> trendingColleges() async {
    final local = await CollegeLocalCache.loadTrending();
    if (local != null && local.isNotEmpty) return local;

    final featuredLocal = await CollegeLocalCache.loadFeatured();
    if (featuredLocal != null && featuredLocal.isNotEmpty) {
      final trending = featuredLocal.take(12).toList();
      await CollegeLocalCache.saveTrending(trending);
      return trending;
    }

    final trending = await CollegeBundledDataSource.trendingFallback();
    await CollegeLocalCache.saveTrending(trending);
    return trending;
  }

  static Future<List<CollegeModel>> topRatedColleges() async {
    final local = await CollegeLocalCache.loadTopRated();
    if (local != null && local.isNotEmpty) return local;

    final featuredLocal = await CollegeLocalCache.loadFeatured();
    if (featuredLocal != null && featuredLocal.isNotEmpty) {
      final sorted = [...featuredLocal]
        ..sort(
          (a, b) =>
              b.aggregatedRatings.overall.compareTo(a.aggregatedRatings.overall),
        );
      final topRated = sorted.take(8).toList();
      await CollegeLocalCache.saveTopRated(topRated);
      return topRated;
    }

    final topRated = await CollegeBundledDataSource.topRatedFallback();
    await CollegeLocalCache.saveTopRated(topRated);
    return topRated;
  }
}
