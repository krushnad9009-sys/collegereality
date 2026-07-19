/// Yes/No survey questions for verified student & alumni reviews.
class ReviewYesNoQuestions {
  ReviewYesNoQuestions._();

  static const String wouldRecommend = 'wouldRecommend';
  static const String raggingPresent = 'raggingPresent';
  static const String placementsAsPromised = 'placementsAsPromised';
  static const String facultySupportive = 'facultySupportive';
  static const String hostelWorthIt = 'hostelWorthIt';
  static const String wouldTakeAdmissionAgain = 'wouldTakeAdmissionAgain';

  static const List<ReviewYesNoQuestion> questions = [
    ReviewYesNoQuestion(
      key: wouldRecommend,
      label: 'Would you recommend this college?',
    ),
    ReviewYesNoQuestion(
      key: raggingPresent,
      label: 'Is ragging present?',
    ),
    ReviewYesNoQuestion(
      key: placementsAsPromised,
      label: 'Are placements as promised?',
    ),
    ReviewYesNoQuestion(
      key: facultySupportive,
      label: 'Are faculty supportive?',
    ),
    ReviewYesNoQuestion(
      key: hostelWorthIt,
      label: 'Is hostel worth it?',
    ),
    ReviewYesNoQuestion(
      key: wouldTakeAdmissionAgain,
      label: 'Would you take admission here again?',
    ),
  ];

  static Map<String, bool?> emptyAnswers() {
    return {for (final q in questions) q.key: null};
  }
}

class ReviewYesNoQuestion {
  final String key;
  final String label;

  const ReviewYesNoQuestion({required this.key, required this.label});
}
