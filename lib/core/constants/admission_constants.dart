class AdmissionConstants {
  AdmissionConstants._();

  static const String providerCentralGovt = 'central_government';
  static const String providerStateGovt = 'state_government';
  static const String providerPrivate = 'private';

  static const List<String> providerTypes = [
    providerCentralGovt,
    providerStateGovt,
    providerPrivate,
  ];

  static const List<String> scholarshipCategories = [
    'General',
    'OBC',
    'SC',
    'ST',
    'EWS',
    'Minority',
    'Girl Child',
    'PWD',
    'Merit',
    'Need-based',
  ];

  static const List<String> examSlugs = [
    'jee',
    'neet',
    'mht_cet',
    'cuet',
    'gate',
    'cat',
    'xat',
    'clat',
    'nata',
    'polytechnic',
    'diploma',
  ];

  static const List<String> reservationCategories = [
    'General',
    'OBC',
    'SC',
    'ST',
    'EWS',
    'PWD',
  ];

  static const List<String> genders = ['All', 'Male', 'Female', 'Other'];

  static const List<String> cutoffRounds = [
    'Round 1',
    'Round 2',
    'Round 3',
    'Round 4',
    'Spot Round',
  ];

  static const String scoreTypeRank = 'rank';
  static const String scoreTypePercentile = 'percentile';
  static const String scoreTypeMarks = 'marks';

  static const String chanceHigh = 'high';
  static const String chanceMedium = 'medium';
  static const String chanceLow = 'low';

  static const String metaAdmissionSeededDoc = 'admissionSeeded';
}
