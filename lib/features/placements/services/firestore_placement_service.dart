import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/placement_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../models/placement_submission_model.dart';
import '../models/verified_placement_stats.dart';
import '../utils/placement_stats_calculator.dart';

class PlacementFirestoreException implements Exception {
  final String message;
  PlacementFirestoreException({required this.message});
  @override
  String toString() => message;
}

class FirestorePlacementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _submissions =>
      _firestore.collection(FirestoreConstants.placementSubmissionsCollection);

  CollectionReference<Map<String, dynamic>> get _colleges =>
      _firestore.collection(FirestoreConstants.collegesCollection);

  Future<bool> isUserVerified(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    return data['verificationBadge'] != VerificationConstants.badgeNone &&
        data['verificationStatus'] == VerificationConstants.statusApproved;
  }

  Future<PlacementSubmissionModel> createSubmission({
    required PlacementSubmissionModel submission,
    String? offerLetterStoragePath,
  }) async {
    final verified = await isUserVerified(submission.userId);
    if (!verified) {
      throw PlacementFirestoreException(
        message: 'Only verified students can submit placement details.',
      );
    }

    final id = submission.id.isEmpty ? _uuid.v4() : submission.id;
    final now = DateTime.now();
    final saved = PlacementSubmissionModel(
      id: id,
      collegeId: submission.collegeId,
      collegeName: submission.collegeName,
      userId: submission.userId,
      companyName: submission.companyName.trim(),
      jobRole: submission.jobRole.trim(),
      packageLpa: submission.packageLpa,
      employmentType: submission.employmentType,
      year: submission.year,
      branch: submission.branch,
      status: PlacementConstants.statusPending,
      isVerifiedStudent: true,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(_submissions.doc(id), saved.toJson());
      if (offerLetterStoragePath != null &&
          offerLetterStoragePath.isNotEmpty) {
        transaction.set(
          _submissions.doc(id).collection('private').doc('offer'),
          {
            'offerLetterStoragePath': offerLetterStoragePath,
            'createdAt': now.toIso8601String(),
          },
        );
      }
    });

    return saved;
  }

  Future<void> attachOfferLetter({
    required String submissionId,
    required String offerLetterStoragePath,
  }) async {
    await _submissions.doc(submissionId).collection('private').doc('offer').set({
      'offerLetterStoragePath': offerLetterStoragePath,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<PlacementSubmissionModel>> getApprovedByCollege(
    String collegeId,
  ) async {
    final snapshot = await _submissions
        .where('collegeId', isEqualTo: collegeId)
        .where('status', isEqualTo: PlacementConstants.statusApproved)
        .orderBy('year', descending: true)
        .get();
    return snapshot.docs
        .map((d) => PlacementSubmissionModel.fromJson(d.data()))
        .toList();
  }

  Future<List<PlacementSubmissionModel>> getPendingSubmissions() async {
    final snapshot = await _submissions
        .where('status', isEqualTo: PlacementConstants.statusPending)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map((d) => PlacementSubmissionModel.fromJson(d.data()))
        .toList();
  }

  Future<List<PlacementSubmissionModel>> getUserSubmissions(String userId) async {
    final snapshot = await _submissions
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((d) => PlacementSubmissionModel.fromJson(d.data()))
        .toList();
  }

  Future<String?> getOfferLetterPath(String submissionId) async {
    final doc = await _submissions
        .doc(submissionId)
        .collection('private')
        .doc('offer')
        .get();
    if (!doc.exists) return null;
    return doc.data()?['offerLetterStoragePath'] as String?;
  }

  Future<void> approveSubmission({
    required String submissionId,
    required String adminUid,
    String? adminNote,
  }) async {
    await _updateStatusAndReaggregate(
      submissionId: submissionId,
      status: PlacementConstants.statusApproved,
      adminUid: adminUid,
      adminNote: adminNote,
    );
  }

  Future<void> rejectSubmission({
    required String submissionId,
    required String adminUid,
    String? adminNote,
  }) async {
    await _updateStatusAndReaggregate(
      submissionId: submissionId,
      status: PlacementConstants.statusRejected,
      adminUid: adminUid,
      adminNote: adminNote,
    );
  }

  Future<void> _updateStatusAndReaggregate({
    required String submissionId,
    required String status,
    required String adminUid,
    String? adminNote,
  }) async {
    final submissionDoc = await _submissions.doc(submissionId).get();
    if (!submissionDoc.exists) return;
    final submission =
        PlacementSubmissionModel.fromJson(submissionDoc.data()!);
    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      transaction.update(_submissions.doc(submissionId), {
        'status': status,
        'adminNote': adminNote,
        'reviewedBy': adminUid,
        'reviewedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    });

    await _reaggregateCollegeStats(submission.collegeId);
  }

  Future<void> _reaggregateCollegeStats(String collegeId) async {
    final approved = await getApprovedByCollege(collegeId);
    final stats = PlacementStatsCalculator.compute(approved);
    await _colleges.doc(collegeId).update({
      'verifiedPlacementStats': stats.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<VerifiedPlacementStats> getCollegeVerifiedStats(
    String collegeId,
  ) async {
    final doc = await _colleges.doc(collegeId).get();
    if (!doc.exists) return const VerifiedPlacementStats();
    final data = doc.data()?['verifiedPlacementStats'] as Map<String, dynamic>?;
    if (data != null && (data['approvedCount'] as num? ?? 0) > 0) {
      return VerifiedPlacementStats.fromJson(data);
    }
    final approved = await getApprovedByCollege(collegeId);
    return PlacementStatsCalculator.compute(approved);
  }
}
