import 'package:college_reality_india/core/constants/admission_constants.dart';
import 'package:college_reality_india/features/admission/models/admission_prediction_model.dart';
import 'package:college_reality_india/features/admission/models/cutoff_record_model.dart';
import 'package:college_reality_india/features/admission/models/entrance_exam_model.dart';
import 'package:college_reality_india/features/admission/models/scholarship_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 1, 20);
  final deadline = DateTime(2026, 8, 31);

  group('ScholarshipModel JSON', () {
    test('round-trip preserves eligibility and documents', () {
      final original = ScholarshipModel(
        id: 'sch-1',
        name: 'Merit Scholarship',
        nameLower: 'merit scholarship',
        providerType: AdmissionConstants.providerStateGovt,
        state: 'Maharashtra',
        courses: const ['Engineering', 'Medical'],
        categories: const ['General', 'OBC'],
        maxIncomeLpa: 8.0,
        amount: 'INR 75,000',
        eligibility: 'Above 85% in 12th',
        requiredDocuments: const ['Income certificate', 'Marksheet'],
        lastDate: deadline,
        officialWebsite: 'https://maharashtra.gov.in/scholarship',
        searchText: 'merit maharashtra',
        createdAt: now,
        updatedAt: now,
      );
      final restored = ScholarshipModel.fromJson(original.toJson(), docId: 'sch-1');
      expect(restored.name, original.name);
      expect(restored.courses, original.courses);
      expect(restored.maxIncomeLpa, 8.0);
      expect(restored.lastDate, deadline);
      expect(restored.providerLabel, 'State Government');
      expect(restored.isExpired, isFalse);
    });

    test('providerLabel maps central government', () {
      final scholarship = ScholarshipModel(
        id: '1',
        name: 'NSP',
        nameLower: 'nsp',
        providerType: AdmissionConstants.providerCentralGovt,
        amount: '50000',
        createdAt: now,
        updatedAt: now,
      );
      expect(scholarship.providerLabel, 'Central Government');
    });
  });

  group('CutoffRecordModel JSON', () {
    test('round-trip preserves rank percentile and marks', () {
      final original = CutoffRecordModel(
        id: 'cut-1',
        collegeId: 'col-1',
        collegeName: 'COEP',
        course: 'B.Tech',
        branch: 'CSE',
        examId: 'jee-main',
        examName: 'JEE Main',
        year: 2025,
        round: 'Round 2',
        category: 'OBC',
        gender: 'Female',
        university: 'SPPU',
        state: 'Maharashtra',
        cutoffRank: 4500,
        cutoffPercentile: 98.5,
        cutoffMarks: 185.0,
        scoreType: AdmissionConstants.scoreTypeRank,
        updatedAt: now,
      );
      final restored = CutoffRecordModel.fromJson(original.toJson());
      expect(restored.cutoffRank, 4500);
      expect(restored.cutoffPercentile, 98.5);
      expect(restored.category, 'OBC');
      expect(restored.gender, 'Female');
    });
  });

  group('EntranceExamModel JSON', () {
    test('round-trip preserves important dates', () {
      final examDate = DateTime(2026, 4, 15);
      final original = EntranceExamModel(
        id: 'exam-jee',
        name: 'JEE Main',
        slug: 'jee-main',
        category: 'Engineering',
        conductingBody: 'NTA',
        eligibility: '12th PCM',
        examPattern: 'MCQ',
        syllabus: 'Physics Chemistry Maths',
        importantDates: [
          ExamImportantDate(label: 'Registration closes', date: examDate),
        ],
        officialWebsite: 'https://jeemain.nta.nic.in',
        searchText: 'jee main engineering',
        scoreType: AdmissionConstants.scoreTypeRank,
        createdAt: now,
        updatedAt: now,
      );
      final restored = EntranceExamModel.fromJson(original.toJson());
      expect(restored.importantDates.single.label, 'Registration closes');
      expect(restored.importantDates.single.date, examDate);
      expect(restored.conductingBody, 'NTA');
    });

    test('ExamImportantDate round-trip', () {
      final date = DateTime(2026, 5, 1);
      final original = ExamImportantDate(label: 'Exam day', date: date);
      final restored = ExamImportantDate.fromJson(original.toJson());
      expect(restored.date, date);
    });
  });

  group('AdmissionPredictionModel JSON', () {
    test('round-trip preserves results list', () {
      final original = AdmissionPredictionModel(
        id: 'pred-1',
        userId: 'user-1',
        examId: 'jee-main',
        examName: 'JEE Main',
        rank: 8000,
        scoreType: AdmissionConstants.scoreTypeRank,
        category: 'General',
        gender: 'All',
        state: 'Maharashtra',
        homeUniversity: 'SPPU',
        results: const [
          PredictionResultModel(
            collegeId: 'col-1',
            collegeName: 'COEP',
            course: 'B.Tech',
            branch: 'CSE',
            chance: AdmissionConstants.chanceMedium,
            explanation: 'Close to cutoff',
            cutoffRank: 8500,
          ),
        ],
        label: 'My JEE prediction',
        createdAt: now,
      );
      final restored = AdmissionPredictionModel.fromJson(original.toJson(), docId: 'pred-1');
      expect(restored.rank, 8000);
      expect(restored.results.single.collegeName, 'COEP');
      expect(restored.label, 'My JEE prediction');
    });

    test('PredictionResultModel round-trip with percentile', () {
      const original = PredictionResultModel(
        collegeId: 'col-2',
        collegeName: 'VIT',
        course: 'B.Tech',
        chance: AdmissionConstants.chanceHigh,
        explanation: 'Strong chance',
        cutoffPercentile: 90.0,
      );
      final restored = PredictionResultModel.fromJson(original.toJson());
      expect(restored.cutoffPercentile, 90.0);
      expect(restored.chance, AdmissionConstants.chanceHigh);
    });
  });
}
