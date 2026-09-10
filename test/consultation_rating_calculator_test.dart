import 'package:college_reality_india/features/consultations/utils/consultation_rating_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

/// One `consultation_ratings` doc as stored (see
/// ConsultationRatingModel.toJson): a top-level `overall` plus a nested
/// `criteria` map.
///
/// NOTE: the guide-facing aggregate (`recomputeConsultationStats`) moved
/// server-side — it is covered by
/// functions/test/consultationRatingLogic.test.js now. Only the on-demand
/// student summary stays client-side and is tested here.
Map<String, dynamic> _rating({
  required int overall,
  int communication = 5,
  int c2 = 5,
  int c3 = 5,
  int c4 = 5,
}) {
  return {
    'overall': overall,
    'criteria': {
      'communication': communication,
      'criterion2': c2,
      'criterion3': c3,
      'criterion4': c4,
    },
  };
}

void main() {
  group('StudentConsultationSummary.fromJson (denormalized summary doc)', () {
    test('null / missing doc -> zero summary', () {
      final s = StudentConsultationSummary.fromJson(null);
      expect(s.totalRatings, 0);
      expect(s.overallAvg, 0);
    });

    test('reads the stored student-facing keys', () {
      final s = StudentConsultationSummary.fromJson({
        'studentId': 'u1',
        'totalRatings': 3,
        'overallAvg': 4.33,
        'communicationAvg': 4.0,
        'respectfulAvg': 4.5,
        'seriousnessAvg': 3.75,
        'appropriateAvg': 5.0,
      });
      expect(s.totalRatings, 3);
      expect(s.overallAvg, 4.33);
      expect(s.respectfulAvg, 4.5);
      expect(s.appropriateAvg, 5.0);
    });
  });

  group('StudentConsultationSummary.fromRatings (guide -> student)', () {
    test('empty list is the zero summary', () {
      final s = StudentConsultationSummary.fromRatings(const []);
      expect(s.totalRatings, 0);
      expect(s.overallAvg, 0);
    });

    test('aggregates criteria under the student-facing labels', () {
      final s = StudentConsultationSummary.fromRatings([
        _rating(overall: 5, communication: 5, c2: 4, c3: 5, c4: 5),
        _rating(overall: 4, communication: 4, c2: 4, c3: 4, c4: 4),
      ]);
      expect(s.totalRatings, 2);
      expect(s.overallAvg, 4.5);
      expect(s.communicationAvg, 4.5);
      expect(s.respectfulAvg, 4.0); // criterion2
      expect(s.seriousnessAvg, 4.5); // criterion3
      expect(s.appropriateAvg, 4.5); // criterion4
    });

    test('rounds to 2 dp', () {
      final s = StudentConsultationSummary.fromRatings([
        _rating(overall: 5),
        _rating(overall: 4),
        _rating(overall: 4),
      ]);
      expect(s.overallAvg, 4.33);
    });

    test('missing criteria map counts as zeros, no crash', () {
      final s = StudentConsultationSummary.fromRatings([
        {'overall': 4},
      ]);
      expect(s.totalRatings, 1);
      expect(s.overallAvg, 4.0);
      expect(s.communicationAvg, 0.0);
    });
  });
}
