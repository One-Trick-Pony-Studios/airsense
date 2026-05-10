import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../domain/sensor_data.dart';

class SensorDataChart extends ConsumerWidget {
  const SensorDataChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataPoints =
        ref.watch(sensorStateProvider.select((s) => s.uiRingBuffer));

    if (dataPoints.isEmpty) {
      return const Center(child: Text('Waiting for data...'));
    }

    final double minY = 0;
    final double maxY = dataPoints.fold<double>(
          0.0,
          (max, e) => max > e.pm25 && max > e.pm10
              ? max
              : (e.pm25 > e.pm10 ? e.pm25 : e.pm10),
        ) *
        1.2; // Add 20% padding

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY.isFinite && maxY > 0 ? maxY : 50, // Fallback maxY
                lineBarsData: [
                  _createLineBarData(dataPoints, true, Colors.blue),
                  _createLineBarData(dataPoints, false, Colors.red),
                ],
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y;
                        final label =
                            spot.bar.color == Colors.blue ? 'PM2.5' : 'PM10';
                        final dataPoint = dataPoints[spot.x.toInt()];
                        return LineTooltipItem(
                          '$label: ${value.toStringAsFixed(1)}\n${dataPoint.timestamp.hour}:${dataPoint.timestamp.minute.toString().padLeft(2, '0')}',
                          TextStyle(color: spot.bar.color),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: Colors.blue, label: 'PM2.5'),
              SizedBox(width: 24),
              _LegendItem(color: Colors.red, label: 'PM10'),
            ],
          ),
        ),
      ],
    );
  }

  LineChartBarData _createLineBarData(
      List<SensorData> data, bool isPm25, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((entry) {
        final index = entry.key;
        final value = isPm25 ? entry.value.pm25 : entry.value.pm10;
        return FlSpot(index.toDouble(), value);
      }).toList(),
      isCurved: true,
      color: color,
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
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
