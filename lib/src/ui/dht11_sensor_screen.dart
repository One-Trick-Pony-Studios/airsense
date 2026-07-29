import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/dht_providers.dart';
import '../app/dht_app_state.dart';
import '../common/utils/dht_chart_exporter.dart';
import '../domain/dht_data.dart';
import 'widgets/reading_card.dart';
import 'widgets/sensor_control_panel.dart';
import 'widgets/series_chart.dart';

/// Full-screen content for the DHT11 temperature / humidity sensor
/// connected via an ESP01 module over OTG USB serial.
class Dht11SensorScreen extends ConsumerWidget {
  const Dht11SensorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dhtState = ref.watch(dhtStateProvider);
    final notifier = ref.read(dhtStateProvider.notifier);
    final portsAsync = ref.watch(dhtAvailablePortsProvider);

    final config = ControlPanelConfig(
      isConnected: dhtState.isConnected,
      connectedPort: dhtState.connectedPort,
      isRecording: dhtState.isRecording,
      activeRecordFilePath: dhtState.activeRecordFilePath,
      locationEnabled: dhtState.locationEnabled,
      errorMessage: dhtState.errorMessage,
      availablePortsAsync: portsAsync,
      selectedBaudRate: dhtState.selectedBaudRate,
      onConnect: notifier.connect,
      onDisconnect: notifier.disconnect,
      onToggleLocation: notifier.toggleLocation,
      onToggleRecording: notifier.toggleRecording,
      onRefreshPorts: () => ref.invalidate(dhtAvailablePortsProvider),
      onBaudRateChanged: notifier.setBaudRate,
      onExportChart: () async {
        if (dhtState.activeRecordFilePath != null) {
          await DhtChartExporter.exportToPng(dhtState.activeRecordFilePath!);
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: SensorControlPanel(config: config),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _DhtReadings(state: dhtState),
                    ),
                    Expanded(child: _DhtChart()),
                  ],
                ),
              ),
            ],
          );
        } else {
          return ListView(
            children: [
              SensorControlPanel(config: config),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _DhtReadings(state: dhtState),
              ),
              SizedBox(height: 300, child: _DhtChart()),
            ],
          );
        }
      },
    );
  }
}

/// Current reading cards for temperature and relative humidity.
class _DhtReadings extends StatelessWidget {
  const _DhtReadings({required this.state});
  final DhtAppState state;

  @override
  Widget build(BuildContext context) {
    final reading = state.currentReading;
    final temp = reading?.temperatureCelsius ?? 0.0;
    final hum = reading?.relativeHumidity ?? 0.0;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        ReadingCard(
          title: 'Temperature',
          value: temp,
          unit: '°C',
          color: _temperatureColor(temp),
        ),
        ReadingCard(
          title: 'Humidity',
          value: hum,
          unit: '% RH',
          color: _humidityColor(hum),
        ),
      ],
    );
  }

  Color _temperatureColor(double t) {
    if (t < 18) return Colors.blue;
    if (t < 25) return Colors.green;
    if (t < 32) return Colors.orange;
    return Colors.red;
  }

  Color _humidityColor(double h) {
    if (h < 30) return Colors.orange;
    if (h <= 60) return Colors.teal;
    return Colors.blue;
  }
}

class _DhtChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataPoints =
        ref.watch(dhtStateProvider.select((s) => s.uiRingBuffer));

    return SeriesChart<DhtData>(
      dataPoints: dataPoints,
      series: [
        ChartSeries<DhtData>(
          label: 'Temperature (°C)',
          color: Colors.deepOrange,
          valueExtractor: (d) => d.temperatureCelsius,
        ),
        ChartSeries<DhtData>(
          label: 'Humidity (%)',
          color: Colors.teal,
          valueExtractor: (d) => d.relativeHumidity,
        ),
      ],
      minY: 0,
    );
  }
}
