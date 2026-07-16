import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/careers_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/firestore_seed_guard.dart';
import '../../social/services/notification_bridge_service.dart';
import '../../engagement/services/firestore_engagement_service.dart';
import '../models/careers_models.dart';
import '../utils/careers_filter_utils.dart';

class FirestoreCareersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _notificationBridge =
      NotificationBridgeService(FirestoreEngagementService());

  CollectionReference<Map<String, dynamic>> get _internships =>
      _firestore.collection(FirestoreConstants.internshipsCollection);
  CollectionReference<Map<String, dynamic>> get _jobs =>
      _firestore.collection(FirestoreConstants.jobsCollection);
  CollectionReference<Map<String, dynamic>> get _companies =>
      _firestore.collection(FirestoreConstants.companiesCollection);
  CollectionReference<Map<String, dynamic>> get _companyReviews =>
      _firestore.collection(FirestoreConstants.companyReviewsCollection);
  CollectionReference<Map<String, dynamic>> get _alumniProfiles =>
      _firestore.collection(FirestoreConstants.alumniProfilesCollection);
  CollectionReference<Map<String, dynamic>> get _savedInternships =>
      _firestore.collection(FirestoreConstants.savedInternshipsCollection);
  CollectionReference<Map<String, dynamic>> get _savedJobs =>
      _firestore.collection(FirestoreConstants.savedJobsCollection);
  CollectionReference<Map<String, dynamic>> get _alumniFollows =>
      _firestore.collection(FirestoreConstants.alumniFollowsCollection);
  CollectionReference<Map<String, dynamic>> get _internshipApplications =>
      _firestore.collection(FirestoreConstants.internshipApplicationsCollection);
  CollectionReference<Map<String, dynamic>> get _jobApplications =>
      _firestore.collection(FirestoreConstants.jobApplicationsCollection);
  CollectionReference<Map<String, dynamic>> get _studentResumes =>
      _firestore.collection(FirestoreConstants.studentResumesCollection);
  CollectionReference<Map<String, dynamic>> get _companyAccounts =>
      _firestore.collection(FirestoreConstants.companyAccountsCollection);
  DocumentReference<Map<String, dynamic>> get _meta =>
      _firestore.collection(FirestoreConstants.metaCollection).doc(
            CareersConstants.metaCareersSeededDoc,
          );

  Future<void> ensureSeeded() async {
    await FirestoreSeedGuard.tryBootstrapSeed(
      metaDocId: CareersConstants.metaCareersSeededDoc,
      sampleQuery: _companies.limit(1).get(),
      seed: _seedFromAssets,
    );
  }

  Future<void> _seedFromAssets() async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final companiesJson = await rootBundle.loadString('assets/data/companies_seed.json');
    for (final item in jsonDecode(companiesJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      final name = map['name'] as String;
      map['nameLower'] = name.toLowerCase();
      map['searchText'] = buildCareersSearchText([name, map['industry'] as String? ?? '']);
      map['isActive'] = true;
      map['isVerified'] = map['isVerified'] as bool? ?? true;
      map['updatedAt'] = now.toIso8601String();
      batch.set(_companies.doc(id), map);
    }

    final internshipsJson = await rootBundle.loadString('assets/data/internships_seed.json');
    for (final item in jsonDecode(internshipsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildCareersSearchText([
        map['title'] as String? ?? '',
        map['companyName'] as String? ?? '',
        map['city'] as String? ?? '',
      ]);
      map['workType'] = map['workType'] as String? ?? CareersConstants.workTypeOffice;
      map['stipendMin'] = (map['stipendMin'] as num?)?.toInt() ??
          _parseStipendMin(map['stipend'] as String? ?? '');
      map['durationWeeks'] = (map['durationWeeks'] as num?)?.toInt() ??
          _parseDurationWeeks(map['duration'] as String? ?? '');
      map['isActive'] = true;
      map['createdAt'] = now.toIso8601String();
      map['updatedAt'] = now.toIso8601String();
      batch.set(_internships.doc(id), map);
    }

    final jobsJson = await rootBundle.loadString('assets/data/jobs_seed.json');
    for (final item in jsonDecode(jobsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildCareersSearchText([
        map['title'] as String? ?? '',
        map['companyName'] as String? ?? '',
        map['location'] as String? ?? '',
      ]);
      map['eligibility'] = map['eligibility'] as String? ??
          'B.E./B.Tech in relevant discipline. Good academic record.';
      map['isActive'] = true;
      map['createdAt'] = now.toIso8601String();
      map['updatedAt'] = now.toIso8601String();
      batch.set(_jobs.doc(id), map);
    }

    final alumniJson = await rootBundle.loadString('assets/data/alumni_profiles_seed.json');
    for (final item in jsonDecode(alumniJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildCareersSearchText([
        map['displayName'] as String? ?? '',
        map['company'] as String? ?? '',
        map['jobTitle'] as String? ?? '',
        map['collegeName'] as String? ?? '',
      ]);
      map['isActive'] = true;
      map['updatedAt'] = now.toIso8601String();
      batch.set(_alumniProfiles.doc(id), map);
    }

    // Seed sample company reviews
    batch.set(_companyReviews.doc('cr_1'), {
      'id': 'cr_1',
      'companyId': 'co_tcs',
      'userId': 'seed_user',
      'authorDisplayName': 'Verified Student #4821',
      'isVerifiedStudent': true,
      'rating': 4.5,
      'textReview': 'Great learning environment for freshers. Structured training program.',
      'status': CareersConstants.reviewStatusPublished,
      'createdAt': now.toIso8601String(),
    });

    await batch.commit();
  }

  int _parseStipendMin(String stipend) {
    final digits = RegExp(r'[\d,]+').firstMatch(stipend)?.group(0)?.replaceAll(',', '');
    return int.tryParse(digits ?? '') ?? 0;
  }

  int _parseDurationWeeks(String duration) {
    final months = RegExp(r'(\d+)\s*month').firstMatch(duration.toLowerCase());
    if (months != null) return (int.tryParse(months.group(1) ?? '') ?? 0) * 4;
    final weeks = RegExp(r'(\d+)\s*week').firstMatch(duration.toLowerCase());
    if (weeks != null) return int.tryParse(weeks.group(1) ?? '') ?? 0;
    return 0;
  }

  Future<CareersPageResult<InternshipModel>> fetchInternshipsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = CareersConstants.pageSize,
  }) async {
    await ensureSeeded();
    var query = _internships
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    final items = snap.docs
        .map((d) => InternshipModel.fromJson(d.data(), docId: d.id))
        .toList();
    return CareersPageResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? startAfter : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<CareersPageResult<JobModel>> fetchJobsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = CareersConstants.pageSize,
  }) async {
    await ensureSeeded();
    var query = _jobs
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final snap = await query.get();
    final items =
        snap.docs.map((d) => JobModel.fromJson(d.data(), docId: d.id)).toList();
    return CareersPageResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? startAfter : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Stream<List<InternshipModel>> watchInternships() async* {
    await ensureSeeded();
    yield* _internships
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => InternshipModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<List<JobModel>> watchJobs() async* {
    await ensureSeeded();
    yield* _jobs
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => JobModel.fromJson(d.data(), docId: d.id)).toList());
  }

  Stream<List<CompanyModel>> watchCompanies() async* {
    await ensureSeeded();
    yield* _companies
        .where('isActive', isEqualTo: true)
        .orderBy('nameLower')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => CompanyModel.fromJson(d.data(), docId: d.id)).toList());
  }

  Stream<List<AlumniProfileModel>> watchAlumniProfiles() async* {
    await ensureSeeded();
    yield* _alumniProfiles
        .where('isActive', isEqualTo: true)
        .where('isVerifiedAlumni', isEqualTo: true)
        .orderBy('batchYear', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AlumniProfileModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Future<InternshipModel?> getInternshipById(String id) async {
    final doc = await _internships.doc(id).get();
    if (!doc.exists) return null;
    return InternshipModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<JobModel?> getJobById(String id) async {
    final doc = await _jobs.doc(id).get();
    if (!doc.exists) return null;
    return JobModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<CompanyModel?> getCompanyById(String id) async {
    final doc = await _companies.doc(id).get();
    if (!doc.exists) return null;
    return CompanyModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<AlumniProfileModel?> getAlumniById(String id) async {
    final doc = await _alumniProfiles.doc(id).get();
    if (!doc.exists) return null;
    return AlumniProfileModel.fromJson(doc.data()!, docId: doc.id);
  }

  Stream<List<CompanyReviewModel>> watchCompanyReviews(String companyId) {
    return _companyReviews
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: CareersConstants.reviewStatusPublished)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => CompanyReviewModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

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

  Future<void> submitCompanyReview({
    required String companyId,
    required String userId,
    required String authorDisplayName,
    required double rating,
    required String textReview,
    required bool isVerifiedStudent,
  }) async {
    if (!isVerifiedStudent) {
      throw CareersFirestoreException(
        message: 'Only verified students can review companies.',
      );
    }
    final id = _uuid.v4();
    await _companyReviews.doc(id).set({
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'authorDisplayName': authorDisplayName,
      'isVerifiedStudent': true,
      'rating': rating,
      'textReview': textReview.trim(),
      'status': CareersConstants.reviewStatusPublished,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> saveInternship(String userId, String internshipId) async {
    await _savedInternships.doc('${userId}_$internshipId').set({
      'userId': userId,
      'internshipId': internshipId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveInternship(String userId, String internshipId) async {
    await _savedInternships.doc('${userId}_$internshipId').delete();
  }

  Stream<Set<String>> watchSavedInternshipIds(String userId) {
    return _savedInternships
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['internshipId'] as String).toSet());
  }

  Future<void> saveJob(String userId, String jobId) async {
    await _savedJobs.doc('${userId}_$jobId').set({
      'userId': userId,
      'jobId': jobId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveJob(String userId, String jobId) async {
    await _savedJobs.doc('${userId}_$jobId').delete();
  }

  Stream<Set<String>> watchSavedJobIds(String userId) {
    return _savedJobs
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['jobId'] as String).toSet());
  }

  Future<void> followAlumni(String followerId, String alumniId) async {
    await _alumniFollows.doc('${followerId}_$alumniId').set({
      'followerId': followerId,
      'alumniId': alumniId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unfollowAlumni(String followerId, String alumniId) async {
    await _alumniFollows.doc('${followerId}_$alumniId').delete();
  }

  Stream<Set<String>> watchFollowedAlumniIds(String followerId) {
    return _alumniFollows
        .where('followerId', isEqualTo: followerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['alumniId'] as String).toSet());
  }

  Future<void> applyInternship({
    required String userId,
    required String internshipId,
    required String companyId,
    String coverNote = '',
    String applicantName = '',
    String? resumeUrl,
  }) async {
    final docId = '${userId}_$internshipId';
    final existing = await _internshipApplications.doc(docId).get();
    if (existing.exists) {
      throw CareersFirestoreException(message: 'You have already applied to this internship.');
    }
    await _internshipApplications.doc(docId).set({
      'id': docId,
      'userId': userId,
      'internshipId': internshipId,
      'companyId': companyId,
      'applicantName': applicantName,
      'coverNote': coverNote.trim(),
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      'status': CareersConstants.applicationStatusSubmitted,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> applyJob({
    required String userId,
    required String jobId,
    required String companyId,
    String coverNote = '',
    String applicantName = '',
    String? resumeUrl,
  }) async {
    final docId = '${userId}_$jobId';
    final existing = await _jobApplications.doc(docId).get();
    if (existing.exists) {
      throw CareersFirestoreException(message: 'You have already applied to this job.');
    }
    await _jobApplications.doc(docId).set({
      'id': docId,
      'userId': userId,
      'jobId': jobId,
      'companyId': companyId,
      'applicantName': applicantName,
      'coverNote': coverNote.trim(),
      if (resumeUrl != null) 'resumeUrl': resumeUrl,
      'status': CareersConstants.applicationStatusSubmitted,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<StudentResumeModel?> watchStudentResume(String userId) {
    return _studentResumes.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return StudentResumeModel.fromJson(doc.data()!, docId: userId);
    });
  }

  Future<void> saveStudentResume(StudentResumeModel resume) async {
    await _studentResumes.doc(resume.userId).set(resume.toJson());
  }

  Future<CompanyAccountModel?> getCompanyAccount(String userId) async {
    final doc = await _companyAccounts.doc(userId).get();
    if (!doc.exists) return null;
    return CompanyAccountModel.fromJson(doc.data()!, docId: userId);
  }

  Stream<CompanyAccountModel?> watchCompanyAccount(String userId) {
    return _companyAccounts.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CompanyAccountModel.fromJson(doc.data()!, docId: userId);
    });
  }

  Future<void> createInternshipListing(InternshipModel internship) async {
    await _internships.doc(internship.id).set(internship.toJson());
    await _notifyCareerSubscribersAboutInternship(internship);
  }

  Future<void> createJobListing(JobModel job) async {
    await _jobs.doc(job.id).set(job.toJson());
    await _notifyCareerSubscribersAboutJob(job);
  }

  Future<void> _notifyCareerSubscribersAboutJob(JobModel job) async {
    final savedSnap = await _savedJobs.limit(100).get();
    final notified = <String>{};
    for (final doc in savedSnap.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId == null || notified.contains(userId)) continue;
      notified.add(userId);
      await _notificationBridge.notifyNewJob(
        userId: userId,
        jobTitle: job.title,
        companyName: job.companyName,
        jobId: job.id,
      );
    }
  }

  Future<void> _notifyCareerSubscribersAboutInternship(InternshipModel internship) async {
    final savedSnap = await _savedInternships.limit(100).get();
    final notified = <String>{};
    for (final doc in savedSnap.docs) {
      final userId = doc.data()['userId'] as String?;
      if (userId == null || notified.contains(userId)) continue;
      notified.add(userId);
      await _notificationBridge.notifyNewInternship(
        userId: userId,
        title: internship.title,
        companyName: internship.companyName,
        internshipId: internship.id,
      );
    }
  }

  Stream<List<ApplicationModel>> watchInternshipApplicationsForCompany(String companyId) {
    return _internshipApplications
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ApplicationModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<List<ApplicationModel>> watchJobApplicationsForCompany(String companyId) {
    return _jobApplications
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ApplicationModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    required bool isInternship,
  }) async {
    final collection = isInternship ? _internshipApplications : _jobApplications;
    final doc = await collection.doc(applicationId).get();
    await collection.doc(applicationId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if (doc.exists) {
      final data = doc.data()!;
      final userId = data['userId'] as String?;
      final listingTitle = data['listingTitle'] as String? ?? 'Your application';
      if (userId != null) {
        await _notificationBridge.notifyApplicationUpdate(
          userId: userId,
          listingTitle: listingTitle,
          status: status,
          applicationId: applicationId,
          isInternship: isInternship,
        );
      }
    }
  }

  Stream<List<InternshipModel>> watchCompanyInternships(String companyId) {
    return _internships
        .where('companyId', isEqualTo: companyId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => InternshipModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<List<JobModel>> watchCompanyJobs(String companyId) {
    return _jobs
        .where('companyId', isEqualTo: companyId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => JobModel.fromJson(d.data(), docId: d.id)).toList());
  }
}

class CareersFirestoreException implements Exception {
  final String message;
  CareersFirestoreException({required this.message});
  @override
  String toString() => message;
}
