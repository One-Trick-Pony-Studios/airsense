import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:airsense/src/domain/dht_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Exports DHT11 temperature / humidity data as a PNG chart.
class DhtChartExporter {
  static Future<void> exportToPng(String csvPath) async {
    final file = File(csvPath);
    if (!await file.exists()) {
      debugPrint('CSV file not found');
      return;
    }
    final lines = await file.readAsLines();
    if (lines.length < 2) {
      debugPrint('No data to export');
      return;
    }

    final List<DhtData> data = [];
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length >= 3) {
        data.add(DhtData(
          timestamp: DateTime.parse(parts[0]),
          temperatureCelsius: double.parse(parts[1]),
          relativeHumidity: double.parse(parts[2]),
          latitude: parts.length >= 4 && parts[3].isNotEmpty
              ? double.tryParse(parts[3])
              : null,
          longitude: parts.length >= 5 && parts[4].isNotEmpty
              ? double.tryParse(parts[4])
              : null,
          locationName:
              parts.length >= 6 && parts[5].isNotEmpty ? parts[5] : null,
        ));
      }
    }

    if (data.isEmpty) {
      debugPrint('No valid data parsed from CSV');
      return;
    }

    const width = 3840.0;
    const height = 2160.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

    _drawDhtChartOnCanvas(canvas, const Size(width, height), data);

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final fileName = 'dht-chart-export-${DateTime.now().millisecondsSinceEpoch}.png';

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final directory = await getApplicationDocumentsDirectory();
      final outputFile = p.join(directory.path, fileName);
      await File(outputFile).writeAsBytes(pngBytes);
    } else {
      await FilePicker.saveFile(
        dialogTitle: 'Save DHT11 Chart PNG',
        fileName: fileName,
        allowedExtensions: ['png'],
        bytes: pngBytes,
      );
    }
  }


  static void _drawDhtChartOnCanvas(
      Canvas canvas, Size size, List<DhtData> data) {
    final paintTemp = Paint()
      ..color = Colors.deepOrange
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintHum = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    final double maxTemp =
        data.fold(0.0, (m, d) => d.temperatureCelsius > m ? d.temperatureCelsius : m);
    final double maxHum =
        data.fold(0.0, (m, d) => d.relativeHumidity > m ? d.relativeHumidity : m);
    // Use the larger of the two for a shared Y axis
    final double maxVal = (maxTemp > maxHum ? maxTemp : maxHum) * 1.1;

    final margin = 120.0;
    final chartWidth = size.width - (2 * margin);
    final chartHeight = size.height - (2 * margin);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid + Y labels
    for (int i = 0; i <= 10; i++) {
      final y = margin + chartHeight - (i / 10.0) * chartHeight;
      canvas.drawLine(
          Offset(margin, y), Offset(margin + chartWidth, y), gridPaint);
      textPainter.text = TextSpan(
        text: ((i / 10.0) * maxVal).toStringAsFixed(0),
        style: const TextStyle(color: Colors.black, fontSize: 32),
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(margin - textPainter.width - 20, y - textPainter.height / 2));
    }

    // X labels
    const labelCount = 10;
    for (int i = 0; i < labelCount; i++) {
      final dataIndex = (i * (data.length - 1) / (labelCount - 1)).round();
      if (dataIndex >= data.length) continue;
      final x = margin + (dataIndex / (data.length - 1)) * chartWidth;
      final ts = data[dataIndex].timestamp;
      final timeStr =
          '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
      textPainter.text = TextSpan(
          text: timeStr,
          style: const TextStyle(color: Colors.black, fontSize: 24));
      textPainter.layout();
      canvas.save();
      canvas.translate(x, margin + chartHeight + 20);
      canvas.rotate(1.5708);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Paths
    final pathTemp = Path();
    final pathHum = Path();
    for (int i = 0; i < data.length; i++) {
      final x = margin + (i / (data.length - 1)) * chartWidth;
      final yTemp =
          margin + chartHeight - (data[i].temperatureCelsius / maxVal) * chartHeight;
      final yHum =
          margin + chartHeight - (data[i].relativeHumidity / maxVal) * chartHeight;
      if (i == 0) {
        pathTemp.moveTo(x, yTemp);
        pathHum.moveTo(x, yHum);
      } else {
        pathTemp.lineTo(x, yTemp);
        pathHum.lineTo(x, yHum);
      }
    }
    canvas.drawPath(pathTemp, paintTemp);
    canvas.drawPath(pathHum, paintHum);

    // Legend
    _drawLegend(canvas, margin, margin, textPainter);
  }

  static void _drawLegend(
      Canvas canvas, double left, double top, TextPainter tp) {
    const legendOffset = 50.0;
    const boxSize = 30.0;
    const spacing = 200.0;

    final paintTemp = Paint()..color = Colors.deepOrange;
    canvas.drawRect(
        Rect.fromLTWH(left + 20, top - legendOffset, boxSize, boxSize),
        paintTemp);
    tp.text = const TextSpan(
        text: 'Temperature (°C)',
        style: TextStyle(color: Colors.black, fontSize: 32));
    tp.layout();
    tp.paint(canvas, Offset(left + 20 + boxSize + 10, top - legendOffset));

    final paintHum = Paint()..color = Colors.teal;
    canvas.drawRect(
        Rect.fromLTWH(
            left + 20 + spacing, top - legendOffset, boxSize, boxSize),
        paintHum);
    tp.text = const TextSpan(
        text: 'Relative Humidity (%)',
        style: TextStyle(color: Colors.black, fontSize: 32));
    tp.layout();
    tp.paint(canvas,
        Offset(left + 20 + spacing + boxSize + 10, top - legendOffset));
  }
}
