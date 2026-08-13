import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/consultation_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../auth/services/firestore_user_service.dart';
import '../../communication/services/communication_firestore_service.dart';
import '../../social/models/social_models.dart';
import '../models/consultation_model.dart';
import '../models/consultation_rating_model.dart';
import '../utils/consultation_rating_calculator.dart';

class ConsultationException implements Exception {
  final String message;
  ConsultationException(this.message);
  @override
  String toString() => message;
}

/// Client-side half of the paid-consultation flow. Reuses the guide
/// directory / block list / verification systems already in
/// CommunicationFirestoreService and FirestoreUserService rather than
/// duplicating them. Anything money-bearing (order creation, payment
/// verification, completion, refunds, guide earnings) is intentionally
/// NOT here — see PaymentService, which calls the trusted Cloud Functions
/// backend for those.
class ConsultationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _userService = FirestoreUserService();
  final _communicationService = CommunicationFirestoreService();

  CollectionReference<Map<String, dynamic>> get _consultations =>
      _firestore.collection(FirestoreConstants.consultationsCollection);

  CollectionReference<Map<String, dynamic>> get _ratings =>
      _firestore.collection(FirestoreConstants.consultationRatingsCollection);

  Future<void> _checkSpam(String studentId) async {
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final snap = await _consultations
        .where('studentId', isEqualTo: studentId)
        .where('createdAt', isGreaterThan: hourAgo.toIso8601String())
        .get();
    if (snap.docs.length >= ConsultationConstants.maxConsultationRequestsPerHour) {
      throw ConsultationException(
        'Too many consultation requests. Please wait before trying again.',
      );
    }
  }

  /// Creates the initial `requested` consultation doc. No money moves here
  /// — PaymentService.createOrder() is the next step, run by a trusted
  /// Cloud Function. Reuses the same block-check + guide-availability
  /// validation as free calls (CommunicationFirestoreService).
  Future<ConsultationModel> requestConsultation({
    required String studentId,
    required String guideId,
    required String type,
    required int durationMinutes,
    required int grossPaise,
    String? collegeId,
  }) async {
    if (studentId == guideId) {
      throw ConsultationException('You cannot book a consultation with yourself.');
    }
    if (await _communicationService.isBlocked(studentId, guideId) ||
        await _communicationService.isBlocked(guideId, studentId)) {
      throw ConsultationException('Unable to connect with this guide.');
    }
    await _checkSpam(studentId);

    final guide = await _userService.getPublicProfileByUID(guideId);
    if (guide == null) {
      throw ConsultationException('Guide not found.');
    }
    if (guide.verificationBadge != 'verified_student' &&
        guide.verificationBadge != 'verified_alumni') {
      throw ConsultationException('This guide is not a verified student/alumni.');
    }
    final settings = guide.communicationSettings;
    final wantsChat = type == ConsultationConstants.typeChat;
    if (wantsChat && !settings.chatAvailable) {
      throw ConsultationException('This guide is not available for chat right now.');
    }
    if (!wantsChat && !settings.callAvailable) {
      throw ConsultationException('This guide is not available for calls right now.');
    }
    if (grossPaise <= 0) {
      throw ConsultationException('Invalid consultation price.');
    }

    final id = _uuid.v4();
    final consultation = ConsultationModel(
      id: id,
      studentId: studentId,
      guideId: guideId,
      collegeId: collegeId ?? guide.collegeName,
      type: type,
      status: ConsultationConstants.statusRequested,
      priceInfo: ConsultationPriceInfo(grossPaise: grossPaise),
      durationMinutes: durationMinutes,
      createdAt: DateTime.now(),
    );
    await _consultations.doc(id).set(consultation.toJson());
    return consultation;
  }

  Stream<ConsultationModel?> watchConsultation(String consultationId) {
    return _consultations.doc(consultationId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ConsultationModel.fromJson(doc.data()!, docId: doc.id);
    });
  }

  Future<ConsultationModel?> getConsultation(String consultationId) async {
    final doc = await _consultations.doc(consultationId).get();
    if (!doc.exists) return null;
    return ConsultationModel.fromJson(doc.data()!, docId: doc.id);
  }

  /// Cancels a consultation. firestore.rules decides which transition is
  /// actually valid for the caller's role/current status (pre-payment
  /// student cancel vs. post-payment participant cancel); refunds for the
  /// post-payment case are initiated server-side by a Cloud Function
  /// watching for this status change.
  Future<void> cancelConsultation({
    required String consultationId,
    String? reason,
  }) async {
    await _consultations.doc(consultationId).update({
      'status': ConsultationConstants.statusCancelled,
      'cancelledAt': DateTime.now().toIso8601String(),
      'cancelReason': reason,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Call-signaling step once paid: guide (or either participant) marks the
  /// call as ringing / joined. Chat consultations skip straight to `active`
  /// server-side when the conversation is created post-payment.
  Future<void> markWaitingForGuide(String consultationId) async {
    await _consultations.doc(consultationId).update({
      'status': ConsultationConstants.statusWaitingForGuide,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markActive(String consultationId) async {
    await _consultations.doc(consultationId).update({
      'status': ConsultationConstants.statusActive,
      'startedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Either participant ends an active consultation (mirrors endCall).
  /// Must land BEFORE either side can rate — ratings require status
  /// `completed` (see firestore.rules isEligibleConsultationRating).
  Future<void> completeConsultation(String consultationId) async {
    await _consultations.doc(consultationId).update({
      'status': ConsultationConstants.statusCompleted,
      'completedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<SocialPageResult<ConsultationModel>> fetchHistoryPage({
    required String userId,
    required bool asGuide,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _consultations
        .where(asGuide ? 'guideId' : 'studentId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final items = snap.docs
        .map((d) => ConsultationModel.fromJson(d.data(), docId: d.id))
        .toList();
    return SocialPageResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Stream<ConsultationRatingModel?> watchRating(
    String consultationId,
    String raterRole,
  ) {
    final id = ConsultationRatingModel.docId(consultationId, raterRole);
    return _ratings.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ConsultationRatingModel.fromJson(doc.data()!, docId: doc.id);
    });
  }

  /// Submits a two-way post-consultation rating. firestore.rules enforce:
  /// completed-only, participant-only, no self-rating, one per
  /// participant/consultation (the deterministic doc ID is the dedupe key
  /// — a duplicate write is evaluated as an `update`, which is always
  /// denied). Recomputes the ratee's aggregate the same way free-call
  /// ratings already do.
  Future<void> submitRating({
    required String consultationId,
    required String raterId,
    required String raterRole,
    required String rateeId,
    required int overall,
    required int communication,
    required int criterion2,
    required int criterion3,
    required int criterion4,
  }) async {
    final id = ConsultationRatingModel.docId(consultationId, raterRole);
    final rating = ConsultationRatingModel(
      id: id,
      consultationId: consultationId,
      raterId: raterId,
      raterRole: raterRole,
      rateeId: rateeId,
      overall: overall,
      communication: communication,
      criterion2: criterion2,
      criterion3: criterion3,
      criterion4: criterion4,
      createdAt: DateTime.now(),
    );
    // Step 1: create the immutable rating doc — allowed only once the
    // consultation is already `completed` (see completeConsultation()).
    await _ratings.doc(id).set(rating.toJson());

    // Step 2: flip *only the rater's own* submitted flag. The rules branch
    // (isConsultationRatingFlagUpdate) re-checks that this exact rating doc
    // now exists before allowing it, so this can never be forged ahead of
    // step 1.
    final flagField = raterRole == ConsultationConstants.raterRoleStudent
        ? 'ratingByStudentSubmitted'
        : 'ratingByGuideSubmitted';
    await _consultations.doc(consultationId).update({
      flagField: true,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    // Only ratings a *guide* receives are denormalized onto guideStats
    // (high-read-volume: guide directory cards). Student-received ratings
    // are aggregated on demand — see getStudentConsultationSummary.
    if (raterRole == ConsultationConstants.raterRoleStudent) {
      await _recomputeGuideConsultationStats(rateeId);
    }
  }

  Future<void> _recomputeGuideConsultationStats(String guideId) async {
    final guide = await _userService.getPublicProfileByUID(guideId);
    if (guide == null) return;
    final snap = await _ratings
        .where('rateeId', isEqualTo: guideId)
        .where('raterRole', isEqualTo: ConsultationConstants.raterRoleStudent)
        .get();
    final updated = recomputeConsultationStats(
      current: guide.guideStats,
      studentRatings: snap.docs.map((d) => d.data()).toList(),
    );
    final statsUpdate = {
      'guideStats': updated.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(guideId)
        .update(statsUpdate);
    await _userService.syncPublicProfile(guideId, statsUpdate);
  }

  Future<StudentConsultationSummary> getStudentConsultationSummary(
    String studentId,
  ) async {
    final snap = await _ratings
        .where('rateeId', isEqualTo: studentId)
        .where('raterRole', isEqualTo: ConsultationConstants.raterRoleGuide)
        .limit(200)
        .get();
    return StudentConsultationSummary.fromRatings(
      snap.docs.map((d) => d.data()).toList(),
    );
  }
}
