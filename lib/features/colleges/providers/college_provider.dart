import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/college_model.dart';
import '../repositories/college_repository.dart';
import '../services/college_storage_service.dart';
import '../services/firestore_college_service.dart';
import '../services/college_seed_service.dart';
import '../../../core/bootstrap/startup_bootstrap.dart';
import '../../auth/providers/auth_provider.dart';
import '../../engagement/providers/engagement_provider.dart';

final firestoreCollegeServiceProvider =
    Provider<FirestoreCollegeService>((ref) {
  return FirestoreCollegeService();
});

final collegeSeedProvider = FutureProvider<bool>((ref) async {
  final service = CollegeSeedService(ref.watch(firestoreCollegeServiceProvider));
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    return service.ensureSeeded();
  }
  final count = await ref.watch(collegeRepositoryProvider).getCollegeCount();
  return count > 0;
});

/// True when Firestore has college data (no client seed required).
final collegeDataReadyProvider = FutureProvider<bool>((ref) async {
  final count = await ref.watch(collegeCountProvider.future);
  if (count > 0) return true;
  return ref.watch(collegeSeedProvider.future);
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
  final String? category;
  final String? startAfterDocumentId;

  const CollegeSearchParams({
    this.query,
    this.city,
    this.state,
    this.course,
    this.category,
    this.startAfterDocumentId,
  });

  CollegeSearchParams nextPage(String lastDocumentId) {
    return CollegeSearchParams(
      query: query,
      city: city,
      state: state,
      course: course,
      category: category,
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
          category == other.category &&
          startAfterDocumentId == other.startAfterDocumentId;

  @override
  int get hashCode =>
      Object.hash(query, city, state, course, category, startAfterDocumentId);
}

final collegeSearchPageProvider =
    FutureProvider.family<CollegeSearchPage, CollegeSearchParams>(
        (ref, params) async {
  await ref.watch(collegeDataReadyProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.searchColleges(
    query: params.query,
    city: params.city,
    state: params.state,
    course: params.course,
    category: params.category,
    startAfterDocumentId: params.startAfterDocumentId,
  );
});

final collegeAutocompleteProvider =
    FutureProvider.family<List<CollegeModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  await ref.watch(collegeDataReadyProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.autocomplete(query);
});

final collegeInstantSuggestProvider =
    FutureProvider.family<List<CollegeModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  await ref.watch(collegeDataReadyProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.autocomplete(query);
});

/// Loads bookmarked colleges by their saved document IDs.
final savedCollegesProvider = FutureProvider<List<CollegeModel>>((ref) async {
  final favoriteIds =
      ref.watch(favoriteCollegeIdsProvider).valueOrNull ?? {};
  if (favoriteIds.isEmpty) return const [];
  await ref.watch(collegeSeedProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getCollegesByIds(favoriteIds.toList());
});

/// All-India featured colleges from Firestore AISHE directory.
final indiaFeaturedCollegesProvider =
    FutureProvider<List<CollegeModel>>((ref) async {
  await ref.watch(collegeDataReadyProvider.future);
  final repository = ref.watch(collegeRepositoryProvider);
  return repository.getFeaturedColleges(limit: 24);
});

/// Category counts from directory meta.
final collegeCategoryCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final meta = await ref.watch(collegeDirectoryMetaProvider.future);
  if (meta.categoryCounts.isNotEmpty) return meta.categoryCounts;
  return const {
    'Engineering': 4400,
    'Medical': 1400,
    'MBA': 2300,
    'Law': 800,
    'Pharmacy': 1200,
    'Arts': 1400,
    'Commerce': 1500,
    'Science': 900,
    'General': 27000,
  };
});

/// Backward-compatible alias.
final maharashtraCollegesProvider = indiaFeaturedCollegesProvider;

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
