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
                  SizedBox(
                    width: 320, // Constrain width so it doesn't expand infinitely
                    child: SingleChildScrollView(child: ControlPanel()),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: CurrentReadings(),
                        ),
                        Expanded(child: SensorDataChart()),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Narrow layout
              return ListView(
                children: [
                  ControlPanel(),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: CurrentReadings(),
                  ),
                  SizedBox(height: 300, child: SensorDataChart()),
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
