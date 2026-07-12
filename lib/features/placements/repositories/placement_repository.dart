import 'dart:typed_data';

import '../models/placement_submission_model.dart';
import '../models/verified_placement_stats.dart';
import '../services/firestore_placement_service.dart';
import '../services/placement_storage_service.dart';

abstract class PlacementRepository {
  Future<bool> isUserVerified(String userId);
  Future<PlacementSubmissionModel> createSubmission({
    required PlacementSubmissionModel submission,
    String? offerLetterStoragePath,
  });
  Future<List<PlacementSubmissionModel>> getApprovedByCollege(String collegeId);
  Future<List<PlacementSubmissionModel>> getPendingSubmissions();
  Future<List<PlacementSubmissionModel>> getUserSubmissions(String userId);
  Future<void> approveSubmission({
    required String submissionId,
    required String adminUid,
    String? adminNote,
  });
  Future<void> rejectSubmission({
    required String submissionId,
    required String adminUid,
    String? adminNote,
  });
  Future<VerifiedPlacementStats> getCollegeVerifiedStats(String collegeId);
  Future<String?> getOfferLetterPath(String submissionId);
  Future<void> attachOfferLetter({
    required String submissionId,
    required String offerLetterStoragePath,
  });
  Future<String> uploadOfferLetter({
    required String userId,
    required String submissionId,
    required String extension,
    required Uint8List bytes,
  });
}

class PlacementRepositoryImpl implements PlacementRepository {
  final FirestorePlacementService _firestore;
  final PlacementStorageService _storage;

  PlacementRepositoryImpl(this._firestore, this._storage);

  @override
  Future<bool> isUserVerified(String userId) => _firestore.isUserVerified(userId);

  @override
  Future<PlacementSubmissionModel> createSubmission({
    required PlacementSubmissionModel submission,
    String? offerLetterStoragePath,
  }) =>
      _firestore.createSubmission(
        submission: submission,
        offerLetterStoragePath: offerLetterStoragePath,
      );

  @override
  Future<List<PlacementSubmissionModel>> getApprovedByCollege(String collegeId) =>
      _firestore.getApprovedByCollege(collegeId);

  @override
  Future<List<PlacementSubmissionModel>> getPendingSubmissions() =>
      _firestore.getPendingSubmissions();

  @override
  Future<List<PlacementSubmissionModel>> getUserSubmissions(String userId) =>
      _firestore.getUserSubmissions(userId);

  @override
  Future<void> approveSubmission({
    required String submissionId,
    required String adminUid,
    String? adminNote,
  }) =>
      _firestore.approveSubmission(
        submissionId: submissionId,
        adminUid: adminUid,
        adminNote: adminNote,
      );

  @override
  Future<void> rejectSubmission({
    required String submissionId,
    required String adminUid,
    String? adminNote,
  }) =>
      _firestore.rejectSubmission(
        submissionId: submissionId,
        adminUid: adminUid,
        adminNote: adminNote,
      );

  @override
  Future<VerifiedPlacementStats> getCollegeVerifiedStats(String collegeId) =>
      _firestore.getCollegeVerifiedStats(collegeId);

  @override
  Future<String?> getOfferLetterPath(String submissionId) =>
      _firestore.getOfferLetterPath(submissionId);

  @override
  Future<void> attachOfferLetter({
    required String submissionId,
    required String offerLetterStoragePath,
  }) =>
      _firestore.attachOfferLetter(
        submissionId: submissionId,
        offerLetterStoragePath: offerLetterStoragePath,
      );

  @override
  Future<String> uploadOfferLetter({
    required String userId,
    required String submissionId,
    required String extension,
    required Uint8List bytes,
  }) =>
      _storage.uploadOfferLetter(
        userId: userId,
        submissionId: submissionId,
        extension: extension,
        bytes: bytes,
      );
}
