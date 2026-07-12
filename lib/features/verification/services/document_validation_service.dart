import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../../core/constants/verification_constants.dart';
import '../models/verification_request_model.dart';

class DocumentValidationService {
  /// AI-style document validation using content analysis heuristics.
  Future<DocumentValidationResult> validate({
    required Uint8List bytes,
    required String fileName,
    required String documentType,
    required Future<bool> Function(String hash) isDuplicateHash,
  }) async {
    final flags = <String>[];
    var confidence = 1.0;

    if (bytes.length < VerificationConstants.minFileBytes) {
      flags.add(VerificationConstants.flagLowQuality);
      confidence -= 0.35;
    }
    if (bytes.length > VerificationConstants.maxFileBytes) {
      flags.add(VerificationConstants.flagInvalidFormat);
      confidence -= 0.5;
    }

    final ext = fileName.split('.').last.toLowerCase();
    if (!VerificationConstants.allowedExtensions.contains(ext)) {
      flags.add(VerificationConstants.flagInvalidFormat);
      confidence -= 0.4;
    }

    final hash = sha256.convert(bytes).toString();
    final isDuplicate = await isDuplicateHash(hash);
    if (isDuplicate) {
      flags.add(VerificationConstants.flagDuplicate);
      confidence -= 0.6;
    }

    if (_looksManipulated(bytes, fileName)) {
      flags.add(VerificationConstants.flagManipulated);
      confidence -= 0.45;
    }

    if (_looksSuspicious(fileName, documentType, bytes)) {
      flags.add(VerificationConstants.flagSuspicious);
      confidence -= 0.35;
    }

    confidence = confidence.clamp(0.0, 1.0);
    final requiresManualReview =
        flags.isNotEmpty || confidence < VerificationConstants.autoApproveConfidence;

    final summary = _buildSummary(flags, confidence, isDuplicate);

    return DocumentValidationResult(
      confidence: confidence,
      flags: flags,
      summary: summary,
      requiresManualReview: requiresManualReview,
      isDuplicate: isDuplicate,
    );
  }

  String computeHash(Uint8List bytes) => sha256.convert(bytes).toString();

  bool _looksManipulated(Uint8List bytes, String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.contains('edited') ||
        lower.contains('photoshop') ||
        lower.contains('fake') ||
        lower.contains('template')) {
      return true;
    }

    // Low byte entropy can indicate flat/generated images.
    final entropy = _byteEntropy(bytes);
    if (entropy < 3.2 && bytes.length > 20 * 1024) {
      return true;
    }

    // Repeated byte blocks may indicate copy-paste manipulation.
    if (_hasRepeatedBlocks(bytes)) {
      return true;
    }

    return false;
  }

  bool _looksSuspicious(String fileName, String documentType, Uint8List bytes) {
    final lower = fileName.toLowerCase();
    if (lower.contains('screenshot') || lower.contains('screen_shot')) {
      return true;
    }
    if (lower.contains('sample') || lower.contains('demo')) {
      return true;
    }

    // Alumni doc should be larger than a tiny thumbnail.
    if (documentType == VerificationConstants.documentFinalMarksheet &&
        bytes.length < 30 * 1024) {
      return true;
    }

    return false;
  }

  double _byteEntropy(Uint8List bytes) {
    if (bytes.isEmpty) return 0;
    final sampleSize = min(bytes.length, 8192);
    final freq = List<int>.filled(256, 0);
    for (var i = 0; i < sampleSize; i++) {
      freq[bytes[i]]++;
    }
    var entropy = 0.0;
    for (final count in freq) {
      if (count == 0) continue;
      final p = count / sampleSize;
      entropy -= p * (log(p) / ln2);
    }
    return entropy;
  }

  bool _hasRepeatedBlocks(Uint8List bytes) {
    if (bytes.length < 4096) return false;
    final block = bytes.sublist(0, 64);
    var matches = 0;
    for (var i = 64; i < min(bytes.length, 4096); i += 64) {
      final slice = bytes.sublist(i, min(i + 64, bytes.length));
      if (slice.length == block.length && _listEquals(slice, block)) {
        matches++;
      }
    }
    return matches >= 3;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _buildSummary(List<String> flags, double confidence, bool duplicate) {
    if (duplicate) {
      return 'Duplicate document detected. Flagged for manual admin review.';
    }
    if (flags.isEmpty && confidence >= VerificationConstants.autoApproveConfidence) {
      return 'Document passed automated validation checks.';
    }
    if (flags.contains(VerificationConstants.flagManipulated)) {
      return 'Possible editing or manipulation detected. Admin review required.';
    }
    if (flags.contains(VerificationConstants.flagSuspicious)) {
      return 'Document appears suspicious. Admin review required.';
    }
    return 'Document submitted for secure manual verification.';
  }
}
