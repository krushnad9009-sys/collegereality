class BranchPlacementStat {
  final String branch;
  final int count;
  final double avgPackageLpa;
  final double placementRate;

  const BranchPlacementStat({
    required this.branch,
    this.count = 0,
    this.avgPackageLpa = 0,
    this.placementRate = 0,
  });

  factory BranchPlacementStat.fromJson(Map<String, dynamic> json) {
    return BranchPlacementStat(
      branch: json['branch'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      avgPackageLpa: (json['avgPackageLpa'] as num?)?.toDouble() ?? 0,
      placementRate: (json['placementRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'branch': branch,
        'count': count,
        'avgPackageLpa': avgPackageLpa,
        'placementRate': placementRate,
      };
}

class YearPlacementTrend {
  final int year;
  final int count;
  final double avgPackageLpa;
  final double highestPackageLpa;
  final double fullTimeRate;

  const YearPlacementTrend({
    required this.year,
    this.count = 0,
    this.avgPackageLpa = 0,
    this.highestPackageLpa = 0,
    this.fullTimeRate = 0,
  });

  factory YearPlacementTrend.fromJson(Map<String, dynamic> json) {
    return YearPlacementTrend(
      year: (json['year'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      avgPackageLpa: (json['avgPackageLpa'] as num?)?.toDouble() ?? 0,
      highestPackageLpa: (json['highestPackageLpa'] as num?)?.toDouble() ?? 0,
      fullTimeRate: (json['fullTimeRate'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'year': year,
        'count': count,
        'avgPackageLpa': avgPackageLpa,
        'highestPackageLpa': highestPackageLpa,
        'fullTimeRate': fullTimeRate,
      };
}

class VerifiedPlacementStats {
  final double averagePackageLpa;
  final double highestPackageLpa;
  final double medianPackageLpa;
  final double placementPercentage;
  final double internshipPercentage;
  final List<String> topRecruiters;
  final List<BranchPlacementStat> branchWise;
  final List<YearPlacementTrend> yearWise;
  final int approvedCount;
  final DateTime? lastUpdatedAt;

  const VerifiedPlacementStats({
    this.averagePackageLpa = 0,
    this.highestPackageLpa = 0,
    this.medianPackageLpa = 0,
    this.placementPercentage = 0,
    this.internshipPercentage = 0,
    this.topRecruiters = const [],
    this.branchWise = const [],
    this.yearWise = const [],
    this.approvedCount = 0,
    this.lastUpdatedAt,
  });

  bool get hasData => approvedCount > 0;

  factory VerifiedPlacementStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const VerifiedPlacementStats();
    return VerifiedPlacementStats(
      averagePackageLpa: (json['averagePackageLpa'] as num?)?.toDouble() ?? 0,
      highestPackageLpa: (json['highestPackageLpa'] as num?)?.toDouble() ?? 0,
      medianPackageLpa: (json['medianPackageLpa'] as num?)?.toDouble() ?? 0,
      placementPercentage:
          (json['placementPercentage'] as num?)?.toDouble() ?? 0,
      internshipPercentage:
          (json['internshipPercentage'] as num?)?.toDouble() ?? 0,
      topRecruiters: (json['topRecruiters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      branchWise: (json['branchWise'] as List<dynamic>?)
              ?.map((e) => BranchPlacementStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      yearWise: (json['yearWise'] as List<dynamic>?)
              ?.map((e) => YearPlacementTrend.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      approvedCount: (json['approvedCount'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: json['lastUpdatedAt'] != null
          ? DateTime.tryParse(json['lastUpdatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'averagePackageLpa': averagePackageLpa,
        'highestPackageLpa': highestPackageLpa,
        'medianPackageLpa': medianPackageLpa,
        'placementPercentage': placementPercentage,
        'internshipPercentage': internshipPercentage,
        'topRecruiters': topRecruiters,
        'branchWise': branchWise.map((e) => e.toJson()).toList(),
        'yearWise': yearWise.map((e) => e.toJson()).toList(),
        'approvedCount': approvedCount,
        'lastUpdatedAt': lastUpdatedAt?.toIso8601String(),
      };
}
