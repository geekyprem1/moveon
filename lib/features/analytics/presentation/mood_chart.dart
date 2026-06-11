import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../mood/domain/mood_entry.dart';
import '../../../utils/recovery_calculator.dart';

class MoodChart extends StatelessWidget {
  final List<MoodEntry> moods;
  final int days;

  const MoodChart({
    super.key,
    required this.moods,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Prepare data points
    final now = DateTime.now();
    final List<double> values = [];
    final List<String> labels = [];

    // Map to quickly query mood value by yyyy-MM-dd
    final moodMap = {
      for (var m in moods)
        DateFormat('yyyy-MM-dd').format(m.timestamp): RecoveryCalculator.getMoodValue(m.mood) / 20.0 // Map 20-100 to 1-5
    };

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Check if entry exists, else use 3.0 (Okay) as placeholder
      final double val = moodMap[dateStr] ?? 3.0;
      values.add(val);

      // X axis labels: for 7 days show weekday letter, for 30 days show day number
      if (days == 7) {
        labels.add(DateFormat('E').format(date).substring(0, 1));
      } else {
        if (i % 5 == 0) {
          labels.add(DateFormat('d').format(date));
        } else {
          labels.add('');
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mood Trend - Last $days Days',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _MoodChartPainter(
                  values: values,
                  xLabels: labels,
                  lineColor: theme.colorScheme.primary,
                  gridColor: theme.dividerTheme.color ?? theme.colorScheme.surfaceContainerHighest,
                  textColor: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> xLabels;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  _MoodChartPainter({
    required this.values,
    required this.xLabels,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Padding for axes labels
    const double paddingLeft = 32.0;
    const double paddingBottom = 20.0;
    const double paddingTop = 10.0;

    final double chartWidth = size.width - paddingLeft;
    final double chartHeight = size.height - paddingBottom - paddingTop;

    // Y Axis scale goes from 1.0 (Terrible) to 5.0 (Great)
    const double minY = 1.0;
    const double maxY = 5.0;

    // Helper to calculate X/Y coordinates
    double getX(int index) {
      if (values.length <= 1) return paddingLeft;
      return paddingLeft + (index * (chartWidth / (values.length - 1)));
    }

    double getY(double value) {
      final double ratio = (value - minY) / (maxY - minY);
      return size.height - paddingBottom - (ratio * chartHeight);
    }

    // 1. Draw Grid Lines & Y Labels (Emojis)
    final List<String> emojis = ['😭', '😢', '😐', '🙂', '😁'];
    final gridLinePaint = Paint()
      ..color = gridColor.withAlpha(80)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final double val = minY + i;
      final double y = getY(val);

      // Horizontal grid line
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridLinePaint);

      // Y Label emoji
      textPainter.text = TextSpan(
        text: emojis[i],
        style: const TextStyle(fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(8, y - (textPainter.height / 2)),
      );
    }

    // 2. Draw Line & Gradient Fill under the line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final fillPath = Path();

    // Start coordinates
    final double startX = getX(0);
    final double startY = getY(values[0]);

    path.moveTo(startX, startY);
    fillPath.moveTo(startX, size.height - paddingBottom);
    fillPath.lineTo(startX, startY);

    for (int i = 1; i < values.length; i++) {
      final double x = getX(i);
      final double y = getY(values[i]);

      // Draw straight line segments (clean, simple and responsive)
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    // Close fill path to bottom of chart
    fillPath.lineTo(getX(values.length - 1), size.height - paddingBottom);
    fillPath.close();

    // Draw gradient filling
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withAlpha(80),
          lineColor.withAlpha(0),
        ],
      ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width, size.height - paddingBottom))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // 3. Draw Data Points (circles)
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final pointStrokePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Only draw circles if showing 7 days (too crowded for 30)
    if (values.length <= 7) {
      for (int i = 0; i < values.length; i++) {
        final double x = getX(i);
        final double y = getY(values[i]);
        canvas.drawCircle(Offset(x, y), 5.0, pointPaint);
        canvas.drawCircle(Offset(x, y), 5.0, pointStrokePaint);
      }
    }

    // 4. Draw X Axis Labels (Days)
    final labelStyle = TextStyle(
      fontSize: 10,
      color: textColor,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < xLabels.length; i++) {
      if (xLabels[i].isEmpty) continue;

      final double x = getX(i);
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: labelStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - paddingBottom + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.xLabels != xLabels;
  }
}
