import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../domain/dht_data.dart';

/// Parses the newline-delimited ASCII output from a DHT11 sensor relayed
/// through an ESP01 module.
///
/// Expected frame format (each line):
///   `T:<temperature>,H:<humidity>\r\n`
///   e.g. `T:25.3,H:61.0\r\n`
///
/// The ESP01 firmware should emit one such line per measurement cycle.
class Dht11Parser {
  final StringBuffer _lineBuffer = StringBuffer();

  StreamTransformer<Uint8List, DhtData> get transformer =>
      StreamTransformer<Uint8List, DhtData>.fromHandlers(
        handleData: (data, sink) {
          // Decode incoming bytes as ASCII/UTF-8 text
          final text = utf8.decode(data, allowMalformed: true);
          _lineBuffer.write(text);
          _processBuffer(sink);
        },
      );

  void _processBuffer(EventSink<DhtData> sink) {
    final raw = _lineBuffer.toString();
    final lines = raw.split('\n');

    // Keep the last (potentially incomplete) fragment in the buffer
    _lineBuffer.clear();
    _lineBuffer.write(lines.last);

    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parsed = _parseLine(line);
      if (parsed != null) sink.add(parsed);
    }
  }

  DhtData? _parseLine(String line) {
    // Expected: T:25.3,H:61.0
    try {
      final tIdx = line.indexOf('T:');
      final hIdx = line.indexOf(',H:');
      if (tIdx == -1 || hIdx == -1) return null;

      final tempStr = line.substring(tIdx + 2, hIdx);
      final humStr = line.substring(hIdx + 3);

      final temp = double.parse(tempStr);
      final hum = double.parse(humStr);

      return DhtData(
        temperatureCelsius: temp,
        relativeHumidity: hum,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
