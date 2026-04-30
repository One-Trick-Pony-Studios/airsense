import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:airsense/src/domain/sensor_data.dart';

class ChartExporter {
  static Future<void> exportToPng(String csvPath) async {
    // 1. Read and parse the CSV file
    final file = File(csvPath);
    if (!await file.exists()) {
      debugPrint("CSV file not found");
      return;
    }
    final lines = await file.readAsLines();
    if (lines.length < 2) {
      debugPrint("No data to export");
      return;
    }

    final List<SensorData> data = [];
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length == 3) {
        data.add(SensorData(
          timestamp: DateTime.parse(parts[0]),
          pm25: double.parse(parts[1]),
          pm10: double.parse(parts[2]),
        ));
      }
    }

    if (data.isEmpty) {
      debugPrint("No valid data parsed from CSV");
      return;
    }

    // 2. Setup for off-screen drawing
    const width = 3840.0;
    const height = 2160.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

    // 3. Draw the chart
    _drawChartOnCanvas(canvas, const Size(width, height), data);

    // 4. Convert to image and save
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Save PNG Export',
      fileName: 'chart-export.png',
      allowedExtensions: ['png'],
    );

    if (outputFile != null) {
      await File(outputFile).writeAsBytes(pngBytes);
    }
  }

  static void _drawChartOnCanvas(
      Canvas canvas, Size size, List<SensorData> data) {
    // Basic chart drawing logic. This can be made much more sophisticated.
    final paintPm25 = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintPm10 = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    final double maxVal = data.fold(0.0, (max, d) {
      final currentMax = d.pm25 > d.pm10 ? d.pm25 : d.pm10;
      return currentMax > max ? currentMax : max;
    });

    final margin = 80.0;
    final chartWidth = size.width - (2 * margin);
    final chartHeight = size.height - (2 * margin);

    // Draw grid and labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i <= 10; i++) {
      final y = margin + chartHeight - (i / 10.0) * chartHeight;
      canvas.drawLine(
          Offset(margin, y), Offset(margin + chartWidth, y), gridPaint);
      textPainter.text = TextSpan(
        text: ((i / 10.0) * maxVal).toStringAsFixed(0),
        style: const TextStyle(color: Colors.black, fontSize: 24),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(margin - textPainter.width - 10, y - textPainter.height / 2));
    }

    // Draw paths
    final pathPm25 = Path();
    final pathPm10 = Path();

    for (int i = 0; i < data.length; i++) {
      final x = margin + (i / (data.length - 1)) * chartWidth;

      final yPm25 = margin + chartHeight - (data[i].pm25 / maxVal) * chartHeight;
      if (i == 0) {
        pathPm25.moveTo(x, yPm25);
      } else {
        pathPm25.lineTo(x, yPm25);
      }

      final yPm10 = margin + chartHeight - (data[i].pm10 / maxVal) * chartHeight;
      if (i == 0) {
        pathPm10.moveTo(x, yPm10);
      } else {
        pathPm10.lineTo(x, yPm10);
      }
    }

    canvas.drawPath(pathPm25, paintPm25);
    canvas.drawPath(pathPm10, paintPm10);
  }
}
