class PlacementConstants {
  PlacementConstants._();

  static const String statusPending = 'pending_review';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  static const String typeFullTime = 'full_time';
  static const String typeInternship = 'internship';

  static const int maxOfferLetterBytes = 10 * 1024 * 1024;
  static const int minCompanyNameLength = 2;
  static const int minRoleLength = 2;
  static const double minPackageLpa = 0.1;
  static const double maxPackageLpa = 200.0;

  static const List<String> employmentTypes = [typeFullTime, typeInternship];

  static const List<String> allowedOfferExtensions = [
    'jpg',
    'jpeg',
    'png',
    'pdf',
  ];
}
