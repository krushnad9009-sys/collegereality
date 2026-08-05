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
  }) async {
    final intent = CollegeSearchUtils.resolveSearchIntent(
      query: query,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
    );
    final effectiveState = intent.state;
    final effectiveCity = intent.city;
    final effectiveUniversity = intent.university;
    final effectiveCourse = intent.course;
    final effectiveCategory = intent.category;
    final retrievalQuery = intent.retrievalQuery;
    final rankingQuery = intent.rankingQuery;
    final hasRetrievalQuery =
        retrievalQuery != null &&
        retrievalQuery.length >= CollegeConstants.minSearchChars;
    final hasCity = effectiveCity != null && effectiveCity.isNotEmpty;
    final hasCourse = effectiveCourse != null && effectiveCourse.isNotEmpty;
    final hasUniversity =
        effectiveUniversity != null && effectiveUniversity.isNotEmpty;

    // Merge multi-field free-text hits; never early-return a sparse token page
    // when a city/category was resolved from the same query.
    if (hasRetrievalQuery && !hasCity) {
      final merged = await _searchGlobalFreeText(
        retrievalQuery,
        state: effectiveState,
        city: effectiveCity,
        university: effectiveUniversity,
        course: effectiveCourse,
        category: effectiveCategory,
        type: type,
        includeInactive: includeInactive,
        limit: limit + 1,
      );
      if (merged.isNotEmpty) {
        final hasMore = merged.length > limit;
        return _buildSearchPage(
          merged.take(limit).toList(),
          hasMore: hasMore,
          query: rankingQuery,
          city: effectiveCity,
          state: effectiveState,
          university: effectiveUniversity,
          course: effectiveCourse,
          category: effectiveCategory,
          type: type,
          limit: limit,
        );
      }
    }

    Query<Map<String, dynamic>> q = _colleges;
    if (!includeInactive) {
      q = q.where('isActive', isEqualTo: true);
    }

    if (effectiveState != null && effectiveState.isNotEmpty) {
      q = q.where(
        'stateLower',
        isEqualTo: CollegeSearchUtils.normalizeState(effectiveState),
      );
    }
    if (hasCity) {
      final normalizedCity = CollegeSearchUtils.normalizeCity(effectiveCity);
      q = q
          .where('cityLower', isGreaterThanOrEqualTo: normalizedCity)
          .where('cityLower', isLessThan: '$normalizedCity\uf8ff');
    }
    if (hasCourse) {
      q = q.where('courses', arrayContains: effectiveCourse);
    }
    if (effectiveCategory != null && effectiveCategory.isNotEmpty) {
      q = q.where('category', isEqualTo: effectiveCategory);
    }
    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type.toLowerCase());
    }

    final fetchLimit =
        (hasUniversity || hasCity || hasCourse) ? limit * 8 : limit * 3;

    if (hasRetrievalQuery) {
      final normalized = retrievalQuery.toLowerCase();
      q = q
          .where('nameLower', isGreaterThanOrEqualTo: normalized)
          .where('nameLower', isLessThan: '$normalized\uf8ff');
      q = q.orderBy('nameLower');
    } else if (hasCity) {
      q = q.orderBy('cityLower').orderBy('nameLower');
    } else if (hasUniversity) {
      final normalizedUniversity =
          CollegeSearchUtils.normalizeUniversity(effectiveUniversity);
      q = q
          .where(
            'universityLower',
            isGreaterThanOrEqualTo: normalizedUniversity,
          )
          .where(
            'universityLower',
            isLessThan: '$normalizedUniversity\uf8ff',
          )
          .orderBy('universityLower');
    } else {
      q = q.orderBy('nameLower');
    }

    q = q.limit(fetchLimit);

    if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
      final cursor = await _colleges.doc(startAfterDocumentId).get();
      if (cursor.exists) {
        q = q.startAfterDocument(cursor);
      }
    }

    try {
      final snapshot = await q.get();
      final rawDocs = snapshot.docs;
      var colleges = _mapDocs(rawDocs);
      colleges = CollegeSearchUtils.applyFilters(
        colleges,
        state: effectiveState,
        city: effectiveCity,
        university: effectiveUniversity,
        course: effectiveCourse,
        category: effectiveCategory,
        type: type,
        query: hasRetrievalQuery ? retrievalQuery : null,
      );

      var usedCityFallback = false;
      if (hasCity &&
          (colleges.isEmpty ||
              colleges.length < limit ||
              CollegeSearchUtils.cityNeedsAliasMerge(effectiveCity))) {
        final aliasHits = await _searchByCityFallback(
          effectiveCity,
          limit: fetchLimit,
        );
        final byId = {for (final c in colleges) c.id: c};
        for (final c in aliasHits) {
          byId.putIfAbsent(c.id, () => c);
        }
        // Also merge free-text global hits when city was resolved from query.
        if (hasRetrievalQuery) {
          final global = await _searchGlobalFreeText(
            retrievalQuery,
            state: effectiveState,
            city: effectiveCity,
            university: effectiveUniversity,
            course: effectiveCourse,
            category: effectiveCategory,
            type: type,
            includeInactive: includeInactive,
            limit: fetchLimit,
          );
          for (final c in global) {
            byId.putIfAbsent(c.id, () => c);
          }
        }
        colleges = CollegeSearchUtils.applyFilters(
          byId.values.toList(),
          state: effectiveState,
          city: effectiveCity,
          university: effectiveUniversity,
          course: effectiveCourse,
          category: effectiveCategory,
          type: type,
          query: hasRetrievalQuery ? retrievalQuery : null,
        );
        usedCityFallback = true;
      }

      if (colleges.isEmpty && hasCourse) {
        colleges = await _searchCourseFuzzyFallback(
          state: effectiveState,
          city: effectiveCity,
          university: effectiveUniversity,
          course: effectiveCourse,
          category: effectiveCategory,
          type: type,
          query: hasRetrievalQuery ? retrievalQuery : null,
          includeInactive: includeInactive,
          limit: fetchLimit,
        );
      }

      if (colleges.isEmpty && hasRetrievalQuery) {
        colleges = await _searchGlobalFreeText(
          retrievalQuery,
          state: effectiveState,
          city: effectiveCity,
          university: effectiveUniversity,
          course: effectiveCourse,
          category: effectiveCategory,
          type: type,
          includeInactive: includeInactive,
          limit: limit + 1,
        );
      }

      final pageWindow = colleges.take(limit).toList();
      final hasMore = usedCityFallback
          ? colleges.length > limit
          : rawDocs.length >= fetchLimit && pageWindow.length >= limit;
      final cursorId = pageWindow.isEmpty ? null : pageWindow.last.id;
      final ranked = _finalizeSearchResults(
        pageWindow,
        query: rankingQuery,
        city: effectiveCity,
        state: effectiveState,
        university: effectiveUniversity,
        course: effectiveCourse,
        category: effectiveCategory,
        type: type,
        limit: limit,
      );

      return CollegeSearchPage(
        colleges: ranked,
        lastDocumentId: cursorId,
        hasMore: hasMore,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      return _searchFallback(
        trimmedQuery: rankingQuery ?? '',
        hasQuery: rankingQuery != null && rankingQuery.isNotEmpty,
        state: effectiveState,
        city: effectiveCity,
        university: effectiveUniversity,
        course: effectiveCourse,
        category: effectiveCategory,
        type: type,
        includeInactive: includeInactive,
        limit: limit,
        startAfterDocumentId: startAfterDocumentId,
      );
    }
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

  Future<CollegeSearchPage> _searchFallback({
    required String trimmedQuery,
    required bool hasQuery,
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    bool includeInactive = false,
    int limit = CollegeConstants.searchPageSize,
    String? startAfterDocumentId,
  }) async {
    return CollegeBundledDataSource.search(
      query: hasQuery ? trimmedQuery : null,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      limit: limit,
      includeInactive: includeInactive,
      startAfterDocumentId: startAfterDocumentId,
    );
  }

  Future<List<CollegeModel>> _searchCourseFuzzyFallback({
    String? state,
    String? city,
    String? university,
    required String course,
    String? category,
    String? type,
    String? query,
    bool includeInactive = false,
    int limit = CollegeConstants.searchPageSize,
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
    if (city != null && city.isNotEmpty) {
      final normalizedCity = CollegeSearchUtils.normalizeCity(city);
      q = q
          .where('cityLower', isGreaterThanOrEqualTo: normalizedCity)
          .where('cityLower', isLessThan: '$normalizedCity\uf8ff');
    }
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    if (type != null && type.isNotEmpty) {
      q = q.where('type', isEqualTo: type.toLowerCase());
    }
    q = q.orderBy('nameLower').limit(limit);

    try {
      final snapshot = await q.get();
      var colleges = _mapDocs(snapshot.docs);
      if (city != null &&
          city.isNotEmpty &&
          CollegeSearchUtils.cityNeedsAliasMerge(city)) {
        final aliasHits = await _searchByCityFallback(city);
        final byId = {for (final c in colleges) c.id: c};
        for (final c in aliasHits) {
          byId.putIfAbsent(c.id, () => c);
        }
        colleges = byId.values.toList();
      }
      return _applyClientFilters(
        colleges,
        state: state,
        city: city,
        university: university,
        course: course,
        category: category,
        type: type,
        query: query,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      final page = await CollegeBundledDataSource.search(
        query: query,
        state: state,
        city: city,
        university: university,
        course: course,
        category: category,
        type: type,
        limit: limit,
        includeInactive: includeInactive,
      );
      return page.colleges;
    }
  }

  List<CollegeModel> _applyClientFilters(
    List<CollegeModel> colleges, {
    String? state,
    String? city,
    String? university,
    String? course,
    String? category,
    String? type,
    String? query,
  }) {
    return CollegeSearchUtils.applyFilters(
      colleges,
      state: state,
      city: city,
      university: university,
      course: course,
      category: category,
      type: type,
      query: query,
    );
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

  Future<List<CollegeModel>> _searchByCityFallback(
    String city, {
    int limit = CollegeConstants.searchPageSize,
  }) async {
    final variants = <String>{
      city.trim(),
      CollegeSearchUtils.titleCaseCity(city),
      ...CollegeSearchUtils.citySearchKeys(city),
      ...CollegeSearchUtils.citySearchKeys(city)
          .map(CollegeSearchUtils.titleCaseCity),
    }.where((v) => v.isNotEmpty).toList();

    final found = <String, CollegeModel>{};
    final perVariantLimit = limit.clamp(CollegeConstants.searchPageSize, 200);
    for (final variant in variants) {
      final snap = await _colleges
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: variant)
          .limit(perVariantLimit)
          .get();
      for (final doc in snap.docs) {
        found[doc.id] = CollegeModel.fromJson(doc.data(), docId: doc.id);
      }
      final lowerSnap = await _colleges
          .where('isActive', isEqualTo: true)
          .where(
            'cityLower',
            isEqualTo: CollegeSearchUtils.normalizeCity(variant),
          )
          .limit(perVariantLimit)
          .get();
      for (final doc in lowerSnap.docs) {
        found[doc.id] = CollegeModel.fromJson(doc.data(), docId: doc.id);
      }
    }
    return found.values.toList();
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

  CollegeSearchPage _buildSearchPage(
    List<CollegeModel> colleges, {
    required bool hasMore,
    String? query,
    String? city,
    String? state,
    String? university,
    String? course,
    String? category,
    String? type,
    int limit = CollegeConstants.searchPageSize,
  }) {
    final ranked = _finalizeSearchResults(
      colleges,
      query: query,
      city: city,
      state: state,
      university: university,
      course: course,
      category: category,
      type: type,
      limit: limit,
    );
    return CollegeSearchPage(
      colleges: ranked,
      lastDocumentId: ranked.isEmpty ? null : ranked.last.id,
      hasMore: hasMore,
    );
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
