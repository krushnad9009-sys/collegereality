import 'package:flutter/material.dart';

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

  /// Returns a valid Firestore/remote URL or a known featured fallback.
  static String? resolveCoverUrl(String? coverPhotoUrl, {String? collegeId}) {
    if (isValidUrl(coverPhotoUrl)) return coverPhotoUrl!.trim();
    if (collegeId != null) {
      final fallback = _featuredCoverUrls[collegeId];
      if (isValidUrl(fallback)) return fallback;
    }
    return null;
  }

  static String? resolveLogoUrl(String? logoUrl, {String? collegeId}) {
    if (isValidUrl(logoUrl)) return logoUrl!.trim();
    if (collegeId != null) {
      final cover = _featuredCoverUrls[collegeId];
      if (isValidUrl(cover)) return cover;
    }
    return null;
  }

  static Color logoColor(String collegeId) {
    final hash = collegeId.codeUnits.fold<int>(0, (a, b) => a + b) % 8;
    const palette = [
      Color(0xFF1E3A5F),
      Color(0xFF2D6A4F),
      Color(0xFF5C4D7D),
      Color(0xFFB5651D),
      Color(0xFF006D77),
      Color(0xFF7B2D26),
      Color(0xFF3D5A80),
      Color(0xFF6A4C93),
    ];
    return palette[hash];
  }

  static List<Color> coverGradient(String collegeId) {
    final base = logoColor(collegeId);
    return [
      base,
      Color.lerp(base, Colors.white, 0.25) ?? base,
    ];
  }
}
