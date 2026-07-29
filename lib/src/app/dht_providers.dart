import 'dart:async';
import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../data/repositories/desktop_sensor_repository.dart';
import '../data/repositories/mock_dht11_sensor_repository.dart';
import '../data/repositories/mobile_sensor_repository.dart';
import '../data/repositories/sensor_repository.dart';
import '../domain/dht_data.dart';
import '../common/utils/dht11_parser.dart';

import 'dht_app_state.dart';

// Set to true to use mock DHT11 data during development
const bool useDhtMockData = false;

final dhtSensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final SensorRepository repo;
  if (useDhtMockData) {
    repo = MockDht11SensorRepository();
  } else if (!kIsWeb && Platform.isAndroid) {
    // Re-use the same underlying USB-serial infrastructure; the parser
    // is what differentiates the two devices.
    repo = MobileSensorRepository();
  } else {
    repo = DesktopSensorRepository();
  }
  ref.onDispose(() => repo.dispose());
  return repo;
});

final dhtAvailablePortsProvider = FutureProvider<List<String>>((ref) async {
  return ref.watch(dhtSensorRepositoryProvider).getAvailablePorts();
});

final parsedDhtStreamProvider = StreamProvider<DhtData>((ref) {
  final repository = ref.watch(dhtSensorRepositoryProvider);
  return repository.rawDataStream.transform(Dht11Parser().transformer);
});

final dhtStateProvider =
    NotifierProvider<DhtStateNotifier, DhtAppState>(DhtStateNotifier.new);

class DhtStateNotifier extends Notifier<DhtAppState> {
  IOSink? _fileSink;

  @override
  DhtAppState build() {
    ref.listen<AsyncValue<DhtData>>(parsedDhtStreamProvider,
        (previous, next) async {
      if (next.hasValue && next.value != null) {
        await _onNewSensorData(next.value!);
      }
    });

    ref.onDispose(() {
      _fileSink?.close();
    });

    return const DhtAppState();
  }

  Future<void> _onNewSensorData(DhtData data) async {
    DhtData updatedData = data;
    if (state.isRecording &&
        state.recordingLat != null &&
        state.recordingLon != null) {
      updatedData = DhtData(
        temperatureCelsius: data.temperatureCelsius,
        relativeHumidity: data.relativeHumidity,
        timestamp: data.timestamp,
        latitude: state.recordingLat,
        longitude: state.recordingLon,
        locationName: state.recordingLocationName,
      );
    }

    final newBuffer = List<DhtData>.from(state.uiRingBuffer);
    if (newBuffer.length >= 300) {
      newBuffer.removeAt(0);
    }
    newBuffer.add(updatedData);

    state = state.copyWith(
      currentReading: updatedData,
      uiRingBuffer: newBuffer,
    );

    if (state.isRecording) {
      final lat = updatedData.latitude?.toString() ?? '';
      final lon = updatedData.longitude?.toString() ?? '';
      final loc = updatedData.locationName ?? '';
      _fileSink?.writeln(
          '${updatedData.timestamp.toIso8601String()},${updatedData.temperatureCelsius},${updatedData.relativeHumidity},$lat,$lon,$loc');
    }
  }

  Future<void> connect(String port) async {
    state = state.copyWith(clearError: true);
    try {
      await ref
          .read(dhtSensorRepositoryProvider)
          .connect(port, baudRate: state.selectedBaudRate);
      state = state.copyWith(isConnected: true, connectedPort: port);
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    await ref.read(dhtSensorRepositoryProvider).disconnect();
    state = state.copyWith(
      isConnected: false,
      clearConnectedPort: true,
      currentReading: null,
      clearError: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void setBaudRate(int baudRate) {
    if (!state.isConnected) {
      state = state.copyWith(selectedBaudRate: baudRate);
    }
  }

  Future<void> toggleLocation() async {
    if (state.locationEnabled) {
      state = state.copyWith(locationEnabled: false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(errorMessage: 'Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
          errorMessage:
              'Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    state = state.copyWith(locationEnabled: true, clearError: true);
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
    final fileName = 'dht11-log-$timestamp.csv';

    // Always write to the app documents directory; users export via the
    // History screen. (file_picker 12 requires bytes at save time, which is
    // incompatible with streaming IOSink writes.)
    final directory = await getApplicationDocumentsDirectory();
    final outputFile = p.join(directory.path, fileName);

    double? lat;
    double? lon;
    String? locationName;

    if (state.locationEnabled) {
      try {
        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ));
        lat = position.latitude;
        lon = position.longitude;

        try {
          final placemarks = await Geocoding()
              .placemarkFromCoordinates(lat, lon)
              .timeout(const Duration(seconds: 3));
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final addressParts = <String>[];
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              addressParts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              if (!addressParts.contains(place.locality)) {
                addressParts.add(place.locality!);
              }
            }
            locationName = addressParts.isEmpty
                ? place.street ?? 'Unknown Location'
                : addressParts.join(', ');
          }
        } catch (e) {
          debugPrint('Error reverse geocoding: $e');
          locationName = 'Unknown Location';
        }
      } catch (e) {
        debugPrint('Error getting starting location: $e');
      }
    }

    try {
      final file = File(outputFile);
      _fileSink = file.openWrite();
      _fileSink?.writeln(
          'timestamp,temperature_c,relative_humidity,latitude,longitude,location_name');
      state = state.copyWith(
        isRecording: true,
        activeRecordFilePath: outputFile,
        recordingLat: lat,
        recordingLon: lon,
        recordingLocationName: locationName,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create file: $e',
        isRecording: false,
      );
    }
  }

  Future<void> _stopRecording() async {
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;
    state = state.copyWith(
      isRecording: false,
      clearRecordingLocation: true,
    );
  }
}
