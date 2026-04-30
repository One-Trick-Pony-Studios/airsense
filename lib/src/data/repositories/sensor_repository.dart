import 'dart:typed_data';

abstract class SensorRepository {
  Stream<Uint8List> get rawDataStream;

  Future<void> connect(String portName);

  Future<void> disconnect();

  Future<List<String>> getAvailablePorts();

  void dispose();
}
