import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

import 'sensor_repository.dart';

class MobileSensorRepository implements SensorRepository {
  UsbPort? _port;
  StreamController<Uint8List>? _controller;
  StreamSubscription<Uint8List>? _subscription;
  List<UsbDevice> _devices = [];

  @override
  Stream<Uint8List> get rawDataStream {
    _controller ??= StreamController<Uint8List>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> connect(String portName) async {
    if (_port != null) {
      await disconnect();
    }

    try {
      final device = _devices.firstWhere(
        (d) => d.deviceName == portName,
        orElse: () => throw Exception("Device $portName not found"),
      );

      _port = await device.create();
      if (!await _port!.open()) {
        throw Exception("Failed to open USB port. Ensure permissions are granted.");
      }

      // Standard setup for USB-to-TTL serial chips
      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
          9600, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

      _controller ??= StreamController<Uint8List>.broadcast();
      _subscription = _port!.inputStream?.listen((data) {
        _controller?.add(data);
      });
    } catch (e) {
      debugPrint("USB Serial Error: $e");
      _port = null;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _port?.close();
    } catch (e) {
      // Ignore errors on close
    }
    _port = null;
  }

  @override
  Future<List<String>> getAvailablePorts() async {
    _devices = await UsbSerial.listDevices();
    return _devices.map((d) => d.deviceName).toList();
  }

  @override
  void dispose() {
    disconnect();
    _controller?.close();
  }
}
