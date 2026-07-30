import 'package:college_reality_india/core/constants/role_constants.dart';
import 'package:college_reality_india/features/admin/models/admin_models.dart';
import 'package:college_reality_india/features/admin/utils/admin_analytics_utils.dart';
import 'package:college_reality_india/features/admin/utils/admin_export_utils.dart';
import 'package:college_reality_india/features/admin/utils/admin_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  test('exportAnalyticsCsv and exportCollegeStatsCsv', () {
    final data = AdminAnalyticsData(
      reviewGrowth: [AdminGrowthPoint(date: now, count: 3)],
      userGrowth: [AdminGrowthPoint(date: now, count: 5)],
      collegeGrowth: [AdminGrowthPoint(date: now, count: 1)],
      mostViewed: [
        const AdminTopCollegeMetric(collegeId: 'c1', collegeName: 'COEP', value: 10, label: 'views'),
      ],
      mostSearched: [
        const AdminTopCollegeMetric(collegeId: 'c1', collegeName: 'COEP', value: 8, label: 'search'),
      ],
      mostBookmarked: [
        const AdminTopCollegeMetric(collegeId: 'c1', collegeName: 'COEP', value: 4, label: 'bm'),
      ],
      topReviewed: [
        const AdminTopCollegeMetric(collegeId: 'c1', collegeName: 'COEP', value: 20, label: 'rev'),
      ],
      trendingColleges: [
        const AdminTopCollegeMetric(collegeId: 'c1', collegeName: 'COEP', value: 7, label: 'tr'),
      ],
      mostActiveColleges: [
        const AdminTopCollegeMetric(collegeId: 'c1', collegeName: 'COEP', value: 9, label: 'act'),
      ],
      topContributors: [
        const AdminTopContributor(userId: 'u1', displayName: 'Ada, A', reviewCount: 2, answerCount: 1, postCount: 1),
      ],
      fetchedAt: now,
    );
    final csv = exportAnalyticsCsv(data);
    expect(csv, contains('Review Growth'));
    expect(csv, contains('Most Viewed'));
    expect(csv, contains('Top Contributors'));
    expect(csv, contains('"Ada, A"'));

    final collegeCsv = exportCollegeStatsCsv([
      {'id': 'c1', 'name': 'COEP', 'city': 'Pune', 'reviewCount': 10},
    ]);
    expect(collegeCsv, contains('COEP'));
  });

  test('buildGrowthSeries and rankBookmarkCounts', () {
    final series = buildGrowthSeries(
      timestamps: [DateTime.now(), DateTime.now().subtract(const Duration(days: 1))],
      days: 7,
    );
    expect(series, isNotEmpty);

    final ranked = rankBookmarkCounts(
      {'c1': 5, 'c2': 10, 'c3': 1},
      {'c1': 'One', 'c2': 'Two', 'c3': 'Three'},
    );
    expect(ranked.first.collegeId, 'c2');
    expect(ranked.first.collegeName, 'Two');
  });

  test('AdminPermissions matrix', () {
    expect(AdminPermissions.isStaff(RoleConstants.userTypeModerator), isTrue);
    expect(AdminPermissions.isAdmin(RoleConstants.userTypeAdmin), isTrue);
    expect(AdminPermissions.isSuperAdmin(RoleConstants.userTypeSuperAdmin), isTrue);
    expect(AdminPermissions.canManageColleges(RoleConstants.userTypeAdmin), isTrue);
    expect(AdminPermissions.canMergeColleges(RoleConstants.userTypeSuperAdmin), isTrue);
    expect(AdminPermissions.canBroadcast(RoleConstants.userTypeAdmin), isTrue);
    expect(AdminPermissions.canManageUsers(RoleConstants.userTypeAdmin), isTrue);
    expect(AdminPermissions.canModerateContent(RoleConstants.userTypeModerator), isTrue);
    expect(AdminPermissions.canManageVerification(RoleConstants.userTypeAdmin), isTrue);
    expect(AdminPermissions.canExportData(RoleConstants.userTypeAdmin), isTrue);
    expect(AdminPermissions.canViewAnalytics(RoleConstants.userTypeModerator), isTrue);
    expect(AdminPermissions.canMergeColleges(RoleConstants.userTypeAdmin), isFalse);
  });
}