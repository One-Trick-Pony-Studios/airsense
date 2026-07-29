import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../common/utils/chart_exporter.dart';
import '../common/utils/dht_chart_exporter.dart';
import '../domain/dht_data.dart';
import '../domain/sensor_data.dart';
import '../theme/app_theme.dart';
import 'widgets/series_chart.dart';

/// Screen that loads, parses, and plots any previously recorded CSV file,
/// allowing interactive viewing and PNG export.
class CsvViewerScreen extends StatefulWidget {
  const CsvViewerScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<CsvViewerScreen> createState() => _CsvViewerScreenState();
}

class _CsvViewerScreenState extends State<CsvViewerScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isDht = false;
  List<SensorData> _novaData = [];
  List<DhtData> _dhtData = [];
  String? _locationName;

  @override
  void initState() {
    super.initState();
    _parseCsv();
  }

  Future<void> _parseCsv() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = File(widget.filePath);
      if (!await file.exists()) {
        setState(() {
          _error = 'File does not exist.';
          _isLoading = false;
        });
        return;
      }

      final lines = await file.readAsLines();
      if (lines.isEmpty) {
        setState(() {
          _error = 'CSV file is empty.';
          _isLoading = false;
        });
        return;
      }

      final header = lines[0].toLowerCase();
      _isDht = header.contains('temperature') ||
          header.contains('humidity') ||
          header.contains('relative_humidity');

      if (_isDht) {
        final List<DhtData> list = [];
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final parts = line.split(',');
          if (parts.length >= 3) {
            final ts = DateTime.tryParse(parts[0]);
            final temp = double.tryParse(parts[1]);
            final hum = double.tryParse(parts[2]);
            if (ts != null && temp != null && hum != null) {
              final loc =
                  parts.length >= 6 && parts[5].isNotEmpty ? parts[5] : null;
              if (loc != null && _locationName == null) {
                _locationName = loc;
              }
              list.add(DhtData(
                timestamp: ts,
                temperatureCelsius: temp,
                relativeHumidity: hum,
                latitude: parts.length >= 4 ? double.tryParse(parts[3]) : null,
                longitude: parts.length >= 5 ? double.tryParse(parts[4]) : null,
                locationName: loc,
              ));
            }
          }
        }
        _dhtData = list;
      } else {
        final List<SensorData> list = [];
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final parts = line.split(',');
          if (parts.length >= 3) {
            final ts = DateTime.tryParse(parts[0]);
            final pm25 = double.tryParse(parts[1]);
            final pm10 = double.tryParse(parts[2]);
            if (ts != null && pm25 != null && pm10 != null) {
              final loc =
                  parts.length >= 6 && parts[5].isNotEmpty ? parts[5] : null;
              if (loc != null && _locationName == null) {
                _locationName = loc;
              }
              list.add(SensorData(
                timestamp: ts,
                pm25: pm25,
                pm10: pm10,
                latitude: parts.length >= 4 ? double.tryParse(parts[3]) : null,
                longitude: parts.length >= 5 ? double.tryParse(parts[4]) : null,
                locationName: loc,
              ));
            }
          }
        }
        _novaData = list;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to parse CSV: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPng() async {
    try {
      if (_isDht) {
        await DhtChartExporter.exportToPng(widget.filePath);
      } else {
        await ChartExporter.exportToPng(widget.filePath);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              ? 'Chart exported as PNG to Documents.'
              : 'Chart exported to PNG.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share CSV',
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(widget.filePath)]),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            tooltip: 'Export Plot as PNG',
            onPressed: _exportPng,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.skyGradientDecoration,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Header Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                _isDht ? Icons.thermostat : Icons.grain,
                                color: _isDht ? Colors.deepOrange : Colors.blue,
                                size: 36,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isDht
                                          ? 'DHT11 Data Log'
                                          : 'Nova PM (SDS011) Data Log',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Points: ${_isDht ? _dhtData.length : _novaData.length}'
                                      '${_locationName != null ? ' • Location: $_locationName' : ''}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _exportPng,
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Export PNG'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _isDht
                                ? SeriesChart<DhtData>(
                                    dataPoints: _dhtData,
                                    yAxisLabel: 'Temp (°C) / Humidity (%)',
                                    series: [
                                      ChartSeries<DhtData>(
                                        label: 'Temperature (°C)',
                                        color: Colors.deepOrange,
                                        valueExtractor: (d) =>
                                            d.temperatureCelsius,
                                      ),
                                      ChartSeries<DhtData>(
                                        label: 'Relative Humidity (%)',
                                        color: Colors.teal,
                                        valueExtractor: (d) =>
                                            d.relativeHumidity,
                                      ),
                                    ],
                                  )
                                : SeriesChart<SensorData>(
                                    dataPoints: _novaData,
                                    yAxisLabel: 'Particulate Matter (µg/m³)',
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
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
