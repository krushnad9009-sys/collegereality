import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cache/firestore_quota_guard.dart';
import '../../../core/data/college_bundled_data_source.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/services/firestore_college_service.dart';

/// Preference-driven college queries for the Home feeds.
///
/// Kept separate from `CollegeRepository` on purpose: that interface is
/// implemented by test fakes, and these queries are Home-specific. Mirrors
/// the repository's quota behaviour -- when Firestore is over quota (or the
/// guard is tripped) it answers from the bundled offline dataset instead of
/// throwing, so the feed still renders.
class CollegeRecommendationService {
  final FirestoreCollegeService _service;

  CollegeRecommendationService(this._service);

  /// Best-rated colleges whose `category` equals [category].
  Future<List<CollegeModel>> topRatedInCategory(
    String category, {
    int limit = 10,
  }) {
    return _run(
      fetch: () => _service.getTopRatedInCategory(category, limit: limit),
      offline: () =>
          CollegeBundledDataSource.search(category: category, limit: limit * 3),
      limit: limit,
    );
  }

  /// Best-rated colleges located in [state].
  Future<List<CollegeModel>> topRatedInState(String state, {int limit = 10}) {
    return _run(
      fetch: () => _service.getTopRatedInState(state, limit: limit),
      offline: () =>
          CollegeBundledDataSource.search(state: state, limit: limit * 3),
      limit: limit,
    );
  }

  Future<List<CollegeModel>> _run({
    required Future<List<CollegeModel>> Function() fetch,
    required Future<CollegeSearchPage> Function() offline,
    required int limit,
  }) async {
    Future<List<CollegeModel>> fromBundle() async {
      final page = await offline();
      final sorted = [...page.colleges]
        ..sort(
          (a, b) => b.aggregatedRatings.overall.compareTo(
            a.aggregatedRatings.overall,
          ),
        );
      return sorted.take(limit).toList();
    }

    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      return fromBundle();
    }
    try {
      final colleges = await fetch();
      FirestoreQuotaGuard.instance.markRecovered();
      return colleges;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      return fromBundle();
    }
  }
}
