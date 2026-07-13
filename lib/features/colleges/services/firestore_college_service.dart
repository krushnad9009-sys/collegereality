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
    final snapshot = await _colleges
        .where('isActive', isEqualTo: true)
        .orderBy('aggregatedRatings.overall', descending: true)
        .limit(limit)
        .get();
    return _mapDocs(snapshot.docs);
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

    final trimmedQuery = query?.trim().toLowerCase();
    final hasCity = city != null && city.isNotEmpty;

    if (trimmedQuery != null && trimmedQuery.length >= CollegeConstants.minSearchChars) {
      q = q
          .where('nameLower', isGreaterThanOrEqualTo: trimmedQuery)
          .where('nameLower', isLessThan: '$trimmedQuery\uf8ff');
      q = q.orderBy('nameLower');
    } else if (hasCity) {
      q = q.orderBy('cityLower').orderBy('nameLower');
    } else {
      q = q.orderBy('nameLower');
    }

    q = q.limit(limit);

    if (startAfterDocumentId != null && startAfterDocumentId.isNotEmpty) {
      final cursor = await _colleges.doc(startAfterDocumentId).get();
      if (cursor.exists) {
        q = q.startAfterDocument(cursor);
      }
    }

    final snapshot = await q.get();
    var colleges = _mapDocs(snapshot.docs);
    if (colleges.isEmpty && city != null && city.isNotEmpty) {
      colleges = await _searchByCityFallback(city);
    }
    final lastId = snapshot.docs.isEmpty ? null : snapshot.docs.last.id;

    return CollegeSearchPage(
      colleges: colleges,
      lastDocumentId: lastId,
      hasMore: snapshot.docs.length >= limit,
    );
  }

  Future<List<CollegeModel>> autocompleteColleges(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < CollegeConstants.minSearchChars) return [];

    final results = <String, CollegeModel>{};

    Future<void> loadPrefix(String field) async {
      final snap = await _colleges
          .where('isActive', isEqualTo: true)
          .where(field, isGreaterThanOrEqualTo: trimmed)
          .where(field, isLessThan: '$trimmed\uf8ff')
          .orderBy(field)
          .limit(CollegeConstants.autocompleteLimit)
          .get();
      for (final doc in snap.docs) {
        results[doc.id] = CollegeModel.fromJson(doc.data(), docId: doc.id);
      }
    }

    await loadPrefix('nameLower');
    if (results.length < CollegeConstants.autocompleteLimit) {
      await loadPrefix('cityLower');
    }
    if (results.length < CollegeConstants.autocompleteLimit) {
      await loadPrefix('universityLower');
    }
    if (results.length < CollegeConstants.autocompleteLimit) {
      await loadPrefix('stateLower');
    }

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
      universityLower:
          CollegeSearchUtils.normalizeUniversity(college.universityName),
      stateLower: CollegeSearchUtils.normalizeState(college.state),
      slug: college.slug.isNotEmpty
          ? college.slug
          : CollegeSearchUtils.buildSlug(college.name, college.city),
      searchTokens: CollegeSearchUtils.buildSearchTokens(
        name: college.name,
        city: college.city,
        state: college.state,
        courses: college.courses,
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
