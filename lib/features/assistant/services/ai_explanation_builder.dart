import 'package:intl/intl.dart';

import '../../colleges/models/college_model.dart';
import '../models/ai_query_intent.dart';

/// Template-based explanations citing only verified Firestore fields.
class AiExplanationBuilder {
  static final _currency = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹');

  List<String> buildReasons(CollegeModel college, AiQueryIntent intent) {
    final reasons = <String>[];
    final ratings = college.aggregatedRatings;
    final placements = college.placements;
    final fees = college.fees;
    final acc = college.accreditation;
    final hostel = college.hostel;

    if (college.reviewCount > 0 && ratings.overall > 0) {
      reasons.add(
        'Verified student rating: ${ratings.overall.toStringAsFixed(1)}/5 '
        'from ${college.reviewCount} review${college.reviewCount == 1 ? '' : 's'}.',
      );
    }

    switch (intent.sortBy) {
      case AiSortPriority.placements:
        if (placements.placementPercentage > 0) {
          reasons.add(
            'Placement rate: ${placements.placementPercentage}% '
            '(avg package ${placements.averagePackageLpa.toStringAsFixed(1)} LPA).',
          );
        }
        if (ratings.placements > 0) {
          reasons.add(
            'Students rated placements ${ratings.placements.toStringAsFixed(1)}/5.',
          );
        }
        break;
      case AiSortPriority.feesLow:
        final feeLabel = _feeRangeLabel(fees);
        if (feeLabel != null) reasons.add('Annual fees: $feeLabel.');
        if (ratings.fees > 0) {
          reasons.add(
            'Value-for-money rating: ${ratings.fees.toStringAsFixed(1)}/5.',
          );
        }
        break;
      case AiSortPriority.hostel:
        if (hostel.available) {
          reasons.add('Hostel available on campus.');
          if (hostel.annualFee > 0) {
            reasons.add(
              'Hostel fee: ${_currency.format(hostel.annualFee)}/year.',
            );
          }
          if (ratings.hostel > 0) {
            reasons.add(
              'Hostel rated ${ratings.hostel.toStringAsFixed(1)}/5 by verified students.',
            );
          }
        }
        break;
      case AiSortPriority.campusLife:
        if (ratings.campusLife > 0) {
          reasons.add(
            'Campus life rated ${ratings.campusLife.toStringAsFixed(1)}/5.',
          );
        }
        break;
      case AiSortPriority.attendance:
        if (ratings.attendance > 0) {
          reasons.add(
            'Attendance policies rated ${ratings.attendance.toStringAsFixed(1)}/5 '
            'by verified students.',
          );
        }
        break;
      case AiSortPriority.faculty:
        if (ratings.faculty > 0) {
          reasons.add(
            'Faculty rated ${ratings.faculty.toStringAsFixed(1)}/5.',
          );
        }
        if (ratings.teaching > 0) {
          reasons.add(
            'Teaching quality: ${ratings.teaching.toStringAsFixed(1)}/5.',
          );
        }
        break;
      case AiSortPriority.naac:
        if (acc.naacGrade != null && acc.naacGrade!.isNotEmpty) {
          reasons.add('NAAC accreditation: ${acc.naacGrade}.');
        }
        break;
      case AiSortPriority.nirf:
        if (acc.nirfRank != null) {
          reasons.add(
            'NIRF rank #${acc.nirfRank}'
            '${acc.nirfCategory != null ? ' (${acc.nirfCategory})' : ''}.',
          );
        }
        break;
      case AiSortPriority.overall:
        if (placements.placementPercentage > 0) {
          reasons.add(
            '${placements.placementPercentage}% placements, '
            'avg ${placements.averagePackageLpa.toStringAsFixed(1)} LPA.',
          );
        }
        break;
    }

    if (acc.naacGrade != null &&
        acc.naacGrade!.isNotEmpty &&
        intent.sortBy != AiSortPriority.naac) {
      reasons.add('NAAC: ${acc.naacGrade}.');
    }
    if (acc.nirfRank != null &&
        intent.sortBy != AiSortPriority.nirf) {
      reasons.add('NIRF rank #${acc.nirfRank}.');
    }

    reasons.add('Location: ${college.locationLabel}.');
    reasons.add('Type: ${_capitalize(college.type)} college.');

    if (intent.course != null && _offersCourse(college, intent.course!)) {
      reasons.add('Offers ${intent.course}.');
    }

    return reasons.take(5).toList();
  }

  String buildSearchSummary(AiQueryIntent intent, int resultCount) {
    final parts = <String>[];
    if (intent.city != null) parts.add('in ${intent.city}');
    if (intent.state != null && intent.city == null) {
      parts.add('in ${intent.state}');
    }
    if (intent.course != null) parts.add('for ${intent.course}');
    if (intent.collegeType != null) {
      parts.add('(${_capitalize(intent.collegeType!)} only)');
    }
    if (intent.maxFees != null) {
      parts.add('under ${_currency.format(intent.maxFees)}');
    }
    if (intent.requireHostel) parts.add('with hostel');
    if (intent.naacGrade != null) parts.add('NAAC ${intent.naacGrade}');

    final filterText = parts.isEmpty ? '' : ' ${parts.join(', ')}';
    if (resultCount == 0) {
      return 'No colleges in our verified database match your query$filterText. '
          'Try broadening location or filters.';
    }
    return 'Found $resultCount verified colleges$filterText, ranked using '
        'Firestore ratings, placements, fees, hostel, NAAC & NIRF data.';
  }

  static String? _feeRangeLabel(CollegeFees fees) {
    if (fees.tuitionMin <= 0 && fees.tuitionMax <= 0) return null;
    if (fees.tuitionMin > 0 && fees.tuitionMax > 0) {
      return '${_currency.format(fees.tuitionMin)} – ${_currency.format(fees.tuitionMax)}';
    }
    return _currency.format(
      fees.tuitionMax > 0 ? fees.tuitionMax : fees.tuitionMin,
    );
  }

  static bool _offersCourse(CollegeModel college, String course) {
    if (course == 'Computer Engineering') {
      return college.displayCourses.any(
        (c) =>
            c.toLowerCase().contains('computer') ||
            c.toLowerCase().contains('cse') ||
            c.toLowerCase().contains('information technology'),
      );
    }
    return college.courses.contains(course) ||
        college.displayCourses.any(
          (c) => c.toLowerCase().contains(course.toLowerCase()),
        );
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
