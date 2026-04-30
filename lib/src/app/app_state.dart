import 'package:flutter/foundation.dart';

import '../domain/sensor_data.dart';

@immutable
class AppState {
  const AppState({
    this.currentReading,
    this.uiRingBuffer = const [],
    this.isRecording = false,
    this.activeRecordFilePath,
    this.isConnected = false,
    this.connectedPort,
  });

  final SensorData? currentReading;
  final List<SensorData> uiRingBuffer;
  final bool isRecording;
  final String? activeRecordFilePath;
  final bool isConnected;
  final String? connectedPort;

  AppState copyWith({
    SensorData? currentReading,
    List<SensorData>? uiRingBuffer,
    bool? isRecording,
    String? activeRecordFilePath,
    bool? isConnected,
    String? connectedPort,
    bool clearRecordFile = false,
    bool clearConnectedPort = false,
  }) {
    return AppState(
      currentReading: currentReading ?? this.currentReading,
      uiRingBuffer: uiRingBuffer ?? this.uiRingBuffer,
      isRecording: isRecording ?? this.isRecording,
      activeRecordFilePath: clearRecordFile ? null : activeRecordFilePath ?? this.activeRecordFilePath,
      isConnected: isConnected ?? this.isConnected,
      connectedPort: clearConnectedPort ? null : connectedPort ?? this.connectedPort,
    );
  }
}
