import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_model.dart';
import '../repositories/college_repository.dart';
import '../services/college_storage_service.dart';
import '../services/firestore_college_service.dart';
import '../services/college_seed_service.dart';
import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../../core/cache/college_session_cache.dart';

final collegeSeedProvider = FutureProvider<bool>((ref) async {
  final service = CollegeSeedService(ref.watch(firestoreCollegeServiceProvider));
  return service.ensureSeeded();
});

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
  await ref.watch(collegeSeedProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getFeaturedColleges();
});

/// Loads a small featured slice only after Home has painted (startup deferral).
final homeFeaturedCollegesProvider =
    FutureProvider<List<CollegeModel>>((ref) async {
  final ready = ref.watch(homeContentReadyProvider);
  if (!ready) return const [];
  await ref.watch(collegeSeedProvider.future);
  await Future<void>.delayed(Duration.zero);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getFeaturedColleges(limit: 6);
});

final collegeByIdProvider =
    FutureProvider.family<CollegeModel?, String>((ref, id) async {
  await ref.watch(collegeSeedProvider.future);
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
  await ref.watch(collegeSeedProvider.future);
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
  if (query.trim().length < 1) return [];
  await ref.watch(collegeSeedProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.autocomplete(query);
});

final collegeInstantSuggestProvider =
    FutureProvider.family<List<CollegeModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
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
