import 'package:college_reality_india/core/constants/engagement_constants.dart';
import 'package:college_reality_india/core/constants/student_life_constants.dart';
import 'package:college_reality_india/features/compare/models/saved_comparison_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EngagementConstants labels cover known values', () {
    final categories = [
      EngagementConstants.calendarCapRound,
      EngagementConstants.calendarCounselling,
      EngagementConstants.calendarDocVerification,
      EngagementConstants.calendarSeatAllotment,
      EngagementConstants.calendarFeePayment,
      EngagementConstants.calendarHostelAdmission,
      EngagementConstants.calendarExamDate,
      EngagementConstants.calendarResultDate,
      'custom',
    ];
    for (final c in categories) {
      expect(EngagementConstants.calendarCategoryLabel(c), isNotEmpty);
    }

    final types = [
      EngagementConstants.typeNewReview,
      EngagementConstants.typeNewAnswer,
      EngagementConstants.typeNewChatMessage,
      EngagementConstants.typeCollegeUpdate,
      EngagementConstants.typePlacementUpdate,
      EngagementConstants.typeScholarshipUpdate,
      EngagementConstants.typeEventReminder,
      EngagementConstants.typeAdmissionReminder,
      EngagementConstants.typeFeesChange,
      EngagementConstants.typePlacementStatsChange,
      EngagementConstants.typeScholarshipOpen,
      EngagementConstants.typeAdmissionStart,
      EngagementConstants.typeAdmissionDeadline,
      EngagementConstants.typeNewEvent,
      EngagementConstants.typeNewJob,
      EngagementConstants.typeNewInternship,
      EngagementConstants.typeApplicationUpdate,
      EngagementConstants.typeVerificationUpdate,
      EngagementConstants.typeReviewApproved,
      EngagementConstants.typeReviewComment,
      EngagementConstants.typeCommunityPost,
      EngagementConstants.typeCommunityComment,
      EngagementConstants.typeCommunityReply,
      EngagementConstants.typeAdminAnnouncement,
      'unknown',
    ];
    for (final t in types) {
      expect(EngagementConstants.notificationTypeLabel(t), isNotEmpty);
    }
  });

  test('StudentLifeConstants labels', () {
    expect(StudentLifeConstants.collegeFeedCommunityId('c1'), contains('c1'));
    expect(StudentLifeConstants.eventCategoryLabel(StudentLifeConstants.eventCultural), isNotEmpty);
    expect(StudentLifeConstants.eventCategoryLabel('x'), 'x');
    expect(StudentLifeConstants.clubTypeLabel(StudentLifeConstants.clubTechnical), isNotEmpty);
    expect(StudentLifeConstants.clubTypeLabel('x'), 'x');
    expect(StudentLifeConstants.competitionScopeLabel(StudentLifeConstants.scopeCollege), isNotEmpty);
    expect(StudentLifeConstants.competitionScopeLabel('x'), 'x');
  });

  test('SavedComparisonModel JSON', () {
    final m = SavedComparisonModel(
      id: 's1',
      title: 'My compare',
      collegeIds: const ['a', 'b'],
      savedAt: DateTime(2026, 1, 1),
    );
    final restored = SavedComparisonModel.fromJson(m.toJson());
    expect(restored.collegeIds, ['a', 'b']);
    expect(SavedComparisonModel.fromJson({}).title, 'Saved comparison');
  });
}