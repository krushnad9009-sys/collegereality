import '../models/placement_submission_model.dart';
import '../models/verified_placement_stats.dart';

class PlacementStatsCalculator {
  static VerifiedPlacementStats compute(List<PlacementSubmissionModel> approved) {
    if (approved.isEmpty) return const VerifiedPlacementStats();

    final packages = approved.map((e) => e.packageLpa).toList()..sort();
    final fullTime =
        approved.where((e) => e.isFullTime).length;
    final internships =
        approved.where((e) => e.isInternship).length;
    final total = approved.length;

    final companyCounts = <String, int>{};
    for (final s in approved) {
      final key = s.companyName.trim();
      if (key.isNotEmpty) {
        companyCounts[key] = (companyCounts[key] ?? 0) + 1;
      }
    }
    final topRecruiters = companyCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final branchMap = <String, List<PlacementSubmissionModel>>{};
    for (final s in approved) {
      final branch = (s.branch?.trim().isNotEmpty == true)
          ? s.branch!.trim()
          : 'General';
      branchMap.putIfAbsent(branch, () => []).add(s);
    }
    final branchWise = branchMap.entries.map((entry) {
      final items = entry.value;
      final branchPackages = items.map((e) => e.packageLpa).toList();
      final ft = items.where((e) => e.isFullTime).length;
      return BranchPlacementStat(
        branch: entry.key,
        count: items.length,
        avgPackageLpa: branchPackages.isEmpty
            ? 0
            : branchPackages.reduce((a, b) => a + b) / branchPackages.length,
        placementRate: items.isEmpty ? 0 : (ft / items.length) * 100,
      );
    }).toList()
      ..sort((a, b) => b.avgPackageLpa.compareTo(a.avgPackageLpa));

    final yearMap = <int, List<PlacementSubmissionModel>>{};
    for (final s in approved) {
      yearMap.putIfAbsent(s.year, () => []).add(s);
    }
    final yearWise = yearMap.entries.map((entry) {
      final items = entry.value;
      final pkgs = items.map((e) => e.packageLpa).toList();
      final ft = items.where((e) => e.isFullTime).length;
      return YearPlacementTrend(
        year: entry.key,
        count: items.length,
        avgPackageLpa:
            pkgs.isEmpty ? 0 : pkgs.reduce((a, b) => a + b) / pkgs.length,
        highestPackageLpa: pkgs.isEmpty ? 0 : pkgs.reduce((a, b) => a > b ? a : b),
        fullTimeRate: items.isEmpty ? 0 : (ft / items.length) * 100,
      );
    }).toList()
      ..sort((a, b) => a.year.compareTo(b.year));

    return VerifiedPlacementStats(
      averagePackageLpa: packages.reduce((a, b) => a + b) / packages.length,
      highestPackageLpa: packages.last,
      medianPackageLpa: _median(packages),
      placementPercentage: total == 0 ? 0 : (fullTime / total) * 100,
      internshipPercentage: total == 0 ? 0 : (internships / total) * 100,
      topRecruiters: topRecruiters.take(10).map((e) => e.key).toList(),
      branchWise: branchWise,
      yearWise: yearWise,
      approvedCount: total,
      lastUpdatedAt: DateTime.now(),
    );
  }

  static double _median(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
