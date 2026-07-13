import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class ResumeStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadResume({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final safeExt = extension.toLowerCase().replaceAll('.', '');
    final path = 'resumes/$userId/resume.$safeExt';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentType(safeExt)),
    );
    return ref.getDownloadURL();
  }

  Future<Uint8List?> downloadResume(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    final data = await ref.getData(5 * 1024 * 1024);
    return data;
  }

  String _contentType(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
