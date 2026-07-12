import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class ReviewStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadPhoto({
    required String userId,
    required String reviewId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'review_media/$userId/$reviewId/photo_$timestamp.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
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
