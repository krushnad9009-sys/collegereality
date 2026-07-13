import 'package:flutter/material.dart';

import '../models/admin_models.dart';

class AdminLineChart extends StatelessWidget {
  final List<AdminGrowthPoint> points;
  final Color color;
  final String emptyLabel;

  const AdminLineChart({
    super.key,
    required this.points,
    this.color = Colors.blue,
    this.emptyLabel = 'No data yet',
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(child: Text(emptyLabel)),
      );
    }

    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _LineChartPainter(points: points, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<AdminGrowthPoint> points;
  final Color color;

  _LineChartPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final maxY = points.map((p) => p.count).reduce((a, b) => a > b ? a : b).toDouble();
    final minY = points.map((p) => p.count).reduce((a, b) => a < b ? a : b).toDouble();
    final range = (maxY - minY).clamp(1, double.infinity);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * (i / (points.length - 1));
      final y = size.height - ((points[i].count - minY) / range) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class AdminBarChart extends StatelessWidget {
  final List<AdminTopCollegeMetric> metrics;
  final Color color;

  const AdminBarChart({
    super.key,
    required this.metrics,
    this.color = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No ranking data yet')),
      );
    }

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _BarChartPainter(metrics: metrics, color: color),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<AdminTopCollegeMetric> metrics;
  final Color color;

  _BarChartPainter({required this.metrics, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = metrics.map((m) => m.value).reduce((a, b) => a > b ? a : b).toDouble();
    final barWidth = size.width / (metrics.length * 1.6);
    final gap = barWidth * 0.6;

    for (var i = 0; i < metrics.length; i++) {
      final barHeight = (metrics[i].value / maxVal) * (size.height - 24);
      final x = i * (barWidth + gap) + gap / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        rect,
        Paint()..color = color.withValues(alpha: 0.75 + (0.25 * i / metrics.length)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.metrics != metrics;
  }
}
