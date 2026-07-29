import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'csv_viewer_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    final directory = await getApplicationDocumentsDirectory();
    final entities = await directory.list().toList();

    // Filter for all app log/export files and sort by newest first
    final filteredFiles = entities.where((e) {
      final name = p.basename(e.path);
      return name.startsWith('sds011-log-') ||
          name.startsWith('chart-export-') ||
          name.startsWith('dht11-log-') ||
          name.startsWith('dht-chart-export-');
    }).toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    setState(() {
      _files = filteredFiles;
      _isLoading = false;
    });
  }

  Future<void> _pickExternalCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CsvViewerScreen(filePath: result.files.single.path!),
        ),
      );
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content:
            Text('Are you sure you want to delete ${p.basename(file.path)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await file.delete();
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings & Exports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: 'Open CSV File',
            onPressed: _pickExternalCsv,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadFiles,
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.skyGradientDecoration,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No saved files found.'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickExternalCsv,
                        icon: const Icon(Icons.file_open),
                        label: const Text('Open External CSV File'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final stat = file.statSync();
                    final name = p.basename(file.path);
                    final isCsv = name.endsWith('.csv');

                    return ListTile(
                      leading: Icon(
                        isCsv ? Icons.show_chart : Icons.image,
                        color: isCsv ? Colors.blue : Colors.green,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        '${DateFormat.yMMMd().add_jm().format(stat.modified)} • ${(stat.size / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: () => SharePlus.instance.share(
                                ShareParams(files: [XFile(file.path)])),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteFile(file),
                          ),
                        ],
                      ),
                      onTap: () {
                        if (isCsv) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CsvViewerScreen(filePath: file.path),
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Image.file(File(file.path)),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
      ),
    );
  }
}
