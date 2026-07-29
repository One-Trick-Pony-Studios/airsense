import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

import 'sensor_repository.dart';

class DesktopSensorRepository implements SensorRepository {
  SerialPort? _port;
  StreamController<Uint8List>? _controller;
  SerialPortReader? _reader;

  @override
  Stream<Uint8List> get rawDataStream {
    _controller ??= StreamController<Uint8List>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> connect(String portName, {int baudRate = 9600}) async {
    if (_port != null && _port!.isOpen) {
      if (_port!.name == portName) return; // Already connected
      await disconnect();
    }

    try {
      _port = SerialPort(portName);
      if (!_port!.openReadWrite()) {
        throw SerialPortError("Failed to open port for reading and writing.");
      }

      final config = _port!.config;
      config.baudRate = baudRate;
      config.bits = 8;
      config.parity = SerialPortParity.none;
      config.stopBits = 1;
      
      // Explicitly disable flow control. Linux TTY devices often default to 
      // hardware flow control (CRTSCTS) enabled, which blocks RX on SDS011 sensors.
      config.setFlowControl(SerialPortFlowControl.none);
      
      _port!.config = config;

      _controller ??= StreamController<Uint8List>.broadcast();
      
      _reader = SerialPortReader(_port!);
      _reader!.stream.listen((data) {
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
    _disconnectSync();
  }

  /// Synchronously disconnects and cleans up resources.
  /// This is safe to call from `dispose()`.
  void _disconnectSync() {
    // The subscription is on the reader's stream. Closing the reader
    // kills its isolate and closes its stream, which is sufficient to stop
    // the flow of data and terminate the subscription.
    _reader?.close();
    _reader = null;

    try {
      if (_port != null && _port!.isOpen) {
        _port!.close();
      }
    } catch (e) {
      debugPrint("Error on port close: $e");
    }
    _port = null;
  }

  @override
  Future<List<String>> getAvailablePorts() async {
    return SerialPort.availablePorts;
  }

  @override
  void dispose() {
    _disconnectSync();
    _controller?.close();
    _controller = null;
  }
}
