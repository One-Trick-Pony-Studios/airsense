import 'package:flutter/foundation.dart';

@immutable
class SensorData {
  const SensorData({
    required this.pm25,
    required this.pm10,
    required this.timestamp,
  });

  final double pm25;
  final double pm10;
  final DateTime timestamp;

  @override
  String toString() =>
      'SensorData(pm25: $pm25, pm10: $pm10, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SensorData &&
        other.pm25 == pm25 &&
        other.pm10 == pm10 &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => pm25.hashCode ^ pm10.hashCode ^ timestamp.hashCode;
}
