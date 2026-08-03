/// Production college directory constants — filter metadata without loading 40k docs.
class CollegeConstants {
  CollegeConstants._();

  static const int searchPageSize = 24;
  static const int autocompleteLimit = 15;
  static const int featuredLimit = 12;
  static const int adminPageSize = 30;
  static const int minSearchChars = 1;
  static const int instantSuggestLimit = 12;

  static const String metaDirectoryDoc = 'collegeDirectory';

  static const List<String> collegeTypes = [
    'government',
    'private',
    'deemed',
    'autonomous',
  ];

  /// Must stay in sync with browse/home category chips and seed categories.
  static const List<String> collegeCategories = [
    'Engineering',
    'Medical',
    'MBA',
    'Law',
    'Pharmacy',
    'Arts',
    'Commerce',
    'Science',
    'General',
    'Polytechnic',
    'Nursing',
    'Agriculture',
    'Architecture',
    'Fashion',
  ];

  static const List<String> naacGrades = [
    'A++',
    'A+',
    'A',
    'B++',
    'B+',
    'B',
    'C',
    'Not Accredited',
  ];

  static const List<String> popularCourses = [
    'B.Tech',
    'B.E.',
    'BBA',
    'BCA',
    'B.Com',
    'B.Sc',
    'B.Sc Nursing',
    'GNM',
    'ANM',
    'MBA',
    'M.Tech',
    'MBBS',
    'B.Pharm',
    'BA',
    'B.Arch',
    'LLB',
    'BDS',
    'MCA',
  ];

  /// Indian states & UTs for filters (no full-college scan required).
  static const List<String> indianStates = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  /// Case-insensitive dedupe preserving first-seen casing.
  static List<String> dedupePreserveOrder(Iterable<String> values) {
    final seen = <String>{};
    final out = <String>[];
    for (final value in values) {
      final key = value.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(value.trim());
    }
    return out;
  }

  /// Returns [value] only when it exists in [allowed] (case-sensitive match).
  static String? clampToAllowed(String? value, Iterable<String> allowed) {
    if (value == null || value.isEmpty) return null;
    for (final item in allowed) {
      if (item == value) return value;
    }
    return null;
  }
}