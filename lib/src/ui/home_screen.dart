import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import './widgets/control_panel.dart';
import './widgets/current_reading_card.dart';
import './widgets/sensor_data_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAlwaysOnTop = false;

  @override
  void initState() {
    super.initState();
    _checkAlwaysOnTop();
  }

  Future<void> _checkAlwaysOnTop() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      bool isPinned = await windowManager.isAlwaysOnTop();
      if (mounted) setState(() => _isAlwaysOnTop = isPinned);
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.setAlwaysOnTop(!_isAlwaysOnTop);
      if (mounted) setState(() => _isAlwaysOnTop = !_isAlwaysOnTop);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) 
            ? const DragToMoveArea(child: SizedBox.expand()) 
            : null,
        title: const Text('AirSense'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
            IconButton(
              icon: Icon(_isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined),
              tooltip: _isAlwaysOnTop ? 'Unpin window' : 'Pin to top',
              onPressed: _toggleAlwaysOnTop,
            ),
          if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
            IconButton(
              icon: const Icon(Icons.minimize),
              tooltip: 'Minimize',
              onPressed: () async => await windowManager.minimize(),
            ),
          if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () async => await windowManager.close(),
            ),
        ],
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
