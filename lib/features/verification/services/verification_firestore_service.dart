import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/services/firestore_user_service.dart';
import '../models/verification_request_model.dart';
import 'document_validation_service.dart';
import 'verification_storage_service.dart';

class VerificationFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _userService = FirestoreUserService();
  final _storageService = VerificationStorageService();
  final _validationService = DocumentValidationService();

  Future<VerificationRequestModel?> getActiveRequest(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
          VerificationConstants.statusPendingReview,
          VerificationConstants.statusFlagged,
        ])
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return VerificationRequestModel.fromJson(doc.data(), docId: doc.id);
  }

  Future<VerificationRequestModel?> getLatestRequest(String userId) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return VerificationRequestModel.fromJson(doc.data(), docId: doc.id);
  }

  Future<List<VerificationRequestModel>> getReviewQueue({int limit = 100}) async {
    final snapshot = await _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .where('status', whereIn: [
          VerificationConstants.statusPendingReview,
          VerificationConstants.statusFlagged,
        ])
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((d) => VerificationRequestModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<bool> _isDuplicateHash(String hash) async {
    final doc = await _firestore
        .collection(FirestoreConstants.verificationDocumentHashesCollection)
        .doc(hash)
        .get();
    return doc.exists;
  }

  Future<void> _registerHash(String hash, String userId, String requestId) async {
    await _firestore
        .collection(FirestoreConstants.verificationDocumentHashesCollection)
        .doc(hash)
        .set({
      'hash': hash,
      'userId': userId,
      'requestId': requestId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  bool canSubmitDocument(UserModel user) {
    return user.isEmailVerified &&
        user.isPhoneVerified &&
        user.verificationBadge == VerificationConstants.badgeNone &&
        user.verificationStatus != VerificationConstants.statusPendingReview &&
        user.verificationStatus != VerificationConstants.statusFlagged;
  }

  bool isValidDocumentForRole(String role, String documentType) {
    return VerificationConstants.documentTypesForRole(role)
        .any((d) => d['id'] == documentType);
  }

  Future<VerificationRequestModel> submitDocument({
    required UserModel user,
    required String documentType,
    required String verificationRole,
    required String collegeId,
    required String collegeName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!user.isEmailVerified || !user.isPhoneVerified) {
      throw VerificationException(
        'Complete email and mobile OTP verification before uploading a document.',
      );
    }

    if (collegeId.trim().isEmpty || collegeName.trim().isEmpty) {
      throw VerificationException('Select your college before submitting.');
    }

    if (!isValidDocumentForRole(verificationRole, documentType)) {
      throw VerificationException(
        'That document type is not accepted for ${VerificationConstants.roleLabel(verificationRole)} verification.',
      );
    }

    final existing = await getActiveRequest(user.uid);
    if (existing != null) {
      throw VerificationException(
        'You already have a document under review.',
      );
    }

    if (user.verificationBadge != VerificationConstants.badgeNone) {
      throw VerificationException('You are already verified.');
    }

    final validation = await _validationService.validate(
      bytes: bytes,
      fileName: fileName,
      documentType: documentType,
      isDuplicateHash: _isDuplicateHash,
    );

    final hash = _validationService.computeHash(bytes);
    final requestId = _uuid.v4();
    final ext = fileName.split('.').last.toLowerCase();

    final storagePath = await _storageService.uploadVerificationDocument(
      userId: user.uid,
      requestId: requestId,
      extension: ext,
      bytes: bytes,
    );

    await _registerHash(hash, user.uid, requestId);

    final status = validation.isDuplicate
        ? VerificationConstants.statusFlagged
        : VerificationConstants.statusPendingReview;

    final request = VerificationRequestModel(
      id: requestId,
      userId: user.uid,
      documentType: documentType,
      storagePath: storagePath,
      contentHash: hash,
      status: status,
      verificationRole: verificationRole,
      collegeId: collegeId.trim(),
      collegeName: collegeName.trim(),
      aiFlags: validation.flags,
      aiConfidence: validation.confidence,
      aiSummary: validation.summary,
      requiresManualReview: true,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .doc(requestId)
        .set(request.toJson());

    await _firestore.collection(FirestoreConstants.usersCollection).doc(user.uid).update({
      'verificationStatus': status,
      'verificationIntent': verificationRole,
      'collegeId': collegeId.trim(),
      'collegeName': collegeName.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    });

    return request;
  }

  Future<void> approveRequest({
    required String requestId,
    required String adminId,
    String? adminNote,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .doc(requestId);
    final doc = await ref.get();
    if (!doc.exists) throw VerificationException('Request not found.');

    final request =
        VerificationRequestModel.fromJson(doc.data()!, docId: doc.id);
    final user = await _userService.getUserByUID(request.userId);
    if (user == null) throw VerificationException('User not found.');

    final badge = request.verificationRole == VerificationConstants.roleAlumni ||
            VerificationConstants.isAlumniDocument(request.documentType)
        ? VerificationConstants.badgeVerifiedAlumni
        : VerificationConstants.badgeVerifiedStudent;

    final userUpdate = <String, dynamic>{
      'verificationBadge': badge,
      'verificationStatus': VerificationConstants.statusApproved,
      'isVerified': true,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (request.collegeId != null && request.collegeId!.isNotEmpty) {
      userUpdate['collegeId'] = request.collegeId;
      userUpdate['collegeName'] = request.collegeName ?? '';
    }

    await ref.update({
      'status': VerificationConstants.statusApproved,
      'adminNote': adminNote ?? '',
      'reviewedBy': adminId,
      'reviewedAt': DateTime.now().toIso8601String(),
    });

    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(request.userId)
        .update(userUpdate);
  }

  Future<void> rejectRequest({
    required String requestId,
    required String adminId,
    required String adminNote,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .doc(requestId);
    final doc = await ref.get();
    if (!doc.exists) throw VerificationException('Request not found.');

    final request =
        VerificationRequestModel.fromJson(doc.data()!, docId: doc.id);

    await ref.update({
      'status': VerificationConstants.statusRejected,
      'adminNote': adminNote,
      'reviewedBy': adminId,
      'reviewedAt': DateTime.now().toIso8601String(),
    });

    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(request.userId)
        .update({
      'verificationStatus': VerificationConstants.statusRejected,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> requestResubmission({
    required String requestId,
    required String adminId,
    required String adminNote,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.verificationRequestsCollection)
        .doc(requestId);
    final doc = await ref.get();
    if (!doc.exists) throw VerificationException('Request not found.');

    final request =
        VerificationRequestModel.fromJson(doc.data()!, docId: doc.id);

    await ref.update({
      'status': VerificationConstants.statusResubmissionRequested,
      'adminNote': adminNote,
      'reviewedBy': adminId,
      'reviewedAt': DateTime.now().toIso8601String(),
    });

    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(request.userId)
        .update({
      'verificationStatus': VerificationConstants.statusResubmissionRequested,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}

class VerificationException implements Exception {
  final String message;
  VerificationException(this.message);
  @override
  String toString() => message;
}
