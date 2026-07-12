import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class CommunityStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadAttachment({
    required String conversationId,
    required String userId,
    required String messageId,
    required String extension,
    required Uint8List bytes,
  }) async {
    final path = 'community_media/$conversationId/$userId/$messageId.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentType(extension),
        customMetadata: {'conversationId': conversationId, 'userId': userId},
      ),
    );
    return await ref.getDownloadURL();
  }

  String _contentType(String ext) {
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
