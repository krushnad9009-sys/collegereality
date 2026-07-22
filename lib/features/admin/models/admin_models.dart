class AdminDashboardStats {
  final int totalColleges;
  final int totalUsers;
  final int verifiedStudents;
  final int verifiedAlumni;
  final int totalReviews;
  final int totalQuestions;
  final int totalAnswers;
  final int communityPosts;
  final int totalReports;
  final int pendingVerifications;
  final int dailyActiveUsers;
  final int monthlyActiveUsers;
  final DateTime fetchedAt;

  const AdminDashboardStats({
    this.totalColleges = 0,
    this.totalUsers = 0,
    this.verifiedStudents = 0,
    this.verifiedAlumni = 0,
    this.totalReviews = 0,
    this.totalQuestions = 0,
    this.totalAnswers = 0,
    this.communityPosts = 0,
    this.totalReports = 0,
    this.pendingVerifications = 0,
    this.dailyActiveUsers = 0,
    this.monthlyActiveUsers = 0,
    required this.fetchedAt,
  });
}

class AdminGrowthPoint {
  final DateTime date;
  final int count;

  const AdminGrowthPoint({required this.date, required this.count});
}

class AdminTopCollegeMetric {
  final String collegeId;
  final String collegeName;
  final int value;
  final String label;

  const AdminTopCollegeMetric({
    required this.collegeId,
    required this.collegeName,
    required this.value,
    required this.label,
  });
}

class AdminTopContributor {
  final String userId;
  final String displayName;
  final int reviewCount;
  final int answerCount;
  final int postCount;

  const AdminTopContributor({
    required this.userId,
    required this.displayName,
    this.reviewCount = 0,
    this.answerCount = 0,
    this.postCount = 0,
  });

  int get totalActivity => reviewCount + answerCount + postCount;
}

class AdminAnalyticsData {
  final List<AdminGrowthPoint> reviewGrowth;
  final List<AdminGrowthPoint> userGrowth;
  final List<AdminGrowthPoint> collegeGrowth;
  final List<AdminTopCollegeMetric> mostViewed;
  final List<AdminTopCollegeMetric> mostSearched;
  final List<AdminTopCollegeMetric> mostBookmarked;
  final List<AdminTopCollegeMetric> topReviewed;
  final List<AdminTopCollegeMetric> trendingColleges;
  final List<AdminTopCollegeMetric> mostActiveColleges;
  final List<AdminTopContributor> topContributors;
  final DateTime fetchedAt;

  const AdminAnalyticsData({
    this.reviewGrowth = const [],
    this.userGrowth = const [],
    this.collegeGrowth = const [],
    this.mostViewed = const [],
    this.mostSearched = const [],
    this.mostBookmarked = const [],
    this.topReviewed = const [],
    this.trendingColleges = const [],
    this.mostActiveColleges = const [],
    this.topContributors = const [],
    required this.fetchedAt,
  });
}

class AdminReportSummary {
  final String source;
  final String reportId;
  final String reason;
  final String status;
  final String entityId;
  final DateTime createdAt;

  const AdminReportSummary({
    required this.source,
    required this.reportId,
    required this.reason,
    required this.status,
    this.entityId = '',
    required this.createdAt,
  });
}

class AdminSystemHealth {
  final int estimatedFirestoreReads;
  final int estimatedStorageMb;
  final int crashCount24h;
  final double avgResponseMs;
  final int errorLogCount;
  final DateTime fetchedAt;

  const AdminSystemHealth({
    this.estimatedFirestoreReads = 0,
    this.estimatedStorageMb = 0,
    this.crashCount24h = 0,
    this.avgResponseMs = 0,
    this.errorLogCount = 0,
    required this.fetchedAt,
  });
}

class AdminUserSearchResult {
  final String uid;
  final String email;
  final String? displayName;
  final String accountStatus;
  final String verificationStatus;
  final String verificationBadge;
  final DateTime? lastSeenAt;

  const AdminUserSearchResult({
    required this.uid,
    required this.email,
    this.displayName,
    this.accountStatus = 'active',
    this.verificationStatus = '',
    this.verificationBadge = '',
    this.lastSeenAt,
  });
}

class AdminPageResult<T> {
  final List<T> items;
  final String? lastDocumentId;
  final bool hasMore;

  const AdminPageResult({
    required this.items,
    this.lastDocumentId,
    this.hasMore = false,
  });
}
