import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/app_state.dart';
import '../common/utils/aqi_color.dart';
import '../common/utils/chart_exporter.dart';
import '../domain/sensor_data.dart';
import 'widgets/reading_card.dart';
import 'widgets/sensor_control_panel.dart';
import 'widgets/series_chart.dart';

/// Full-screen content for the Nova PM (SDS011) sensor.
class NovaSensorScreen extends ConsumerWidget {
  const NovaSensorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(sensorStateProvider);
    final notifier = ref.read(sensorStateProvider.notifier);
    final portsAsync = ref.watch(availablePortsProvider);

    final config = ControlPanelConfig(
      isConnected: appState.isConnected,
      connectedPort: appState.connectedPort,
      isRecording: appState.isRecording,
      activeRecordFilePath: appState.activeRecordFilePath,
      locationEnabled: appState.locationEnabled,
      errorMessage: appState.errorMessage,
      availablePortsAsync: portsAsync,
      selectedBaudRate: appState.selectedBaudRate,
      onConnect: notifier.connect,
      onDisconnect: notifier.disconnect,
      onToggleLocation: notifier.toggleLocation,
      onToggleRecording: notifier.toggleRecording,
      onRefreshPorts: () => ref.invalidate(availablePortsProvider),
      onBaudRateChanged: notifier.setBaudRate,
      onExportChart: () async {
        if (appState.activeRecordFilePath != null) {
          await ChartExporter.exportToPng(appState.activeRecordFilePath!);
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
                      child: _NovaReadings(state: appState),
                    ),
                    Expanded(child: _NovaSensorChart()),
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
                child: _NovaReadings(state: appState),
              ),
              SizedBox(height: 300, child: _NovaSensorChart()),
            ],
          );
        }
      },
    );
  }
}

class _NovaReadings extends StatelessWidget {
  const _NovaReadings({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final reading = state.currentReading;
    final pm25 = reading?.pm25 ?? 0.0;
    final pm10 = reading?.pm10 ?? 0.0;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        ReadingCard(
          title: 'PM2.5',
          value: pm25,
          unit: 'µg/m³',
          color: getAqiColor(pm25),
        ),
        ReadingCard(
          title: 'PM10',
          value: pm10,
          unit: 'µg/m³',
          color: getAqiColor(pm10),
        ),
      ],
    );
  }
}

class _NovaSensorChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataPoints =
        ref.watch(sensorStateProvider.select((s) => s.uiRingBuffer));

    return SeriesChart<SensorData>(
      dataPoints: dataPoints,
      yAxisLabel: 'µg/m³',
      series: [
        ChartSeries<SensorData>(
          label: 'PM2.5',
          color: Colors.blue,
          valueExtractor: (d) => d.pm25,
        ),
        ChartSeries<SensorData>(
          label: 'PM10',
          color: Colors.red,
          valueExtractor: (d) => d.pm10,
        ),
      ],
    );
  }
}
