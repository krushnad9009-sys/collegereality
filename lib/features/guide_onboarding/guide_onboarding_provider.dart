import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_constants.dart';
import '../../core/constants/verification_constants.dart';
import '../auth/providers/auth_provider.dart';
import '../reviews/providers/review_provider.dart';
import '../verification/models/verification_request_model.dart';
import '../verification/providers/verification_provider.dart';
import 'guide_onboarding_service.dart';

final guideOnboardingServiceProvider = Provider<GuideOnboardingService>((ref) {
  return GuideOnboardingService(
    reviews: ref.watch(firestoreReviewServiceProvider),
    verification: ref.watch(verificationServiceProvider),
  );
});

/// Documents currently waiting for review (pending / flagged), if any.
final activeVerificationRequestProvider = FutureProvider.family
    .autoDispose<VerificationRequestModel?, String>((ref, uid) {
  return ref.watch(verificationServiceProvider).getActiveRequest(uid);
});

/// Finishes guide onboarding the moment the user's documents are approved
/// (by the AI agent or an admin) while the app is open -- publishes the
/// pending review into the college aggregates and switches guide mode on.
/// Watches the user's own users doc; also runs once on start for approvals
/// that happened while the app was closed. Started by AppShell; idempotent.
class GuideOnboardingFinalizer {
  GuideOnboardingFinalizer(this._ref);

  final Ref _ref;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;
  bool _running = false;

  void start() {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null || (uid == _uid && _sub != null)) return;
    stop();
    _uid = uid;
    _sub = FirebaseFirestore.instance
        .collection(FirestoreConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .listen(
          (snap) => _maybeFinalize(uid, snap.data()),
          onError: (Object e) => debugPrint('[GuideOnboarding] watch: $e'),
        );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
  }

  Future<void> _maybeFinalize(String uid, Map<String, dynamic>? data) async {
    if (_running || data == null) return;
    final onboarding = data['guideOnboarding'];
    if (onboarding is! Map ||
        onboarding['reviewId'] == null ||
        onboarding['completedAt'] != null) {
      return;
    }
    if (!VerificationConstants.isApprovedStudentOrAlumni(
      data['verificationBadge'] as String?,
      data['verificationStatus'] as String?,
    )) {
      return;
    }
    _running = true;
    try {
      await _ref.read(guideOnboardingServiceProvider).finalizeIfVerified(uid);
    } catch (e) {
      debugPrint('[GuideOnboarding] finalize failed (will retry): $e');
    } finally {
      _running = false;
    }
  }
}

final guideOnboardingFinalizerProvider =
    Provider<GuideOnboardingFinalizer>((ref) {
  final finalizer = GuideOnboardingFinalizer(ref);
  ref.onDispose(finalizer.stop);
  return finalizer;
});
