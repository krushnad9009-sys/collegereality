import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/placement_submission_model.dart';
import '../models/verified_placement_stats.dart';
import '../repositories/placement_repository.dart';
import '../services/firestore_placement_service.dart';
import '../services/placement_insights_service.dart';
import '../services/placement_storage_service.dart';

final firestorePlacementServiceProvider =
    Provider<FirestorePlacementService>((ref) {
  return FirestorePlacementService();
});

final placementStorageServiceProvider =
    Provider<PlacementStorageService>((ref) {
  return PlacementStorageService();
});

final placementRepositoryProvider = Provider<PlacementRepository>((ref) {
  return PlacementRepositoryImpl(
    ref.watch(firestorePlacementServiceProvider),
    ref.watch(placementStorageServiceProvider),
  );
});

final placementInsightsServiceProvider =
    Provider<PlacementInsightsService>((ref) {
  return PlacementInsightsService();
});

final isVerifiedForPlacementProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.read(placementRepositoryProvider).isUserVerified(user.uid);
});

final collegeVerifiedPlacementStatsProvider =
    FutureProvider.family<VerifiedPlacementStats, String>((ref, collegeId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getCollegeVerifiedStats(collegeId);
});

final pendingPlacementSubmissionsProvider =
    FutureProvider<List<PlacementSubmissionModel>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getPendingSubmissions();
});

final userPlacementSubmissionsProvider =
    FutureProvider.family<List<PlacementSubmissionModel>, String>(
        (ref, userId) async {
  final repo = ref.watch(placementRepositoryProvider);
  return repo.getUserSubmissions(userId);
});

final collegePlacementInsightsProvider =
    FutureProvider.family<List<String>, String>((ref, collegeId) async {
  final stats =
      await ref.watch(collegeVerifiedPlacementStatsProvider(collegeId).future);
  return ref.read(placementInsightsServiceProvider).buildInsights(stats);
});
