import 'package:flutter_test/flutter_test.dart';

import 'package:college_reality_india/core/constants/admission_constants.dart';
import 'package:college_reality_india/features/admission/models/cutoff_record_model.dart';
import 'package:college_reality_india/features/admission/models/scholarship_model.dart';
import 'package:college_reality_india/features/admission/utils/admission_utils.dart';

void main() {
  group('AdmissionUtils', () {
    ScholarshipModel sampleScholarship({
      required String id,
      required String name,
      List<String> categories = const ['General'],
      String? state,
      List<String> courses = const ['Engineering'],
      double? maxIncomeLpa,
      DateTime? lastDate,
    }) {
      final now = DateTime.now().add(const Duration(days: 30));
      return ScholarshipModel(
        id: id,
        name: name,
        nameLower: name.toLowerCase(),
        providerType: AdmissionConstants.providerCentralGovt,
        state: state,
        courses: courses,
        categories: categories,
        maxIncomeLpa: maxIncomeLpa,
        amount: '₹50,000',
        eligibility: 'Test eligibility',
        searchText: name.toLowerCase(),
        lastDate: lastDate ?? now,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
    }

    test('filterScholarships applies provider and search filters', () {
      final items = [
        sampleScholarship(id: '1', name: 'NSP Central Grant'),
        sampleScholarship(
          id: '2',
          name: 'Maharashtra State Scheme',
          state: 'Maharashtra',
        ),
      ];

      final filtered = filterScholarships(
        scholarships: items,
        searchQuery: 'maharashtra',
        providerType: null,
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('checkScholarshipEligibility validates income and state', () {
      final scholarship = sampleScholarship(
        id: '1',
        name: 'Income Test',
        state: 'Maharashtra',
        maxIncomeLpa: 5,
      );

      expect(
        checkScholarshipEligibility(
          scholarship: scholarship,
          userCategory: 'General',
          userState: 'Maharashtra',
          userCourse: 'Engineering',
          userIncomeLpa: 4,
        ),
        isTrue,
      );

      expect(
        checkScholarshipEligibility(
          scholarship: scholarship,
          userCategory: 'General',
          userState: 'Karnataka',
          userCourse: 'Engineering',
          userIncomeLpa: 4,
        ),
        isFalse,
      );
    });

    test('predictAdmission returns high chance when rank is better than cutoff', () {
      final cutoffs = [
        CutoffRecordModel(
          id: 'c1',
          collegeId: 'col1',
          collegeName: 'Test Institute',
          course: 'B.Tech',
          branch: 'CSE',
          examId: 'exam_jee',
          examName: 'JEE',
          year: 2025,
          round: 'Round 1',
          category: 'General',
          cutoffRank: 5000,
          scoreType: AdmissionConstants.scoreTypeRank,
          updatedAt: DateTime(2025),
        ),
      ];

      final results = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 1000,
        category: 'General',
      );

      expect(results, isNotEmpty);
      expect(results.first.chance, AdmissionConstants.chanceHigh);
    });

    test('predictAdmission returns low chance when rank is worse than cutoff', () {
      final cutoffs = [
        CutoffRecordModel(
          id: 'c1',
          collegeId: 'col1',
          collegeName: 'Test Institute',
          course: 'B.Tech',
          examId: 'exam_jee',
          examName: 'JEE',
          year: 2025,
          round: 'Round 1',
          category: 'General',
          cutoffRank: 1000,
          scoreType: AdmissionConstants.scoreTypeRank,
          updatedAt: DateTime(2025),
        ),
      ];

      final results = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 5000,
        category: 'General',
      );

      expect(results.first.chance, AdmissionConstants.chanceLow);
    });
  });
}
