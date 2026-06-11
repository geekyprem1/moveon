import 'package:flutter/material.dart';
import '../../emergency/domain/emergency_click.dart';

class CravingHeatmap extends StatelessWidget {
  final List<EmergencyClick> clicks;

  const CravingHeatmap({super.key, required this.clicks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 1. Build matrix: 7 days (0=Mon, 6=Sun) x 24 hours (0-23)
    final grid = List.generate(7, (_) => List.filled(24, 0));
    int maxClicks = 1;

    for (var click in clicks) {
      // weekday is 1-indexed (1=Mon, 7=Sun)
      final dayIndex = (click.dayOfWeek - 1).clamp(0, 6);
      final hourIndex = click.hourOfDay.clamp(0, 23);
      grid[dayIndex][hourIndex]++;
      if (grid[dayIndex][hourIndex] > maxClicks) {
        maxClicks = grid[dayIndex][hourIndex];
      }
    }

    // 2. Perform stats calculations
    final daySums = List.filled(7, 0);
    final hourSums = List.filled(24, 0);
    for (int d = 0; d < 7; d++) {
      for (int h = 0; h < 24; h++) {
        daySums[d] += grid[d][h];
        hourSums[h] += grid[d][h];
      }
    }

    // Find most difficult day
    int maxDayIndex = 6; // default to Sun
    int maxDaySum = -1;
    for (int d = 0; d < 7; d++) {
      if (daySums[d] > maxDaySum) {
        maxDaySum = daySums[d];
        maxDayIndex = d;
      }
    }

    final List<String> dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final String difficultDay = clicks.isEmpty ? 'N/A' : dayNames[maxDayIndex];

    // Find most difficult time block
    // Morning: 6-12, Afternoon: 12-18, Evening: 18-22, Night: 22-6
    int morning = 0;
    int afternoon = 0;
    int evening = 0;
    int night = 0;

    for (var click in clicks) {
      final h = click.hourOfDay;
      if (h >= 6 && h < 12) {
        morning++;
      } else if (h >= 12 && h < 18) {
        afternoon++;
      } else if (h >= 18 && h < 22) {
        evening++;
      } else {
        night++;
      }
    }

    String difficultTime = 'N/A';
    int maxTimeCount = -1;
    if (clicks.isNotEmpty) {
      if (morning > maxTimeCount) {
        maxTimeCount = morning;
        difficultTime = 'Mornings (6 AM - 12 PM)';
      }
      if (afternoon > maxTimeCount) {
        maxTimeCount = afternoon;
        difficultTime = 'Afternoons (12 PM - 6 PM)';
      }
      if (evening > maxTimeCount) {
        maxTimeCount = evening;
        difficultTime = 'Evenings (6 PM - 10 PM)';
      }
      if (night > maxTimeCount) {
        maxTimeCount = night;
        difficultTime = 'Late Nights (10 PM - 6 AM)';
      }
    }

    // Dynamic insight generator
    String insightText = "Tap the Emergency button when you feel like contacting your ex to track your triggers.";
    if (clicks.isNotEmpty) {
      final String timeDesc = maxTimeCount == night
          ? "nights"
          : maxTimeCount == evening
              ? "evenings"
              : maxTimeCount == afternoon
                  ? "afternoons"
                  : "mornings";
      insightText = "You are most likely to miss your ex on $difficultDay $timeDesc. Keep using the SOS toolkit during these times.";
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Craving Heatmap',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SOS Triggers',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tracks hourly and weekly cravings when the emergency button is clicked.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),

            // The Heatmap CustomPaint
            SizedBox(
              height: 250,
              child: CustomPaint(
                painter: _HeatmapGridPainter(
                  grid: grid,
                  maxClicks: maxClicks,
                  theme: theme,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Statistics Info Panel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('📊'),
                      const SizedBox(width: 8),
                      Text(
                        'Trigger Insights',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insightText,
                    style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniInsight(
                        context,
                        'Peak Day',
                        difficultDay,
                        theme.colorScheme.primary,
                      ),
                      _buildMiniInsight(
                        context,
                        'Peak Time',
                        clicks.isEmpty ? 'N/A' : difficultTime.split(' ').first,
                        theme.colorScheme.secondary,
                      ),
                      _buildMiniInsight(
                        context,
                        'Total SOS Logs',
                        '${clicks.length}',
                        theme.colorScheme.tertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniInsight(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _HeatmapGridPainter extends CustomPainter {
  final List<List<int>> grid;
  final int maxClicks;
  final ThemeData theme;

  _HeatmapGridPainter({
    required this.grid,
    required this.maxClicks,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double leftLabelWidth = 45.0;
    final double topLabelHeight = 25.0;

    final double gridWidth = size.width - leftLabelWidth;
    final double gridHeight = size.height - topLabelHeight;

    final double colWidth = gridWidth / 7.0;
    final double rowHeight = gridHeight / 24.0;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Draw Weekday Headers (Columns)
    final List<String> weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int col = 0; col < 7; col++) {
      final double x = leftLabelWidth + col * colWidth + (colWidth / 2);
      textPaint.text = TextSpan(
        text: weekdays[col],
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary,
        ),
      );
      textPaint.layout();
      canvas.drawText(
        textPaint,
        Offset(x - (textPaint.width / 2), 0),
      );
    }

    // 2. Draw Hour Labels (Rows, every 4 hours to avoid overcrowding)
    for (int row = 0; row < 24; row += 4) {
      final double y = topLabelHeight + row * rowHeight + (rowHeight / 2);
      final int displayHour = row == 0
          ? 12
          : row > 12
              ? row - 12
              : row;
      final String amPm = row < 12 ? 'AM' : 'PM';
      final String hourStr = '$displayHour $amPm';

      textPaint.text = TextSpan(
        text: hourStr,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: theme.colorScheme.secondary,
        ),
      );
      textPaint.layout();
      canvas.drawText(
        textPaint,
        Offset(5, y - (textPaint.height / 2)),
      );
    }

    // 3. Draw Heatmap Grid Cells
    final cellPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = theme.dividerTheme.color ?? theme.colorScheme.outlineVariant.withAlpha(80);

    for (int col = 0; col < 7; col++) {
      for (int row = 0; row < 24; row++) {
        final double x = leftLabelWidth + col * colWidth;
        final double y = topLabelHeight + row * rowHeight;
        final rect = Rect.fromLTWH(x + 1, y + 1, colWidth - 2, rowHeight - 2);

        final int count = grid[col][row];
        if (count == 0) {
          cellPaint.color = theme.colorScheme.surfaceContainerHighest.withAlpha(50);
        } else {
          final double density = count / maxClicks;
          cellPaint.color = theme.colorScheme.primary.withValues(alpha: 0.15 + 0.85 * density);
        }

        // Draw rounded cell rect for a high-end look
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          cellPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          borderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapGridPainter oldDelegate) => true;
}

extension CanvasDrawText on Canvas {
  void drawText(TextPainter painter, Offset offset) {
    painter.paint(this, offset);
  }
}
