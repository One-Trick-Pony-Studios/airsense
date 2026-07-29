import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Describes a single data series to plot.
class ChartSeries<T> {
  const ChartSeries({
    required this.label,
    required this.color,
    required this.valueExtractor,
  });

  /// Legend label shown below the chart.
  final String label;

  /// Line and legend colour.
  final Color color;

  /// Given a data point, returns the y-axis value to plot.
  final double Function(T dataPoint) valueExtractor;
}

/// A generic time-series line chart that plots one or more [ChartSeries]
/// over a list of data points [T].
///
/// Data points are indexed along the x-axis; the y-axis range is computed
/// automatically with a 20 % top-padding.
class SeriesChart<T> extends StatelessWidget {
  const SeriesChart({
    super.key,
    required this.dataPoints,
    required this.series,
    this.emptyMessage = 'Waiting for data...',
    this.yAxisLabel,
    this.minY,
    this.maxYOverride,
  });

  final List<T> dataPoints;
  final List<ChartSeries<T>> series;
  final String emptyMessage;

  /// Optional label for the Y-axis (shown as a rotated title).
  final String? yAxisLabel;

  /// Explicit minimum Y value. Defaults to 0.
  final double? minY;

  /// If provided, overrides the auto-computed max Y value.
  final double? maxYOverride;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final double effectiveMinY = minY ?? 0;
    double computedMaxY = maxYOverride ?? 0;
    if (maxYOverride == null) {
      for (final point in dataPoints) {
        for (final s in series) {
          final v = s.valueExtractor(point);
          if (v > computedMaxY) computedMaxY = v;
        }
      }
      computedMaxY *= 1.2; // 20 % headroom
    }
    final effectiveMaxY =
        computedMaxY.isFinite && computedMaxY > effectiveMinY
            ? computedMaxY
            : effectiveMinY + 50;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LineChart(
              LineChartData(
                minY: effectiveMinY,
                maxY: effectiveMaxY,
                lineBarsData: series.map((s) => _buildBarData(s)).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    axisNameWidget: yAxisLabel != null
                        ? Text(yAxisLabel!,
                            style: const TextStyle(fontSize: 11))
                        : null,
                    sideTitles: const SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final matchingSeries = series.firstWhere(
                          (s) => s.color == spot.bar.color,
                          orElse: () => series[spot.barIndex],
                        );
                        return LineTooltipItem(
                          '${matchingSeries.label}: ${spot.y.toStringAsFixed(1)}',
                          TextStyle(
                              color: spot.bar.color,
                              fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Wrap(
            spacing: 24,
            children: series
                .map((s) => _LegendItem(color: s.color, label: s.label))
                .toList(),
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildBarData(ChartSeries<T> s) {
    return LineChartBarData(
      spots: dataPoints.asMap().entries.map((entry) {
        return FlSpot(
            entry.key.toDouble(), s.valueExtractor(entry.value));
      }).toList(),
      isCurved: true,
      color: s.color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
