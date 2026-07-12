/// Resolves college cover image URLs from Firestore.
class CollegeImageHelper {
  CollegeImageHelper._();

  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Returns a valid Firestore/remote URL, or null when no real image exists.
  static String? resolveCoverUrl(String? coverPhotoUrl) {
    if (isValidUrl(coverPhotoUrl)) return coverPhotoUrl!.trim();
    return null;
  }
}
