import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/features/admin/models/admin_models.dart';
import 'package:college_reality_india/features/admin/services/admin_college_bulk_service.dart';
import 'package:college_reality_india/features/admin/utils/admin_analytics_utils.dart';
import 'package:college_reality_india/features/admin/utils/admin_export_utils.dart';
import 'package:college_reality_india/features/admin/utils/admin_moderation_utils.dart';
import 'package:college_reality_india/features/admin/utils/admin_permissions.dart';

void main() {
  group('AdminAnalyticsUtils', () {
    test('buildDailyGrowthSeries buckets timestamps by day', () {
      final now = DateTime.now();
      final points = buildDailyGrowthSeries(
        timestamps: [now, now.subtract(const Duration(days: 1))],
        days: 7,
      );
      expect(points.length, 7);
      expect(points.where((p) => p.count > 0).length, greaterThanOrEqualTo(1));
    });

    test('countActiveSince counts recent users', () {
      final count = countActiveSince(
        [DateTime.now(), DateTime.now().subtract(const Duration(days: 40))],
        const Duration(days: 30),
      );
      expect(count, 1);
    });

    test('spam and abuse detection helpers', () {
      expect(isLikelySpamReport('This is spam content'), isTrue);
      expect(isLikelyAbuseReport('Harassment report'), isTrue);
      expect(isLikelySpamReport('Wrong college info'), isFalse);
    });
  });

  group('AdminExportUtils', () {
    test('exportDashboardStatsCsv includes KPI rows', () {
      final csv = exportDashboardStatsCsv(
        AdminDashboardStats(
          totalColleges: 10,
          totalUsers: 100,
          pendingVerifications: 5,
          fetchedAt: DateTime(2026, 1, 1),
        ),
      );
      expect(csv, contains('Total Colleges,10'));
      expect(csv, contains('Total Users,100'));
      expect(csv, contains('Pending Verifications,5'));
    });

    test('exportVerificationReportCsv includes headers', () {
      final csv = exportVerificationReportCsv([
        {
          'id': 'v1',
          'userId': 'u1',
          'collegeName': 'ABC College',
          'verificationRole': 'student',
          'documentType': 'id_card',
          'status': 'pending',
          'createdAt': '2026-01-01',
        },
      ]);
      expect(csv, contains('Request ID,User ID,College'));
      expect(csv, contains('ABC College'));
    });

    test('exportUserReportsCsv includes headers', () {
      final csv = exportUserReportsCsv([
        {
          'id': 'r1',
          'reportedId': 'u2',
          'reporterId': 'u1',
          'reason': 'Harassment',
          'status': 'open',
          'createdAt': '2026-01-01',
        },
      ]);
      expect(csv, contains('Report ID,Reported User'));
      expect(csv, contains('Harassment'));
    });

    test('exportReportsCsv escapes commas', () {
      final csv = exportReportsCsv([
        AdminReportSummary(
          source: 'Review',
          reportId: 'r1',
          reason: 'Bad, content',
          status: 'open',
          createdAt: DateTime(2026, 1, 1),
        ),
      ]);
      expect(csv, contains('"Bad, content"'));
    });

    test('toExcelCompatible replaces commas with tabs', () {
      expect(toExcelCompatible('a,b,c'), 'a\tb\tc');
    });
  });

  group('AdminCollegeBulkService', () {
    test('parseCsv reads header and rows', () {
      const raw = 'name,city,state\nABC,Mumbai,MH';
      final rows = AdminCollegeBulkService().parseCsv(raw);
      expect(rows.length, 1);
      expect(rows.first['name'], 'ABC');
      expect(rows.first['city'], 'Mumbai');
    });

    test('collegeFromCsvRow builds college model', () {
      final college = AdminCollegeBulkService().collegeFromCsvRow({
        'name': 'Test College',
        'city': 'Pune',
        'state': 'Maharashtra',
      });
      expect(college.name, 'Test College');
      expect(college.city, 'Pune');
      expect(college.isActive, isTrue);
    });
  });

  group('AdminPermissions', () {
    test('role checks gate admin-only actions', () {
      expect(AdminPermissions.canMergeColleges('super_admin'), isTrue);
      expect(AdminPermissions.canMergeColleges('admin'), isFalse);
      expect(AdminPermissions.canModerateContent('moderator'), isTrue);
      expect(AdminPermissions.canBroadcast('moderator'), isFalse);
    });
  });

  group('AdminModerationUtils', () {
    test('reportCollectionForSource maps known sources', () {
      expect(reportCollectionForSource('Review'), 'review_reports');
      expect(reportCollectionForSource('Question'), 'question_reports');
    });

    test('moderationLabel flags spam', () {
      expect(
        moderationLabel(reason: 'spam link', source: 'Community'),
        contains('spam'),
      );
    });
  });
}
