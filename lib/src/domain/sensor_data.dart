import 'package:flutter/foundation.dart';

@immutable
class SensorData {
  const SensorData({
    required this.pm25,
    required this.pm10,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  final double pm25;
  final double pm10;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  @override
  String toString() =>
      'SensorData(pm25: $pm25, pm10: $pm10, timestamp: $timestamp, lat: $latitude, lon: $longitude, loc: $locationName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SensorData &&
        other.pm25 == pm25 &&
        other.pm10 == pm10 &&
        other.timestamp == timestamp &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.locationName == locationName;
  }

  @override
  int get hashCode =>
      pm25.hashCode ^
      pm10.hashCode ^
      timestamp.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      locationName.hashCode;
}
