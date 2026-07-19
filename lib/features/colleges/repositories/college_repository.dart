import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/college_model.dart';
import '../services/firestore_college_service.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/cache/college_session_cache.dart';
import '../../../core/cache/college_local_cache.dart';
import '../../../core/cache/firestore_quota_guard.dart';
import '../../../core/utils/firestore_error_utils.dart';

abstract class CollegeRepository {
  Future<List<CollegeModel>> getFeaturedColleges({int limit});
  Future<CollegeModel?> getCollegeById(String id);
  Future<List<CollegeModel>> getCollegesByIds(List<String> ids);
  Future<CollegeSearchPage> searchColleges({
    String? query,
    String? state,
    String? city,
    String? course,
    String? category,
    String? startAfterDocumentId,
    int limit,
    bool includeInactive,
  });
  Future<List<CollegeModel>> autocomplete(String query);
  Future<CollegeDirectoryMeta> getDirectoryMeta();
  Future<int> getCollegeCount({bool activeOnly});
  Future<void> createCollege(CollegeModel college);
  Future<void> updateCollege(CollegeModel college, {String? updatedBy});
  Future<void> setCollegeActive(String id, {required bool isActive});
}

class CollegeRepositoryImpl implements CollegeRepository {
  final FirestoreCollegeService _service;

  CollegeRepositoryImpl(this._service);

  Future<T> _withQuotaHandling<T>({
    required Future<T> Function() fetch,
    required Future<T?> Function() loadLocalCache,
    T? Function()? loadSessionCache,
    Future<void> Function(T result)? persist,
  }) async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      final session = loadSessionCache?.call();
      if (session != null) return session;
      final local = await loadLocalCache();
      if (local != null) return local;
      throw const FirestoreQuotaException();
    }

    try {
      final result = await fetch();
      FirestoreQuotaGuard.instance.markRecovered();
      if (persist != null) {
        await persist(result);
      }
      return result;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();

      final session = loadSessionCache?.call();
      if (session != null) return session;
      final local = await loadLocalCache();
      if (local != null) return local;
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<List<CollegeModel>> getFeaturedColleges({
    int limit = CollegeConstants.featuredLimit,
  }) async {
    final cached = CollegeSessionCache.getFeatured(limit);
    if (cached != null) return cached;

    return _withQuotaHandling<List<CollegeModel>>(
      loadSessionCache: () => CollegeSessionCache.getFeaturedStale(limit),
      loadLocalCache: () async {
        final local = await CollegeLocalCache.loadFeatured();
        if (local == null) return null;
        return local.length <= limit ? local : local.take(limit).toList();
      },
      fetch: () async {
        final colleges = await _service.getFeaturedColleges(limit: limit);
        return colleges.length <= limit
            ? colleges
            : colleges.take(limit).toList();
      },
      persist: (colleges) async {
        CollegeSessionCache.setFeatured(colleges);
        await CollegeLocalCache.saveFeatured(colleges);
      },
    );
  }

  @override
  Future<CollegeModel?> getCollegeById(String id) async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      final featured = CollegeSessionCache.getFeaturedStale(500);
      if (featured != null) {
        for (final college in featured) {
          if (college.id == id) return college;
        }
      }
      final local = await CollegeLocalCache.loadFeatured();
      if (local != null) {
        for (final college in local) {
          if (college.id == id) return college;
        }
      }
      throw const FirestoreQuotaException();
    }

    try {
      final college = await _service.getCollegeById(id);
      FirestoreQuotaGuard.instance.markRecovered();
      return college;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<List<CollegeModel>> getCollegesByIds(List<String> ids) async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      throw const FirestoreQuotaException();
    }

    try {
      final colleges = await _service.getCollegesByIds(ids);
      FirestoreQuotaGuard.instance.markRecovered();
      return colleges;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<CollegeSearchPage> searchColleges({
    String? query,
    String? state,
    String? city,
    String? course,
    String? category,
    String? startAfterDocumentId,
    int limit = 24,
    bool includeInactive = false,
  }) async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      final session = CollegeSessionCache.getSearchStale(limit);
      if (session != null && session.isNotEmpty) {
        return CollegeSearchPage(
          colleges: session,
          hasMore: false,
        );
      }
      final local = await CollegeLocalCache.loadSearch();
      if (local != null && local.isNotEmpty) {
        return CollegeSearchPage(
          colleges: local.take(limit).toList(),
          hasMore: false,
        );
      }
      throw const FirestoreQuotaException();
    }

    try {
      final page = await _service.searchColleges(
        query: query,
        state: state,
        city: city,
        course: course,
        category: category,
        startAfterDocumentId: startAfterDocumentId,
        limit: limit,
        includeInactive: includeInactive,
      );
      FirestoreQuotaGuard.instance.markRecovered();
      if (page.colleges.isNotEmpty) {
        CollegeSessionCache.setSearch(page.colleges);
        await CollegeLocalCache.saveSearch(page.colleges);
      }
      return page;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();

      final session = CollegeSessionCache.getSearchStale(limit);
      if (session != null && session.isNotEmpty) {
        return CollegeSearchPage(colleges: session, hasMore: false);
      }
      final local = await CollegeLocalCache.loadSearch();
      if (local != null && local.isNotEmpty) {
        return CollegeSearchPage(
          colleges: local.take(limit).toList(),
          hasMore: false,
        );
      }
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<List<CollegeModel>> autocomplete(String query) async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      final session = CollegeSessionCache.getSearchStale(12);
      if (session != null) {
        return session
            .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
            .take(12)
            .toList();
      }
      throw const FirestoreQuotaException();
    }

    try {
      final results = await _service.autocompleteColleges(query);
      FirestoreQuotaGuard.instance.markRecovered();
      return results;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<CollegeDirectoryMeta> getDirectoryMeta() async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      throw const FirestoreQuotaException();
    }

    try {
      final meta = await _service.getDirectoryMeta();
      FirestoreQuotaGuard.instance.markRecovered();
      return meta;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<int> getCollegeCount({bool activeOnly = true}) async {
    if (FirestoreQuotaGuard.instance.shouldBlockRequest()) {
      final cached = await CollegeLocalCache.loadCollegeCount();
      if (cached != null && cached > 0) return cached;
      throw const FirestoreQuotaException();
    }

    try {
      final count = await _service.getCollegeCount(activeOnly: activeOnly);
      FirestoreQuotaGuard.instance.markRecovered();
      if (count > 0) {
        await CollegeLocalCache.saveCollegeCount(count);
      }
      return count;
    } on FirebaseException catch (e) {
      if (!FirestoreErrorUtils.isQuotaExceeded(e)) rethrow;
      FirestoreQuotaGuard.instance.markQuotaExceeded();
      final cached = await CollegeLocalCache.loadCollegeCount();
      if (cached != null && cached > 0) return cached;
      throw const FirestoreQuotaException();
    }
  }

  @override
  Future<void> createCollege(CollegeModel college) =>
      _service.createCollege(college);

  @override
  Future<void> updateCollege(CollegeModel college, {String? updatedBy}) =>
      _service.updateCollege(college, updatedBy: updatedBy);

  @override
  Future<void> setCollegeActive(String id, {required bool isActive}) =>
      _service.setCollegeActive(id, isActive: isActive);
}
