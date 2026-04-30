import 'package:flutter/material.dart';
import './widgets/control_panel.dart';
import './widgets/current_reading_card.dart';
import './widgets/sensor_data_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AirSense'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              // Wide layout
              return const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ControlPanel(),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        CurrentReadings(),
                        Expanded(child: SensorDataChart()),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Narrow layout
              return const Column(
                children: [
                  ControlPanel(),
                  CurrentReadings(),
                  Expanded(child: SensorDataChart()),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class CurrentReadings extends StatelessWidget {
  const CurrentReadings({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        CurrentReadingCard(
          title: 'PM2.5',
          isPm25: true,
        ),
        CurrentReadingCard(
          title: 'PM10',
          isPm25: false,
        ),
      ],
    );
  }
}
