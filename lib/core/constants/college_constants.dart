/// Production college directory constants — filter metadata without loading 40k docs.
class CollegeConstants {
  CollegeConstants._();

  static const int searchPageSize = 24;
  static const int autocompleteLimit = 15;
  static const int featuredLimit = 12;
  static const int adminPageSize = 30;
  static const int minSearchChars = 2;

  static const String metaDirectoryDoc = 'collegeDirectory';

  static const List<String> collegeTypes = [
    'government',
    'private',
    'deemed',
    'autonomous',
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
}
