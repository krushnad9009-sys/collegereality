import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/verification_constants.dart';

class VerificationStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadVerificationDocument({
    required String userId,
    required String requestId,
    required String extension,
    required Uint8List bytes,
  }) async {
    final path = 'verification_documents/$userId/$requestId.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        customMetadata: {
          'ownerId': userId,
          'requestId': requestId,
        },
      ),
    );
    return path;
  }

  Future<Uint8List?> downloadDocument(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return ref.getData(VerificationConstants.maxFileBytes);
  }

  String _contentTypeForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
