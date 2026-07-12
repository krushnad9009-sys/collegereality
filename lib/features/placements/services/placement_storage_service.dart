import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/placement_constants.dart';

class PlacementStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadOfferLetter({
    required String userId,
    required String submissionId,
    required String extension,
    required Uint8List bytes,
  }) async {
    final path =
        'placement_documents/$userId/$submissionId.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentTypeForExtension(extension),
        customMetadata: {
          'ownerId': userId,
          'submissionId': submissionId,
        },
      ),
    );
    return path;
  }

  Future<Uint8List?> downloadOfferLetter(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return ref.getData(PlacementConstants.maxOfferLetterBytes);
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
