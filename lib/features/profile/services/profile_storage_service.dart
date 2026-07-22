import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/image_optimization_utils.dart';

class ProfileStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final optimized = await ImageOptimizationUtils.optimizeForUpload(bytes);
    final path = 'profile_images/$userId/avatar.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(
      optimized,
      SettableMetadata(contentType: _imageType(extension)),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadCoverPhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final optimized = await ImageOptimizationUtils.optimizeForUpload(bytes);
    final path = 'profile_images/$userId/cover.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(
      optimized,
      SettableMetadata(contentType: _imageType(extension)),
    );
    return ref.getDownloadURL();
  }

  String _imageType(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
