# Project: AirSense — Multi-Sensor Environmental Monitor (Flutter)

**Current Target:** Flutter Mobile (Android USB OTG) — primary deployment.  
**Secondary Target:** Flutter Desktop (Linux/Windows) — supported via `flutter_libserialport`.

---

## 1. Project Overview

AirSense is a Flutter application that reads, displays, and records environmental sensor data arriving over a USB OTG serial connection. The app supports two distinct sensor devices, selectable at runtime from a welcome screen:

| Device | Sensor | Measurements |
|---|---|---|
| **Nova PM** | SDS011 | PM2.5 & PM10 particulate matter (µg/m³) |
| **DHT11 via ESP01** | DHT11 + ESP-01 | Temperature (°C) & Relative Humidity (%) |

The hardware layer is fully abstracted; the same `SensorRepository` interface (raw `Stream<Uint8List>`) is shared between both devices. What differs per device is only the **parser** (binary frame vs. ASCII text) and the **domain model** (`SensorData` vs. `DhtData`).

---

## 2. Tech Stack & Packages

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management (Notifier / FutureProvider / StreamProvider) |
| `flutter_libserialport` | Desktop serial comms |
| `usb_serial` | Mobile USB OTG serial comms |
| `fl_chart` | Live time-series charting |
| `window_manager` | Desktop window chrome control |
| `file_picker` | Save-file dialogs |
| `geolocator` / `geocoding` | Optional GPS tagging of recordings |
| `path_provider`, `path` | File path utilities |
| `share_plus` | Mobile file sharing / export |
| `intl` | Date/time formatting |
| `dart:io`, `dart:ui` | File I/O and off-screen canvas rendering |

---

## 3. Hardware Protocols

### 3.1 Nova PM — SDS011 Binary Protocol

The sensor outputs a **10-byte frame at 1 Hz** over **9600 baud (8N1)**.

| Byte | Meaning |
|------|---------|
| 0 | Header `0xAA` |
| 1 | Command `0xC0` |
| 2 | PM2.5 Low Byte |
| 3 | PM2.5 High Byte |
| 4 | PM10 Low Byte |
| 5 | PM10 High Byte |
| 6 | ID Byte 1 |
| 7 | ID Byte 2 |
| 8 | Checksum (sum of bytes 2–7, mod 256) |
| 9 | Tail `0xAB` |

**Formulae:**
```
PM2.5 = ((Byte[3] << 8) | Byte[2]) / 10.0   // µg/m³
PM10  = ((Byte[5] << 8) | Byte[4]) / 10.0   // µg/m³
```

Parser: `Sds011Parser` — validates header / tail / checksum and emits `SensorData`.

---

### 3.2 DHT11 via ESP01 — ASCII Text Protocol

A DHT11 sensor is wired to an **ESP-01 (ESP8266)** module. The ESP-01 reads the sensor and forwards measurements over its **UART** to the phone via USB OTG at **9600 baud (8N1)** (or the firmware baud rate in use).

#### Arduino / ESP8266 firmware snippet (reference)

```cpp
#include <DHT.h>

DHT dht(DHTPIN, DHT11);

void loop() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();   // Celsius by default

  if (!isnan(h) && !isnan(t)) {
    Serial.print("T:");
    Serial.print(t, 1);
    Serial.print(",H:");
    Serial.println(h, 1);           // \r\n appended by println
  }
  delay(2000);                      // DHT11 max sample rate ~0.5 Hz
}
```

#### Wire format (one line per measurement)

```
T:<temperature>,H:<humidity>\r\n
```

**Examples:**
```
T:25.3,H:61.0\r\n
T:24.8,H:63.5\r\n
```

- `T` — temperature in **°C** (one decimal place), from `dht.readTemperature()`
- `H` — relative humidity in **%** (one decimal place), from `dht.readHumidity()`
- Lines are newline-delimited; the parser buffers partial lines across `Uint8List` chunks

Parser: `Dht11Parser` — decodes UTF-8, splits on `\n`, and emits `DhtData`.

---

## 4. Architecture — Repository Pattern

```
SensorRepository (abstract)
  ├── rawDataStream: Stream<Uint8List>   ← raw bytes from USB serial
  ├── connect(portName)
  ├── disconnect()
  └── getAvailablePorts()

Implementations
  ├── MobileSensorRepository    (usb_serial — Android)
  ├── DesktopSensorRepository   (flutter_libserialport — Linux/Windows)
  ├── MockSensorRepository      (fake SDS011 binary frames for dev/testing)
  └── MockDht11SensorRepository (fake DHT11 ASCII frames for dev/testing)
```

**Key principle:** Both Nova PM and DHT11 share the *same* `SensorRepository` interface. The **parser** (a `StreamTransformer`) is what differentiates them:

```
rawDataStream  ──[Sds011Parser.transformer]──► Stream<SensorData>   (Nova)
rawDataStream  ──[Dht11Parser.transformer]───► Stream<DhtData>      (DHT11)
```

---

## 5. Domain Models

```dart
// Nova PM
class SensorData {
  final double pm25;           // µg/m³
  final double pm10;           // µg/m³
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? locationName;
}

// DHT11 via ESP01
class DhtData {
  final double temperatureCelsius;  // from dht.readTemperature()
  final double relativeHumidity;    // from dht.readHumidity(), in %
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? locationName;
}

// Device selector
enum DeviceType { nova, dht11 }
```

---

## 6. State Management (Riverpod)

Two parallel state pipelines — one per device — following the same pattern:

```
parsedSensorStreamProvider  ──listen──► SensorStateNotifier  ──► AppState
parsedDhtStreamProvider     ──listen──► DhtStateNotifier     ──► DhtAppState
```

**Dual-Pipeline Rule** (applies to both): when a new reading arrives it is:
1. Appended to the **`uiRingBuffer`** (max 300 items ≈ 5–10 minutes of data).
2. Written immediately to the **active `IOSink`** if recording is active.

Data is never held entirely in memory during a long recording session.

**Navigation state:**
```dart
// selectedDeviceProvider: NotifierProvider<DeviceType?>
// null  → show WelcomeScreen
// nova  → show NovaSensorScreen
// dht11 → show Dht11SensorScreen
```

---

## 7. UI & UX

### 7.1 Welcome Screen

Shown on launch before a device is connected. Contains:
- **AirSense logo** (glowing air icon with radial gradient)
- App name and tagline
- **Device selector cards** — one per supported device type, each showing an icon, display name, and brief description. Tapping a card navigates to the sensor screen.

### 7.2 Sensor Screens (shared structure)

Both `NovaSensorScreen` and `Dht11SensorScreen` share identical layout chrome, provided by generic reusable widgets:

| Widget | Type | Description |
|---|---|---|
| `SensorControlPanel` | Generic (config DTO) | Port dropdown, connect/disconnect, location toggle, record/stop, export PNG |
| `ReadingCard` | Generic | Displays any `double` with a title, unit, and accent colour |
| `SeriesChart<T>` | Generic (type param + `ChartSeries<T>`) | Plots any list of data points with pluggable `valueExtractor` callbacks |

**Responsive layout:**
- `maxWidth > 600px` → `Row` (control panel left, readings + chart right)
- `maxWidth ≤ 600px` → `ListView` (stacked vertically)

### 7.3 Colour Coding

**Nova PM — AQI colours (PM2.5 / PM10):**

| Value | Colour |
|---|---|
| ≤ 50 | Green |
| 51–100 | Yellow |
| 101–150 | Orange |
| > 150 | Red |

**DHT11 — comfort colours:**

| Temperature | Colour |
|---|---|
| < 18 °C | Blue (cold) |
| 18–24 °C | Green (comfortable) |
| 25–31 °C | Orange (warm) |
| ≥ 32 °C | Red (hot) |

| Humidity | Colour |
|---|---|
| < 30 % | Orange (dry) |
| 30–60 % | Teal (ideal) |
| > 60 % | Blue (humid) |

### 7.4 Charting (`fl_chart`)

- Y-axis scales dynamically to `max(values) × 1.2` (20 % headroom)
- Legend rendered below chart via `Wrap` of `ChartSeries` entries
- Touch tooltips show series label + value

---

## 8. Recording & Export

### 8.1 CSV Recording

| Device | File name prefix | CSV columns |
|---|---|---|
| Nova PM | `sds011-log-<timestamp>.csv` | `timestamp, pm25, pm10, latitude, longitude, location_name` |
| DHT11 | `dht11-log-<timestamp>.csv` | `timestamp, temperature_c, relative_humidity, latitude, longitude, location_name` |

On both **Desktop** and **Mobile**: saved to `getApplicationDocumentsDirectory()` so they can be written as a stream and indexed in the History screen (file_picker 12 requires all bytes at once for saveFile, so streaming directly to a selected path is bypassed). Users can view, share, or export these files from the History screen.

### 8.2 High-Resolution PNG Export

An off-screen `dart:ui` `PictureRecorder` + `Canvas` renders the full recorded dataset at **4K (3840 × 2160)** and writes it to:
- `chart-export-<ms>.png` (Nova PM, via `ChartExporter`)
- `dht-chart-export-<ms>.png` (DHT11, via `DhtChartExporter`)

**Important:** Does **not** use `RepaintBoundary`; rendering is entirely off-screen.

### 8.3 History Screen

`HistoryScreen` lists all saved files from the app documents directory, filtering for prefixes:
- `sds011-log-`, `chart-export-` (Nova PM)
- `dht11-log-`, `dht-chart-export-` (DHT11)

Each file can be shared (mobile) or previewed (images).

---

## 9. File Structure

```
lib/
├── main.dart
└── src/
    ├── app/
    │   ├── app_state.dart          # Immutable state for Nova PM
    │   ├── dht_app_state.dart      # Immutable state for DHT11
    │   ├── providers.dart          # Nova PM Riverpod providers + SensorStateNotifier
    │   └── dht_providers.dart      # DHT11 Riverpod providers + DhtStateNotifier
    ├── common/utils/
    │   ├── sds011_parser.dart      # Binary frame parser → SensorData
    │   ├── dht11_parser.dart       # ASCII line parser → DhtData
    │   ├── aqi_color.dart          # AQI colour helper
    │   ├── chart_exporter.dart     # Off-screen PNG export (Nova PM)
    │   └── dht_chart_exporter.dart # Off-screen PNG export (DHT11)
    ├── data/repositories/
    │   ├── sensor_repository.dart          # Abstract interface
    │   ├── mobile_sensor_repository.dart   # Android (usb_serial)
    │   ├── desktop_sensor_repository.dart  # Desktop (flutter_libserialport)
    │   ├── mock_sensor_repository.dart     # Fake SDS011 frames
    │   └── mock_dht11_sensor_repository.dart # Fake DHT11 ASCII frames
    ├── domain/
    │   ├── sensor_data.dart   # Nova PM domain model
    │   ├── dht_data.dart      # DHT11 domain model
    │   └── device_type.dart   # DeviceType enum
    └── ui/
        ├── home_screen.dart         # Shell: welcome view + AppBar routing
        ├── nova_sensor_screen.dart  # Nova PM sensor screen
        ├── dht11_sensor_screen.dart # DHT11 sensor screen
        ├── history_screen.dart      # Recordings & exports list
        └── widgets/
            ├── reading_card.dart          # Generic scalar reading card
            ├── series_chart.dart          # Generic SeriesChart<T>
            ├── sensor_control_panel.dart  # Generic control panel (config DTO)
            ├── control_panel.dart         # (legacy — superseded)
            ├── current_reading_card.dart  # (legacy — superseded)
            └── sensor_data_chart.dart     # (legacy — superseded)
```