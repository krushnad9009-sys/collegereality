import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_model.dart';
import '../repositories/college_repository.dart';
import '../services/college_storage_service.dart';
import '../services/firestore_college_service.dart';

final firestoreCollegeServiceProvider =
    Provider<FirestoreCollegeService>((ref) {
  return FirestoreCollegeService();
});

final collegeStorageServiceProvider = Provider<CollegeStorageService>((ref) {
  return CollegeStorageService();
});

final collegeRepositoryProvider = Provider<CollegeRepository>((ref) {
  return CollegeRepositoryImpl(ref.watch(firestoreCollegeServiceProvider));
});

final featuredCollegesProvider =
    FutureProvider<List<CollegeModel>>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getFeaturedColleges();
});

final collegeByIdProvider =
    FutureProvider.family<CollegeModel?, String>((ref, id) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getCollegeById(id);
});

final collegeDirectoryMetaProvider =
    FutureProvider<CollegeDirectoryMeta>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getDirectoryMeta();
});

final collegeCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getCollegeCount();
});

class CollegeSearchParams {
  final String? query;
  final String? city;
  final String? state;
  final String? course;
  final String? startAfterDocumentId;

  const CollegeSearchParams({
    this.query,
    this.city,
    this.state,
    this.course,
    this.startAfterDocumentId,
  });

  CollegeSearchParams nextPage(String lastDocumentId) {
    return CollegeSearchParams(
      query: query,
      city: city,
      state: state,
      course: course,
      startAfterDocumentId: lastDocumentId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollegeSearchParams &&
          query == other.query &&
          city == other.city &&
          state == other.state &&
          course == other.course &&
          startAfterDocumentId == other.startAfterDocumentId;

  @override
  int get hashCode =>
      Object.hash(query, city, state, course, startAfterDocumentId);
}

final collegeSearchPageProvider =
    FutureProvider.family<CollegeSearchPage, CollegeSearchParams>(
        (ref, params) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.searchColleges(
    query: params.query,
    city: params.city,
    state: params.state,
    course: params.course,
    startAfterDocumentId: params.startAfterDocumentId,
  );
});

final collegeAutocompleteProvider =
    FutureProvider.family<List<CollegeModel>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.autocomplete(query);
});

/// Backward-compatible alias for home featured list.
final collegesProvider = featuredCollegesProvider;

final indianStatesProvider = FutureProvider<List<String>>((ref) async {
  final meta = await ref.watch(collegeDirectoryMetaProvider.future);
  return meta.states;
});

final indianCoursesProvider = FutureProvider<List<String>>((ref) async {
  final meta = await ref.watch(collegeDirectoryMetaProvider.future);
  return meta.courses;
});

final indianCitiesProvider = FutureProvider<List<String>>((ref) async {
  // Cities are loaded on demand via search; no full scan at 40k scale.
  return const [];
});

class AdminCollegeSearchParams {
  final String? query;
  final String? startAfterDocumentId;

  const AdminCollegeSearchParams({this.query, this.startAfterDocumentId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminCollegeSearchParams &&
          query == other.query &&
          startAfterDocumentId == other.startAfterDocumentId;

  @override
  int get hashCode => Object.hash(query, startAfterDocumentId);
}

final adminCollegeSearchProvider =
    FutureProvider.family<CollegeSearchPage, AdminCollegeSearchParams>(
        (ref, params) async {
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.searchColleges(
    query: params.query,
    startAfterDocumentId: params.startAfterDocumentId,
    limit: 30,
    includeInactive: true,
  );
});
