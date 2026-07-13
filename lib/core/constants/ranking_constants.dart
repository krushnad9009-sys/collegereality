class RankingConstants {
  RankingConstants._();

  static const int defaultPageSize = 24;
  static const int compareRecommendationLimit = 5;
  static const int smartRecommendationLimit = 10;
  static const int analyticsTopLimit = 10;
  static const Duration rankingCacheTtl = Duration(minutes: 20);

  static const String rankScopeOverall = 'overall';
  static const String rankScopeState = 'state';
  static const String rankScopeDistrict = 'district';
  static const String rankScopeCourse = 'course';
  static const String rankScopeType = 'type';
  static const String rankScopeCategory = 'category';

  static const String examCet = 'cet';
  static const String examJee = 'jee';
  static const String examNeet = 'neet';

  static const List<String> reservationCategories = [
    'General',
    'OBC',
    'SC',
    'ST',
    'EWS',
  ];

  static const List<String> rankCategories = [
    'overall',
    'placements',
    'teaching',
    'infrastructure',
    'hostel',
    'fees',
    'campusLife',
  ];

  static String rankCategoryLabel(String key) {
    switch (key) {
      case 'overall':
        return 'Overall';
      case 'placements':
        return 'Placements';
      case 'teaching':
        return 'Teaching Quality';
      case 'infrastructure':
        return 'Infrastructure';
      case 'hostel':
        return 'Hostel';
      case 'fees':
        return 'Value for Money';
      case 'campusLife':
        return 'Campus Life';
      default:
        return key;
    }
  }
}
