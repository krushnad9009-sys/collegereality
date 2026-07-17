import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../colleges/models/college_model.dart';

import '../../colleges/providers/college_provider.dart';

import '../../reviews/models/review_model.dart';

import '../../reviews/providers/review_provider.dart';

import '../../careers/models/careers_models.dart';

import '../../careers/providers/careers_provider.dart';



/// Trending / featured colleges for horizontal carousel (all-India).

final trendingCollegesProvider =

    FutureProvider<List<CollegeModel>>((ref) async {

  await ref.watch(collegeDataReadyProvider.future);

  final featured = await ref.watch(homeFeaturedCollegesProvider.future);

  if (featured.isNotEmpty) return featured.take(12).toList();

  return ref.watch(featuredCollegesProvider.future);

});



/// Top-rated colleges sorted by overall rating.

final topRatedCollegesProvider = FutureProvider<List<CollegeModel>>((ref) async {

  await ref.watch(collegeDataReadyProvider.future);

  final colleges = await ref.watch(featuredCollegesProvider.future);

  final sorted = [...colleges]

    ..sort(

      (a, b) => b.aggregatedRatings.overall

          .compareTo(a.aggregatedRatings.overall),

    );

  return sorted.take(8).toList();

});



/// Recent published student reviews for home feed.

final homeRecentReviewsProvider =

    FutureProvider<List<ReviewModel>>((ref) async {

  final repo = ref.watch(reviewRepositoryProvider);

  final reviews = await repo.getAllReviews(

    limit: 24,

    statusFilter: ReviewModel.statusPublished,

  );

  return reviews.where((r) => r.isPublicVisible).take(6).toList();

});



/// Alumni profiles for success stories strip.

final homeAlumniStoriesProvider =

    FutureProvider<List<AlumniProfileModel>>((ref) async {

  final alumni = await ref.watch(alumniProfilesProvider.future);

  return alumni.take(6).toList();

});



/// Colleges with strongest placement stats.

final homePlacementHighlightsProvider =

    FutureProvider<List<CollegeModel>>((ref) async {

  await ref.watch(collegeDataReadyProvider.future);

  final source = await ref.watch(featuredCollegesProvider.future);

  final sorted = [...source]

    ..sort(

      (a, b) => b.placements.averagePackageLpa

          .compareTo(a.placements.averagePackageLpa),

    );

  final withPlacements =

      sorted.where((c) => c.placements.averagePackageLpa > 0).take(5).toList();

  if (withPlacements.isNotEmpty) return withPlacements;

  return sorted.take(5).toList();

});

