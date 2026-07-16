import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/college_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../models/college_model.dart';
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
    String? course,
    String? startAfterDocumentId,
    int limit = CollegeConstants.searchPageSize,
    bool includeInactive = false,
  }) async {
    final trimmedQuery = query?.trim() ?? '';
    final hasQuery = trimmedQuery.length >= CollegeConstants.minSearchChars;

    if (hasQuery) {
      final tokenResults = await _searchByTokens(
        trimmedQuery,
        state: state,
        city: city,
        course: course,
        includeInactive: includeInactive,
        limit: limit,
      );
      if (tokenResults.isNotEmpty) {
        return CollegeSearchPage(
          colleges: tokenResults,
          hasMore: tokenResults.length >= limit,
        );
      }
    }

    Query<Map<String, dynamic>> q = _colleges;
    if (!includeInactive) {
      q = q.where('isActive', isEqualTo: true);
    }

    if (state != null && state.isNotEmpty) {
      q = q.where('state', isEqualTo: state);
    }
    if (city != null && city.isNotEmpty) {
      final normalizedCity = CollegeSearchUtils.normalizeCity(city);
      q = q
          .where('cityLower', isGreaterThanOrEqualTo: normalizedCity)
          .where('cityLower', isLessThan: '$normalizedCity\uf8ff');
    }
    if (course != null && course.isNotEmpty) {
      q = q.where('courses', arrayContains: course);
    }

    final hasCity = city != null && city.isNotEmpty;

    if (hasQuery) {
      final normalized = trimmedQuery.toLowerCase();
      q = q
          .where('nameLower', isGreaterThanOrEqualTo: normalized)
          .where('nameLower', isLessThan: '$normalized\uf8ff');
      q = q.orderBy('nameLower');
    } else if (hasCity) {
      q = q.orderBy('cityLower').orderBy('nameLower');
    } else {
      q = q.orderBy('nameLower');
    }

    q = q.limit(limit * 2);

    if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
      final cursor = await _colleges.doc(startAfterDocumentId).get();
      if (cursor.exists) {
        q = q.startAfterDocument(cursor);
      }
    }

    final snapshot = await q.get();
    var colleges = _mapDocs(snapshot.docs);
    if (hasQuery) {
      colleges = colleges
          .where((c) => CollegeSearchUtils.matchesQuery(c, trimmedQuery))
          .take(limit)
          .toList();
    } else {
      colleges = colleges.take(limit).toList();
    }

    if (colleges.isEmpty && city != null && city.isNotEmpty) {
      colleges = await _searchByCityFallback(city);
      if (hasQuery) {
        colleges = colleges
            .where((c) => CollegeSearchUtils.matchesQuery(c, trimmedQuery))
            .toList();
      }
    }

    final lastId = colleges.isEmpty ? null : colleges.last.id;
    return CollegeSearchPage(
      colleges: colleges,
      lastDocumentId: lastId,
      hasMore: snapshot.docs.length >= limit,
    );
  }

  Future<List<CollegeModel>> _searchByTokens(
    String query, {
    String? state,
    String? city,
    String? course,
    bool includeInactive = false,
    int limit = CollegeConstants.searchPageSize,
  }) async {
    final tokens = CollegeSearchUtils.queryTokens(query);
    if (tokens.isEmpty) return [];

    Query<Map<String, dynamic>> q = _colleges;
    if (!includeInactive) {
      q = q.where('isActive', isEqualTo: true);
    }
    if (state != null && state.isNotEmpty) {
      q = q.where('state', isEqualTo: state);
    }

    q = q.where('searchTokens', arrayContainsAny: tokens).limit(limit * 3);

    final snapshot = await q.get();
    final ranked = <CollegeModel>[];
    for (final doc in snapshot.docs) {
      final college = CollegeModel.fromJson(doc.data(), docId: doc.id);
      if (!CollegeSearchUtils.matchesQuery(college, query)) continue;
      if (city != null &&
          city.isNotEmpty &&
          !college.cityLower.contains(CollegeSearchUtils.normalizeCity(city)) &&
          !college.districtLower
              .contains(CollegeSearchUtils.normalizeDistrict(city))) {
        continue;
      }
      if (course != null &&
          course.isNotEmpty &&
          !college.courses.contains(course)) {
        continue;
      }
      ranked.add(college);
    }

    ranked.sort((a, b) {
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
    }

    await loadPrefix('nameLower');
    await loadPrefix('cityLower');
    await loadPrefix('districtLower');
    await loadPrefix('universityLower');
    await loadPrefix('stateLower');

    return results.values.take(CollegeConstants.autocompleteLimit).toList();
  }

  Future<List<CollegeModel>> _searchByCityFallback(String city) async {
    final variants = <String>{
      city.trim(),
      CollegeSearchUtils.titleCaseCity(city),
      CollegeSearchUtils.normalizeCity(city),
    }.where((v) => v.isNotEmpty).toList();

    final found = <String, CollegeModel>{};
    for (final variant in variants) {
      final snap = await _colleges
          .where('isActive', isEqualTo: true)
          .where('city', isEqualTo: variant)
          .limit(CollegeConstants.searchPageSize)
          .get();
      for (final doc in snap.docs) {
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
  }) async {
    await _firestore
        .collection(FirestoreConstants.metaCollection)
        .doc(CollegeConstants.metaDirectoryDoc)
        .set({
      'totalColleges': totalColleges,
      'states': states ?? CollegeConstants.indianStates,
      'courses': courses ?? CollegeConstants.popularCourses,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  List<CollegeModel> _mapDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => CollegeModel.fromJson(doc.data(), docId: doc.id))
        .toList();
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
