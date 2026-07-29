import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'sensor_repository.dart';

/// Emits fake DHT11 text frames for development / UI testing.
class MockDht11SensorRepository implements SensorRepository {
  final _controller = StreamController<Uint8List>.broadcast();
  Timer? _timer;
  final Random _random = Random();
  bool _isDisposed = false;

  // Slowly drifting baseline values so the chart looks interesting
  double _baseTemp = 24.0;
  double _baseHum = 58.0;

  @override
  Stream<Uint8List> get rawDataStream => _controller.stream;

  @override
  Future<void> connect(String portName, {int baudRate = 9600}) async {
    if (_timer?.isActive ?? false) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isDisposed) {
        _controller.add(_generateFakeDhtFrame());
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<List<String>> getAvailablePorts() async {
    return ['/dev/mock_dht1', '/dev/mock_dht2'];
  }

  Uint8List _generateFakeDhtFrame() {
    // Slowly drift the baseline
    _baseTemp += (_random.nextDouble() - 0.5) * 0.4;
    _baseHum += (_random.nextDouble() - 0.5) * 0.8;
    _baseTemp = _baseTemp.clamp(18.0, 40.0);
    _baseHum = _baseHum.clamp(20.0, 95.0);

    final temp = _baseTemp + (_random.nextDouble() - 0.5) * 0.5;
    final hum = _baseHum + (_random.nextDouble() - 0.5) * 1.0;
    final line = 'T:${temp.toStringAsFixed(1)},H:${hum.toStringAsFixed(1)}\r\n';
    return Uint8List.fromList(utf8.encode(line));
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller.close();
  }
}
