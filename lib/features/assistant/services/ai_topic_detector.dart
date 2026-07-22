import '../../../core/constants/ranking_constants.dart';
import '../models/ai_topic.dart';

/// Detects college topics, exam scores, and rejects off-topic queries.
class AiTopicDetector {
  static const _nonCollegePatterns = [
    'weather',
    'recipe',
    'movie',
    'cricket score',
    'bitcoin',
    'stock market',
    'python',
    'python code',
    'javascript',
    'write an essay',
    'homework help',
    'translate this',
    'who is the president',
    'prime minister',
    'tell me a joke',
    'write a poem',
    'dating',
    'relationship advice',
  ];

  static const _collegeSignals = [
    'college',
    'university',
    'institute',
    'campus',
    'placement',
    'hostel',
    'fees',
    'admission',
    'cutoff',
    'rank',
    'percentile',
    'jee',
    'neet',
    'cet',
    'mht',
    'cse',
    'engineering',
    'mba',
    'b.tech',
    'btech',
    'review',
    'naac',
    'nirf',
    'compare',
    'ragging',
    'package',
    'lpa',
    'faculty',
    'course',
    'branch',
    'कॉलेज',
    'विद्यालय',
    'प्रवेश',
    'महाविद्यालय',
  ];

  bool isCollegeRelated(String query, {bool hasCollegeContext = false}) {
    if (hasCollegeContext) return true;
    final q = query.toLowerCase().trim();
    if (q.length < 3) return false;
    if (_nonCollegePatterns.any((p) => q.contains(p))) {
      return _collegeSignals.any((s) => q.contains(s));
    }
    return _collegeSignals.any((s) => q.contains(s));
  }

  AiTopic detectTopic(String query) {
    final q = query.toLowerCase();
    if (_matchesExamScore(q)) return AiTopic.examScore;
    if (_containsAny(q, ['compare', ' vs ', 'versus', 'better than', 'which is better'])) {
      return AiTopic.general;
    }
    if (_containsAny(q, ['cse', 'computer science', 'computer engineering', 'it branch', 'coding'])) {
      return AiTopic.cse;
    }
    if (_containsAny(q, ['placement', 'placed', 'recruit', 'company visit', 'internship'])) {
      return AiTopic.placements;
    }
    if (_containsAny(q, ['hostel', 'hostel life', 'mess', 'room', 'accommodation'])) {
      return AiTopic.hostel;
    }
    if (_containsAny(q, ['package', 'lpa', 'salary', 'ctc', 'average package'])) {
      return AiTopic.package;
    }
    if (_containsAny(q, ['ragging', 'bullying', 'anti-ragging'])) {
      return AiTopic.ragging;
    }
    if (_containsAny(q, ['faculty', 'professor', 'teaching', 'professor'])) {
      return AiTopic.faculty;
    }
    if (_containsAny(q, ['fees', 'fee', 'tuition', 'cost', 'affordable'])) {
      return AiTopic.fees;
    }
    if (_containsAny(q, ['campus life', 'campus', 'fest', 'extra curricular'])) {
      return AiTopic.campusLife;
    }
    return AiTopic.general;
  }

  ({String examType, int score})? extractExamScore(String query) {
    final q = query.toLowerCase().replaceAll(',', '');

    final jeeRank = RegExp(r'jee(?:\s*main|\s*advanced)?\s*(?:rank|score)?\s*(\d{1,7})')
        .firstMatch(q);
    if (jeeRank != null) {
      return (examType: RankingConstants.examJee, score: int.parse(jeeRank.group(1)!));
    }

    final neetRank =
        RegExp(r'neet(?:\s*ug)?\s*(?:rank|score)?\s*(\d{1,7})').firstMatch(q);
    if (neetRank != null) {
      return (examType: RankingConstants.examNeet, score: int.parse(neetRank.group(1)!));
    }

    final cetPercentile = RegExp(
      r'(?:cet|mht[\s-]?cet|percentile)\s*(\d{1,3}(?:\.\d+)?)',
    ).firstMatch(q);
    if (cetPercentile != null) {
      final value = double.parse(cetPercentile.group(1)!);
      return (examType: RankingConstants.examCet, score: value.round());
    }

    final scoreUnder = RegExp(
      r'under\s*(?:my\s*)?(cet|jee|neet)\s*(?:rank|score)?\s*(\d{1,7})',
    ).firstMatch(q);
    if (scoreUnder != null) {
      final exam = scoreUnder.group(1)!;
      final score = int.parse(scoreUnder.group(2)!);
      if (exam == 'jee') {
        return (examType: RankingConstants.examJee, score: score);
      }
      if (exam == 'neet') {
        return (examType: RankingConstants.examNeet, score: score);
      }
      return (examType: RankingConstants.examCet, score: score);
    }

    return null;
  }

  bool _matchesExamScore(String q) {
    return extractExamScore(q) != null ||
        q.contains('best colleges under') ||
        q.contains('colleges for my') ||
        q.contains('colleges with my');
  }

  bool _containsAny(String q, List<String> terms) {
    return terms.any((t) => q.contains(t));
  }

  String offTopicMessage() =>
      'I can only help with college-related questions using verified College Reality data '
      '(profiles, reviews, student answers, and community posts). '
      'Try asking about placements, hostel, fees, CSE, or comparing colleges.';
}
