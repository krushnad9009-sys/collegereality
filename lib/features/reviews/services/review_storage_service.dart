import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/image_optimization_utils.dart';

class ReviewStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPhoto({
    required String userId,
    required String reviewId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final optimized = await ImageOptimizationUtils.optimizeForUpload(bytes);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'review_media/$userId/$reviewId/photo_$timestamp.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(optimized);
    return ref.getDownloadURL();
  }

  Future<String> uploadVideo({
    required String userId,
    required String reviewId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'review_media/$userId/$reviewId/video_$timestamp.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}
