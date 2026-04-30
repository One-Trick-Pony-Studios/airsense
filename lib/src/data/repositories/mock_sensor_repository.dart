import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'sensor_repository.dart';

class MockSensorRepository implements SensorRepository {
  final _controller = StreamController<Uint8List>.broadcast();
  Timer? _timer;
  final Random _random = Random();
  bool _isDisposed = false;

  @override
  Stream<Uint8List> get rawDataStream => _controller.stream;

  @override
  Future<void> connect(String portName) async {
    if (_timer?.isActive ?? false) {
      return;
    }
    // Start emitting fake data every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed) {
        _controller.add(_generateFakeSds011Frame());
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _timer?.cancel();
    _timer = null;
  }

  @override
  List<String> getAvailablePorts() {
    return ['/dev/mock_tty1', '/dev/mock_tty2', 'COM_MOCK'];
  }

  Uint8List _generateFakeSds011Frame() {
    final buffer = ByteData(10);
    buffer.setUint8(0, 0xAA); // Header
    buffer.setUint8(1, 0xC0); // Command

    // Fake PM2.5: 5.0 to 25.0 ug/m3
    final pm25 = (50 + _random.nextInt(200));
    buffer.setUint8(2, pm25 & 0xFF);
    buffer.setUint8(3, (pm25 >> 8) & 0xFF);

    // Fake PM10: 10.0 to 50.0 ug/m3
    final pm10 = (100 + _random.nextInt(400));
    buffer.setUint8(4, pm10 & 0xFF);
    buffer.setUint8(5, (pm10 >> 8) & 0xFF);

    // Fake ID
    buffer.setUint8(6, 0x01);
    buffer.setUint8(7, 0x02);

    // Checksum
    int checksum = 0;
    for (int i = 2; i <= 7; i++) {
      checksum += buffer.getUint8(i);
    }
    buffer.setUint8(8, checksum & 0xFF);

    buffer.setUint8(9, 0xAB); // Tail

    return buffer.buffer.asUint8List();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _controller.close();
  }
}
