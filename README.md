# AirSense

AirSense is a cross-platform Flutter application designed to read, display, and record particulate matter (PM2.5 and PM10) data from a **Nova PM Sensor (SDS011)** via a USB-to-TTL serial connection.

It currently supports **Linux**, **Windows**, and **Android (via USB-OTG)**.

## Features

* **Real-Time Dashboard:** View live PM2.5 and PM10 readings with contextual AQI coloring (Green, Yellow, Orange, Red).
* **Live Charting:** Dynamic line charts that automatically scale based on the recent 5-minute data history.
* **CSV Data Logging:** Record live sensor data straight to disk in a standard CSV format.
* **High-Res PNG Export:** Generate 4K resolution off-screen PNG plots from recorded CSV sessions.
* **Cross-Platform Serial:** Uses `flutter_libserialport` for Desktop (Windows/Linux) and `usb_serial` for Mobile (Android).
* **Mock Mode:** Built-in mock data generator for UI testing without the physical sensor.

## Hardware Requirements

* Nova PM Sensor (SDS011)
* USB-to-TTL Serial Adapter (usually included with the sensor)
* USB-OTG adapter (if using on an Android device)

## Getting Started

### 1. Prerequisites
Ensure you have the Flutter SDK installed.

If you are building for **Linux**, you need the C++ build toolchain and GTK development headers:
```bash
sudo apt-get update
sudo apt-get install build-essential cmake ninja-build pkg-config libgtk-3-dev
```

### 2. Testing with Mock Data
Before plugging in the hardware, you can test the UI using the built-in mock repository.
1. Open `lib/src/app/providers.dart`.
2. Ensure `const bool useMockData = true;` is set.
3. Run the app: `flutter run -d windows` (or `linux`, `chrome`, etc.)

### 3. Running with the Real Sensor
1. Connect the SDS011 sensor to your computer or Android device.
2. Open `lib/src/app/providers.dart` and change the flag to `const bool useMockData = false;`.
3. Run the app on your target platform.
4. Select the correct COM port (e.g., `COM3`, `/dev/ttyUSB0`) from the dropdown and click **Connect**.

## Building for Production

To create distributable packages for your respective platforms, use the following Flutter commands:

### Windows
```bash
flutter build windows
```
The executable will be located in `build\windows\runner\Release\`.

### Linux
```bash
flutter build linux
```
The executable bundle will be located in `build/linux/x64/release/bundle/`.

### Android
```bash
flutter build apk
```
The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`. You can transfer this file to your Android device and install it directly.

## Troubleshooting & Tips

* **Linux Permission Denied:** If the app cannot connect to `/dev/ttyUSB0` on Linux, your user likely lacks permissions to access serial ports. Add your user to the `dialout` group:
  ```bash
  sudo usermod -a -G dialout $USER
  ```
  *Note: You will need to log out and log back in for this to take effect.*
* **Linux Toolchain Errors:** If CMake fails to find `type_traits` or `libstdc++`, ensure `g++` and `build-essential` are fully installed. The `linux/CMakeLists.txt` is strictly configured to use GCC instead of Clang to avoid header path issues.
* **Android USB Permissions:** On Android, the app will automatically request USB permissions when you attempt to connect to the port. If you plug in the device *after* launching the app, use the **Refresh** button next to the port dropdown to scan for the new device.
* **Missing Ports:** If the port list is empty, ensure your USB cable supports data transfer (some cables are charge-only).

## Project Architecture

This project uses the **Repository Pattern** to completely decouple the platform-specific serial logic from the UI. 
* `DesktopSensorRepository` handles Windows/Linux serial ports.
* `MobileSensorRepository` handles Android USB-OTG serial ports.
* Riverpod dynamically injects the correct repository at runtime based on the target OS.
