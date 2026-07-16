/// Resolves college cover image URLs from Firestore.
class CollegeImageHelper {
  CollegeImageHelper._();

  static const Map<String, String> _featuredCoverUrls = {
    'iit_bombay':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/IIT_Bombay_Main_Building.jpg/1280px-IIT_Bombay_Main_Building.jpg',
    'iit_delhi':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Indian_Institute_of_Technology_Delhi_%28IIT_Delhi%29_campus.jpg/1280px-Indian_Institute_of_Technology_Delhi_%28IIT_Delhi%29_campus.jpg',
    'iit_madras':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/69/IIT_Madras_Hostel.jpg/1280px-IIT_Madras_Hostel.jpg',
    'nit_trichy':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4d/NIT_Trichy_Admin_Building.jpg/1280px-NIT_Trichy_Admin_Building.jpg',
    'iiit_hyderabad':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/IIIT_Hyderabad_campus.jpg/1280px-IIIT_Hyderabad_campus.jpg',
    'aiims_delhi':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0d/AIIMS_New_Delhi.jpg/1280px-AIIMS_New_Delhi.jpg',
    'national_rohtak_school_business':
        'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
    'vit_vellore':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7d/VIT_University_Campus.jpg/1280px-VIT_University_Campus.jpg',
    'coep_pune':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/COEP_Main_Building.jpg/1280px-COEP_Main_Building.jpg',
    'sppu_pune':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5d/Savitribai_Phule_Pune_University_main_building.jpg/1280px-Savitribai_Phule_Pune_University_main_building.jpg',
  };

  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Returns a valid Firestore/remote URL, a known featured fallback, or a
  /// deterministic campus photo for the college id.
  static String? resolveCoverUrl(String? coverPhotoUrl, {String? collegeId}) {
    if (isValidUrl(coverPhotoUrl)) return coverPhotoUrl!.trim();
    if (collegeId != null) {
      final fallback = _featuredCoverUrls[collegeId];
      if (isValidUrl(fallback)) return fallback;
      return _genericCampusPhoto(collegeId);
    }
    return null;
  }

  static String _genericCampusPhoto(String collegeId) {
    final hash = collegeId.codeUnits.fold<int>(0, (a, b) => a + b) % 6;
    const photos = [
      'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1541339907192-ebe66fcfbe8c?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1498243691581-b145c3f54a5a?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1607237138185-eedd9c632b0b?auto=format&fit=crop&w=1200&q=80',
      'https://images.unsplash.com/photo-1576495199011-eb94736d05d6?auto=format&fit=crop&w=1200&q=80',
    ];
    return photos[hash];
  }
}
