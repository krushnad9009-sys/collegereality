import 'package:college_reality_india/core/constants/placement_constants.dart';
import 'package:college_reality_india/features/placements/models/placement_submission_model.dart';
import 'package:college_reality_india/features/placements/models/verified_placement_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('PlacementSubmissionModel JSON, getters, copyWith', () {
    final m = PlacementSubmissionModel(
      id: 'p1',
      collegeId: 'c1',
      collegeName: 'COEP',
      userId: 'u1',
      companyName: 'Acme',
      jobRole: 'SDE',
      packageLpa: 12.5,
      employmentType: PlacementConstants.typeFullTime,
      year: 2025,
      branch: 'CSE',
      status: PlacementConstants.statusApproved,
      adminNote: 'ok',
      reviewedBy: 'admin',
      reviewedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    expect(m.isApproved, isTrue);
    expect(m.isPending, isFalse);
    expect(m.isFullTime, isTrue);
    expect(m.employmentLabel, 'Full-time');
    final restored = PlacementSubmissionModel.fromJson(m.toJson());
    expect(restored.packageLpa, 12.5);
    expect(restored.branch, 'CSE');
    expect(restored.copyWith(status: PlacementConstants.statusPending).isPending, isTrue);

    final intern = PlacementSubmissionModel(
      id: 'p2',
      collegeId: 'c1',
      collegeName: 'COEP',
      userId: 'u1',
      companyName: 'Acme',
      jobRole: 'Intern',
      packageLpa: 0.5,
      employmentType: PlacementConstants.typeInternship,
      year: 2025,
      createdAt: now,
      updatedAt: now,
    );
    expect(intern.isInternship, isTrue);
    expect(intern.employmentLabel, 'Internship');

    final empty = PlacementSubmissionModel.fromJson({});
    expect(empty.id, '');
    expect(empty.isPending, isTrue);
  });

  test('VerifiedPlacementStats nested JSON', () {
    expect(VerifiedPlacementStats.fromJson(null).hasData, isFalse);
    final stats = VerifiedPlacementStats(
      averagePackageLpa: 8,
      highestPackageLpa: 40,
      medianPackageLpa: 7,
      placementPercentage: 85,
      internshipPercentage: 40,
      topRecruiters: const ['Acme'],
      branchWise: const [
        BranchPlacementStat(branch: 'CSE', count: 10, avgPackageLpa: 9, placementRate: 90),
      ],
      yearWise: const [
        YearPlacementTrend(year: 2025, count: 20, avgPackageLpa: 8, highestPackageLpa: 40, fullTimeRate: 70),
      ],
      approvedCount: 20,
      lastUpdatedAt: now,
    );
    expect(stats.hasData, isTrue);
    final restored = VerifiedPlacementStats.fromJson(stats.toJson());
    expect(restored.topRecruiters, ['Acme']);
    expect(restored.branchWise.first.branch, 'CSE');
    expect(restored.yearWise.first.year, 2025);
    expect(BranchPlacementStat.fromJson({}).branch, '');
    expect(YearPlacementTrend.fromJson({}).year, 0);
  });
}