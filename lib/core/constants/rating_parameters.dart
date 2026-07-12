/// Core rating parameters for the 5-star review system (Phase 2).
class RatingParameters {
  RatingParameters._();

  static const String overall = 'overall';
  static const String faculty = 'faculty';
  static const String hostel = 'hostel';
  static const String placements = 'placements';
  static const String fees = 'fees';
  static const String infrastructure = 'infrastructure';
  static const String campusLife = 'campusLife';
  static const String facultyTeaching = 'facultyTeaching';
  static const String hostelFood = 'hostelFood';
  static const String hostelCleanliness = 'hostelCleanliness';

  static const List<RatingCategory> categories = [
    RatingCategory(
      id: 'academics',
      label: 'Academics & Faculty',
      parameters: [
        RatingParam(key: faculty, label: 'Faculty Quality'),
        RatingParam(key: facultyTeaching, label: 'Teaching Methodology'),
      ],
    ),
    RatingCategory(
      id: 'infrastructure',
      label: 'Infrastructure',
      parameters: [
        RatingParam(key: infrastructure, label: 'Infrastructure'),
        RatingParam(key: campusLife, label: 'Campus Life'),
      ],
    ),
    RatingCategory(
      id: 'hostel',
      label: 'Hostel & Food',
      parameters: [
        RatingParam(key: hostel, label: 'Hostel Quality'),
        RatingParam(key: hostelFood, label: 'Hostel Food'),
        RatingParam(key: hostelCleanliness, label: 'Hostel Cleanliness'),
      ],
    ),
    RatingCategory(
      id: 'career',
      label: 'Placements & Fees',
      parameters: [
        RatingParam(key: placements, label: 'Placements'),
        RatingParam(key: fees, label: 'Value for Money (Fees)'),
      ],
    ),
    RatingCategory(
      id: 'overall',
      label: 'Overall',
      parameters: [
        RatingParam(key: overall, label: 'Overall Experience'),
      ],
    ),
  ];

  static List<String> get allKeys =>
      categories.expand((c) => c.parameters.map((p) => p.key)).toList();

  static Map<String, double> emptyRatings() {
    return {for (final key in allKeys) key: 0.0};
  }

  static String labelFor(String key) {
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
