import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../student_life/models/student_life_models.dart';
import '../repositories/college_community_feed_repository.dart';
import '../services/college_community_feed_service.dart';
import '../services/college_community_storage_service.dart';

final collegeCommunityFeedServiceProvider =
    Provider<CollegeCommunityFeedService>((ref) {
  return CollegeCommunityFeedService();
});

final collegeCommunityStorageServiceProvider =
    Provider<CollegeCommunityStorageService>((ref) {
  return CollegeCommunityStorageService();
});

final collegeCommunityFeedRepositoryProvider =
    Provider<CollegeCommunityFeedRepository>((ref) {
  return CollegeCommunityFeedRepositoryImpl(
    ref.watch(collegeCommunityFeedServiceProvider),
  );
});

final isVerifiedCommunityPosterProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return ref.watch(collegeCommunityFeedRepositoryProvider).isVerifiedPoster(
        user.uid,
      );
});

final collegeCommunityCommentsProvider = StreamProvider.family<
    List<StudentCommunityCommentModel>, String>((ref, postId) {
  return ref
      .watch(collegeCommunityFeedRepositoryProvider)
      .watchPostComments(postId);
});

final collegeCommunityFeedPreviewProvider = FutureProvider.family<
    List<StudentCommunityPostModel>, ({String collegeId, String collegeName})>(
  (ref, params) async {
    await ref.read(collegeCommunityFeedRepositoryProvider).ensureCollegeCommunity(
          collegeId: params.collegeId,
          collegeName: params.collegeName,
        );
    final page = await ref.read(collegeCommunityFeedRepositoryProvider).fetchFeedPage(
          collegeId: params.collegeId,
          mode: StudentLifeConstants.feedLatest,
          limit: 3,
        );
    return page.items;
  },
);
