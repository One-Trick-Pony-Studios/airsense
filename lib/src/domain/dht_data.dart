import 'package:flutter/foundation.dart';

@immutable
class DhtData {
  const DhtData({
    required this.temperatureCelsius,
    required this.relativeHumidity,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  final double temperatureCelsius;
  final double relativeHumidity;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  @override
  String toString() =>
      'DhtData(temp: $temperatureCelsius°C, rh: $relativeHumidity%, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DhtData &&
        other.temperatureCelsius == temperatureCelsius &&
        other.relativeHumidity == relativeHumidity &&
        other.timestamp == timestamp &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.locationName == locationName;
  }

  @override
  int get hashCode =>
      temperatureCelsius.hashCode ^
      relativeHumidity.hashCode ^
      timestamp.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      locationName.hashCode;
}
