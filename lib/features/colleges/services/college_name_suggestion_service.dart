import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/cache/firestore_quota_guard.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/data/college_bundled_data_source.dart';
import '../../../core/utils/firestore_error_utils.dart';
import '../models/college_model.dart';
import '../utils/college_name_matcher.dart';
import 'firestore_college_service.dart';

/// College-name suggestions for the search dropdown, with the app's usual
/// quota behaviour: when Firestore is over quota (or the guard is tripped) it
/// answers from the bundled offline colleges instead of failing.
///
/// A separate class rather than a `CollegeRepository` method on purpose --
/// that interface is implemented by several test fakes and this is specific
/// to the search dropdown.
class CollegeNameSuggestionService {
  final FirestoreCollegeService Function() _serviceFactory;

  /// [serviceFactory] is called only when an online lookup actually runs, so
  /// constructing this (or watching the provider that owns it) never touches
  /// Firestore.
  CollegeNameSuggestionService(this._serviceFactory);

  Future<List<CollegeModel>> suggest(
    String query, {
    int limit = CollegeConstants.nameSuggestionLimit,
  }) async {
    Future<List<CollegeModel>> offline() async => CollegeNameMatcher.rank(
      query,
      await CollegeBundledDataSource.loadAll(),
      limit: limit,
    );

    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) return offline();
    try {
      final colleges = await _serviceFactory().suggestCollegesByName(
        query,
        limit: limit,
      );
      FirestoreQuotaGuard.instance.markRecovered();
      return colleges;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      return offline();
    }
  }
}
