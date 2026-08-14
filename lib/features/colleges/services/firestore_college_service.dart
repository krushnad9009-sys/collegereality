import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/data/college_bundled_data_source.dart';
import '../models/college_model.dart';
import '../utils/college_search_ranker.dart';
import '../utils/college_search_utils.dart';

class FirestoreCollegeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  Future<int> getCollegeCount({bool activeOnly = true}) async {
    Query<Map<String, dynamic>> query = _colleges;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    final countSnapshot = await query.count().get();
    return countSnapshot.count ?? 0;
  }

  Future<List<CollegeModel>> getFeaturedColleges({
    int limit = CollegeConstants.featuredLimit,
  }) async {
    final queryBuilders = <Query<Map<String, dynamic>> Function()>[
      () => _colleges
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('aggregatedRatings.overall', descending: true)
          .limit(limit),
      () => _colleges
          .where('isActive', isEqualTo: true)
          .orderBy('aggregatedRatings.overall', descending: true)
          .limit(limit),
      () => _colleges
          .where('isActive', isEqualTo: true)
          .orderBy('nameLower')
          .limit(limit),
    ];

    for (final buildQuery in queryBuilders) {
      try {
        final snapshot = await buildQuery().get();
        final colleges = _prioritizeFeaturedColleges(
          _mapDocs(snapshot.docs),
          limit,
        );
        if (colleges.isNotEmpty) return colleges;
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
      }
    }

    return [];
  }

  List<CollegeModel> _prioritizeFeaturedColleges(
    List<CollegeModel> colleges,
    int limit,
  ) {
    final sorted = [...colleges]
      ..sort((a, b) {
        final featuredCompare =
            (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0);
        if (featuredCompare != 0) return featuredCompare;

        final photoCompare = (_hasCoverPhoto(b) ? 1 : 0)
            .compareTo(_hasCoverPhoto(a) ? 1 : 0);
        if (photoCompare != 0) return photoCompare;

        final ratingCompare = b.aggregatedRatings.overall
            .compareTo(a.aggregatedRatings.overall);
        if (ratingCompare != 0) return ratingCompare;

        return a.nameLower.compareTo(b.nameLower);
      });
    return sorted.take(limit).toList();
  }

  bool _hasCoverPhoto(CollegeModel college) {
    final url = college.coverPhotoUrl;
    return url != null && url.trim().isNotEmpty && url != 'null';
  }

  Future<CollegeModel?> getCollegeById(String id) async {
    final doc = await _colleges.doc(id).get();
    if (!doc.exists) return null;
    return CollegeModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<List<CollegeModel>> getCollegesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final unique = ids.toSet().toList();
    final results = <CollegeModel>[];
    const chunkSize = 30;
    for (var i = 0; i < unique.length; i += chunkSize) {
      final chunk = unique.skip(i).take(chunkSize).toList();
      final futures = chunk.map((id) => _colleges.doc(id).get());
      final docs = await Future.wait(futures);
      for (final doc in docs) {
        if (doc.exists) {
          results.add(CollegeModel.fromJson(doc.data()!, docId: doc.id));
        }
      }
    }
    final order = {for (var i = 0; i < unique.length; i++) unique[i]: i};
    results.sort(
      (a, b) => (order[a.id] ?? 999).compareTo(order[b.id] ?? 999),
    );
    return results;
  }

  Future<CollegeDirectoryMeta> getDirectoryMeta() async {
    final doc = await _firestore
        .collection(FirestoreConstants.metaCollection)
        .doc(CollegeConstants.metaDirectoryDoc)
        .get();
    if (!doc.exists) return const CollegeDirectoryMeta();
    return CollegeDirectoryMeta.fromJson(doc.data());
  }

  Future<int> countSearchMatches({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? ownership,
    bool includeInactive = false,
  }) async {
    final intent = CollegeSearchUtils.resolveSearchIntent(
      query: query,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      ownership: ownership,
    );
    final effectiveType = intent.type;

    if (intent.hasRetrievalQuery) {
      // Free-text totals require a fetch; avoid recursion with searchAllMatching.
      return -1;
    }

    return _countStructured(
      state: intent.state,
      city: intent.city,
      category: intent.category,
      course: intent.course,
      type: effectiveType,
      includeInactive: includeInactive,
    );
  }

  Future<int> _countStructured({
    String? state,
    String? city,
    String? category,
    String? course,
    String? type,
    bool includeInactive = false,
  }) async {
    Query<Map<String, dynamic>> q = _colleges;
    if (!includeInactive) {
      q = q.where('isActive', isEqualTo: true);
    }
    if (state != null && state.isNotEmpty) {
      q = q.where(
        'stateLower',
        isEqualTo: CollegeSearchUtils.normalizeState(state),
      );
    }
    if (city != null && city.trim().isNotEmpty) {
      final keys = CollegeSearchUtils.citySearchKeys(city).toList();
      if (keys.length == 1) {
        q = q.where('cityLower', isEqualTo: keys.first);
      } else if (keys.length > 1) {
        q = q.where('cityLower', whereIn: keys);
      }
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (course != null && course.isNotEmpty) {
      q = q.where('courses', arrayContains: course);
    }
    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type.toLowerCase());
    }
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  /// Exhaustively pages live Firestore until every match is collected.
  Future<CollegeSearchPage> searchAllMatching({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? ownership,
    bool includeInactive = false,
  }) async {
    final intent = CollegeSearchUtils.resolveSearchIntent(
      query: query,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      ownership: ownership,
    );
    final effectiveType = intent.type;
    final batch = CollegeConstants.searchExhaustBatchSize;
    final byId = <String, CollegeModel>{};
    var fromLive = true;
    int? totalCount;

    try {
      totalCount = await countSearchMatches(
        query: query,
        state: state,
        city: city,
        university: university,
        course: course,
        category: category,
        type: effectiveType,
        includeInactive: includeInactive,
      );
      if (totalCount < 0) totalCount = null;
    } catch (_) {
      totalCount = null;
    }

    if (!intent.hasRetrievalQuery) {
      // Structured path: Firestore indexes state/category/course/type; city always client-matched.
      String? cursor;
      var hasMore = true;
      while (hasMore) {
        final page = await _queryStructuredPage(
          cityFilter: intent.hasCity ? intent.city : null,
          state: intent.state,
          category: intent.category,
          course: intent.course,
          type: effectiveType,
          university: intent.university,
          retrievalQuery: null,
          rankingQuery: intent.rankingQuery,
          includeInactive: includeInactive,
          limit: batch,
          startAfterDocumentId: cursor,
        );
        fromLive = fromLive && page.fromLiveDatabase;
        for (final c in page.colleges) {
          byId[c.id] = c;
        }
        cursor = page.lastDocumentId;
        hasMore = page.hasMore;
        if (!hasMore) break;
      }
    } else {
      // Free-text: merge fields once at exhaust batch size; stop when growth ends.
      String? cursor;
      var hasMore = true;
      var stagnant = 0;
      while (hasMore && stagnant < 2 && byId.length < 100000) {
        final before = byId.length;
        final page = await searchColleges(
          query: query,
          state: state,
          city: city,
          university: university,
          course: course,
          category: category,
          type: effectiveType,
          startAfterDocumentId: cursor,
          limit: batch,
          includeInactive: includeInactive,
        );
        fromLive = fromLive && page.fromLiveDatabase;
        for (final c in page.colleges) {
          byId[c.id] = c;
        }
        if (byId.length == before) {
          stagnant++;
        } else {
          stagnant = 0;
        }
        cursor = page.lastDocumentId;
        hasMore = page.hasMore;
        if (page.colleges.isEmpty) break;
      }
    }

    final colleges = byId.values.toList()
      ..sort((a, b) => a.nameLower.compareTo(b.nameLower));
    final hasUniversity =
        intent.university != null && intent.university!.trim().isNotEmpty;
    final resolvedTotal = hasUniversity || intent.hasCity
        ? colleges.length
        : (totalCount ?? colleges.length);
    return CollegeSearchPage(
      colleges: colleges,
      lastDocumentId: colleges.isEmpty ? null : colleges.last.id,
      hasMore: false,
      totalCount: resolvedTotal,
      fromLiveDatabase: fromLive,
    );
  }

  Future<CollegeSearchPage> searchColleges({
    String? query,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? startAfterDocumentId,
    int limit = CollegeConstants.searchPageSize,
    bool includeInactive = false,
    String? ownership,
  }) async {
    final intent = CollegeSearchUtils.resolveSearchIntent(
      query: query,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      ownership: ownership,
    );
    final effectiveType = intent.type;
    final pageLimit =
        limit <= 0 ? CollegeConstants.searchExhaustBatchSize : limit;

    try {
      if (intent.hasCity && !intent.hasRetrievalQuery) {
        return _queryStructuredPage(
          cityFilter: intent.city,
          state: intent.state,
          category: intent.category,
          course: intent.course,
          type: effectiveType,
          university: intent.university,
          retrievalQuery: null,
          rankingQuery: intent.rankingQuery,
          includeInactive: includeInactive,
          limit: pageLimit,
          startAfterDocumentId: startAfterDocumentId,
        );
      }

      if (!intent.hasRetrievalQuery) {
        return _queryStructuredPage(
          state: intent.state,
          category: intent.category,
          course: intent.course,
          type: effectiveType,
          university: intent.university,
          retrievalQuery: null,
          rankingQuery: intent.rankingQuery,
          includeInactive: includeInactive,
          limit: pageLimit,
          startAfterDocumentId: startAfterDocumentId,
        );
      }

      final merged = await _searchGlobalFreeText(
        intent.retrievalQuery!,
        state: intent.state,
        city: intent.city,
        university: intent.university,
        course: intent.course,
        category: intent.category,
        type: effectiveType,
        includeInactive: includeInactive,
        limit: pageLimit + 1,
      );
      final hasMore = merged.length > pageLimit;
      final page = merged.take(pageLimit).toList();
      return CollegeSearchPage(
        colleges: _finalizeSearchResults(
          page,
          query: intent.rankingQuery,
          city: intent.city,
          state: intent.state,
          university: intent.university,
          course: intent.course,
          category: intent.category,
          type: effectiveType,
          limit: pageLimit,
        ),
        lastDocumentId: page.isEmpty ? null : page.last.id,
        hasMore: hasMore,
        fromLiveDatabase: true,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      final fallback = await CollegeBundledDataSource.search(
        query: intent.rankingQuery,
        state: intent.state,
        city: intent.city,
        university: intent.university,
        course: intent.course,
        category: intent.category,
        type: effectiveType,
        limit: pageLimit,
        includeInactive: includeInactive,
        startAfterDocumentId: startAfterDocumentId,
      );
      return CollegeSearchPage(
        colleges: fallback.colleges,
        lastDocumentId: fallback.lastDocumentId,
        hasMore: fallback.hasMore,
        fromLiveDatabase: false,
      );
    }
  }

  Future<CollegeSearchPage> _queryStructuredPage({
    String? cityFilter,
    String? state,
    String? category,
    String? course,
    String? type,
    String? university,
    String? retrievalQuery,
    String? rankingQuery,
    bool includeInactive = false,
    required int limit,
    String? startAfterDocumentId,
  }) async {
    Query<Map<String, dynamic>> q = _colleges;
    if (!includeInactive) {
      q = q.where('isActive', isEqualTo: true);
    }
    if (state != null && state.isNotEmpty) {
      q = q.where(
        'stateLower',
        isEqualTo: CollegeSearchUtils.normalizeState(state),
      );
    }
    // City is filtered server-side (cityLower equality/alias whereIn) so a
    // city search like Mumbai/Pune only ever reads the matching page of
    // documents instead of paging through the whole collection. Falls back
    // to the bundled dataset automatically (see searchColleges catch below)
    // if a combo needs a composite index that hasn't been deployed yet.
    final cityKeys = (cityFilter != null && cityFilter.trim().isNotEmpty)
        ? CollegeSearchUtils.citySearchKeys(cityFilter).toList()
        : const <String>[];
    if (cityKeys.length == 1) {
      q = q.where('cityLower', isEqualTo: cityKeys.first);
    } else if (cityKeys.length > 1) {
      q = q.where('cityLower', whereIn: cityKeys);
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (course != null && course.isNotEmpty) {
      q = q.where('courses', arrayContains: course);
    }
    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type.toLowerCase());
    }

    q = q.orderBy('nameLower').limit(limit);

    if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
      final cursor = await _colleges.doc(startAfterDocumentId).get();
      if (cursor.exists) {
        q = q.startAfterDocument(cursor);
      }
    }

    final snapshot = await q.get();
    var colleges = _mapDocs(snapshot.docs);

    // Defense-in-depth only: the Firestore filter above already restricts
    // results to the matching city, this just guards against a stale/blank
    // cityLower on an individual document (falls back to district match).
    if (cityFilter != null && cityFilter.trim().isNotEmpty) {
      colleges = colleges
          .where(
            (c) => CollegeSearchUtils.cityMatchesCollege(
              cityLower: c.cityLower.isNotEmpty
                  ? CollegeSearchUtils.normalizeCity(c.cityLower)
                  : CollegeSearchUtils.normalizeCity(c.city),
              districtLower: CollegeSearchUtils.normalizeDistrict(c.district),
              cityFilter: cityFilter,
            ),
          )
          .toList();
    }
    if ((university != null && university.isNotEmpty) ||
        (retrievalQuery != null && retrievalQuery.trim().isNotEmpty)) {
      colleges = CollegeSearchUtils.applyFilters(
        colleges,
        university: university,
        query: retrievalQuery,
      );
    }

    final hasMore = snapshot.docs.length >= limit;
    final cursorId = snapshot.docs.isEmpty ? null : snapshot.docs.last.id;

    return CollegeSearchPage(
      colleges: _finalizeSearchResults(
        colleges,
        query: rankingQuery,
        city: cityFilter,
        state: state,
        university: university,
        course: course,
        category: category,
        type: type,
      ),
      lastDocumentId: cursorId,
      hasMore: hasMore,
      fromLiveDatabase: true,
    );
  }

  Future<List<CollegeModel>> _searchGlobalFreeText(
    String query, {
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    bool includeInactive = false,
    int limit = CollegeConstants.searchPageSize,
  }) async {
    final merged = <String, CollegeModel>{};

    final tokenHits = await _searchByTokens(
      query,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      includeInactive: includeInactive,
      limit: limit,
    );
    for (final college in tokenHits) {
      merged[college.id] = college;
    }

    Future<void> loadPrefix(String field) async {
      if (merged.length >= limit) return;
      final lower = query.trim().toLowerCase();
      if (lower.isEmpty) return;
      try {
        Query<Map<String, dynamic>> q = _colleges;
        if (!includeInactive) {
          q = q.where('isActive', isEqualTo: true);
        }
        final snap = await q
            .where(field, isGreaterThanOrEqualTo: lower)
            .where(field, isLessThan: '$lower\uf8ff')
            .orderBy(field)
            .limit(limit)
            .get();
        for (final doc in snap.docs) {
          final college = CollegeModel.fromJson(doc.data(), docId: doc.id);
          if (CollegeSearchUtils.matchesQuery(college, query)) {
            merged.putIfAbsent(doc.id, () => college);
          }
        }
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
      }
    }

    await loadPrefix('nameLower');
    await loadPrefix('cityLower');
    await loadPrefix('universityLower');
    await loadPrefix('stateLower');
    await loadPrefix('districtLower');

    final filtered = CollegeSearchUtils.applyFilters(
      merged.values.toList(),
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      query: query,
    );
    return filtered.take(limit).toList();
  }

  Future<List<CollegeModel>> _searchByTokens(
    String query, {
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    bool includeInactive = false,
    int limit = CollegeConstants.searchPageSize,
  }) async {
    final tokens = CollegeSearchUtils.queryTokens(query);
    if (tokens.isEmpty) return [];

    Query<Map<String, dynamic>> q = _colleges;
    if (!includeInactive) {
      q = q.where('isActive', isEqualTo: true);
    }

    q = q.where('searchTokens', arrayContainsAny: tokens).limit(limit * 3);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await q.get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      snapshot = await _colleges
          .where('isActive', isEqualTo: true)
          .where('searchTokens', arrayContainsAny: tokens)
          .limit(limit * 3)
          .get();
    }

    final ranked = <CollegeModel>[];
    for (final doc in snapshot.docs) {
      final college = CollegeModel.fromJson(doc.data(), docId: doc.id);
      if (!CollegeSearchUtils.matchesQuery(college, query)) continue;
      if (city != null &&
          city.isNotEmpty &&
          !CollegeSearchUtils.cityMatchesCollege(
            cityLower: college.cityLower,
            districtLower: college.districtLower,
            cityFilter: city,
          )) {
        continue;
      }
      if (state != null &&
          state.isNotEmpty &&
          CollegeSearchUtils.normalizeState(college.state) !=
              CollegeSearchUtils.normalizeState(state) &&
          college.stateLower != CollegeSearchUtils.normalizeState(state)) {
        continue;
      }
      if (course != null &&
          course.isNotEmpty &&
          !CollegeSearchUtils.courseMatches(college.courses, course)) {
        continue;
      }
      if (university != null &&
          university.isNotEmpty &&
          !college.universityLower.contains(
            CollegeSearchUtils.normalizeUniversity(university),
          )) {
        continue;
      }
      if (category != null &&
          category.isNotEmpty &&
          college.category.toLowerCase() != category.toLowerCase()) {
        continue;
      }
      if (type != null &&
          type.isNotEmpty &&
          college.type.toLowerCase() != type.toLowerCase()) {
        continue;
      }
      ranked.add(college);
    }

    ranked.sort((a, b) {
      final effectiveCity =
          city ?? CollegeSearchRanker.inferCityFromQuery(query);
      final cityA = CollegeSearchRanker.cityMatchScore(a, effectiveCity);
      final cityB = CollegeSearchRanker.cityMatchScore(b, effectiveCity);
      if (cityA != cityB) return cityB.compareTo(cityA);
      final queryA = CollegeSearchRanker.queryMatchScore(a, query);
      final queryB = CollegeSearchRanker.queryMatchScore(b, query);
      if (queryA != queryB) return queryB.compareTo(queryA);
      final aName = a.nameLower.startsWith(query.toLowerCase()) ? 0 : 1;
      final bName = b.nameLower.startsWith(query.toLowerCase()) ? 0 : 1;
      if (aName != bName) return aName.compareTo(bName);
      return a.nameLower.compareTo(b.nameLower);
    });
    return ranked.take(limit).toList();
  }

  Future<List<CollegeModel>> autocompleteColleges(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final results = <String, CollegeModel>{};
    final lower = trimmed.toLowerCase();

    if (lower.length >= CollegeConstants.minSearchChars) {
      final tokenMatches = await _searchByTokens(
        trimmed,
        limit: CollegeConstants.autocompleteLimit,
      );
      for (final college in tokenMatches) {
        results[college.id] = college;
      }
    }

    Future<void> loadPrefix(String field) async {
      if (results.length >= CollegeConstants.autocompleteLimit) return;
      try {
        final snap = await _colleges
            .where('isActive', isEqualTo: true)
            .where(field, isGreaterThanOrEqualTo: lower)
            .where(field, isLessThan: '$lower\uf8ff')
            .orderBy(field)
            .limit(CollegeConstants.autocompleteLimit)
            .get();
        for (final doc in snap.docs) {
          final college = CollegeModel.fromJson(doc.data(), docId: doc.id);
          if (CollegeSearchUtils.matchesQuery(college, trimmed)) {
            results[doc.id] = college;
          }
        }
      } on FirebaseException catch (e) {
        if (e.code != 'failed-precondition') rethrow;
      }
    }

    await loadPrefix('nameLower');
    await loadPrefix('cityLower');
    await loadPrefix('districtLower');
    await loadPrefix('universityLower');
    await loadPrefix('stateLower');

    final resultsList = results.values.toList();
    CollegeSearchRanker.rankResults(resultsList, query: trimmed);
    return resultsList.take(CollegeConstants.autocompleteLimit).toList();
  }

  Future<List<CollegeModel>> instantSearchColleges(String query) async {
    return autocompleteColleges(query);
  }

  Future<void> createCollege(CollegeModel college) async {
    final data = _prepareForWrite(college);
    await _colleges.doc(college.id).set(data);
  }

  Future<void> updateCollege(CollegeModel college, {String? updatedBy}) async {
    final data = _prepareForWrite(
      college.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: updatedBy,
      ),
    );
    await _colleges.doc(college.id).update(data);
  }

  Future<void> setCollegeActive(String id, {required bool isActive}) async {
    await _colleges.doc(id).update({
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> batchSeedColleges(List<CollegeModel> colleges) async {
    const batchSize = 450;
    for (var i = 0; i < colleges.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = colleges.skip(i).take(batchSize);
      for (final college in chunk) {
        batch.set(
          _colleges.doc(college.id),
          _prepareForWrite(college),
        );
      }
      await batch.commit();
    }
  }

  Future<void> batchUpsertColleges(List<CollegeModel> colleges) async {
    const batchSize = 450;
    for (var i = 0; i < colleges.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = colleges.skip(i).take(batchSize);
      for (final college in chunk) {
        batch.set(
          _colleges.doc(college.id),
          _prepareForWrite(college),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<void> updateDirectoryMeta({
    required int totalColleges,
    List<String>? states,
    List<String>? courses,
    DateTime? seededAt,
  }) async {
    await _firestore
        .collection(FirestoreConstants.metaCollection)
        .doc(CollegeConstants.metaDirectoryDoc)
        .set({
      'totalColleges': totalColleges,
      'states': states ?? CollegeConstants.indianStates,
      'courses': courses ?? CollegeConstants.popularCourses,
      'updatedAt': DateTime.now().toIso8601String(),
      if (seededAt != null) 'seededAt': seededAt.toIso8601String(),
    }, SetOptions(merge: true));
  }

  List<CollegeModel> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => CollegeModel.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  List<CollegeModel> _finalizeSearchResults(
    List<CollegeModel> colleges, {
    String? query,
    String? city,
    String? state,
    String? university,
    String? course,
    String? category,
    String? type,
    int? limit,
  }) {
    final seen = <String>{};
    final deduped = <CollegeModel>[];
    for (final college in colleges) {
      if (seen.add(college.id)) deduped.add(college);
    }
    CollegeSearchRanker.rankResults(
      deduped,
      query: query,
      city: city,
      state: state,
      university: university,
      course: course,
      category: category,
      type: type,
    );
    if (limit != null && deduped.length > limit) {
      return deduped.sublist(0, limit);
    }
    return deduped;
  }

  Map<String, dynamic> _prepareForWrite(CollegeModel college) {
    final normalized = college.copyWith(
      nameLower: CollegeSearchUtils.normalizeName(college.name),
      cityLower: CollegeSearchUtils.normalizeCity(college.city),
      districtLower: CollegeSearchUtils.normalizeDistrict(college.district),
      universityLower:
          CollegeSearchUtils.normalizeUniversity(college.universityName),
      stateLower: CollegeSearchUtils.normalizeState(college.state),
      slug: college.slug.isNotEmpty
          ? college.slug
          : CollegeSearchUtils.buildSlug(college.name, college.city),
      searchTokens: CollegeSearchUtils.buildSearchTokens(
        name: college.name,
        city: college.city,
        district: college.district,
        state: college.state,
        university: college.universityName ?? '',
        courses: college.courses,
        keywords: college.searchKeywords,
      ),
      updatedAt: DateTime.now(),
    );
    return normalized.toJson();
  }
}

class CollegeFirestoreException implements Exception {
  final String message;
  CollegeFirestoreException({required this.message});
  @override
  String toString() => message;
}
