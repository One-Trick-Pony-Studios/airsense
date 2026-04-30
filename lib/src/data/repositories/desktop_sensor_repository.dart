import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'sensor_repository.dart';

class DesktopSensorRepository implements SensorRepository {
  SerialPort? _port;
  StreamController<Uint8List>? _controller;
  StreamSubscription<Uint8List>? _subscription;

  @override
  Stream<Uint8List> get rawDataStream {
    _controller ??= StreamController<Uint8List>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> connect(String portName) async {
    if (_port != null && _port!.isOpen) {
      if (_port!.name == portName) return; // Already connected
      await disconnect();
    }

    try {
      _port = SerialPort(portName);
      if (!_port!.openRead()) {
        throw SerialPortError("Failed to open port for reading.");
      }
      _port!.config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..parity = SerialPortParity.none
        ..stopBits = 1;

      _controller ??= StreamController<Uint8List>.broadcast();
      final reader = SerialPortReader(_port!);
      _subscription = reader.stream.listen((data) {
        _controller?.add(data);
      });
    } on SerialPortError catch (e) {
      debugPrint("Serial Port Error: $e");
      _port = null;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      _port?.close();
    } catch (e) {
      // Ignore errors on close
    }
    _port = null;
  }

  @override
  Future<List<String>> getAvailablePorts() async {
    return SerialPort.availablePorts;
  }

  @override
  void dispose() {
    disconnect();
    _controller?.close();
  }
}
