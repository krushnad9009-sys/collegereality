import 'package:college_reality_india/core/constants/admission_constants.dart';
import 'package:college_reality_india/features/admission/models/cutoff_record_model.dart';
import 'package:college_reality_india/features/admission/models/entrance_exam_model.dart';
import 'package:college_reality_india/features/admission/utils/admission_utils.dart';
import 'package:flutter_test/flutter_test.dart';

CutoffRecordModel _cutoff({
  required String id,
  int? cutoffRank,
  double? cutoffPercentile,
  double? cutoffMarks,
  String category = 'General',
  String gender = 'All',
  String state = 'Maharashtra',
  String university = 'SPPU',
  String round = 'Round 1',
  String examId = 'jee',
  int year = 2025,
}) {
  return CutoffRecordModel(
    id: id,
    collegeId: 'col-$id',
    collegeName: 'College $id',
    course: 'B.Tech',
    branch: 'CSE',
    examId: examId,
    examName: 'JEE Main',
    year: year,
    round: round,
    category: category,
    gender: gender,
    university: university,
    state: state,
    cutoffRank: cutoffRank,
    cutoffPercentile: cutoffPercentile,
    cutoffMarks: cutoffMarks,
    updatedAt: DateTime(2025),
  );
}

EntranceExamModel _exam({
  required String id,
  required String name,
  bool isActive = true,
}) {
  return EntranceExamModel(
    id: id,
    name: name,
    slug: name.toLowerCase().replaceAll(' ', '-'),
    category: 'Engineering',
    searchText: name.toLowerCase(),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isActive: isActive,
  );
}

void main() {
  group('filterExams', () {
    test('filters inactive exams and applies search', () {
      final exams = [
        _exam(id: '1', name: 'JEE Main'),
        _exam(id: '2', name: 'MHT CET', isActive: false),
        _exam(id: '3', name: 'NEET UG'),
      ];

      final filtered = filterExams(exams: exams, searchQuery: 'jee');
      expect(filtered.length, 1);
      expect(filtered.first.name, 'JEE Main');
    });

    test('sorts exams alphabetically by name', () {
      final exams = [
        _exam(id: '1', name: 'NEET UG'),
        _exam(id: '2', name: 'JEE Main'),
      ];
      final filtered = filterExams(exams: exams, searchQuery: '');
      expect(filtered.first.name, 'JEE Main');
    });

    test('returns all active exams for empty search', () {
      final exams = [
        _exam(id: '1', name: 'JEE Main'),
        _exam(id: '2', name: 'MHT CET'),
      ];
      expect(filterExams(exams: exams, searchQuery: '').length, 2);
    });
  });

  group('filterCutoffs', () {
    final cutoffs = [
      _cutoff(id: '1', cutoffRank: 5000, state: 'Maharashtra', university: 'SPPU'),
      _cutoff(id: '2', cutoffRank: 8000, state: 'Karnataka', university: 'VTU'),
      _cutoff(id: '3', cutoffRank: 3000, category: 'OBC', gender: 'Female'),
    ];

    test('filters by college and course query', () {
      final filtered = filterCutoffs(
        cutoffs: cutoffs,
        collegeQuery: 'College 1',
        courseQuery: 'CSE',
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });

    test('filters by state, category, gender, round, examId', () {
      final filtered = filterCutoffs(
        cutoffs: cutoffs,
        collegeQuery: '',
        courseQuery: '',
        state: 'Karnataka',
      );
      expect(filtered.single.id, '2');

      final obc = filterCutoffs(
        cutoffs: cutoffs,
        collegeQuery: '',
        courseQuery: '',
        category: 'OBC',
      );
      expect(obc.single.category, 'OBC');
    });

    test('sorts by year descending then college name', () {
      final items = [
        _cutoff(id: 'a', cutoffRank: 1000, year: 2024),
        _cutoff(id: 'b', cutoffRank: 2000, year: 2025),
      ];
      final filtered = filterCutoffs(
        cutoffs: items,
        collegeQuery: '',
        courseQuery: '',
      );
      expect(filtered.first.year, 2025);
    });
  });

  group('predictAdmission rank path', () {
    test('high chance when rank significantly better than cutoff', () {
      final results = predictAdmission(
        cutoffs: [_cutoff(id: '1', cutoffRank: 10000)],
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 5000,
        category: 'General',
      );
      expect(results.single.chance, AdmissionConstants.chanceHigh);
      expect(results.single.explanation, contains('significantly better'));
    });

    test('medium chance when rank equals cutoff', () {
      final results = predictAdmission(
        cutoffs: [_cutoff(id: '1', cutoffRank: 8000)],
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 8000,
        category: 'General',
      );
      expect(results.single.chance, AdmissionConstants.chanceMedium);
    });

    test('low chance when rank worse than cutoff', () {
      final results = predictAdmission(
        cutoffs: [_cutoff(id: '1', cutoffRank: 5000)],
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 9000,
        category: 'General',
      );
      expect(results.single.chance, AdmissionConstants.chanceLow);
    });
  });

  group('predictAdmission percentile path', () {
    test('high/medium/low percentile chances', () {
      final cutoffs = [_cutoff(id: '1', cutoffPercentile: 90.0)];

      final high = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypePercentile,
        percentile: 95.0,
        category: 'General',
      );
      expect(high.single.chance, AdmissionConstants.chanceHigh);

      final medium = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypePercentile,
        percentile: 90.0,
        category: 'General',
      );
      expect(medium.single.chance, AdmissionConstants.chanceMedium);

      final low = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypePercentile,
        percentile: 85.0,
        category: 'General',
      );
      expect(low.single.chance, AdmissionConstants.chanceLow);
    });
  });

  group('predictAdmission marks path', () {
    test('high/medium/low marks chances', () {
      final cutoffs = [_cutoff(id: '1', cutoffMarks: 180.0)];

      final high = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypeMarks,
        marks: 195.0,
        category: 'General',
      );
      expect(high.single.chance, AdmissionConstants.chanceHigh);

      final medium = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypeMarks,
        marks: 180.0,
        category: 'General',
      );
      expect(medium.single.chance, AdmissionConstants.chanceMedium);

      final low = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypeMarks,
        marks: 170.0,
        category: 'General',
      );
      expect(low.single.chance, AdmissionConstants.chanceLow);
    });
  });

  group('predictAdmission filtering', () {
    test('skips cutoffs with missing score data', () {
      final results = predictAdmission(
        cutoffs: [_cutoff(id: '1')],
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 1000,
        category: 'General',
      );
      expect(results, isEmpty);
    });

    test('filters by category and gender', () {
      final cutoffs = [
        _cutoff(id: '1', cutoffRank: 5000, category: 'General'),
        _cutoff(id: '2', cutoffRank: 8000, category: 'OBC', gender: 'Female'),
      ];
      final results = predictAdmission(
        cutoffs: cutoffs,
        scoreType: AdmissionConstants.scoreTypeRank,
        rank: 4000,
        category: 'OBC',
        gender: 'Female',
      );
      expect(results.length, 1);
      expect(results.first.collegeName, contains('2'));
    });
  });
}
