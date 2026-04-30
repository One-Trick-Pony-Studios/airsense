# Project: Nova PM Sensor (SDS011) Cross-Platform Flutter App
**Target:** Flutter Desktop (Linux/Windows) - Phase 1. 
**Future Target:** Flutter Mobile (Android USB OTG) - Phase 2.

## 1. Project Overview
Build a Flutter application to read, display, and record particulate matter (PM2.5 and PM10) data from a Nova SDS011 sensor via a USB-to-TTL serial connection. The app must be architected to support Linux/Windows desktop immediately, with a strictly abstracted hardware layer to allow for an easy Android USB-OTG implementation in the future.

## 2. Tech Stack & Packages
*   **Framework:** Flutter
*   **State Management:** `flutter_riverpod`
*   **Desktop Serial Comms:** `flutter_libserialport` (Phase 1)
*   **Mobile Serial Comms:** `usb_serial` (Phase 2)
*   **Charting:** `fl_chart`
*   **Desktop Window Control:** `window_manager`
*   **File System:** `file_picker`, `dart:io`, `dart:ui` (for off-screen rendering)

## 3. Hardware Protocol (SDS011)
The sensor outputs a 10-byte frame at 1Hz over 9600 baud (8N1).
*   Byte 0: Header (0xAA)
*   Byte 1: Command (0xC0)
*   Byte 2: PM2.5 Low Byte
*   Byte 3: PM2.5 High Byte
*   Byte 4: PM10 Low Byte
*   Byte 5: PM10 High Byte
*   Byte 6: ID Byte 1
*   Byte 7: ID Byte 2
*   Byte 8: Checksum (Sum of Bytes 2-7 modulo 256)
*   Byte 9: Tail (0xAB)
*   *Formula:* `PM2.5 = ((Byte 3 * 256) + Byte 2) / 10.0`
*   *Formula:* `PM10 = ((Byte 5 * 256) + Byte 4) / 10.0`

## 4. Architectural Requirements (Strict Separation)
Implement a **Repository Pattern** to decouple the OS-specific serial port libraries from the UI and business logic.

*   `SensorData` class: Holds `pm25`, `pm10`, and `timestamp`.
*   `SensorRepository` interface: Exposes a `Stream<Uint8List>` (raw bytes) and `connect()` / `disconnect()` methods.
*   `DesktopSensorRepository`: Implements the interface using `flutter_libserialport`.
*   `MockSensorRepository`: Implements the interface generating fake 10-byte frames for UI testing without the hardware.
*   Create a shared parsing utility that listens to the `Stream<Uint8List>`, buffers it, validates the header/tail/checksum, and yields a `Stream<SensorData>`.

## 5. State Management (Riverpod)
Define a `Notifier` or `StateNotifier` to manage the following state object:
```dart
class AppState {
  final SensorData? currentReading;
  final List<SensorData> uiRingBuffer; // Max 300 items (5 minutes)
  final bool isRecording;
  final File? activeRecordFile;
}
```

**Dual-Pipeline Rule**: When a new SensorData arrives, it MUST be appended to the uiRingBuffer. If isRecording is true, the raw data MUST be immediately appended to activeRecordFile on disk using an IOSink (PCAP style). Do not hold the entire recording in memory.

## 6. UI & UX Requirements
**Window Management**
On desktop, initialize `window_manager` before `runApp`.

Set initial window size to 500x400. Set minimum size to 350x300. Center it.

**Layout**
Use responsive widgets (`Wrap` or `LayoutBuilder`).

Wide screens: `Row` layout (Current Values on left, Chart on right).

Narrow screens: `Column` layout (Current Values on top, Chart below).

**Dashboard Widgets**
Display PM2.5 and PM10 in prominent `Card` widgets.

Apply contextual AQI coloring to the card or text (Green < 50, Yellow 51-100, Red > 150).

**Charting (`fl_chart`)**
Plot the uiRingBuffer (PM2.5 and PM10 lines).

Y-axis must dynamically scale based on the min/max of the current ring buffer.

## 7. Export functionality
**CSV Export**
Provide a "Start/Stop Recording" button. When starting, use `file_picker` to create a new CSV file, open an `IOSink`, and write headers. Route live data directly to the sink. Close sink on stop.

**High-Resolution PNG Export**
Provide an "Export Full Plot" button.

Requirement: This MUST NOT use a `RepaintBoundary` on the UI chart.

Implementation: Read the fully recorded CSV from disk. Use `dart:ui` `PictureRecorder` and `Canvas` to draw the entire dataset off-screen at a fixed 4K resolution (3840x2160). Save the resulting bytes to disk as a PNG via `file_picker`.

## 8. Implementation Steps for Code Assist

* Update the base project structure, pubspec.yaml dependencies, and the SensorData / SensorRepository interfaces.
* Implement the byte parsing logic and the MockSensorRepository for immediate testing.
* Implement the Riverpod state management and dual-pipeline recording logic.
* Build the responsive UI, Dashboard Cards, and the fl_chart implementation.
* Implement the DesktopSensorRepository using flutter_libserialport.
* Implement the off-screen Canvas PNG generation.