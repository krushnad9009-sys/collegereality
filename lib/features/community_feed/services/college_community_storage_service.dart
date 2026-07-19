import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads images attached to college community feed posts.
class CollegeCommunityStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPostImage({
    required String collegeId,
    required String userId,
    required String postId,
    required String extension,
    required Uint8List bytes,
  }) async {
    final path =
        'college_community/$collegeId/$userId/${postId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentType(extension),
        customMetadata: {'collegeId': collegeId, 'userId': userId},
      ),
    );
    return ref.getDownloadURL();
  }

  String _contentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
