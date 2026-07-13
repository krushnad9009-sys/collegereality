import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/ecosystem_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../auth/models/user_model.dart';
import '../../colleges/models/college_model.dart';
import '../../colleges/utils/college_search_utils.dart';
import '../../engagement/services/firestore_engagement_service.dart';
import '../models/ecosystem_models.dart';
import 'audit_log_service.dart';

class EcosystemException implements Exception {
  final String message;
  EcosystemException(this.message);
  @override
  String toString() => message;
}

class EcosystemFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _audit = AuditLogService();
  final _engagement = FirestoreEngagementService();

  // ── Duplicate detection ─────────────────────────────────────────────

  Future<bool> isDuplicateCollege({
    required String name,
    required String city,
  }) async {
    final nameLower = CollegeSearchUtils.normalizeName(name);
    final cityLower = CollegeSearchUtils.normalizeCity(city);

    final collegeSnap = await _firestore
        .collection(FirestoreConstants.collegesCollection)
        .where('nameLower', isEqualTo: nameLower)
        .where('cityLower', isEqualTo: cityLower)
        .limit(1)
        .get();
    if (collegeSnap.docs.isNotEmpty) return true;

    final pendingSnap = await _firestore
        .collection(FirestoreConstants.collegeRequestsCollection)
        .where('nameLower', isEqualTo: nameLower)
        .where('cityLower', isEqualTo: cityLower)
        .where('status', isEqualTo: EcosystemConstants.statusPending)
        .limit(1)
        .get();
    return pendingSnap.docs.isNotEmpty;
  }

  // ── A. Request new college ────────────────────────────────────────

  Future<CollegeRequestModel> submitCollegeRequest({
    required UserModel user,
    required String name,
    required String city,
    required String state,
    String address = '',
    String? website,
    String? universityName,
    String notes = '',
  }) async {
    if (user.verificationBadge == VerificationConstants.badgeNone) {
      throw EcosystemException('Verified students can request new colleges.');
    }
    if (await isDuplicateCollege(name: name, city: city)) {
      throw EcosystemException(
        'This college already exists or has a pending request.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final request = CollegeRequestModel(
      id: id,
      userId: user.uid,
      userName: user.displayName ?? 'Student',
      name: name.trim(),
      nameLower: CollegeSearchUtils.normalizeName(name),
      city: city.trim(),
      cityLower: CollegeSearchUtils.normalizeCity(city),
      state: state.trim(),
      address: address.trim(),
      website: website?.trim(),
      universityName: universityName?.trim(),
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestoreConstants.collegeRequestsCollection)
        .doc(id)
        .set(request.toJson());

    await _audit.log(
      action: EcosystemConstants.auditCollegeRequest,
      actorId: user.uid,
      actorName: user.displayName ?? '',
      targetId: id,
      targetType: 'college_request',
      metadata: {'name': name, 'city': city},
    );

    return request;
  }

  Future<List<CollegeRequestModel>> fetchCollegeRequests({
    String? status,
    int limit = EcosystemConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.collegeRequestsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => CollegeRequestModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> reviewCollegeRequest({
    required String requestId,
    required String adminId,
    required String adminName,
    required bool approve,
    String? adminNotes,
    String? approvedCollegeId,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.collegeRequestsCollection)
        .doc(requestId);
    final doc = await ref.get();
    if (!doc.exists) throw EcosystemException('Request not found.');
    final request = CollegeRequestModel.fromJson(doc.data()!, docId: doc.id);

    await ref.update({
      'status': approve
          ? EcosystemConstants.statusApproved
          : EcosystemConstants.statusRejected,
      'adminNotes': adminNotes,
      'approvedCollegeId': approvedCollegeId,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _engagement.notifyUser(
      userId: request.userId,
      title: approve ? 'College request approved' : 'College request rejected',
      body: approve
          ? 'Your request for ${request.name} was approved.'
          : adminNotes ?? 'Your college request was not approved.',
      type: EcosystemConstants.notifCollegeRequestUpdate,
      category: 'colleges',
    );

    await _audit.log(
      action: EcosystemConstants.auditCollegeRequest,
      actorId: adminId,
      actorName: adminName,
      targetId: requestId,
      metadata: {'approve': approve},
    );
  }

  // ── B. Suggest edit ─────────────────────────────────────────────────

  Future<CollegeEditSuggestionModel> submitEditSuggestion({
    required UserModel user,
    required CollegeModel college,
    required String field,
    required String suggestedValue,
    String reason = '',
  }) async {
    if (user.verificationBadge == VerificationConstants.badgeNone) {
      throw EcosystemException('Verified users can suggest edits.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final currentValue = _fieldValue(college, field);
    final suggestion = CollegeEditSuggestionModel(
      id: id,
      collegeId: college.id,
      collegeName: college.name,
      userId: user.uid,
      userName: user.displayName ?? 'User',
      field: field,
      currentValue: currentValue,
      suggestedValue: suggestedValue.trim(),
      reason: reason.trim(),
      editHistory: [
        EditHistoryEntry(
          action: 'submitted',
          field: field,
          oldValue: currentValue,
          newValue: suggestedValue.trim(),
          actorId: user.uid,
          actorName: user.displayName ?? '',
          at: now,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestoreConstants.collegeEditSuggestionsCollection)
        .doc(id)
        .set(suggestion.toJson());

    await _audit.log(
      action: EcosystemConstants.auditEditSuggestion,
      actorId: user.uid,
      targetId: id,
      metadata: {'collegeId': college.id, 'field': field},
    );

    return suggestion;
  }

  Future<List<CollegeEditSuggestionModel>> fetchEditSuggestions({
    String? collegeId,
    String? status,
    int limit = EcosystemConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.collegeEditSuggestionsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (collegeId != null) {
      query = query.where('collegeId', isEqualTo: collegeId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => CollegeEditSuggestionModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> reviewEditSuggestion({
    required String suggestionId,
    required String adminId,
    required String adminName,
    required bool approve,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.collegeEditSuggestionsCollection)
        .doc(suggestionId);
    final doc = await ref.get();
    if (!doc.exists) throw EcosystemException('Suggestion not found.');
    final suggestion =
        CollegeEditSuggestionModel.fromJson(doc.data()!, docId: doc.id);
    final now = DateTime.now();

    final history = [
      ...suggestion.editHistory,
      EditHistoryEntry(
        action: approve ? 'approved' : 'rejected',
        field: suggestion.field,
        oldValue: suggestion.currentValue,
        newValue: suggestion.suggestedValue,
        actorId: adminId,
        actorName: adminName,
        at: now,
      ),
    ].take(EcosystemConstants.maxEditHistory).toList();

    await ref.update({
      'status': approve
          ? EcosystemConstants.statusApproved
          : EcosystemConstants.statusRejected,
      'reviewedBy': adminId,
      'editHistory': history.map((e) => e.toJson()).toList(),
      'updatedAt': now.toIso8601String(),
    });

    if (approve) {
      await _applyCollegeFieldEdit(
        collegeId: suggestion.collegeId,
        field: suggestion.field,
        value: suggestion.suggestedValue,
        adminId: adminId,
      );
      await ref.update({'status': EcosystemConstants.statusApplied});
    }

    await _engagement.notifyUser(
      userId: suggestion.userId,
      title: approve ? 'Edit suggestion approved' : 'Edit suggestion rejected',
      body: '${suggestion.field} for ${suggestion.collegeName}',
      type: EcosystemConstants.notifEditSuggestionUpdate,
      category: 'colleges',
    );

    await _audit.log(
      action: EcosystemConstants.auditEditSuggestion,
      actorId: adminId,
      actorName: adminName,
      targetId: suggestionId,
      metadata: {'approve': approve},
    );
  }

  Future<void> _applyCollegeFieldEdit({
    required String collegeId,
    required String field,
    required String value,
    required String adminId,
  }) async {
    final ref =
        _firestore.collection(FirestoreConstants.collegesCollection).doc(collegeId);
    final update = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': adminId,
    };
    switch (field) {
      case 'address':
        update['address'] = value;
      case 'website':
        update['website'] = value;
      case 'phone':
        update['phone'] = value;
      case 'email':
        update['email'] = value;
      case 'city':
        update['city'] = value;
        update['cityLower'] = CollegeSearchUtils.normalizeCity(value);
      case 'fees.tuitionMin':
        update['fees.tuitionMin'] = int.tryParse(value) ?? 0;
      case 'fees.tuitionMax':
        update['fees.tuitionMax'] = int.tryParse(value) ?? 0;
      default:
        update[field] = value;
    }
    await ref.update(update);
  }

  String _fieldValue(CollegeModel college, String field) {
    switch (field) {
      case 'address':
        return college.address;
      case 'website':
        return college.website ?? '';
      case 'phone':
        return college.phone ?? '';
      case 'email':
        return college.email ?? '';
      case 'city':
        return college.city;
      case 'fees.tuitionMin':
        return '${college.fees.tuitionMin}';
      case 'fees.tuitionMax':
        return '${college.fees.tuitionMax}';
      default:
        return '';
    }
  }

  // ── C. Report wrong information ─────────────────────────────────────

  Future<CollegeDataReportModel> submitDataReport({
    required UserModel user,
    required CollegeModel college,
    required String reportType,
    String description = '',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final report = CollegeDataReportModel(
      id: id,
      collegeId: college.id,
      collegeName: college.name,
      userId: user.uid,
      userName: user.displayName ?? 'User',
      reportType: reportType,
      description: description.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestoreConstants.collegeDataReportsCollection)
        .doc(id)
        .set(report.toJson());

    await _audit.log(
      action: EcosystemConstants.auditDataReport,
      actorId: user.uid,
      targetId: id,
      metadata: {'collegeId': college.id, 'reportType': reportType},
    );

    return report;
  }

  Future<List<CollegeDataReportModel>> fetchDataReports({
    String? status,
    int limit = EcosystemConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.collegeDataReportsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => CollegeDataReportModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> resolveDataReport({
    required String reportId,
    required String adminId,
    required String adminName,
    required bool resolved,
  }) async {
    await _firestore
        .collection(FirestoreConstants.collegeDataReportsCollection)
        .doc(reportId)
        .update({
      'status': resolved
          ? EcosystemConstants.statusApproved
          : EcosystemConstants.statusRejected,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _audit.log(
      action: EcosystemConstants.auditDataReport,
      actorId: adminId,
      actorName: adminName,
      targetId: reportId,
      metadata: {'resolved': resolved},
    );
  }

  // ── D. Claim college ──────────────────────────────────────────────

  Future<CollegeClaimModel> submitCollegeClaim({
    required UserModel user,
    required CollegeModel college,
    required String officialEmail,
    required String representativeName,
    String representativeDesignation = '',
    String? authorizationLetterUrl,
    String? representativeIdUrl,
  }) async {
    final existing = await _firestore
        .collection(FirestoreConstants.collegeClaimsCollection)
        .where('collegeId', isEqualTo: college.id)
        .where('status', isEqualTo: EcosystemConstants.statusPending)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw EcosystemException('A claim is already pending for this college.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final claim = CollegeClaimModel(
      id: id,
      collegeId: college.id,
      collegeName: college.name,
      userId: user.uid,
      userName: user.displayName ?? 'Representative',
      officialEmail: officialEmail.trim(),
      representativeName: representativeName.trim(),
      representativeDesignation: representativeDesignation.trim(),
      authorizationLetterUrl: authorizationLetterUrl,
      representativeIdUrl: representativeIdUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestoreConstants.collegeClaimsCollection)
        .doc(id)
        .set(claim.toJson());

    await _audit.log(
      action: EcosystemConstants.auditCollegeClaim,
      actorId: user.uid,
      targetId: id,
      metadata: {'collegeId': college.id},
    );

    return claim;
  }

  Future<List<CollegeClaimModel>> fetchCollegeClaims({
    String? status,
    int limit = EcosystemConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.collegeClaimsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => CollegeClaimModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> approveCollegeClaim({
    required String claimId,
    required String adminId,
    required String adminName,
  }) async {
    final claimRef =
        _firestore.collection(FirestoreConstants.collegeClaimsCollection).doc(claimId);
    final doc = await claimRef.get();
    if (!doc.exists) throw EcosystemException('Claim not found.');
    final claim = CollegeClaimModel.fromJson(doc.data()!, docId: doc.id);
    final now = DateTime.now();

    await claimRef.update({
      'status': EcosystemConstants.statusApproved,
      'updatedAt': now.toIso8601String(),
    });

    final account = CollegeAccountModel(
      userId: claim.userId,
      collegeId: claim.collegeId,
      collegeName: claim.collegeName,
      officialEmail: claim.officialEmail,
      isVerified: true,
      showOfficialBadge: true,
      verifiedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _firestore
        .collection(FirestoreConstants.collegeAccountsCollection)
        .doc(claim.userId)
        .set(account.toJson());

    await _firestore
        .collection(FirestoreConstants.collegesCollection)
        .doc(claim.collegeId)
        .update({
      'isOfficialVerified': true,
      'updatedAt': now.toIso8601String(),
    });

    await _engagement.notifyUser(
      userId: claim.userId,
      title: 'College claim approved',
      body: 'You now have official access to ${claim.collegeName}.',
      type: EcosystemConstants.notifClaimUpdate,
      category: 'colleges',
    );

    await _audit.log(
      action: EcosystemConstants.auditCollegeClaim,
      actorId: adminId,
      actorName: adminName,
      targetId: claimId,
      metadata: {'collegeId': claim.collegeId},
    );
  }

  Future<void> rejectCollegeClaim({
    required String claimId,
    required String adminId,
    String? adminNotes,
  }) async {
    final doc = await _firestore
        .collection(FirestoreConstants.collegeClaimsCollection)
        .doc(claimId)
        .get();
    if (!doc.exists) return;
    final claim = CollegeClaimModel.fromJson(doc.data()!, docId: doc.id);

    await doc.reference.update({
      'status': EcosystemConstants.statusRejected,
      'adminNotes': adminNotes,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _engagement.notifyUser(
      userId: claim.userId,
      title: 'College claim rejected',
      body: adminNotes ?? 'Your claim was not approved.',
      type: EcosystemConstants.notifClaimUpdate,
      category: 'colleges',
    );

    await _audit.log(
      action: EcosystemConstants.auditCollegeClaim,
      actorId: adminId,
      targetId: claimId,
      metadata: {'reject': true},
    );
  }

  Future<CollegeAccountModel?> getCollegeAccount(String userId) async {
    final doc = await _firestore
        .collection(FirestoreConstants.collegeAccountsCollection)
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return CollegeAccountModel.fromJson(doc.data()!, docId: doc.id);
  }

  // ── E. Verified faculty ─────────────────────────────────────────────

  Future<FacultyVerificationRequestModel> submitFacultyVerification({
    required UserModel user,
    required String collegeId,
    required String collegeName,
    required String officialEmail,
    String department = '',
    String designation = '',
    String? facultyIdUrl,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final request = FacultyVerificationRequestModel(
      id: id,
      userId: user.uid,
      userName: user.displayName ?? 'Faculty',
      collegeId: collegeId,
      collegeName: collegeName,
      officialEmail: officialEmail.trim(),
      department: department.trim(),
      designation: designation.trim(),
      facultyIdUrl: facultyIdUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(FirestoreConstants.facultyVerificationRequestsCollection)
        .doc(id)
        .set(request.toJson());

    await _audit.log(
      action: EcosystemConstants.auditFacultyVerification,
      actorId: user.uid,
      targetId: id,
    );

    return request;
  }

  Future<void> approveFacultyVerification({
    required String requestId,
    required String adminId,
    required String adminName,
  }) async {
    final ref = _firestore
        .collection(FirestoreConstants.facultyVerificationRequestsCollection)
        .doc(requestId);
    final doc = await ref.get();
    if (!doc.exists) throw EcosystemException('Request not found.');
    final request =
        FacultyVerificationRequestModel.fromJson(doc.data()!, docId: doc.id);

    await ref.update({
      'status': EcosystemConstants.statusApproved,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _firestore
        .collection(FirestoreConstants.usersCollection)
        .doc(request.userId)
        .update({
      'verificationBadge': VerificationConstants.badgeVerifiedFaculty,
      'verificationStatus': VerificationConstants.statusApproved,
      'collegeId': request.collegeId,
      'collegeName': request.collegeName,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    await _engagement.notifyUser(
      userId: request.userId,
      title: 'Faculty verification approved',
      body: 'You are now a verified faculty member at ${request.collegeName}.',
      type: EcosystemConstants.notifVerificationUpdate,
      category: 'colleges',
    );

    await _audit.log(
      action: EcosystemConstants.auditFacultyVerification,
      actorId: adminId,
      actorName: adminName,
      targetId: requestId,
    );
  }

  Future<List<FacultyVerificationRequestModel>> fetchFacultyRequests({
    String? status,
    int limit = EcosystemConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.facultyVerificationRequestsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => FacultyVerificationRequestModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<FacultyWorkshopModel> publishWorkshop({
    required String facultyId,
    required String collegeId,
    required String title,
    String description = '',
    DateTime? scheduledAt,
  }) async {
    final id = _uuid.v4();
    final workshop = FacultyWorkshopModel(
      id: id,
      facultyId: facultyId,
      collegeId: collegeId,
      title: title.trim(),
      description: description.trim(),
      scheduledAt: scheduledAt,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirestoreConstants.facultyWorkshopsCollection)
        .doc(id)
        .set(workshop.toJson());
    await _audit.log(
      action: EcosystemConstants.auditOfficialContent,
      actorId: facultyId,
      targetId: id,
      targetType: 'faculty_workshop',
    );
    return workshop;
  }

  Future<FacultyResearchModel> publishResearch({
    required String facultyId,
    required String collegeId,
    required String title,
    String abstract = '',
    String? linkUrl,
  }) async {
    final id = _uuid.v4();
    final research = FacultyResearchModel(
      id: id,
      facultyId: facultyId,
      collegeId: collegeId,
      title: title.trim(),
      abstract: abstract.trim(),
      linkUrl: linkUrl,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirestoreConstants.facultyResearchCollection)
        .doc(id)
        .set(research.toJson());
    return research;
  }

  Future<List<FacultyWorkshopModel>> fetchWorkshops(String collegeId) async {
    final snap = await _firestore
        .collection(FirestoreConstants.facultyWorkshopsCollection)
        .where('collegeId', isEqualTo: collegeId)
        .orderBy('createdAt', descending: true)
        .limit(EcosystemConstants.pageSize)
        .get();
    return snap.docs
        .map((d) => FacultyWorkshopModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  // ── F. Alumni mentorship ────────────────────────────────────────────

  Future<AlumniMentorshipOfferModel> createMentorshipOffer({
    required UserModel user,
    required String topic,
    String description = '',
  }) async {
    if (user.verificationBadge != VerificationConstants.badgeVerifiedAlumni) {
      throw EcosystemException('Verified alumni only.');
    }
    final id = _uuid.v4();
    final offer = AlumniMentorshipOfferModel(
      id: id,
      alumniId: user.uid,
      alumniName: user.displayName ?? 'Alumni',
      collegeId: user.collegeId ?? '',
      collegeName: user.collegeName ?? '',
      topic: topic.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection(FirestoreConstants.alumniMentorshipOffersCollection)
        .doc(id)
        .set(offer.toJson());
    return offer;
  }

  Future<List<AlumniMentorshipOfferModel>> fetchMentorshipOffers(
    String collegeId,
  ) async {
    final snap = await _firestore
        .collection(FirestoreConstants.alumniMentorshipOffersCollection)
        .where('collegeId', isEqualTo: collegeId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(EcosystemConstants.pageSize)
        .get();
    return snap.docs
        .map((d) => AlumniMentorshipOfferModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  // ── G. Official college content ─────────────────────────────────────

  Future<CollegeOfficialContentModel> publishOfficialContent({
    required String authorId,
    required String collegeId,
    required String collegeName,
    required String section,
    required String title,
    String body = '',
    List<String> mediaUrls = const [],
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final content = CollegeOfficialContentModel(
      id: id,
      collegeId: collegeId,
      collegeName: collegeName,
      authorId: authorId,
      section: section,
      title: title.trim(),
      body: body.trim(),
      mediaUrls: mediaUrls,
      createdAt: now,
      updatedAt: now,
    );
    await _firestore
        .collection(FirestoreConstants.collegeOfficialContentCollection)
        .doc(id)
        .set(content.toJson());

    await _audit.log(
      action: EcosystemConstants.auditOfficialContent,
      actorId: authorId,
      targetId: id,
      metadata: {'section': section, 'collegeId': collegeId},
    );

    return content;
  }

  Future<List<CollegeOfficialContentModel>> fetchOfficialContent({
    required String collegeId,
    String? section,
    int limit = EcosystemConstants.pageSize,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(FirestoreConstants.collegeOfficialContentCollection)
        .where('collegeId', isEqualTo: collegeId)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (section != null) {
      query = query.where('section', isEqualTo: section);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => CollegeOfficialContentModel.fromJson(d.data(), docId: d.id))
        .toList();
  }

  Future<void> deleteOfficialContent(String contentId, String actorId) async {
    await _firestore
        .collection(FirestoreConstants.collegeOfficialContentCollection)
        .doc(contentId)
        .update({
      'isPublished': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    await _audit.log(
      action: EcosystemConstants.auditOfficialContent,
      actorId: actorId,
      targetId: contentId,
      metadata: {'deleted': true},
    );
  }
}
