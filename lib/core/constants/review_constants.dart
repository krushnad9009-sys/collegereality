class ReviewConstants {
  ReviewConstants._();

  static const int minTextLength = 20;
  static const int maxPhotos = 5;
  static const int maxVideos = 2;
  static const int maxPhotoBytes = 5 * 1024 * 1024;
  static const int maxVideoBytes = 25 * 1024 * 1024;
  static const int pageSize = 20;
  static const int editCooldownDays = 30;

  static const String reportStatusOpen = 'open';
  static const String reportStatusReviewed = 'reviewed';
  static const String reportStatusDismissed = 'dismissed';

  static const String helpfulSubcollection = 'helpful';
  static const String reviewReportsCollection = 'review_reports';
}
