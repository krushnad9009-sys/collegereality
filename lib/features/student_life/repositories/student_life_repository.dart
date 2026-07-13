import '../models/student_life_models.dart';
import '../services/firestore_student_life_service.dart';

abstract class StudentLifeRepository {
  Future<void> ensureSeeded();
  Stream<List<CampusEventModel>> watchEvents();
  Stream<List<StudentClubModel>> watchClubs();
  Stream<List<CompetitionModel>> watchCompetitions();
  Stream<List<StudentCommunityModel>> watchCommunities();
  Future<CampusEventModel?> getEventById(String id);
  Future<StudentClubModel?> getClubById(String id);
  Future<CompetitionModel?> getCompetitionById(String id);
  Future<StudentCommunityModel?> getCommunityById(String id);
  Stream<List<StudentCommunityPostModel>> watchCommunityPosts(String communityId);
  Stream<List<StudentCommunityCommentModel>> watchPostComments(String postId);
  Future<bool> isUserVerified(String userId);
  Future<void> registerForEvent(String userId, String eventId);
  Stream<Set<String>> watchRegisteredEventIds(String userId);
  Future<void> saveEvent(String userId, String eventId);
  Future<void> unsaveEvent(String userId, String eventId);
  Stream<Set<String>> watchSavedEventIds(String userId);
  Future<void> requestJoinClub(String userId, String clubId);
  Stream<Map<String, String>> watchClubJoinStatuses(String userId);
  Future<void> createCommunityPost({
    required String communityId,
    required String authorId,
    required String authorDisplayName,
    required bool isVerifiedStudent,
    required String postType,
    required String content,
    List<String> imageUrls,
    List<String> pdfUrls,
    String pollQuestion,
    List<PollOptionModel> pollOptions,
    bool isAnonymous,
  });
  Future<void> likePost({required String postId, required String userId});
  Future<void> addPostComment({
    required String postId,
    required String communityId,
    required String authorId,
    required String authorDisplayName,
    required bool isVerifiedStudent,
    required String content,
  });
  Future<void> votePoll({
    required String postId,
    required String userId,
    required String optionId,
  });
  Future<bool> hasVotedOnPoll(String postId, String userId);
  Future<void> reportPost({
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  });
  Future<void> reportComment({
    required String commentId,
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  });
  Stream<List<Map<String, dynamic>>> watchOpenPostReports();
  Stream<List<Map<String, dynamic>>> watchOpenCommentReports();
  Future<void> updatePostReportStatus(String reportId, String status);
  Future<void> updateCommentReportStatus(String reportId, String status);
  Future<void> hidePost(String postId);
  Future<void> hideComment(String postId, String commentId);
}

class StudentLifeRepositoryImpl implements StudentLifeRepository {
  final FirestoreStudentLifeService _service;

  StudentLifeRepositoryImpl(this._service);

  @override
  Future<void> ensureSeeded() => _service.ensureSeeded();

  @override
  Stream<List<CampusEventModel>> watchEvents() => _service.watchEvents();

  @override
  Stream<List<StudentClubModel>> watchClubs() => _service.watchClubs();

  @override
  Stream<List<CompetitionModel>> watchCompetitions() => _service.watchCompetitions();

  @override
  Stream<List<StudentCommunityModel>> watchCommunities() => _service.watchCommunities();

  @override
  Future<CampusEventModel?> getEventById(String id) => _service.getEventById(id);

  @override
  Future<StudentClubModel?> getClubById(String id) => _service.getClubById(id);

  @override
  Future<CompetitionModel?> getCompetitionById(String id) =>
      _service.getCompetitionById(id);

  @override
  Future<StudentCommunityModel?> getCommunityById(String id) =>
      _service.getCommunityById(id);

  @override
  Stream<List<StudentCommunityPostModel>> watchCommunityPosts(String communityId) =>
      _service.watchCommunityPosts(communityId);

  @override
  Stream<List<StudentCommunityCommentModel>> watchPostComments(String postId) =>
      _service.watchPostComments(postId);

  @override
  Future<bool> isUserVerified(String userId) => _service.isUserVerified(userId);

  @override
  Future<void> registerForEvent(String userId, String eventId) =>
      _service.registerForEvent(userId, eventId);

  @override
  Stream<Set<String>> watchRegisteredEventIds(String userId) =>
      _service.watchRegisteredEventIds(userId);

  @override
  Future<void> saveEvent(String userId, String eventId) =>
      _service.saveEvent(userId, eventId);

  @override
  Future<void> unsaveEvent(String userId, String eventId) =>
      _service.unsaveEvent(userId, eventId);

  @override
  Stream<Set<String>> watchSavedEventIds(String userId) =>
      _service.watchSavedEventIds(userId);

  @override
  Future<void> requestJoinClub(String userId, String clubId) =>
      _service.requestJoinClub(userId, clubId);

  @override
  Stream<Map<String, String>> watchClubJoinStatuses(String userId) =>
      _service.watchClubJoinStatuses(userId);

  @override
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
  }) =>
      _service.createCommunityPost(
        communityId: communityId,
        authorId: authorId,
        authorDisplayName: authorDisplayName,
        isVerifiedStudent: isVerifiedStudent,
        postType: postType,
        content: content,
        imageUrls: imageUrls,
        pdfUrls: pdfUrls,
        pollQuestion: pollQuestion,
        pollOptions: pollOptions,
        isAnonymous: isAnonymous,
      );

  @override
  Future<void> likePost({required String postId, required String userId}) =>
      _service.likePost(postId: postId, userId: userId);

  @override
  Future<void> addPostComment({
    required String postId,
    required String communityId,
    required String authorId,
    required String authorDisplayName,
    required bool isVerifiedStudent,
    required String content,
  }) =>
      _service.addPostComment(
        postId: postId,
        communityId: communityId,
        authorId: authorId,
        authorDisplayName: authorDisplayName,
        isVerifiedStudent: isVerifiedStudent,
        content: content,
      );

  @override
  Future<void> votePoll({
    required String postId,
    required String userId,
    required String optionId,
  }) =>
      _service.votePoll(postId: postId, userId: userId, optionId: optionId);

  @override
  Future<bool> hasVotedOnPoll(String postId, String userId) =>
      _service.hasVotedOnPoll(postId, userId);

  @override
  Future<void> reportPost({
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) =>
      _service.reportPost(
        postId: postId,
        communityId: communityId,
        reporterId: reporterId,
        reason: reason,
      );

  @override
  Future<void> reportComment({
    required String commentId,
    required String postId,
    required String communityId,
    required String reporterId,
    required String reason,
  }) =>
      _service.reportComment(
        commentId: commentId,
        postId: postId,
        communityId: communityId,
        reporterId: reporterId,
        reason: reason,
      );

  @override
  Stream<List<Map<String, dynamic>>> watchOpenPostReports() =>
      _service.watchOpenPostReports();

  @override
  Stream<List<Map<String, dynamic>>> watchOpenCommentReports() =>
      _service.watchOpenCommentReports();

  @override
  Future<void> updatePostReportStatus(String reportId, String status) =>
      _service.updatePostReportStatus(reportId, status);

  @override
  Future<void> updateCommentReportStatus(String reportId, String status) =>
      _service.updateCommentReportStatus(reportId, status);

  @override
  Future<void> hidePost(String postId) => _service.hidePost(postId);

  @override
  Future<void> hideComment(String postId, String commentId) =>
      _service.hideComment(postId, commentId);
}
