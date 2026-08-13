import 'dart:typed_data';
import 'dart:ui' as ui;

/// Optimized image bytes plus the MIME type they were actually encoded as.
/// `optimizeForUpload` sometimes returns the original bytes unchanged and
/// sometimes returns freshly re-encoded PNG bytes, so callers can never
/// safely assume a format from the source filename alone — they must use
/// [contentType] when setting Storage metadata, or images can end up
/// served with a Content-Type that doesn't match their actual bytes.
class OptimizedImage {
  const OptimizedImage(this.bytes, this.contentType);

  final Uint8List bytes;
  final String contentType;
}

/// Client-side image optimization before Firebase Storage upload.
class ImageOptimizationUtils {
  ImageOptimizationUtils._();

  static const int maxUploadBytes = 2 * 1024 * 1024;
  static const int maxEdgePx = 1600;

  /// Downscales large images and rejects payloads above [maxUploadBytes].
  static Future<OptimizedImage> optimizeForUpload(Uint8List bytes) async {
    if (bytes.length <= maxUploadBytes) {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final longest = image.width > image.height ? image.width : image.height;
      if (longest <= maxEdgePx) {
        return OptimizedImage(bytes, _sniffContentType(bytes));
      }
      return OptimizedImage(await _resize(image, maxEdgePx), 'image/png');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return OptimizedImage(await _resize(frame.image, maxEdgePx), 'image/png');
  }

  /// Detects the real format of passthrough (unmodified) bytes from their
  /// magic number, since the caller-supplied file extension isn't reliable.
  static String _sniffContentType(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  static Future<Uint8List> _resize(ui.Image image, int maxEdge) async {
    final width = image.width;
    final height = image.height;
    final longest = width > height ? width : height;
    if (longest <= maxEdge) {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    }

    final scale = maxEdge / longest;
    final targetW = (width * scale).round();
    final targetH = (height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble()),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final resized = await picture.toImage(targetW, targetH);
    final data = await resized.toByteData(format: ui.ImageByteFormat.png);
    final optimized = data!.buffer.asUint8List();
    if (optimized.length > maxUploadBytes) {
      throw StateError(
        'Image is still too large after compression (${optimized.length} bytes). '
        'Choose a smaller photo.',
      );
    }
    return optimized;
  }
}
