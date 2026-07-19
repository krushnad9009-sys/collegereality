/// Verified-student review rating dimensions (13 categories).
class RatingParameters {
  RatingParameters._();

  static const String overall = 'overall';
  static const String teaching = 'teaching';
  static const String placements = 'placements';
  static const String hostel = 'hostel';
  static const String campus = 'campus';
  static const String faculty = 'faculty';
  static const String labs = 'labs';
  static const String sports = 'sports';
  static const String attendance = 'attendance';
  static const String safety = 'safety';
  static const String food = 'food';
  static const String infrastructure = 'infrastructure';
  static const String feesValue = 'feesValue';

  /// Legacy key kept for reading older reviews.
  static const String library = 'library';

  static const List<RatingCategory> categories = [
    RatingCategory(
      id: 'overall',
      label: 'Overall',
      parameters: [
        RatingParam(key: overall, label: 'Overall Rating'),
      ],
    ),
    RatingCategory(
      id: 'academics',
      label: 'Academics',
      parameters: [
        RatingParam(key: teaching, label: 'Teaching'),
        RatingParam(key: faculty, label: 'Faculty'),
        RatingParam(key: labs, label: 'Labs'),
        RatingParam(key: attendance, label: 'Attendance'),
      ],
    ),
    RatingCategory(
      id: 'campus',
      label: 'Campus Life',
      parameters: [
        RatingParam(key: campus, label: 'Campus'),
        RatingParam(key: infrastructure, label: 'Infrastructure'),
        RatingParam(key: sports, label: 'Sports'),
        RatingParam(key: food, label: 'Food'),
        RatingParam(key: hostel, label: 'Hostel'),
        RatingParam(key: safety, label: 'Safety'),
      ],
    ),
    RatingCategory(
      id: 'career',
      label: 'Career & Value',
      parameters: [
        RatingParam(key: placements, label: 'Placements'),
        RatingParam(key: feesValue, label: 'Fees Value'),
      ],
    ),
  ];

  static List<String> get allKeys =>
      categories.expand((c) => c.parameters.map((p) => p.key)).toList();

  static Map<String, double> emptyRatings() {
    return {for (final key in allKeys) key: 0.0};
  }

  static String labelFor(String key) {
    if (key == library) return 'Library';
    for (final category in categories) {
      for (final param in category.parameters) {
        if (param.key == key) return param.label;
      }
    }
    return key;
  }
}

class RatingCategory {
  final String id;
  final String label;
  final List<RatingParam> parameters;

  const RatingCategory({
    required this.id,
    required this.label,
    required this.parameters,
  });
}

class RatingParam {
  final String key;
  final String label;

  const RatingParam({required this.key, required this.label});
}
