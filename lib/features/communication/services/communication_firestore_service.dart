import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/communication_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/firestore_user_service.dart';
import '../models/call_session_model.dart';
import '../models/interaction_rating_model.dart';
import '../models/public_guide_profile.dart';
import '../models/public_student_profile.dart';
import '../utils/guide_stats_calculator.dart';

class CommunicationFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _userService = FirestoreUserService();

  Future<List<PublicGuideProfile>> searchGuides({
    String? language,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.usersCollection)
        .where('communicationSettings.isGuideAvailable', isEqualTo: true)
        .limit(limit);

    if (language != null && language.isNotEmpty) {
      query = query.where('languagesKnown', arrayContains: language);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => PublicGuideProfile.fromUser(UserModel.fromJson(doc.data())))
        .toList();
  }

  Future<PublicGuideProfile?> getPublicGuideProfile(String uid) async {
    final user = await _userService.getUserByUID(uid);
    if (user == null || !user.communicationSettings.isGuideAvailable) {
      return null;
    }
    return PublicGuideProfile.fromUser(user);
  }

  Future<List<PublicStudentProfile>> searchConnectableStudents({
    required String collegeId,
    String? excludeUserId,
    int limit = 30,
  }) async {
    if (collegeId.isEmpty) return [];

    final snapshot = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .where('collegeId', isEqualTo: collegeId)
        .where('communicationSettings.allowPublicProfile', isEqualTo: true)
        .limit(limit)
        .get();

    final blockedIds = excludeUserId != null
        ? await getBlockedUserIds(excludeUserId)
        : <String>[];

    return snapshot.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .where((user) =>
            user.uid != excludeUserId &&
            !blockedIds.contains(user.uid) &&
            user.verificationStatus == VerificationConstants.statusApproved &&
            (user.verificationBadge ==
                    VerificationConstants.badgeVerifiedStudent ||
                user.verificationBadge ==
                    VerificationConstants.badgeVerifiedAlumni))
        .map(PublicStudentProfile.fromUser)
        .toList();
  }

  Future<bool> isBlocked(String userId, String otherUserId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.userBlocksCollection)
        .where('blockerId', isEqualTo: userId)
        .where('blockedId', isEqualTo: otherUserId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<List<String>> getBlockedUserIds(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.userBlocksCollection)
        .where('blockerId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((d) => d.data()['blockedId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final id = _uuid.v4();
    await _firestore
        .collection(FirestoreConstants.userBlocksCollection)
        .doc(id)
        .set({
      'id': id,
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String details = '',
    String? sessionId,
  }) async {
    final id = _uuid.v4();
    await _firestore
        .collection(FirestoreConstants.userReportsCollection)
        .doc(id)
        .set({
      'id': id,
      'reporterId': reporterId,
      'reportedId': reportedId,
      'sessionId': sessionId,
      'reason': reason,
      'details': details,
      'status': CommunicationConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _checkSpam(String callerId) async {
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final snapshot = await _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .where('callerId', isEqualTo: callerId)
        .where('createdAt', isGreaterThan: hourAgo.toIso8601String())
        .get();
    if (snapshot.docs.length >= CommunicationConstants.maxCallRequestsPerHour) {
      throw CommunicationException(
        'Too many call requests. Please wait before trying again.',
      );
    }
  }

  Future<CallSessionModel> requestCall({
    required String callerId,
    required String calleeId,
    required String callType,
  }) async {
    if (await isBlocked(callerId, calleeId) || await isBlocked(calleeId, callerId)) {
      throw CommunicationException('Unable to connect with this guide.');
    }

    await _checkSpam(callerId);

    final caller = await _userService.getUserByUID(callerId);
    final callee = await _userService.getUserByUID(calleeId);
    if (caller == null || callee == null) {
      throw CommunicationException('User not found.');
    }
    if (!callee.communicationSettings.isGuideAvailable) {
      throw CommunicationException('This guide is not available.');
    }
    if (callType == CommunicationConstants.callTypeVideo &&
        !callee.communicationSettings.videoCallsEnabled) {
      throw CommunicationException('Video calls are disabled for this guide.');
    }

    final tier = caller.subscriptionTier;
    final maxDuration = CommunicationConstants.maxDurationSeconds(
      tier: tier,
      callType: callType,
    );
    if (maxDuration <= 0) {
      throw CommunicationException(
        'Upgrade your subscription for ${callType == CommunicationConstants.callTypeVideo ? 'video' : 'voice'} calls.',
      );
    }

    final id = _uuid.v4();
    final session = CallSessionModel(
      id: id,
      callerId: callerId,
      calleeId: calleeId,
      callType: callType,
      status: CommunicationConstants.callStatusRequested,
      callerAccepted: true,
      calleeAccepted: false,
      callerAlias: caller.anonymousGuideAlias,
      calleeAlias: callee.anonymousGuideAlias,
      callerTier: caller.subscriptionTier,
      calleeTier: callee.subscriptionTier,
      maxDurationSeconds: maxDuration,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .doc(id)
        .set(session.toJson());

    return session;
  }

  Stream<CallSessionModel?> watchCallSession(String sessionId) {
    return _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return CallSessionModel.fromJson(doc.data()!, docId: doc.id);
    });
  }

  Future<void> acceptCall({
    required String sessionId,
    required String userId,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .doc(sessionId);
    final doc = await ref.get();
    if (!doc.exists) throw CommunicationException('Call not found.');
    final session = CallSessionModel.fromJson(doc.data()!, docId: doc.id);
    if (!session.isParticipant(userId)) {
      throw CommunicationException('Not a participant.');
    }

    final updates = <String, dynamic>{};
    if (userId == session.callerId) {
      updates['callerAccepted'] = true;
    } else {
      updates['calleeAccepted'] = true;
    }

    final callerAccepted =
        userId == session.callerId ? true : session.callerAccepted;
    final calleeAccepted =
        userId == session.calleeId ? true : session.calleeAccepted;

    if (callerAccepted && calleeAccepted) {
      updates['status'] = CommunicationConstants.callStatusActive;
      updates['startedAt'] = DateTime.now().toIso8601String();
    } else {
      updates['status'] = CommunicationConstants.callStatusAccepted;
    }

    await ref.update(updates);
  }

  Future<void> rejectCall({
    required String sessionId,
    required String userId,
  }) async {
    await _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .doc(sessionId)
        .update({
      'status': CommunicationConstants.callStatusRejected,
      'endedAt': DateTime.now().toIso8601String(),
      'endedBy': userId,
    });
  }

  Future<void> endCall({
    required String sessionId,
    required String userId,
    bool emergency = false,
  }) async {
    await _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .doc(sessionId)
        .update({
      'status': emergency
          ? CommunicationConstants.callStatusEmergencyEnded
          : CommunicationConstants.callStatusEnded,
      'endedAt': DateTime.now().toIso8601String(),
      'endedBy': userId,
      'isEmergencyEnd': emergency,
    });
  }

  Future<void> submitInteractionRating({
    required InteractionRatingModel rating,
    required bool incrementCall,
  }) async {
    final id = rating.id.isEmpty ? _uuid.v4() : rating.id;
    final data = rating.copyWith(id: id).toJson();
    data['id'] = id;

    await _firestore
        .collection(FirestoreConstants.interactionRatingsCollection)
        .doc(id)
        .set(data);

    final ratingsSnapshot = await _firestore
        .collection(FirestoreConstants.interactionRatingsCollection)
        .where('rateeId', isEqualTo: rating.rateeId)
        .get();

    final ratee = await _userService.getUserByUID(rating.rateeId);
    if (ratee == null) return;

    final allRatings = ratingsSnapshot.docs.map((d) => d.data()).toList();
    final newStats = recomputeGuideStats(
      current: ratee.guideStats,
      ratings: allRatings,
      incrementCall: incrementCall,
      incrementChat: !incrementCall,
    );

    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(rating.rateeId)
        .update({
      'guideStats': newStats.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    final sessionRef = _firestore
        .collection(FirestoreConstants.callSessionsCollection)
        .doc(rating.sessionId);
    final sessionDoc = await sessionRef.get();
    if (sessionDoc.exists) {
      final session =
          CallSessionModel.fromJson(sessionDoc.data()!, docId: sessionDoc.id);
      final field = rating.raterId == session.callerId
          ? 'ratingsSubmittedCaller'
          : 'ratingsSubmittedCallee';
      await sessionRef.update({field: true});
    }
  }

  Future<List<UserReportModel>> getOpenReports({int limit = 100}) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.userReportsCollection)
        .where('status', isEqualTo: CommunicationConstants.reportStatusOpen)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((d) => UserReportModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    await _firestore
        .collection(FirestoreConstants.userReportsCollection)
        .doc(reportId)
        .update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateLastActive(String uid) async {
    await _firestore.collection(FirestoreConstants.usersCollection).doc(uid).update({
      'guideStats.lastActiveAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

class CommunicationException implements Exception {
  final String message;
  CommunicationException(this.message);
  @override
  String toString() => message;
}
