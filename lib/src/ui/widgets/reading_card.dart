import 'package:flutter/material.dart';

/// A card that displays a single labelled numeric reading.
///
/// The card is intentionally generic — it takes a [value], [title], [unit],
/// and an optional [color] so it can be used for PM2.5, PM10, temperature,
/// humidity, or any other scalar reading.
class ReadingCard extends StatelessWidget {
  const ReadingCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.color,
  });

  final String title;
  final double value;

  /// Optional unit label shown below the value (e.g. 'µg/m³', '°C', '%').
  final String? unit;

  /// Accent colour for the value text. Falls back to the primary theme colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final valueColor = color ?? Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      child: Container(
        width: 150,
        height: 110,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: valueColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (unit != null)
              Text(
                unit!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
