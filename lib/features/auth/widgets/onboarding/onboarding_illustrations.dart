import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'onboarding_palette.dart';

enum OnboardingScene { reviews, aiCompare, verifiedQA, confidentDecision }

/// Breathing, parallax-ready illustration canvas for each onboarding page.
class OnboardingAnimatedIllustration extends StatelessWidget {
  const OnboardingAnimatedIllustration({
    required this.scene,
    required this.animationValue,
    required this.pageOffset,
    this.size = 280,
    super.key,
  });

  final OnboardingScene scene;
  final double animationValue;
  final double pageOffset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final breathe = math.sin(animationValue * math.pi * 2) * 0.5 + 0.5;
    final parallaxY = pageOffset * 18;
    final scale = 1.0 - (pageOffset.abs() * 0.08);

    return Transform.translate(
      offset: Offset(0, parallaxY - breathe * 6),
      child: Transform.scale(
        scale: scale.clamp(0.88, 1.0),
        child: SizedBox(
          width: size,
          height: size * 0.92,
          child: CustomPaint(
            painter: _OnboardingScenePainter(
              scene: scene,
              breathe: breathe,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingScenePainter extends CustomPainter {
  _OnboardingScenePainter({
    required this.scene,
    required this.breathe,
  });

  final OnboardingScene scene;
  final double breathe;

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene) {
      case OnboardingScene.reviews:
        _paintReviews(canvas, size);
      case OnboardingScene.aiCompare:
        _paintAiCompare(canvas, size);
      case OnboardingScene.verifiedQA:
        _paintVerifiedQA(canvas, size);
      case OnboardingScene.confidentDecision:
        _paintConfidentDecision(canvas, size);
    }
  }

  void _paintReviews(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawAmbientOrb(canvas, Offset(w * 0.82, h * 0.18), w * 0.22, OnboardingPalette.royalBlue, 0.14);
    _drawAmbientOrb(canvas, Offset(w * 0.12, h * 0.72), w * 0.16, OnboardingPalette.softPurple, 0.1);

    final cardRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.46 - breathe * 4),
      width: w * 0.72,
      height: h * 0.42,
    );
    _drawGlassCard(canvas, cardRect, w, OnboardingPalette.royalBlue);

    _drawStarRow(canvas, Offset(cardRect.left + w * 0.1, cardRect.top + h * 0.1), w * 0.045, 5);
    _drawTextLines(canvas, cardRect.left + w * 0.1, cardRect.top + h * 0.2, w * 0.52, h * 0.035, 3);

    _drawVerifiedBadge(
      canvas,
      Offset(cardRect.right - w * 0.08, cardRect.top + h * 0.08),
      w * 0.09,
      OnboardingPalette.successGreen,
    );

    _drawMiniReviewCard(
      canvas,
      Rect.fromLTWH(w * 0.06, h * 0.62 + breathe * 3, w * 0.34, h * 0.18),
      w,
      0.85,
      OnboardingPalette.indigo,
    );
    _drawMiniReviewCard(
      canvas,
      Rect.fromLTWH(w * 0.58, h * 0.68 - breathe * 2, w * 0.32, h * 0.16),
      w,
      0.7,
      OnboardingPalette.softPurple,
    );

    _drawDiscoveryLens(canvas, Offset(w * 0.78, h * 0.34 + breathe * 5), w * 0.11);
  }

  void _paintAiCompare(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawAmbientOrb(canvas, Offset(w * 0.5, h * 0.38), w * 0.28, OnboardingPalette.indigo, 0.12);

    final leftCard = Rect.fromLTWH(w * 0.06, h * 0.28 + breathe * 2, w * 0.36, h * 0.48);
    final rightCard = Rect.fromLTWH(w * 0.58, h * 0.24 - breathe * 2, w * 0.36, h * 0.52);

    _drawCollegeColumn(canvas, leftCard, w, OnboardingPalette.indigo, 0.72);
    _drawCollegeColumn(canvas, rightCard, w, OnboardingPalette.royalBlue, 0.92);

    _drawAiCore(canvas, Offset(w * 0.5, h * 0.42), w * 0.13 + breathe * 0.01);

    _drawCompareBar(canvas, w * 0.18, h * 0.82, w * 0.22, h * 0.06, 0.55, OnboardingPalette.indigo);
    _drawCompareBar(canvas, w * 0.62, h * 0.82, w * 0.22, h * 0.06, 0.82, OnboardingPalette.royalBlue);

    canvas.drawLine(
      Offset(w * 0.42, h * 0.52),
      Offset(w * 0.58, h * 0.48),
      Paint()
        ..color = OnboardingPalette.indigo.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintVerifiedQA(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawAmbientOrb(canvas, Offset(w * 0.2, h * 0.25), w * 0.18, OnboardingPalette.softPurple, 0.12);
    _drawAmbientOrb(canvas, Offset(w * 0.85, h * 0.65), w * 0.14, OnboardingPalette.softPurpleLight, 0.08);

    _drawChatBubble(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.58, h * 0.16),
      tailLeft: true,
      color: OnboardingPalette.warmWhiteDeep,
      border: OnboardingPalette.softPurple.withValues(alpha: 0.25),
    );
    _drawQuestionMark(canvas, Offset(w * 0.16, h * 0.28), w * 0.04);

    _drawChatBubble(
      canvas,
      Rect.fromLTWH(w * 0.28, h * 0.48 - breathe * 3, w * 0.64, h * 0.22),
      tailLeft: false,
      color: Colors.white,
      border: OnboardingPalette.softPurple.withValues(alpha: 0.35),
    );
    _drawTextLines(canvas, w * 0.38, h * 0.54 - breathe * 3, w * 0.46, h * 0.028, 2);

    _drawSeniorAvatar(canvas, Offset(w * 0.34, h * 0.72 + breathe * 2), w * 0.1);
    _drawVerifiedBadge(
      canvas,
      Offset(w * 0.42, h * 0.66 + breathe * 2),
      w * 0.075,
      OnboardingPalette.successGreen,
    );

    _drawSparkDots(canvas, Offset(w * 0.78, h * 0.38), w * 0.025, breathe);
  }

  void _paintConfidentDecision(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawAmbientOrb(canvas, Offset(w * 0.5, h * 0.55), w * 0.32, OnboardingPalette.successGreen, 0.1);

    _drawPath(canvas, w, h, breathe);

    _drawCollegeBuilding(
      canvas,
      Rect.fromLTWH(w * 0.62, h * 0.38 - breathe * 2, w * 0.3, h * 0.34),
      w,
      OnboardingPalette.royalBlue,
    );

    _drawConfidenceCheck(
      canvas,
      Offset(w * 0.28, h * 0.42),
      w * 0.16 + breathe * 0.02,
    );

    _drawMiniReviewCard(
      canvas,
      Rect.fromLTWH(w * 0.08, h * 0.62, w * 0.38, h * 0.2),
      w,
      0.9,
      OnboardingPalette.successGreen,
    );

    for (var i = 0; i < 3; i++) {
      final t = (breathe + i * 0.33) % 1.0;
      _drawParticle(
        canvas,
        Offset(w * (0.15 + i * 0.25), h * (0.18 + t * 0.08)),
        w * 0.018,
        OnboardingPalette.successGreen.withValues(alpha: 0.4 + t * 0.3),
      );
    }
  }

  void _drawAmbientOrb(Canvas canvas, Offset center, double radius, Color color, double alpha) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawGlassCard(Canvas canvas, Rect rect, double w, Color accent) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.05));
    canvas.drawShadow(Path()..addRRect(rrect), accent.withValues(alpha: 0.25), 16, false);
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, OnboardingPalette.warmWhite],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawMiniReviewCard(Canvas canvas, Rect rect, double w, double opacity, Color accent) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.035));
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: opacity));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.2 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _drawStarRow(canvas, Offset(rect.left + w * 0.04, rect.top + rect.height * 0.25), w * 0.028, 4);
  }

  void _drawStarRow(Canvas canvas, Offset start, double radius, int count) {
    for (var i = 0; i < count; i++) {
      _drawStar(canvas, Offset(start.dx + i * radius * 2.4, start.dy), radius, OnboardingPalette.starGold);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = (i * math.pi / points) - math.pi / 2;
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawTextLines(Canvas canvas, double x, double y, double width, double height, int lines) {
    for (var i = 0; i < lines; i++) {
      final lineWidth = width * (i == lines - 1 ? 0.62 : 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y + i * (height + 6), lineWidth, height),
          Radius.circular(height * 0.4),
        ),
        Paint()..color = OnboardingPalette.inkSoft.withValues(alpha: 0.35),
      );
    }
  }

  void _drawVerifiedBadge(Canvas canvas, Offset center, double size, Color color) {
    canvas.drawCircle(center, size, Paint()..color = color);
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.12,
    );
    final check = Path()
      ..moveTo(center.dx - size * 0.35, center.dy)
      ..lineTo(center.dx - size * 0.08, center.dy + size * 0.28)
      ..lineTo(center.dx + size * 0.38, center.dy - size * 0.25);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDiscoveryLens(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.22,
    );
    canvas.drawCircle(
      center,
      radius * 0.75,
      Paint()..color = OnboardingPalette.royalBlue.withValues(alpha: 0.08),
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.65, center.dy + radius * 0.65),
      Offset(center.dx + radius * 1.35, center.dy + radius * 1.35),
      Paint()
        ..color = OnboardingPalette.royalBlue
        ..strokeWidth = radius * 0.24
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCollegeColumn(Canvas canvas, Rect rect, double w, Color accent, double fill) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.04));
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.95));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + w * 0.08, rect.top + rect.height * 0.12, rect.width - w * 0.16, rect.height * 0.22),
        Radius.circular(w * 0.025),
      ),
      Paint()..color = accent.withValues(alpha: 0.15),
    );
    _drawCompareBar(canvas, rect.left + w * 0.1, rect.bottom - rect.height * 0.18, rect.width - w * 0.2, rect.height * 0.06, fill, accent);
  }

  void _drawAiCore(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius * 1.35,
      Paint()..color = OnboardingPalette.indigo.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [OnboardingPalette.indigoLight, OnboardingPalette.indigo],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + breathe * 0.4;
      final end = Offset(center.dx + math.cos(angle) * radius * 1.1, center.dy + math.sin(angle) * radius * 1.1);
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(center, radius * 0.28, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _drawCompareBar(Canvas canvas, double x, double bottom, double width, double height, double fill, Color color) {
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, bottom - height, width, height),
      Radius.circular(height * 0.5),
    );
    canvas.drawRRect(track, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - height, width * fill, height),
        Radius.circular(height * 0.5),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
        ).createShader(Rect.fromLTWH(x, bottom - height, width * fill, height)),
    );
  }

  void _drawChatBubble(Canvas canvas, Rect rect, {required bool tailLeft, required Color color, required Color border}) {
    final r = Radius.circular(rect.height * 0.35);
    final rrect = RRect.fromRectAndRadius(rect, r);
    canvas.drawRRect(rrect, Paint()..color = color);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final tail = Path();
    if (tailLeft) {
      tail.moveTo(rect.left + rect.width * 0.12, rect.bottom);
      tail.lineTo(rect.left + rect.width * 0.06, rect.bottom + rect.height * 0.35);
      tail.lineTo(rect.left + rect.width * 0.22, rect.bottom);
    } else {
      tail.moveTo(rect.right - rect.width * 0.12, rect.bottom);
      tail.lineTo(rect.right - rect.width * 0.06, rect.bottom + rect.height * 0.3);
      tail.lineTo(rect.right - rect.width * 0.24, rect.bottom);
    }
    tail.close();
    canvas.drawPath(tail, Paint()..color = color);
  }

  void _drawQuestionMark(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = OnboardingPalette.softPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.35
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy - size * 0.2), width: size * 1.4, height: size * 1.4),
      -math.pi * 0.85,
      math.pi * 1.2,
      false,
      paint,
    );
    canvas.drawCircle(Offset(center.dx, center.dy + size * 0.9), size * 0.12, Paint()..color = OnboardingPalette.softPurple);
  }

  void _drawSeniorAvatar(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = OnboardingPalette.softPurple.withValues(alpha: 0.15));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = OnboardingPalette.softPurple
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.22),
      radius * 0.38,
      Paint()..color = OnboardingPalette.softPurple.withValues(alpha: 0.75),
    );
  }

  void _drawSparkDots(Canvas canvas, Offset center, double radius, double phase) {
    for (var i = 0; i < 4; i++) {
      final angle = phase * math.pi * 2 + i * math.pi / 2;
      _drawParticle(
        canvas,
        Offset(center.dx + math.cos(angle) * radius * 2.5, center.dy + math.sin(angle) * radius * 2.5),
        radius,
        OnboardingPalette.softPurple.withValues(alpha: 0.5),
      );
    }
  }

  void _drawPath(Canvas canvas, double w, double h, double breathe) {
    final path = Path()
      ..moveTo(w * 0.12, h * 0.78)
      ..quadraticBezierTo(w * 0.28, h * (0.62 - breathe * 0.04), w * 0.42, h * 0.58)
      ..quadraticBezierTo(w * 0.55, h * 0.48, w * 0.62, h * 0.52);
    canvas.drawPath(
      path,
      Paint()
        ..color = OnboardingPalette.successGreen.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCollegeBuilding(Canvas canvas, Rect rect, double w, Color accent) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.03));
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = accent.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final roof = Path()
      ..moveTo(rect.left, rect.top + rect.height * 0.08)
      ..lineTo(rect.center.dx, rect.top - rect.height * 0.06)
      ..lineTo(rect.right, rect.top + rect.height * 0.08)
      ..close();
    canvas.drawPath(roof, Paint()..color = accent.withValues(alpha: 0.85));
  }

  void _drawConfidenceCheck(Canvas canvas, Offset center, double size) {
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..shader = RadialGradient(
          colors: [OnboardingPalette.successGreenLight, OnboardingPalette.successGreen],
        ).createShader(Rect.fromCircle(center: center, radius: size)),
    );
    canvas.drawCircle(
      center,
      size,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.06,
    );
    final check = Path()
      ..moveTo(center.dx - size * 0.35, center.dy + size * 0.02)
      ..lineTo(center.dx - size * 0.05, center.dy + size * 0.32)
      ..lineTo(center.dx + size * 0.42, center.dy - size * 0.28);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawParticle(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _OnboardingScenePainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.breathe != breathe;
}
