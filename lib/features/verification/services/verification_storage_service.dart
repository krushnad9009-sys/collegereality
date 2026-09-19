import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/verification_constants.dart';

class VerificationStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Object name (last path segment) for an uploaded document.
  ///
  /// The path must stay `verification_documents/{uid}/{one segment}` -- that
  /// is the only shape storage.rules allows and the review Cloud Function
  /// accepts. When [documentType] and [fileName] are given the name reads
  /// `{documentType}_{requestId}_{safeFileName}.{ext}`: recognisable to an
  /// admin, and the request id means a re-upload never overwrites the
  /// evidence of an earlier request. The user-supplied file name is reduced
  /// to `[A-Za-z0-9_-]` so it can never smuggle in `/` or `..`.
  static String objectName({
    required String requestId,
    required String extension,
    int? slot,
    String? documentType,
    String? fileName,
  }) {
    // `slot` disambiguates multiple files in one request (the 2-document
    // "Student Verification" flow); a null slot keeps the legacy
    // single-file path shape.
    if (slot != null) return '$requestId-$slot.$extension';
    if (documentType == null || fileName == null) {
      return '$requestId.$extension';
    }
    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    var safe = base
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (safe.length > 40) safe = safe.substring(0, 40);
    if (safe.isEmpty) safe = 'document';
    return '${documentType}_${requestId}_$safe.$extension';
  }

  Future<String> uploadVerificationDocument({
    required String userId,
    required String requestId,
    required String extension,
    required Uint8List bytes,
    int? slot,
    String? documentType,
    String? fileName,
  }) async {
    final name = objectName(
      requestId: requestId,
      extension: extension,
      slot: slot,
      documentType: documentType,
      fileName: fileName,
    );
    final path = 'verification_documents/$userId/$name';
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
