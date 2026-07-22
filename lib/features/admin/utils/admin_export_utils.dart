import '../models/admin_models.dart';

String exportAnalyticsCsv(AdminAnalyticsData data) {
  final buffer = StringBuffer();
  buffer.writeln('Section,Date,Count');

  for (final p in data.reviewGrowth) {
    buffer.writeln('Review Growth,${_fmt(p.date)},${p.count}');
  }
  for (final p in data.userGrowth) {
    buffer.writeln('User Growth,${_fmt(p.date)},${p.count}');
  }
  for (final p in data.collegeGrowth) {
    buffer.writeln('College Growth,${_fmt(p.date)},${p.count}');
  }

  buffer.writeln('');
  buffer.writeln('Most Viewed,College,Count');
  for (final m in data.mostViewed) {
    buffer.writeln('View,${m.collegeName},${m.value}');
  }

  buffer.writeln('');
  buffer.writeln('Most Searched,College,Count');
  for (final m in data.mostSearched) {
    buffer.writeln('Search,${m.collegeName},${m.value}');
  }

  buffer.writeln('');
  buffer.writeln('Most Bookmarked,College,Count');
  for (final m in data.mostBookmarked) {
    buffer.writeln('Bookmark,${m.collegeName},${m.value}');
  }

  buffer.writeln('');
  buffer.writeln('Top Reviewed,College,Count');
  for (final m in data.topReviewed) {
    buffer.writeln('Reviewed,${m.collegeName},${m.value}');
  }

  buffer.writeln('');
  buffer.writeln('Trending,College,Count');
  for (final m in data.trendingColleges) {
    buffer.writeln('Trending,${m.collegeName},${m.value}');
  }

  buffer.writeln('');
  buffer.writeln('Most Active,College,Count');
  for (final m in data.mostActiveColleges) {
    buffer.writeln('Active,${m.collegeName},${m.value}');
  }

  buffer.writeln('');
  buffer.writeln('Top Contributors,Name,Reviews,Answers,Posts,Total');
  for (final c in data.topContributors) {
    buffer.writeln(
      '${_csv(c.displayName)},${c.reviewCount},${c.answerCount},${c.postCount},${c.totalActivity}',
    );
  }

  return buffer.toString();
}

String exportReportsCsv(List<AdminReportSummary> reports) {
  final buffer = StringBuffer();
  buffer.writeln('Source,Report ID,Reason,Status,Entity ID,Created At');
  for (final r in reports) {
    buffer.writeln(
      '${_csv(r.source)},${_csv(r.reportId)},${_csv(r.reason)},${_csv(r.status)},${_csv(r.entityId)},${_fmt(r.createdAt)}',
    );
  }
  return buffer.toString();
}

String exportCollegeStatsCsv(List<Map<String, dynamic>> rows) {
  final buffer = StringBuffer();
  buffer.writeln('College ID,Name,City,State,Type,Overall Rating,Review Count,Active');
  for (final row in rows) {
    buffer.writeln(
      '${_csv(row['id']?.toString() ?? '')},${_csv(row['name']?.toString() ?? '')},${_csv(row['city']?.toString() ?? '')},${_csv(row['state']?.toString() ?? '')},${_csv(row['type']?.toString() ?? '')},${row['overall'] ?? 0},${row['reviewCount'] ?? 0},${row['isActive'] ?? true}',
    );
  }
  return buffer.toString();
}

String exportDashboardStatsCsv(AdminDashboardStats stats) {
  return '''
Metric,Value
Total Colleges,${stats.totalColleges}
Total Users,${stats.totalUsers}
Verified Students,${stats.verifiedStudents}
Verified Alumni,${stats.verifiedAlumni}
Total Reviews,${stats.totalReviews}
Total Questions,${stats.totalQuestions}
Total Answers,${stats.totalAnswers}
Community Posts,${stats.communityPosts}
Total Reports,${stats.totalReports}
Pending Verifications,${stats.pendingVerifications}
Daily Active Users,${stats.dailyActiveUsers}
Monthly Active Users,${stats.monthlyActiveUsers}
Fetched At,${_fmt(stats.fetchedAt)}
''';
}

String exportVerificationReportCsv(List<Map<String, dynamic>> rows) {
  final buffer = StringBuffer();
  buffer.writeln('Request ID,User ID,College,Role,Document Type,Status,Created At');
  for (final row in rows) {
    buffer.writeln(
      '${_csv(row['id']?.toString() ?? '')},${_csv(row['userId']?.toString() ?? '')},${_csv(row['collegeName']?.toString() ?? '')},${_csv(row['verificationRole']?.toString() ?? '')},${_csv(row['documentType']?.toString() ?? '')},${_csv(row['status']?.toString() ?? '')},${_csv(row['createdAt']?.toString() ?? '')}',
    );
  }
  return buffer.toString();
}

String exportUserReportsCsv(List<Map<String, dynamic>> rows) {
  final buffer = StringBuffer();
  buffer.writeln('Report ID,Reported User,Reporter,Reason,Status,Created At');
  for (final row in rows) {
    buffer.writeln(
      '${_csv(row['id']?.toString() ?? '')},${_csv(row['reportedId']?.toString() ?? '')},${_csv(row['reporterId']?.toString() ?? '')},${_csv(row['reason']?.toString() ?? '')},${_csv(row['status']?.toString() ?? '')},${_csv(row['createdAt']?.toString() ?? '')}',
    );
  }
  return buffer.toString();
}

String _fmt(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

String _csv(String value) {
  if (value.contains(',') || value.contains('"')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// Tab-separated for Excel compatibility without extra packages.
String toExcelCompatible(String csv) => csv.replaceAll(',', '\t');
