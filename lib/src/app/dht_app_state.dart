import 'package:flutter/foundation.dart';

import '../domain/dht_data.dart';

@immutable
class DhtAppState {
  const DhtAppState({
    this.currentReading,
    this.uiRingBuffer = const [],
    this.isRecording = false,
    this.activeRecordFilePath,
    this.isConnected = false,
    this.connectedPort,
    this.errorMessage,
    this.locationEnabled = false,
    this.recordingLat,
    this.recordingLon,
    this.recordingLocationName,
    this.selectedBaudRate = 115200,
  });

  final DhtData? currentReading;
  final List<DhtData> uiRingBuffer;
  final bool isRecording;
  final String? activeRecordFilePath;
  final bool isConnected;
  final String? connectedPort;
  final String? errorMessage;
  final bool locationEnabled;
  final double? recordingLat;
  final double? recordingLon;
  final String? recordingLocationName;
  final int selectedBaudRate;

  DhtAppState copyWith({
    DhtData? currentReading,
    List<DhtData>? uiRingBuffer,
    bool? isRecording,
    String? activeRecordFilePath,
    bool? isConnected,
    String? connectedPort,
    String? errorMessage,
    bool? locationEnabled,
    double? recordingLat,
    double? recordingLon,
    String? recordingLocationName,
    int? selectedBaudRate,
    bool clearRecordFile = false,
    bool clearConnectedPort = false,
    bool clearError = false,
    bool clearRecordingLocation = false,
  }) {
    return DhtAppState(
      currentReading: currentReading ?? this.currentReading,
      uiRingBuffer: uiRingBuffer ?? this.uiRingBuffer,
      isRecording: isRecording ?? this.isRecording,
      activeRecordFilePath: clearRecordFile
          ? null
          : activeRecordFilePath ?? this.activeRecordFilePath,
      isConnected: isConnected ?? this.isConnected,
      connectedPort:
          clearConnectedPort ? null : connectedPort ?? this.connectedPort,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      recordingLat:
          clearRecordingLocation ? null : recordingLat ?? this.recordingLat,
      recordingLon:
          clearRecordingLocation ? null : recordingLon ?? this.recordingLon,
      recordingLocationName: clearRecordingLocation
          ? null
          : recordingLocationName ?? this.recordingLocationName,
      selectedBaudRate: selectedBaudRate ?? this.selectedBaudRate,
    );
  }
}
