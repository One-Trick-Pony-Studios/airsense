/// Represents the type of sensor device connected to the app.
enum DeviceType {
  /// Nova PM SDS011 particulate matter sensor (PM2.5 / PM10).
  nova,

  /// DHT11 temperature & humidity sensor relayed over ESP01 via serial.
  dht11,
}

extension DeviceTypeLabel on DeviceType {
  String get displayName {
    switch (this) {
      case DeviceType.nova:
        return 'Nova PM (SDS011)';
      case DeviceType.dht11:
        return 'DHT11 via ESP01';
    }
  }

  String get shortName {
    switch (this) {
      case DeviceType.nova:
        return 'Nova PM';
      case DeviceType.dht11:
        return 'DHT11';
    }
  }
}
