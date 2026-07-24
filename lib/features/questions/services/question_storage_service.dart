import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/utils/image_optimization_utils.dart';

class QuestionStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage({
    required String userId,
    required String questionId,
    required Uint8List bytes,
    required String extension,
    String subPath = 'questions',
  }) async {
    final optimized = await ImageOptimizationUtils.optimizeForUpload(bytes);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'qa_media/$subPath/$userId/$questionId/img_$timestamp.$extension';
    final ref = _storage.ref().child(path);
    await ref.putData(optimized);
    return ref.getDownloadURL();
  }
}
