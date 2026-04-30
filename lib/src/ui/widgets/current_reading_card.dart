import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:airsense/src/app/providers.dart';
import 'package:airsense/src/common/utils/aqi_color.dart';

class CurrentReadingCard extends ConsumerWidget {
  const CurrentReadingCard({
    super.key,
    required this.title,
    required this.isPm25,
  });

  final String title;
  final bool isPm25;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(sensorStateProvider.select((s) => s.currentReading));
    final value = reading == null ? 0.0 : (isPm25 ? reading.pm25 : reading.pm10);
    final color = getAqiColor(value);

    return Card(
      elevation: 2,
      child: Container(
        width: 150,
        height: 100,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(1),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
