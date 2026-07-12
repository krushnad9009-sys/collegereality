/// Resolves a stable cover image URL for a college with placeholder fallback.
class CollegeImageHelper {  CollegeImageHelper._();

  static const String _placeholderAsset = 'assets/images/college_placeholder.png';

  static String getCoverImageUrl(String collegeId, {String? coverPhotoUrl}) {
    if (coverPhotoUrl != null &&
        coverPhotoUrl.isNotEmpty &&
        coverPhotoUrl != 'null') {
      return coverPhotoUrl;
    }
    final seed = collegeId.hashCode.abs();
    return 'https://picsum.photos/seed/college$seed/800/400';
  }

  static String get placeholderAsset => _placeholderAsset;
}
