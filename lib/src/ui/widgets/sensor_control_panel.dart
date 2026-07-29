import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:share_plus/share_plus.dart';

/// Common baud rates available in the dropdown.
const List<int> kSupportedBaudRates = [
  300,
  1200,
  2400,
  4800,
  9600,
  19200,
  38400,
  57600,
  115200,
  230400,
  460800,
  921600,
];

/// Configuration that the sensor-specific screens pass down to [SensorControlPanel].
class ControlPanelConfig {
  const ControlPanelConfig({
    required this.isConnected,
    required this.connectedPort,
    required this.isRecording,
    required this.activeRecordFilePath,
    required this.locationEnabled,
    required this.errorMessage,
    required this.availablePortsAsync,
    required this.selectedBaudRate,
    required this.onConnect,
    required this.onDisconnect,
    required this.onToggleLocation,
    required this.onToggleRecording,
    required this.onRefreshPorts,
    required this.onBaudRateChanged,
    required this.onExportChart,
  });

  final bool isConnected;
  final String? connectedPort;
  final bool isRecording;
  final String? activeRecordFilePath;
  final bool locationEnabled;
  final String? errorMessage;
  final AsyncValue<List<String>> availablePortsAsync;
  final int selectedBaudRate;
  final void Function(String port) onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onToggleLocation;
  final VoidCallback onToggleRecording;
  final VoidCallback onRefreshPorts;
  final void Function(int baudRate) onBaudRateChanged;
  final Future<void> Function() onExportChart;
}

/// A reusable control panel card that works for any sensor type.
/// Sensor-specific screens build a [ControlPanelConfig] and pass it here.
class SensorControlPanel extends StatelessWidget {
  const SensorControlPanel({super.key, required this.config});

  final ControlPanelConfig config;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controls', style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            const SizedBox(height: 4),

            // ── Connection status indicator ──────────────────────────────
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: config.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(config.isConnected ? 'Connected' : 'Disconnected'),
              ],
            ),
            const SizedBox(height: 12),

            // ── Port selector + refresh ──────────────────────────────────
            Text('Port', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    hint: const Text('Select Port'),
                    value: config.isConnected ? config.connectedPort : null,
                    isExpanded: true,
                    items: config.availablePortsAsync.maybeWhen(
                      data: (ports) {
                        final list = ports.toList();
                        if (config.connectedPort != null &&
                            !list.contains(config.connectedPort)) {
                          list.add(config.connectedPort!);
                        }
                        return list
                            .map((v) => DropdownMenuItem<String>(
                                value: v, child: Text(v)))
                            .toList();
                      },
                      orElse: () {
                        if (config.connectedPort != null) {
                          return [
                            DropdownMenuItem(
                                value: config.connectedPort,
                                child: Text(config.connectedPort!))
                          ];
                        }
                        return [];
                      },
                    ),
                    onChanged: config.isConnected
                        ? null
                        : (port) {
                            if (port != null) config.onConnect(port);
                          },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: config.onRefreshPorts,
                  tooltip: 'Refresh Ports',
                ),
              ],
            ),

            // ── Baud rate selector ───────────────────────────────────────
            const SizedBox(height: 8),
            Text('Baud Rate', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            DropdownButton<int>(
              value: kSupportedBaudRates.contains(config.selectedBaudRate)
                  ? config.selectedBaudRate
                  : kSupportedBaudRates.first,
              isExpanded: true,
              // Disable while connected — baud rate must be set before connect
              onChanged: config.isConnected
                  ? null
                  : (rate) {
                      if (rate != null) config.onBaudRateChanged(rate);
                    },
              items: kSupportedBaudRates
                  .map((r) => DropdownMenuItem<int>(
                        value: r,
                        child: Text('$r bps'),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: config.isConnected ? config.onDisconnect : null,
              child: const Text('Disconnect'),
            ),
            const SizedBox(height: 16),
            const Divider(),

            // ── Location + recording ─────────────────────────────────────
            SwitchListTile(
              title: const Text('Track Location'),
              subtitle: const Text('Adds GPS coords to data'),
              value: config.locationEnabled,
              onChanged: (_) => config.onToggleLocation(),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed:
                  !config.isConnected ? null : config.onToggleRecording,
              icon: Icon(config.isRecording ? Icons.stop : Icons.circle),
              label: Text(
                  config.isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.isRecording ? Colors.red : null,
                foregroundColor: config.isRecording ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: config.isRecording ||
                      config.activeRecordFilePath == null
                  ? null
                  : () async {
                      await config.onExportChart();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (!kIsWeb &&
                                    (Platform.isAndroid || Platform.isIOS))
                                ? 'Chart generated. Use Share to export.'
                                : 'Chart exported to PNG.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.image),
              label: const Text('Export Plot as PNG'),
            ),
            if (!kIsWeb &&
                (Platform.isAndroid || Platform.isIOS) &&
                config.activeRecordFilePath != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: config.isRecording
                    ? null
                    : () async {
                        final filePath = config.activeRecordFilePath!;
                        final file = File(filePath);
                        if (await file.exists()) {
                          await SharePlus.instance.share(ShareParams(
                              files: [XFile(filePath)],
                              text: 'AirSense Data Export'));
                        }
                      },
                icon: const Icon(Icons.share),
                label: const Text('Share and Export'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
