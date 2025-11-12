import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color color;

  const StatsChart({
    super.key,
    required this.title,
    required this.spots,
    required this.color,
  });

  String _getValueText(List<FlSpot> spots) {
    if (spots.isEmpty) return '0';
    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (title.contains('CPU')) {
      return '${maxValue.toStringAsFixed(1)}%';
    } else if (title.contains('Memory')) {
      return '${maxValue.toStringAsFixed(1)}%';
    } else if (title.contains('Network')) {
      if (maxValue > 1024 * 1024) {
        return '${(maxValue / (1024 * 1024)).toStringAsFixed(2)} GB';
      } else if (maxValue > 1024) {
        return '${(maxValue / 1024).toStringAsFixed(2)} MB';
      } else {
        return '${maxValue.toStringAsFixed(1)} KB';
      }
    }
    return maxValue.toStringAsFixed(2);
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;

    final maxValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    if (title.contains('CPU') || title.contains('Memory')) {
      // For percentage-based charts, ensure minimum range and cap at reasonable values
      return maxValue < 10 ? 10 : (maxValue * 1.2).clamp(0, 100);
    } else {
      // For network charts, use dynamic scaling with minimum range
      final minRange = maxValue * 0.1; // At least 10% of max value as range
      return maxValue + minRange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getValueText(spots),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                key: ValueKey('${spots.length}_${spots.hashCode}'), // Force rebuild on data change
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (spots.isEmpty) return const Text('');
                          final totalPoints = spots.length;
                          final step = totalPoints ~/ 5; // Show ~5 labels
                          if (step == 0 || value % step != 0) return const Text('');
                          final secondsAgo = totalPoints - value.toInt() - 1;
                          return Text(
                            '${secondsAgo}s',
                            style: TextStyle(
                              color: AppTheme.foreground.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: spots.isNotEmpty ? (spots.length - 1).toDouble() : 1,
                  minY: 0,
                  maxY: _calculateMaxY(spots),
                  // Ensure chart shows all data points properly
                  clipData: const FlClipData.all(),
                  // Prevent overflow and ensure smooth updates
                  backgroundColor: Colors.transparent,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      // Ensure smooth line rendering
                      preventCurveOverShooting: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}