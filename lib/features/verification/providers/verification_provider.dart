import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/user_provider.dart';
import '../models/verification_request_model.dart';
import '../services/verification_firestore_service.dart';

final verificationServiceProvider = Provider<VerificationFirestoreService>((ref) {
  return VerificationFirestoreService();
});

final verificationQueueProvider =
    FutureProvider<List<VerificationRequestModel>>((ref) {
  return ref.watch(verificationServiceProvider).getReviewQueue();
});

final userVerificationRequestProvider =
    FutureProvider.family<VerificationRequestModel?, String>((ref, userId) {
  return ref.watch(verificationServiceProvider).getLatestRequest(userId);
});

final canSubmitVerificationProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserDetailProvider);
  return userAsync.maybeWhen(
    data: (user) =>
        user != null &&
        ref.watch(verificationServiceProvider).canSubmitDocument(user),
    orElse: () => false,
  );
});

bool isUserFullyVerified(UserModel user) {
  return user.verificationBadge != VerificationConstants.badgeNone &&
      user.verificationStatus == VerificationConstants.statusApproved;
}
