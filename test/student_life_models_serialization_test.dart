import 'package:college_reality_india/core/constants/student_life_constants.dart';
import 'package:college_reality_india/features/student_life/models/student_life_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 3, 15, 10, 30);
  final future = DateTime.now().add(const Duration(days: 30));

  group('CampusEventModel JSON', () {
    test('round-trip preserves all fields', () {
      final original = CampusEventModel(
        id: 'evt-1',
        title: 'Tech Fest',
        collegeId: 'col-coep',
        collegeName: 'COEP',
        category: StudentLifeConstants.eventHackathon,
        description: 'Annual hackathon',
        location: 'Main Hall',
        startAt: future,
        endAt: future.add(const Duration(hours: 8)),
        posterUrl: 'https://example.com/poster.jpg',
        galleryUrls: const ['https://example.com/g1.jpg'],
        searchText: 'tech fest coep',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      final restored = CampusEventModel.fromJson(original.toJson(), docId: 'evt-1');
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.category, original.category);
      expect(restored.galleryUrls, original.galleryUrls);
      expect(restored.startAt, original.startAt);
    });

    test('isUpcoming reflects startAt', () {
      final upcoming = CampusEventModel(
        id: '1', title: 'Soon', collegeId: 'c', collegeName: 'C',
        category: StudentLifeConstants.eventTechnical,
        startAt: DateTime.now().add(const Duration(days: 3)),
        endAt: DateTime.now().add(const Duration(days: 4)),
        createdAt: now, updatedAt: now,
      );
      expect(upcoming.isUpcoming, isTrue);
    });
  });

  group('StudentClubModel JSON', () {
    test('round-trip preserves coordinators and counts', () {
      final original = StudentClubModel(
        id: 'club-1',
        name: 'Robotics Club',
        collegeId: 'col-1',
        collegeName: 'PICT',
        clubType: StudentLifeConstants.clubTechnical,
        description: 'Build robots',
        facultyCoordinator: 'Dr. Patil',
        studentCoordinators: const ['Amit', 'Priya'],
        membersCount: 85,
        searchText: 'robotics pict',
        updatedAt: now,
      );
      final restored = StudentClubModel.fromJson(original.toJson());
      expect(restored.name, 'Robotics Club');
      expect(restored.studentCoordinators, ['Amit', 'Priya']);
      expect(restored.membersCount, 85);
    });
  });

  group('CompetitionModel JSON', () {
    test('round-trip preserves winners and media', () {
      final original = CompetitionModel(
        id: 'comp-1',
        title: 'Code Sprint',
        collegeId: 'col-1',
        collegeName: 'VIT',
        scope: StudentLifeConstants.scopeNational,
        description: '24h coding',
        prizeDetails: 'INR 50k',
        registrationDeadline: future,
        winners: const [
          CompetitionWinnerModel(name: 'Team Alpha', position: '1st', collegeName: 'COEP'),
        ],
        certificateUrls: const ['https://example.com/cert.pdf'],
        photoUrls: const ['https://example.com/photo.jpg'],
        videoUrls: const ['https://example.com/video.mp4'],
        searchText: 'code sprint',
        createdAt: now,
        updatedAt: now,
      );
      final restored = CompetitionModel.fromJson(original.toJson());
      expect(restored.winners.single.name, 'Team Alpha');
      expect(restored.certificateUrls, original.certificateUrls);
      expect(restored.isRegistrationOpen, isTrue);
    });
  });

  group('StudentCommunityModel JSON', () {
    test('round-trip preserves branch and verification flag', () {
      final original = StudentCommunityModel(
        id: 'comm-1',
        name: 'CSE 2024',
        collegeId: 'col-1',
        collegeName: 'COEP',
        communityType: StudentLifeConstants.communityBranch,
        branchOrYear: 'CSE 2024',
        description: 'CSE batch group',
        verifiedStudentsOnly: true,
        updatedAt: now,
      );
      final restored = StudentCommunityModel.fromJson(original.toJson());
      expect(restored.branchOrYear, 'CSE 2024');
      expect(restored.verifiedStudentsOnly, isTrue);
    });
  });

  group('PollOptionModel JSON', () {
    test('round-trip preserves vote counts', () {
      const original = PollOptionModel(id: 'opt-a', label: 'Yes', voteCount: 42);
      final restored = PollOptionModel.fromJson(original.toJson());
      expect(restored.label, 'Yes');
      expect(restored.voteCount, 42);
    });
  });

  group('StudentCommunityPostModel JSON', () {
    test('round-trip preserves poll and engagement fields', () {
      final pollEnd = future.add(const Duration(days: 7));
      final original = StudentCommunityPostModel(
        id: 'post-1',
        communityId: 'comm-1',
        collegeId: 'col-1',
        collegeName: 'COEP',
        authorId: 'user-1',
        authorDisplayName: 'Rahul',
        isVerifiedStudent: true,
        postType: StudentLifeConstants.postPoll,
        content: 'Which fest?',
        pollQuestion: 'Favorite fest?',
        pollOptions: const [
          PollOptionModel(id: 'a', label: 'Tech', voteCount: 10),
          PollOptionModel(id: 'b', label: 'Cultural', voteCount: 5),
        ],
        pollEndsAt: pollEnd,
        likeCount: 12,
        likedBy: const ['u2', 'u3'],
        isPinned: true,
        pinnedAt: now,
        createdAt: now,
        updatedAt: now,
      );
      final restored = StudentCommunityPostModel.fromJson(original.toJson());
      expect(restored.isPoll, isTrue);
      expect(restored.pollOptions.length, 2);
      expect(restored.pollEndsAt, pollEnd);
      expect(restored.likedBy, ['u2', 'u3']);
      expect(restored.hasImages, isFalse);
    });

    test('isAnnouncement detects post type', () {
      final post = StudentCommunityPostModel(
        id: 'p', communityId: 'c', authorId: 'a', authorDisplayName: 'X',
        postType: StudentLifeConstants.postAnnouncement,
        imageUrls: const ['img.jpg'],
        createdAt: now, updatedAt: now,
      );
      expect(post.isAnnouncement, isTrue);
      expect(post.hasImages, isTrue);
    });
  });

  group('StudentCommunityCommentModel JSON', () {
    test('round-trip preserves reply metadata', () {
      final original = StudentCommunityCommentModel(
        id: 'cmt-1',
        postId: 'post-1',
        communityId: 'comm-1',
        authorId: 'user-2',
        authorDisplayName: 'Priya',
        isVerifiedStudent: true,
        content: 'Great post!',
        parentCommentId: 'cmt-parent',
        replyCount: 3,
        createdAt: now,
      );
      final restored = StudentCommunityCommentModel.fromJson(original.toJson());
      expect(restored.isReply, isTrue);
      expect(restored.parentCommentId, 'cmt-parent');
      expect(restored.replyCount, 3);
    });
  });
}