import 'package:flutter/material.dart';

/// Google "G" logo drawn without an external asset.
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({this.size = 20, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blue arc
    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84),
      -0.4,
      2.2,
      false,
      blue,
    );

    // Green arc
    final green = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84),
      1.8,
      1.0,
      false,
      green,
    );

    // Yellow arc
    final yellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84),
      2.8,
      1.0,
      false,
      yellow,
    );

    // Red arc
    final red = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.84, h * 0.84),
      3.8,
      1.4,
      false,
      red,
    );

    // Blue bar (G crossbar)
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.44, w * 0.38, h * 0.14),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
