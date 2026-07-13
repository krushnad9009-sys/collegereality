import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/careers_constants.dart';
import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../models/careers_models.dart';
import '../utils/careers_filter_utils.dart';

class FirestoreCareersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

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
  DocumentReference<Map<String, dynamic>> get _meta =>
      _firestore.collection(FirestoreConstants.metaCollection).doc(
            CareersConstants.metaCareersSeededDoc,
          );

  Future<void> ensureSeeded() async {
    final meta = await _meta.get();
    if (meta.exists && meta.data()?['seeded'] == true) return;
    final snap = await _companies.limit(1).get();
    if (snap.docs.isNotEmpty) {
      await _meta.set({'seeded': true, 'updatedAt': DateTime.now().toIso8601String()});
      return;
    }
    await _seedFromAssets();
    await _meta.set({'seeded': true, 'updatedAt': DateTime.now().toIso8601String()});
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
  }) async {
    final id = _uuid.v4();
    await _internshipApplications.doc(id).set({
      'id': id,
      'userId': userId,
      'internshipId': internshipId,
      'companyId': companyId,
      'coverNote': coverNote.trim(),
      'status': CareersConstants.applicationStatusSubmitted,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> applyJob({
    required String userId,
    required String jobId,
    required String companyId,
    String coverNote = '',
  }) async {
    final id = _uuid.v4();
    await _jobApplications.doc(id).set({
      'id': id,
      'userId': userId,
      'jobId': jobId,
      'companyId': companyId,
      'coverNote': coverNote.trim(),
      'status': CareersConstants.applicationStatusSubmitted,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}

class CareersFirestoreException implements Exception {
  final String message;
  CareersFirestoreException({required this.message});
  @override
  String toString() => message;
}
