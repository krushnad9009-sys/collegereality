import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class CollegeStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadLogo({
    required String collegeId,
    required Uint8List bytes,
    required String extension,
  }) async {
    return _upload(
      path: 'college_media/$collegeId/logo.$extension',
      bytes: bytes,
    );
  }

  Future<String> uploadCover({
    required String collegeId,
    required Uint8List bytes,
    required String extension,
  }) async {
    return _upload(
      path: 'college_media/$collegeId/cover.$extension',
      bytes: bytes,
    );
  }

  Future<String> uploadGalleryPhoto({
    required String collegeId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _upload(
      path: 'college_media/$collegeId/gallery/$timestamp.$extension',
      bytes: bytes,
    );
  }

  Future<String> uploadCollegeRequestPhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _upload(
      path: 'college_requests/$userId/$timestamp.$extension',
      bytes: bytes,
    );
  }

  Future<String> _upload({
    required String path,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}
