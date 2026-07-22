import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_constants.dart';
import '../../../core/constants/student_life_constants.dart';
import '../../../core/constants/verification_constants.dart';
import '../../../core/utils/firestore_seed_guard.dart';
import '../../social/models/social_models.dart';
import '../../social/services/moderation_service.dart';
import '../../social/utils/content_filter_utils.dart';
import '../../social/utils/moderation_utils.dart';
import '../models/student_life_models.dart';
import '../utils/student_life_filter_utils.dart';

class FirestoreStudentLifeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _moderationService = ModerationService();

  CollectionReference<Map<String, dynamic>> get _events =>
      _firestore.collection(FirestoreConstants.campusEventsCollection);
  CollectionReference<Map<String, dynamic>> get _clubs =>
      _firestore.collection(FirestoreConstants.studentClubsCollection);
  CollectionReference<Map<String, dynamic>> get _competitions =>
      _firestore.collection(FirestoreConstants.competitionsCollection);
  CollectionReference<Map<String, dynamic>> get _communities =>
      _firestore.collection(FirestoreConstants.studentCommunitiesCollection);
  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection(FirestoreConstants.studentCommunityPostsCollection);
  CollectionReference<Map<String, dynamic>> get _eventRegistrations =>
      _firestore.collection(FirestoreConstants.eventRegistrationsCollection);
  CollectionReference<Map<String, dynamic>> get _savedEvents =>
      _firestore.collection(FirestoreConstants.savedEventsCollection);
  CollectionReference<Map<String, dynamic>> get _clubJoinRequests =>
      _firestore.collection(FirestoreConstants.clubJoinRequestsCollection);
  CollectionReference<Map<String, dynamic>> get _postReports =>
      _firestore.collection(FirestoreConstants.studentCommunityPostReportsCollection);
  CollectionReference<Map<String, dynamic>> get _commentReports =>
      _firestore.collection(FirestoreConstants.studentCommunityCommentReportsCollection);
  CollectionReference<Map<String, dynamic>> get _pollVotes =>
      _firestore.collection(FirestoreConstants.studentCommunityPollVotesCollection);

  Future<void> ensureSeeded() async {
    await FirestoreSeedGuard.tryBootstrapSeed(
      metaDocId: StudentLifeConstants.metaStudentLifeSeededDoc,
      sampleQuery: _events.limit(1).get(),
      seed: _seedFromAssets,
    );
  }

  Future<void> _seedFromAssets() async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    final eventsJson = await rootBundle.loadString('assets/data/events_seed.json');
    for (final item in jsonDecode(eventsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildStudentLifeSearchText([
        map['title'] as String? ?? '',
        map['collegeName'] as String? ?? '',
        map['category'] as String? ?? '',
        map['location'] as String? ?? '',
      ]);
      map['isActive'] = true;
      map['createdAt'] = now.toIso8601String();
      map['updatedAt'] = now.toIso8601String();
      batch.set(_events.doc(id), map);
    }

    final clubsJson = await rootBundle.loadString('assets/data/clubs_seed.json');
    for (final item in jsonDecode(clubsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildStudentLifeSearchText([
        map['name'] as String? ?? '',
        map['clubType'] as String? ?? '',
        map['collegeName'] as String? ?? '',
      ]);
      map['isActive'] = true;
      map['updatedAt'] = now.toIso8601String();
      batch.set(_clubs.doc(id), map);
    }

    final competitionsJson =
        await rootBundle.loadString('assets/data/competitions_seed.json');
    for (final item in jsonDecode(competitionsJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['searchText'] = buildStudentLifeSearchText([
        map['title'] as String? ?? '',
        map['collegeName'] as String? ?? '',
        map['scope'] as String? ?? '',
      ]);
      map['isActive'] = true;
      map['createdAt'] = now.toIso8601String();
      map['updatedAt'] = now.toIso8601String();
      batch.set(_competitions.doc(id), map);
    }

    final communitiesJson =
        await rootBundle.loadString('assets/data/student_communities_seed.json');
    for (final item in jsonDecode(communitiesJson) as List<dynamic>) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String;
      map['verifiedStudentsOnly'] = true;
      map['isActive'] = true;
      map['updatedAt'] = now.toIso8601String();
      batch.set(_communities.doc(id), map);
    }

    // Seed sample community posts
    batch.set(_posts.doc('post_1'), {
      'id': 'post_1',
      'communityId': 'comm_1',
      'authorId': 'seed_user',
      'authorDisplayName': 'Verified Student #2847',
      'isVerifiedStudent': true,
      'postType': StudentLifeConstants.postAnnouncement,
      'content': 'Placement season starts next month. Update your resumes and LinkedIn profiles.',
      'imageUrls': [],
      'pdfUrls': [],
      'pollQuestion': '',
      'pollOptions': [],
      'status': StudentLifeConstants.statusPublished,
      'commentCount': 0,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    batch.set(_posts.doc('post_2'), {
      'id': 'post_2',
      'communityId': 'comm_1',
      'authorId': 'seed_user_2',
      'authorDisplayName': 'Verified Student #1092',
      'isVerifiedStudent': true,
      'postType': StudentLifeConstants.postPoll,
      'content': '',
      'imageUrls': [],
      'pdfUrls': [],
      'pollQuestion': 'Which tech stack are you focusing on for placements?',
      'pollOptions': [
        {'id': 'opt_1', 'label': 'MERN Stack', 'voteCount': 12},
        {'id': 'opt_2', 'label': 'Java/Spring', 'voteCount': 8},
        {'id': 'opt_3', 'label': 'Data Science', 'voteCount': 5},
      ],
      'pollEndsAt': now.add(const Duration(days: 7)).toIso8601String(),
      'status': StudentLifeConstants.statusPublished,
      'commentCount': 0,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    await batch.commit();
  }

  Stream<List<CampusEventModel>> watchEvents() async* {
    await ensureSeeded();
    yield* _events
        .where('isActive', isEqualTo: true)
        .orderBy('startAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => CampusEventModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<List<StudentClubModel>> watchClubs() async* {
    await ensureSeeded();
    yield* _clubs
        .where('isActive', isEqualTo: true)
        .orderBy('membersCount', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudentClubModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<List<CompetitionModel>> watchCompetitions() async* {
    await ensureSeeded();
    yield* _competitions
        .where('isActive', isEqualTo: true)
        .orderBy('registrationDeadline')
        .snapshots()
        .map((s) => s.docs
            .map((d) => CompetitionModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Stream<List<StudentCommunityModel>> watchCommunities() async* {
    await ensureSeeded();
    yield* _communities
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudentCommunityModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Future<CampusEventModel?> getEventById(String id) async {
    final doc = await _events.doc(id).get();
    if (!doc.exists) return null;
    return CampusEventModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<StudentClubModel?> getClubById(String id) async {
    final doc = await _clubs.doc(id).get();
    if (!doc.exists) return null;
    return StudentClubModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<CompetitionModel?> getCompetitionById(String id) async {
    final doc = await _competitions.doc(id).get();
    if (!doc.exists) return null;
    return CompetitionModel.fromJson(doc.data()!, docId: doc.id);
  }

  Future<StudentCommunityModel?> getCommunityById(String id) async {
    final doc = await _communities.doc(id).get();
    if (!doc.exists) return null;
    return StudentCommunityModel.fromJson(doc.data()!, docId: doc.id);
  }

  Stream<List<StudentCommunityPostModel>> watchCommunityPosts(String communityId) {
    return _posts
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: StudentLifeConstants.statusPublished)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudentCommunityPostModel.fromJson(d.data(), docId: d.id))
            .toList());
  }

  Future<SocialPageResult<StudentCommunityPostModel>> fetchCommunityPostsPage({
    required String communityId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _posts
        .where('communityId', isEqualTo: communityId)
        .where('status', isEqualTo: StudentLifeConstants.statusPublished)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final items = snap.docs
        .map((d) => StudentCommunityPostModel.fromJson(d.data(), docId: d.id))
        .toList();
    return SocialPageResult(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Stream<List<StudentCommunityCommentModel>> watchPostComments(String postId) {
    return _posts
        .doc(postId)
        .collection(FirestoreConstants.studentCommunityCommentsSubcollection)
        .where('status', isEqualTo: StudentLifeConstants.statusPublished)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => StudentCommunityCommentModel.fromJson(d.data(), docId: d.id))
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
        data['verificationStatus'] == VerificationConstants.statusApproved &&
        (data['verificationBadge'] == VerificationConstants.badgeVerifiedStudent ||
            data['verificationBadge'] == VerificationConstants.badgeVerifiedAlumni);
  }

  Future<void> registerForEvent(String userId, String eventId) async {
    await _eventRegistrations.doc('${userId}_$eventId').set({
      'userId': userId,
      'eventId': eventId,
      'status': StudentLifeConstants.statusApproved,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<Set<String>> watchRegisteredEventIds(String userId) {
    return _eventRegistrations
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['eventId'] as String).toSet());
  }

  Future<void> saveEvent(String userId, String eventId) async {
    await _savedEvents.doc('${userId}_$eventId').set({
      'userId': userId,
      'eventId': eventId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> unsaveEvent(String userId, String eventId) async {
    await _savedEvents.doc('${userId}_$eventId').delete();
  }

  Stream<Set<String>> watchSavedEventIds(String userId) {
    return _savedEvents
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['eventId'] as String).toSet());
  }

  Future<void> requestJoinClub(String userId, String clubId) async {
    await _clubJoinRequests.doc('${userId}_$clubId').set({
      'userId': userId,
      'clubId': clubId,
      'status': StudentLifeConstants.joinStatusPending,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<Map<String, String>> watchClubJoinStatuses(String userId) {
    return _clubJoinRequests
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => {
              for (final d in s.docs)
                d.data()['clubId'] as String: d.data()['status'] as String,
            });
  }

  Future<void> createCommunityPost({
    required String communityId,
    required String authorId,
    required String authorDisplayName,
    required bool isVerifiedStudent,
    required String postType,
    required String content,
    List<String> imageUrls = const [],
    List<String> pdfUrls = const [],
    String pollQuestion = '',
    List<PollOptionModel> pollOptions = const [],
    bool isAnonymous = false,
  }) async {
    if (!isVerifiedStudent) {
      throw StudentLifeException('Only verified students can post in communities.');
    }
    final sanitized = sanitizeUserContent(
      postType == StudentLifeConstants.postPoll ? pollQuestion : content,
    );
    if (sanitized.isNotEmpty) {
      final moderation = moderateContent(sanitized);
      if (!moderation.allowed) {
        throw StudentLifeException('Post blocked: content violates community guidelines.');
      }
    }
    final displayName = authorDisplayName;
    final id = _uuid.v4();
    await _posts.doc(id).set({
      'id': id,
      'communityId': communityId,
      'authorId': authorId,
      'authorDisplayName': displayName,
      'isVerifiedStudent': true,
      'isAnonymous': isAnonymous,
      'postType': postType,
      'content': content.trim(),
      'imageUrls': imageUrls,
      'pdfUrls': pdfUrls,
      'pollQuestion': pollQuestion,
      'pollOptions': pollOptions.map((o) => o.toJson()).toList(),
      if (postType == StudentLifeConstants.postPoll)
        'pollEndsAt': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'status': StudentLifeConstants.statusPublished,
      'commentCount': 0,
      'likeCount': 0,
      'likedBy': <String>[],
      'reportCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> addPostComment({
    required String postId,
    required String communityId,
    required String authorId,
    required String authorDisplayName,
    required bool isVerifiedStudent,
    required String content,
  }) async {
    if (!isVerifiedStudent) {
      throw StudentLifeException('Only verified students can comment.');
    }
    final id = _uuid.v4();
    final postRef = _posts.doc(postId);
    await _firestore.runTransaction((tx) async {
      tx.set(
        postRef.collection(FirestoreConstants.studentCommunityCommentsSubcollection).doc(id),
        {
          'id': id,
          'postId': postId,
          'communityId': communityId,
          'authorId': authorId,
          'authorDisplayName': authorDisplayName,
          'isVerifiedStudent': true,
          'content': content.trim(),
          'status': StudentLifeConstants.statusPublished,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      final postSnap = await tx.get(postRef);
      final count = (postSnap.data()?['commentCount'] as num?)?.toInt() ?? 0;
      tx.update(postRef, {
        'commentCount': count + 1,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> votePoll({
    required String postId,
    required String userId,
    required String optionId,
  }) async {
    final voteDocId = '${postId}_$userId';
    final existing = await _pollVotes.doc(voteDocId).get();
    if (existing.exists) {
      throw StudentLifeException('You have already voted on this poll.');
    }

    await _firestore.runTransaction((tx) async {
      final postRef = _posts.doc(postId);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) throw StudentLifeException('Poll not found.');
      final data = postSnap.data()!;
      final options = (data['pollOptions'] as List<dynamic>)
          .map((e) => PollOptionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final updated = options
          .map((o) => o.id == optionId
              ? PollOptionModel(id: o.id, label: o.label, voteCount: o.voteCount + 1)
              : o)
          .toList();
      tx.update(postRef, {
        'pollOptions': updated.map((o) => o.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      tx.set(_pollVotes.doc(voteDocId), {
        'postId': postId,
        'userId': userId,
        'optionId': optionId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<bool> hasVotedOnPoll(String postId, String userId) async {
    final doc = await _pollVotes.doc('${postId}_$userId').get();
    return doc.exists;
  }

  Future<void> reportPost({
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) async {
    final id = _uuid.v4();
    await _postReports.doc(id).set({
      'id': id,
      'postId': postId,
      'communityId': communityId,
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': StudentLifeConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _moderationService.incrementPostReportCount(postId);
  }

  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    final ref = _posts.doc(postId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final likedBy = (snap.data()?['likedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (likedBy.contains(userId)) return;
      likedBy.add(userId);
      tx.update(ref, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<void> reportComment({
    required String commentId,
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) async {
    final id = _uuid.v4();
    await _commentReports.doc(id).set({
      'id': id,
      'commentId': commentId,
      'postId': postId,
      'communityId': communityId,
      'reporterId': reporterId,
      'reason': reason.trim(),
      'status': StudentLifeConstants.reportStatusOpen,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchOpenPostReports() {
    return _postReports
        .where('status', isEqualTo: StudentLifeConstants.reportStatusOpen)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> watchOpenCommentReports() {
    return _commentReports
        .where('status', isEqualTo: StudentLifeConstants.reportStatusOpen)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> updatePostReportStatus(String reportId, String status) async {
    await _postReports.doc(reportId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateCommentReportStatus(String reportId, String status) async {
    await _commentReports.doc(reportId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> hidePost(String postId) async {
    await _posts.doc(postId).update({
      'status': StudentLifeConstants.statusHidden,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> hideComment(String postId, String commentId) async {
    await _posts
        .doc(postId)
        .collection(FirestoreConstants.studentCommunityCommentsSubcollection)
        .doc(commentId)
        .update({'status': StudentLifeConstants.statusHidden});
  }
}

class StudentLifeException implements Exception {
  final String message;
  StudentLifeException(this.message);
  @override
  String toString() => message;
}
