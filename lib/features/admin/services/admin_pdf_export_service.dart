import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/admin_models.dart';

/// Builds and shares PDF exports for Super Admin / Admin export center.
class AdminPdfExportService {
  Future<void> shareDashboardPdf(AdminDashboardStats stats) async {
    final bytes = await _buildSimpleReport(
      title: 'College Reality - Dashboard KPIs',
      rows: [
        ['Metric', 'Value'],
        ['Total Colleges', '${stats.totalColleges}'],
        ['Total Users', '${stats.totalUsers}'],
        ['Verified Students', '${stats.verifiedStudents}'],
        ['Verified Alumni', '${stats.verifiedAlumni}'],
        ['Total Reviews', '${stats.totalReviews}'],
        ['Pending Verifications', '${stats.pendingVerifications}'],
        ['Daily Active Users', '${stats.dailyActiveUsers}'],
        ['Monthly Active Users', '${stats.monthlyActiveUsers}'],
        ['Fetched At', stats.fetchedAt.toIso8601String()],
      ],
    );
    await _share(bytes, 'dashboard_kpis.pdf');
  }

  Future<void> shareAnalyticsPdf(AdminAnalyticsData data) async {
    final rows = <List<String>>[
      ['Section', 'Name', 'Value'],
      ...data.mostViewed.map(
        (m) => ['Most Viewed', m.collegeName, '${m.value}'],
      ),
      ...data.topReviewed.map(
        (m) => ['Top Reviewed', m.collegeName, '${m.value}'],
      ),
      ...data.trendingColleges.map(
        (m) => ['Trending', m.collegeName, '${m.value}'],
      ),
    ];
    final bytes = await _buildSimpleReport(
      title: 'College Reality - Analytics Report',
      rows: rows,
    );
    await _share(bytes, 'analytics_report.pdf');
  }

  Future<void> shareReportsPdf(List<AdminReportSummary> reports) async {
    final rows = <List<String>>[
      ['Source', 'Reason', 'Status', 'Entity', 'Created'],
      ...reports.map(
        (r) => [
          r.source,
          r.reason,
          r.status,
          r.entityId,
          r.createdAt.toIso8601String(),
        ],
      ),
    ];
    final bytes = await _buildSimpleReport(
      title: 'College Reality - Moderation Reports',
      rows: rows,
    );
    await _share(bytes, 'moderation_reports.pdf');
  }

  Future<Uint8List> _buildSimpleReport({
    required String title,
    required List<List<String>> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated ${DateTime.now().toIso8601String()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          if (rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.length > 1 ? rows.sublist(1) : const <List<String>>[],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _share(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'College Reality admin export',
    );
  }
}