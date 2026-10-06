import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/firestore_constants.dart';
import '../../core/constants/verification_constants.dart';
import '../../core/constants/review_verification.dart';
import '../auth/models/user_model.dart';
import '../reviews/models/review_model.dart';
import '../reviews/services/firestore_review_service.dart';
import '../social/utils/content_filter_utils.dart';
import '../verification/services/verification_firestore_service.dart';
import 'guide_onboarding_rules.dart';

/// Guide onboarding = college review (steps 1+2) + document verification
/// (step 3), finished automatically once the documents are approved.
///
/// Reuses the app's existing pipelines rather than a parallel one:
///   * the review is a normal `reviews` doc, created `pending_verification`
///     (hidden, not in aggregates) and published through the SAME aggregate
///     path as any review once the author is verified;
///   * documents go through submitGuideVerificationDocuments ->
///     `verification_requests` -> the AI verification agent / admin queue.
///
/// Bookkeeping lives on the owner-only users doc as `guideOnboarding`
/// { reviewId, collegeId, collegeName, submittedAt, completedAt }.
/// firestore.rules refuse to switch guide mode on without a review named
/// there (guideModeRequiresCollegeReview).
class GuideOnboardingService {
  GuideOnboardingService({
    required this._reviews,
    required this._verification,
    FirebaseFirestore? firestore,
  }) : _firestoreOverride = firestore;

  final FirestoreReviewService _reviews;
  final VerificationFirestoreService _verification;
  final FirebaseFirestore? _firestoreOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection(FirestoreConstants.usersCollection).doc(uid);

  /// Submits all three steps. Order matters for retries: documents go
  /// first (skipped if a request is already under review), then the review
  /// (reusing a pending one for this college), then the users doc -- so any
  /// failed step can be retried without duplicating uploads or reviews.
  ///
  /// Returns true when onboarding finished immediately (already verified),
  /// false when it now waits on document review.
  Future<bool> submit({
    required UserModel user,
    required String collegeId,
    required String collegeName,
    required Map<String, double> ratings,
    required String reviewText,
    required DocumentStepState documentState,
    List<GuideVerificationDoc> documents = const [],
  }) async {
    final text = sanitizeUserContent(
      reviewText,
      maxLength: GuideOnboardingRules.maxReviewChars,
    );
    if (!GuideOnboardingRules.step2Complete(text)) {
      throw VerificationException(
        'Your review needs at least ${GuideOnboardingRules.minReviewChars} characters.',
      );
    }

    // Documents FIRST: they are the step most likely to fail (upload,
    // validation), and doing them before the review means a failed attempt
    // leaves nothing behind. On a retry after the documents went through,
    // the active request is found and they are not uploaded again.
    if (documentState == DocumentStepState.needsUpload &&
        await _verification.getActiveRequest(user.uid) == null) {
      await _verification.submitGuideVerificationDocuments(
        user: user,
        verificationRole: VerificationConstants.roleStudent,
        collegeId: collegeId,
        collegeName: collegeName,
        documents: documents,
      );
    }

    final now = DateTime.now();
    // Reuse a pending review of this college from an earlier attempt.
    final review = await _reviews.findPendingVerificationReview(
          userId: user.uid,
          collegeId: collegeId.trim(),
        ) ??
        await _reviews.createPendingVerificationReview(ReviewModel(
      id: '',
      collegeId: collegeId.trim(),
      collegeName: collegeName,
      userId: user.uid,
      anonymousAlias: user.effectivePublicDisplayName,
      isAnonymous: user.usesAnonymousPublicDisplayName,
      course: user.course,
      batchYear: user.batchYear,
      ratings: {
        for (final c in GuideOnboardingRules.ratingCategories)
          c.key: ratings[c.key] ?? 0,
      },
      textReview: text,
      pros: const [],
      cons: const [],
      photoUrls: const [],
      videoUrls: const [],
      isVerifiedStudent: false,
      yesNoAnswers: const {},
      status: ReviewModel.statusPendingVerification,
      createdAt: now,
      updatedAt: now,
    ));

    await _userRef(user.uid).set({
      'guideOnboarding': {
        'reviewId': review.id,
        'collegeId': collegeId,
        'collegeName': collegeName,
        'submittedAt': now.toIso8601String(),
        'completedAt': null,
      },
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    if (documentState == DocumentStepState.alreadyVerified) {
      return finalizeIfVerified(user.uid);
    }
    return false;
  }

  /// Run on app start and after submission: if this user submitted the
  /// wizard and is NOW verified, publish their pending review(s) into the
  /// college aggregates and switch guide mode on (once -- a guide who later
  /// turns it off isn't forced back on). Returns true if it completed.
  Future<bool> finalizeIfVerified(String uid) async {
    final snap = await _userRef(uid).get();
    final data = snap.data();
    if (data == null) return false;
    final onboarding = data['guideOnboarding'];
    if (onboarding is! Map || onboarding['reviewId'] == null) return false;
    if (onboarding['completedAt'] != null) return false;

    final user = UserModel.fromJson(data, docId: uid);
    if (!VerificationConstants.isApprovedStudentOrAlumni(
      user.verificationBadge,
      user.verificationStatus,
    )) {
      return false;
    }

    await _reviews.publishPendingVerificationReviews(
      userId: uid,
      reviewerBadge: reviewerBadgeLabel(user),
    );
    await _userRef(uid).update({
      'communicationSettings.isGuideAvailable': true,
      'guideOnboarding.completedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
    debugPrint('[GuideOnboarding] completed for $uid');
    return true;
  }

  /// Whether this user still has to go through the wizard.
  static bool needsOnboarding(Map<String, dynamic>? userData) {
    final onboarding = userData?['guideOnboarding'];
    return onboarding is! Map || onboarding['reviewId'] == null;
  }
}
