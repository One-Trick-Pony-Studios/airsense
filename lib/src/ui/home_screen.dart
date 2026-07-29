import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../app/providers.dart';
import '../app/dht_providers.dart';
import '../domain/device_type.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'nova_sensor_screen.dart';
import 'dht11_sensor_screen.dart';

/// Provider that holds the currently selected device type.
/// Lives at the UI layer since it's purely a navigation/display concern.
final selectedDeviceProvider =
    NotifierProvider<_SelectedDeviceNotifier, DeviceType?>(
        _SelectedDeviceNotifier.new);

class _SelectedDeviceNotifier extends Notifier<DeviceType?> {
  @override
  DeviceType? build() => null;

  void select(DeviceType device) => state = device;
  void clear() => state = null;
}

/// Root shell that shows the welcome/device-selector and hosts the
/// per-device sensor screens inside a consistent AppBar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isAlwaysOnBottom = true;

  @override
  void initState() {
    super.initState();
    _checkAlwaysOnBottom();
  }

  Future<void> _checkAlwaysOnBottom() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final isPinned = await windowManager.isAlwaysOnBottom();
      if (mounted) setState(() => _isAlwaysOnBottom = isPinned);
    }
  }

  Future<void> _toggleAlwaysOnBottom() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final next = !_isAlwaysOnBottom;
      await windowManager.setAlwaysOnBottom(next);
      await windowManager.setSkipTaskbar(next);
      if (mounted) setState(() => _isAlwaysOnBottom = next);
    }
  }

  /// Implicitly disconnects the active COM port and clears device selection.
  void _navigateBackToWelcome(WidgetRef ref, DeviceType currentDevice) {
    if (currentDevice == DeviceType.nova) {
      ref.read(sensorStateProvider.notifier).disconnect();
    } else if (currentDevice == DeviceType.dht11) {
      ref.read(dhtStateProvider.notifier).disconnect();
    }
    ref.read(selectedDeviceProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDevice = ref.watch(selectedDeviceProvider);

    // Watch error messages from whichever sensor is active
    final novaError =
        ref.watch(sensorStateProvider.select((s) => s.errorMessage));
    final dhtError =
        ref.watch(dhtStateProvider.select((s) => s.errorMessage));
    final errorMessage =
        selectedDevice == DeviceType.dht11 ? dhtError : novaError;

    return PopScope(
      canPop: selectedDevice == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && selectedDevice != null) {
          _navigateBackToWelcome(ref, selectedDevice);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: selectedDevice != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Menu',
                  onPressed: () =>
                      _navigateBackToWelcome(ref, selectedDevice),
                )
              : null,
          flexibleSpace: (!kIsWeb &&
                  (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
              ? const DragToMoveArea(child: SizedBox.expand())
              : null,
          title: Text(
            selectedDevice == null ? 'AirSense' : selectedDevice.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Recordings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
            ),
            if (!kIsWeb &&
                (Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isMacOS)) ...[
              IconButton(
                icon: Icon(
                    _isAlwaysOnBottom ? Icons.layers_clear : Icons.layers),
                tooltip: _isAlwaysOnBottom
                    ? 'Detach from desktop'
                    : 'Pin to desktop',
                onPressed: _toggleAlwaysOnBottom,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () async => await windowManager.close(),
              ),
            ],
          ],
        ),
        body: Container(
          decoration: AppTheme.skyGradientDecoration,
          child: Column(
            children: [
            if (errorMessage != null)
              MaterialBanner(
                content: Text(errorMessage),
                backgroundColor:
                    Theme.of(context).colorScheme.errorContainer,
                actions: [
                  TextButton(
                    onPressed: () {
                      if (selectedDevice == DeviceType.dht11) {
                        ref.read(dhtStateProvider.notifier).clearError();
                      } else {
                        ref.read(sensorStateProvider.notifier).clearError();
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: selectedDevice == null
                    ? const _WelcomeView()
                    : selectedDevice == DeviceType.nova
                        ? const NovaSensorScreen()
                        : const Dht11SensorScreen(),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

/// Welcome / landing screen shown before a device type is chosen.
class _WelcomeView extends ConsumerWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Container(
              width: 130,
              height: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primary.withValues(alpha: 0.6),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.35),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'airsense_reduced.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.air,
                    size: 64,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── App name + tagline ─────────────────────────────────────────
            Text(
              'AirSense',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Environmental monitoring at your fingertips',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),

            // ── Device selector ────────────────────────────────────────────
            Text(
              'Select connected device',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _DeviceCard(
              device: DeviceType.nova,
              icon: Icons.grain,
              description: 'Nova PM (SDS011) — PM2.5 & PM10 particulate matter',
              accentColor: Colors.blue,
              onTap: () => ref
                  .read(selectedDeviceProvider.notifier)
                  .select(DeviceType.nova),
            ),
            const SizedBox(height: 12),
            _DeviceCard(
              device: DeviceType.dht11,
              icon: Icons.thermostat,
              description:
                  'DHT11 via ESP01 — Temperature & relative humidity',
              accentColor: Colors.deepOrange,
              onTap: () => ref
                  .read(selectedDeviceProvider.notifier)
                  .select(DeviceType.dht11),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.icon,
    required this.description,
    required this.accentColor,
    required this.onTap,
  });

  final DeviceType device;
  final IconData icon;
  final String description;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
