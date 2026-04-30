import 'dart:async';
import 'dart:typed_data';

import '../../domain/sensor_data.dart';

class Sds011Parser {
  final List<int> _buffer = [];
  static const int _frameLength = 10;
  static const int _header = 0xAA;
  static const int _tail = 0xAB;
  static const int _command = 0xC0;

  StreamTransformer<Uint8List, SensorData> get transformer =>
      StreamTransformer<Uint8List, SensorData>.fromHandlers(
        handleData: (data, sink) {
          _buffer.addAll(data);
          _processBuffer(sink);
        },
      );

  void _processBuffer(EventSink<SensorData> sink) {
    while (_buffer.length >= _frameLength) {
      if (_buffer[0] != _header) {
        _buffer.removeAt(0);
        continue;
      }

      if (_buffer[9] == _tail) {
        final frame = _buffer.sublist(0, _frameLength);
        if (frame[1] == _command) {
          int checksum = 0;
          for (int i = 2; i <= 7; i++) {
            checksum += frame[i];
          }
          checksum &= 0xFF;

          if (checksum == frame[8]) {
            final pm25low = frame[2];
            final pm25high = frame[3];
            final pm10low = frame[4];
            final pm10high = frame[5];

            final pm25 = ((pm25high << 8) | pm25low) / 10.0;
            final pm10 = ((pm10high << 8) | pm10low) / 10.0;

            sink.add(SensorData(
              pm25: pm25,
              pm10: pm10,
              timestamp: DateTime.now(),
            ));
          }
        }
        _buffer.removeRange(0, _frameLength);
      } else {
        _buffer.removeAt(0);
      }
    }
  }
}
