import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/image_optimization_utils.dart';

class ProfileStorageService {
  ProfileStorageService({FirebaseStorage? storage}) : _storageOverride = storage;

  final FirebaseStorage? _storageOverride;

  /// Lazily resolves storage so profile screens can build in widget tests
  /// without initializing Firebase.
  FirebaseStorage get _storage =>
      _storageOverride ?? FirebaseStorage.instance;

  Future<String> uploadProfilePhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final optimized = await ImageOptimizationUtils.optimizeForUpload(bytes);
    final path = 'profile_images/$userId/avatar.${_extensionFor(optimized.contentType, extension)}';
    final ref = _storage.ref().child(path);
    await ref.putData(
      optimized.bytes,
      SettableMetadata(contentType: optimized.contentType),
    );
    return ref.getDownloadURL();
  }

  Future<String> uploadCoverPhoto({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final optimized = await ImageOptimizationUtils.optimizeForUpload(bytes);
    final path = 'profile_images/$userId/cover.${_extensionFor(optimized.contentType, extension)}';
    final ref = _storage.ref().child(path);
    await ref.putData(
      optimized.bytes,
      SettableMetadata(contentType: optimized.contentType),
    );
    return ref.getDownloadURL();
  }

  // The path extension is cosmetic (Storage serves by contentType, not by
  // path), but keep it truthful to the actual bytes rather than whatever
  // the source file happened to be named.
  String _extensionFor(String contentType, String fallback) {
    switch (contentType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/jpeg':
        return 'jpg';
      default:
        return fallback;
    }
  }
}
