import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/desktop_sensor_repository.dart';
import '../data/repositories/mock_sensor_repository.dart';
import '../data/repositories/mobile_sensor_repository.dart';
import '../data/repositories/sensor_repository.dart';
import '../domain/sensor_data.dart';
import '../common/utils/sds011_parser.dart';

import 'app_state.dart';

const bool useMockData = false; // Set to true to test UI without a sensor

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final SensorRepository repo;
  if (useMockData) {
    repo = MockSensorRepository();
  } else if (!kIsWeb && Platform.isAndroid) {
    repo = MobileSensorRepository();
  } else {
    repo = DesktopSensorRepository();
  }
  ref.onDispose(() => repo.dispose());
  return repo;
});

final availablePortsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(sensorRepositoryProvider).getAvailablePorts();
});

final parsedSensorStreamProvider = StreamProvider<SensorData>((ref) {
  final repository = ref.watch(sensorRepositoryProvider);
  return repository.rawDataStream.transform(Sds011Parser().transformer);
});

final sensorStateProvider =
    NotifierProvider<SensorStateNotifier, AppState>(SensorStateNotifier.new);

class SensorStateNotifier extends Notifier<AppState> {
  IOSink? _fileSink;

  @override
  AppState build() {
    ref.listen<AsyncValue<SensorData>>(parsedSensorStreamProvider,
        (previous, next) {
      if (next.hasValue && next.value != null) {
        _onNewSensorData(next.value!);
      }
    });

    ref.onDispose(() {
      _fileSink?.close();
    });

    return const AppState();
  }

  void _onNewSensorData(SensorData data) {
    final newBuffer = List<SensorData>.from(state.uiRingBuffer);
    if (newBuffer.length >= 300) {
      newBuffer.removeAt(0);
    }
    newBuffer.add(data);

    state = state.copyWith(
      currentReading: data,
      uiRingBuffer: newBuffer,
    );

    if (state.isRecording) {
      _fileSink
          ?.writeln('${data.timestamp.toIso8601String()},${data.pm25},${data.pm10}');
    }
  }

  Future<void> connect(String port) async {
    await ref.read(sensorRepositoryProvider).connect(port);
    state = state.copyWith(isConnected: true, connectedPort: port);
  }

  Future<void> disconnect() async {
    await ref.read(sensorRepositoryProvider).disconnect();
    state = state.copyWith(
      isConnected: false,
      clearConnectedPort: true,
      currentReading: null,
    );
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'sds011-log-$timestamp.csv',
      allowedExtensions: ['csv'],
    );

    if (outputFile != null) {
      try {
        final file = File(outputFile);
        _fileSink = file.openWrite();
        _fileSink?.writeln('timestamp,pm25,pm10'); // Write header
        state =
            state.copyWith(isRecording: true, activeRecordFilePath: outputFile);
      } catch (e) {
        debugPrint('Error starting recording: $e');
        // Optionally, show an error to the user
      }
    }
  }

  Future<void> _stopRecording() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
    state = state.copyWith(isRecording: false);
  }
}
