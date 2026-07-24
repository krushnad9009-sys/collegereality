import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/theme/app_theme.dart';
import '../../../core/constants/cr_score_constants.dart';

class CrScoreGaugeWidget extends StatefulWidget {
  final double score;
  final double size;
  final bool animate;

  const CrScoreGaugeWidget({
    required this.score,
    this.size = 140,
    this.animate = true,
    super.key,
  });

  @override
  State<CrScoreGaugeWidget> createState() => _CrScoreGaugeWidgetState();
}

class _CrScoreGaugeWidgetState extends State<CrScoreGaugeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = widget.score / 100;
    }
  }

  @override
  void didUpdateWidget(CrScoreGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = CrScoreConstants.colorForScore(widget.score);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _CrScoreGaugePainter(
              progress: _animation.value,
              color: color,
              trackColor: AppTheme.gray200,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.score > 0
                        ? widget.score.toStringAsFixed(0)
                        : '—',
                    style: GoogleFonts.poppins(
                      fontSize: widget.size * 0.24,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: GoogleFonts.poppins(
                      fontSize: widget.size * 0.11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gray500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CrScoreGaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _CrScoreGaugePainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke,
        size.height - stroke);
    final start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.35), color],
        startAngle: start,
        endAngle: start + sweep,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, trackPaint);
    canvas.drawArc(rect, start, sweep * progress.clamp(0, 1), false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CrScoreGaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
