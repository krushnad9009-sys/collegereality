import '../../../core/constants/admission_constants.dart';
import '../models/admission_prediction_model.dart';
import '../models/cutoff_record_model.dart';
import '../models/entrance_exam_model.dart';
import '../models/scholarship_model.dart';

String buildAdmissionSearchText(List<String> parts) {
  return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).join(' ').toLowerCase();
}

bool matchesSearch(String searchText, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return true;
  return searchText.contains(normalized);
}

List<ScholarshipModel> filterScholarships({
  required List<ScholarshipModel> scholarships,
  required String searchQuery,
  String? providerType,
  String? category,
  String? state,
  String? course,
  double? maxIncomeLpa,
}) {
  return scholarships.where((s) {
    if (!s.isActive) return false;
    if (!matchesSearch(s.searchText, searchQuery)) return false;
    if (providerType != null && providerType.isNotEmpty && s.providerType != providerType) {
      return false;
    }
    if (category != null &&
        category.isNotEmpty &&
        !s.categories.any((c) => c.toLowerCase() == category.toLowerCase())) {
      return false;
    }
    if (state != null && state.isNotEmpty && (s.state ?? '').toLowerCase() != state.toLowerCase()) {
      return false;
    }
    if (course != null &&
        course.isNotEmpty &&
        !s.courses.any((c) => c.toLowerCase().contains(course.toLowerCase()))) {
      return false;
    }
    if (maxIncomeLpa != null && s.maxIncomeLpa != null && maxIncomeLpa > s.maxIncomeLpa!) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

bool checkScholarshipEligibility({
  required ScholarshipModel scholarship,
  required String userCategory,
  required String? userState,
  required String? userCourse,
  required double? userIncomeLpa,
}) {
  if (scholarship.isExpired) return false;

  if (scholarship.categories.isNotEmpty &&
      !scholarship.categories.any((c) => c.toLowerCase() == userCategory.toLowerCase()) &&
      !scholarship.categories.any((c) => c.toLowerCase() == 'general')) {
    return false;
  }

  if (scholarship.state != null &&
      scholarship.state!.isNotEmpty &&
      userState != null &&
      scholarship.state!.toLowerCase() != userState.toLowerCase()) {
    return false;
  }

  if (scholarship.courses.isNotEmpty &&
      userCourse != null &&
      !scholarship.courses.any((c) => c.toLowerCase().contains(userCourse.toLowerCase()))) {
    return false;
  }

  if (scholarship.maxIncomeLpa != null &&
      userIncomeLpa != null &&
      userIncomeLpa > scholarship.maxIncomeLpa!) {
    return false;
  }

  return true;
}

List<EntranceExamModel> filterExams({
  required List<EntranceExamModel> exams,
  required String searchQuery,
}) {
  return exams
      .where((e) => e.isActive && matchesSearch(e.searchText, searchQuery))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

List<CutoffRecordModel> filterCutoffs({
  required List<CutoffRecordModel> cutoffs,
  required String collegeQuery,
  required String courseQuery,
  String? state,
  String? university,
  String? category,
  String? gender,
  String? round,
  String? examId,
}) {
  return cutoffs.where((c) {
    if (collegeQuery.isNotEmpty &&
        !c.collegeName.toLowerCase().contains(collegeQuery.toLowerCase())) {
      return false;
    }
    if (courseQuery.isNotEmpty &&
        !c.course.toLowerCase().contains(courseQuery.toLowerCase()) &&
        !c.branch.toLowerCase().contains(courseQuery.toLowerCase())) {
      return false;
    }
    if (state != null && state.isNotEmpty && c.state.toLowerCase() != state.toLowerCase()) {
      return false;
    }
    if (university != null &&
        university.isNotEmpty &&
        !c.university.toLowerCase().contains(university.toLowerCase())) {
      return false;
    }
    if (category != null && category.isNotEmpty && c.category != category) return false;
    if (gender != null &&
        gender.isNotEmpty &&
        gender != 'All' &&
        c.gender != 'All' &&
        c.gender != gender) {
      return false;
    }
    if (round != null && round.isNotEmpty && c.round != round) return false;
    if (examId != null && examId.isNotEmpty && c.examId != examId) return false;
    return true;
  }).toList()
    ..sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);
      if (yearCompare != 0) return yearCompare;
      return a.collegeName.compareTo(b.collegeName);
    });
}

List<PredictionResultModel> predictAdmission({
  required List<CutoffRecordModel> cutoffs,
  required String scoreType,
  int? rank,
  double? percentile,
  double? marks,
  required String category,
  String gender = 'All',
  String state = '',
  String homeUniversity = '',
}) {
  final filtered = cutoffs.where((c) {
    if (c.category != category) return false;
    if (gender != 'All' && c.gender != 'All' && c.gender != gender) return false;
    if (state.isNotEmpty && c.state.isNotEmpty && c.state.toLowerCase() != state.toLowerCase()) {
      return false;
    }
    if (homeUniversity.isNotEmpty &&
        c.university.isNotEmpty &&
        !c.university.toLowerCase().contains(homeUniversity.toLowerCase())) {
      // Prefer home university but don't exclude others entirely
    }
    return true;
  }).toList();

  final results = <PredictionResultModel>[];

  for (final cutoff in filtered) {
    final chance = _computeChance(
      scoreType: scoreType,
      rank: rank,
      percentile: percentile,
      marks: marks,
      cutoff: cutoff,
    );
    if (chance == null) continue;

    results.add(
      PredictionResultModel(
        collegeId: cutoff.collegeId,
        collegeName: cutoff.collegeName,
        course: cutoff.course,
        branch: cutoff.branch,
        chance: chance.$1,
        explanation: chance.$2,
        cutoffRank: cutoff.cutoffRank,
        cutoffPercentile: cutoff.cutoffPercentile,
        cutoffMarks: cutoff.cutoffMarks,
      ),
    );
  }

  results.sort((a, b) {
    final order = {
      AdmissionConstants.chanceHigh: 0,
      AdmissionConstants.chanceMedium: 1,
      AdmissionConstants.chanceLow: 2,
    };
    return (order[a.chance] ?? 3).compareTo(order[b.chance] ?? 3);
  });

  return results;
}

(String chance, String explanation)? _computeChance({
  required String scoreType,
  int? rank,
  double? percentile,
  double? marks,
  required CutoffRecordModel cutoff,
}) {
  switch (scoreType) {
    case AdmissionConstants.scoreTypeRank:
      if (rank == null || cutoff.cutoffRank == null) return null;
      final gap = cutoff.cutoffRank! - rank;
      final margin = cutoff.cutoffRank! * 0.15;
      if (gap >= margin) {
        return (
          AdmissionConstants.chanceHigh,
          'Your rank $rank is significantly better than last year\'s closing rank ${cutoff.cutoffRank} (${cutoff.year}, ${cutoff.round}).',
        );
      }
      if (gap >= 0) {
        return (
          AdmissionConstants.chanceMedium,
          'Your rank $rank is close to last year\'s closing rank ${cutoff.cutoffRank} (${cutoff.year}, ${cutoff.round}).',
        );
      }
      return (
        AdmissionConstants.chanceLow,
        'Your rank $rank is below last year\'s closing rank ${cutoff.cutoffRank} (${cutoff.year}, ${cutoff.round}).',
      );

    case AdmissionConstants.scoreTypePercentile:
      if (percentile == null || cutoff.cutoffPercentile == null) return null;
      final gap = percentile - cutoff.cutoffPercentile!;
      final margin = cutoff.cutoffPercentile! * 0.05;
      if (gap >= margin) {
        return (
          AdmissionConstants.chanceHigh,
          'Your percentile ${percentile.toStringAsFixed(2)} exceeds last year\'s cutoff ${cutoff.cutoffPercentile!.toStringAsFixed(2)}.',
        );
      }
      if (gap >= 0) {
        return (
          AdmissionConstants.chanceMedium,
          'Your percentile ${percentile.toStringAsFixed(2)} is near last year\'s cutoff ${cutoff.cutoffPercentile!.toStringAsFixed(2)}.',
        );
      }
      return (
        AdmissionConstants.chanceLow,
        'Your percentile ${percentile.toStringAsFixed(2)} is below last year\'s cutoff ${cutoff.cutoffPercentile!.toStringAsFixed(2)}.',
      );

    case AdmissionConstants.scoreTypeMarks:
      if (marks == null || cutoff.cutoffMarks == null) return null;
      final gap = marks - cutoff.cutoffMarks!;
      final margin = cutoff.cutoffMarks! * 0.05;
      if (gap >= margin) {
        return (
          AdmissionConstants.chanceHigh,
          'Your marks ${marks.toStringAsFixed(0)} exceed last year\'s cutoff ${cutoff.cutoffMarks!.toStringAsFixed(0)}.',
        );
      }
      if (gap >= 0) {
        return (
          AdmissionConstants.chanceMedium,
          'Your marks ${marks.toStringAsFixed(0)} are near last year\'s cutoff ${cutoff.cutoffMarks!.toStringAsFixed(0)}.',
        );
      }
      return (
        AdmissionConstants.chanceLow,
        'Your marks ${marks.toStringAsFixed(0)} are below last year\'s cutoff ${cutoff.cutoffMarks!.toStringAsFixed(0)}.',
      );
    default:
      return null;
  }
}
