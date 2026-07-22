import 'dart:typed_data';
import 'dart:ui' as ui;

/// Client-side image optimization before Firebase Storage upload.
class ImageOptimizationUtils {
  ImageOptimizationUtils._();

  static const int maxUploadBytes = 2 * 1024 * 1024;
  static const int maxEdgePx = 1600;
  static const int jpegQuality = 82;

  /// Downscales large images and rejects payloads above [maxUploadBytes].
  static Future<Uint8List> optimizeForUpload(Uint8List bytes) async {
    if (bytes.length <= maxUploadBytes) {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final longest = image.width > image.height ? image.width : image.height;
      if (longest <= maxEdgePx) return bytes;
      return _resize(image, maxEdgePx);
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return _resize(frame.image, maxEdgePx);
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
