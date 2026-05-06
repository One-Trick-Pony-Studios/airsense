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
  bool _isAlwaysOnBottom = true;

  @override
  void initState() {
    super.initState();
    _checkAlwaysOnBottom();
  }

  Future<void> _checkAlwaysOnBottom() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      bool isPinned = await windowManager.isAlwaysOnBottom();
      if (mounted) setState(() => _isAlwaysOnBottom = isPinned);
    }
  }

  Future<void> _toggleAlwaysOnBottom() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      bool nextState = !_isAlwaysOnBottom;
      await windowManager.setAlwaysOnBottom(nextState);
      await windowManager.setSkipTaskbar(nextState); // Bring back to taskbar when detached!
      if (mounted) setState(() => _isAlwaysOnBottom = nextState);
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
              icon: Icon(_isAlwaysOnBottom ? Icons.layers_clear : Icons.layers),
              tooltip: _isAlwaysOnBottom ? 'Detach from desktop' : 'Pin to desktop',
              onPressed: _toggleAlwaysOnBottom,
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
