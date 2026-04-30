import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airsense/src/app/providers.dart';
import 'package:airsense/src/common/utils/chart_exporter.dart';

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePorts = ref.watch(availablePortsProvider);
    final appState = ref.watch(sensorStateProvider);
    final notifier = ref.read(sensorStateProvider.notifier);

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
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: appState.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(appState.isConnected ? 'Connected' : 'Disconnected'),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              hint: const Text('Select Port'),
              value: appState.isConnected ? appState.connectedPort : null,
              isExpanded: true,
              items: availablePorts.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: appState.isConnected
                  ? null
                  : (port) {
                      if (port != null) {
                        notifier.connect(port);
                      }
                    },
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: appState.isConnected ? notifier.disconnect : null,
              child: const Text('Disconnect'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ElevatedButton.icon(
              onPressed: !appState.isConnected ? null : notifier.toggleRecording,
              icon: Icon(appState.isRecording ? Icons.stop : Icons.circle),
              label:
                  Text(appState.isRecording ? 'Stop Recording' : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: appState.isRecording ? Colors.red : null,
                foregroundColor: appState.isRecording ? Colors.white : null,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed:
                  appState.isRecording || appState.activeRecordFilePath == null
                      ? null
                      : () async {
                          await ChartExporter.exportToPng(
                              appState.activeRecordFilePath!);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Chart exported to PNG.')),
                          );
                        },
              icon: const Icon(Icons.image),
              label: const Text('Export Plot as PNG'),
            ),
          ],
        ),
      ),
    );
  }
}
