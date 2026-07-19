/// Yes/No survey questions for verified student & alumni reviews.
class ReviewYesNoQuestions {
  ReviewYesNoQuestions._();

  static const String raggingPresent = 'raggingPresent';
  static const String hiddenFees = 'hiddenFees';
  static const String wouldChooseAgain = 'wouldChooseAgain';
  static const String placementSupport = 'placementSupport';

  static const List<ReviewYesNoQuestion> questions = [
    ReviewYesNoQuestion(
      key: raggingPresent,
      label: 'Ragging?',
    ),
    ReviewYesNoQuestion(
      key: hiddenFees,
      label: 'Hidden fees?',
    ),
    ReviewYesNoQuestion(
      key: wouldChooseAgain,
      label: 'Would you choose this college again?',
    ),
    ReviewYesNoQuestion(
      key: placementSupport,
      label: 'Placement support?',
    ),
  ];

  /// Legacy question keys from earlier app versions.
  static const Map<String, String> legacyLabels = {
    'wouldRecommend': 'Would you recommend this college?',
    'placementsAsPromised': 'Are placements as promised?',
    'facultySupportive': 'Are faculty supportive?',
    'hostelWorthIt': 'Is hostel worth it?',
    'wouldTakeAdmissionAgain': 'Would you take admission here again?',
  };

  static String labelFor(String key) {
    for (final q in questions) {
      if (q.key == key) return q.label;
    }
    return legacyLabels[key] ?? key;
  }

  static Map<String, bool?> emptyAnswers() {
    return {for (final q in questions) q.key: null};
  }
}

class ReviewYesNoQuestion {
  final String key;
  final String label;

  const ReviewYesNoQuestion({required this.key, required this.label});
}
