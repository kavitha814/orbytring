# BLE Vitals Scanner (Flutter Intern Assignment)

A high-fidelity Flutter application built to discover nearby Bluetooth Low Energy (BLE) peripherals, manage dynamic connection states, explore GATT service trees, and stream real-time vital signs (Heart Rate and Battery percentage) with beautiful clinical-grade custom graphics.

Designed and engineered for the **Orbytring / Sensio Flutter Intern Assignment**.

---

## 📱 User Journey & Key Features

*   **Dynamic Permission Gateway**: Fluidly checks, requests, and displays Bluetooth and Location authorizations. Gracefully supports both Android 11 (legacy Location API requirements) and Android 12+ (modern `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` permissions).
*   **Real-time Radar Scanner**: Implements an animated circular radar pulse visualization. Displays discovered peripherals sorted by signal strength (RSSI) with detailed MAC addresses and advertised service capsules.
*   **Dual-Mode Simulation (Aesthetic & Verification Bonus)**:
    1.  **Production Mode**: Communicates directly with actual physical BLE devices using the `flutter_reactive_ble` package.
    2.  **In-App Simulator Mode**: A toggleable virtual BLE stack that generates simulated peripherals and parses realistic telemetry (fluctuating heart rates and battery streams). This enables robust validation and screen recording directly on **standard Android Emulators and iOS Simulators** without requiring physical BLE hardware.
*   **Clinical Telemetry Dashboard**:
    *   **Pulsing Vital Indicator**: A 3D heart icon that dynamically changes its pulse animation frequency to synchronize with the incoming heart rate (BPM) stream.
    *   **ECG Waveform Graph**: A custom canvas-drawn grid chart illustrating a running history of heart rate packets with smooth Bezier-curve gradients.
    *   **Raw Byte Inspector**: Displays incoming raw hex telemetry bytes (GATT Specification `0x2A37`) for strict diagnostic checks.
*   **GATT Service Explorer**: A collapsible hierarchical tree listing discovered services and characteristics with standard names parsed from standard Bluetooth SIG SIG UUID lookup tables (e.g., Heart Rate Service `0x180D`, Device Info `0x180A`).

---

## 🛠️ Architecture & Project Directory Structure

The application adopts a **Clean Architecture / Feature-First** separation of concerns:

```
lib/
├── main.dart                       # App entrypoint & Provider state binding
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # Slate-navy dark theme with neon cyan & vitals rose accents
│   ├── constants/
│   │   └── ble_constants.dart      # Standard GATT SIG UUIDs and descriptions lookup
│   └── utils/
│       └── permission_helper.dart  # Cross-SDK version runtime permission requests
├── data/
│   ├── ble/
│   │   ├── ble_service.dart        # Unified interface for BLE operations
│   │   ├── reactive_ble_service.dart # Real flutter_reactive_ble implementation
│   │   └── mock_ble_service.dart   # Simulated BLE stack for emulator tests
│   └── models/
│       ├── ble_device_model.dart   # Clean domain abstraction of discovered devices
│       └── vital_record.dart       # Core model holding timestamped vital values
├── logic/
│   ├── ble_provider.dart           # Scanning, permissions, & device link controller
│   └── vitals_provider.dart        # GATT discovery, packet parsers, & vital charts history
└── presentation/
    ├── screens/
    │   ├── permissions_screen.dart # Onboarding & system access prompt
    │   ├── scan_screen.dart        # Radar pulse scanner & device results
    │   └── details_screen.dart     # Service list & live telemetry dashboard
    └── widgets/
        ├── pulse_radar.dart        # Custom Painter circular radar sweep
        ├── vitals_chart.dart       # Custom Painter scrolling ECG waveform
        └── device_card.dart        # Glassmorphic BLE device card
```

### Decoupled Data Flow
We rely on a **Service Locator/Repository Abstraction** pattern. By declaring an abstract `BleService`, our logic classes (`BleProvider`, `VitalsProvider`) do not know whether they are using the real physical antenna or our simulator module. This ensures extreme testability, clean code boundaries, and seamless runtime toggling!

---

## 📡 Usage of `flutter_reactive_ble`

`flutter_reactive_ble` is a highly reactive library driven entirely by Dart `Streams`. Here is how the key actions are handled within our `ReactiveBleService`:

### 1. Device Discovery
Scanning runs asynchronously and yields a stream of discovered devices. We filter and sort these dynamically based on RSSI strength:
```dart
_scanSubscription = _ble.scanForDevices(
  withServices: [],
  scanMode: ScanMode.lowLatency,
).listen((device) {
  final model = BleDeviceModel.fromDiscoveredDevice(device);
  _discoveredDevicesMap[device.id] = model;
  
  final sortedList = _discoveredDevicesMap.values.toList()
    ..sort((a, b) => b.rssi.compareTo(a.rssi));
  _scanResultsController.add(sortedList);
});
```

### 2. Connection Management (Subscription-based Connection)
In `flutter_reactive_ble`, a connection is active only as long as its stream subscription is maintained. To disconnect, **we cancel the subscription**. We wrap this reactive pattern into a unified lifecycle:
```dart
// To Connect
_connectionSubscription = _ble.connectToDevice(
  id: deviceId,
  connectionTimeout: const Duration(seconds: 10),
).listen((update) {
  _connectionStateController.add(update);
});

// To Disconnect
await _connectionSubscription?.cancel();
_connectionSubscription = null;
```

### 3. Service Discovery & Telemetry Subscriptions
Once connected, GATT services are queried and a characteristic notification stream is established using qualified coordinates:
```dart
// Service Discovery
List<DiscoveredService> services = await _ble.discoverAllServices(deviceId);

// Subscribing to Vital Notifications
final characteristic = QualifiedCharacteristic(
  characteristicId: BleConstants.heartRateMeasurementUuid, // 0x2A37
  serviceId: BleConstants.heartRateServiceUuid,            // 0x180D
  deviceId: deviceId,
);
_heartRateSubscription = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
  _parseHeartRatePacket(bytes);
});
```

### 4. Advanced GATT Heart Rate Byte Parsing (Specification 2A37)
BLE heart rate monitors pack data efficiently. The first byte acts as flags indicating the value format:
- **Bit 0 is 0**: Heart rate is an 8-bit integer in `bytes[1]`.
- **Bit 0 is 1**: Heart rate is a 16-bit integer spanning `bytes[1]` and `bytes[2]` (little-endian).
Our parser supports both formats, ensuring full compatibility with professional hospital grade monitors and sports chest straps:
```dart
final flags = bytes[0];
final is16Bit = (flags & 0x01) != 0;
int heartRate = 0;
if (is16Bit && bytes.length >= 3) {
  heartRate = bytes[1] + (bytes[2] << 8); // 16-bit little-endian
} else if (bytes.length >= 2) {
  heartRate = bytes[1]; // 8-bit
}
```

---

## 🐍 Python BLE Peripheral Simulator (`simulator/ble_simulator.py`)

A platform-agnostic Python server script is included to serve as a physical testing partner. It uses the `bless` library to turn your PC's Bluetooth radio into a GATT-compliant medical device broadcasting mock vitals.

### Setup & Execution
1.  **Install system dependencies & BLE library**:
    ```bash
    pip install bless
    ```
2.  **Run the script**:
    ```bash
    python simulator/ble_simulator.py
    ```
3.  The script will start advertising as `Orbytring Vitals Sim`. 
4.  Open the Flutter App, **turn off "Simulator Mode"**, click scan, and the app will discover and connect to your PC, streaming heart rate notifications synchronously.

---

## 🛠️ Dynamic Setup & Build Instructions

### Prerequisites
*   Flutter SDK (3.10+ / Dart 3.0+ recommended)
*   Android Studio / Android SDK (with Gradle supporting Java 17)

### Android Project Setup
Verify that Bluetooth permissions and features are configured in your manifests. The app manifest contains the following lines:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Installation Steps
1.  **Clone / Navigate to the workspace**:
    ```bash
    cd d:/projects/orbytring
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Compile & Run on a device/emulator**:
    ```bash
    flutter run
    ```
4.  **Assemble Release APK**:
    ```bash
    flutter build apk --release
    ```
    The compiled binary will be generated at:
    `build/app/outputs/flutter-apk/app-release.apk`

---

## 🎯 Issues Faced & Technical Solutions

1.  **Android 12+ API Permissions Handshake**:
    *   *Issue*: Calling BLE scans on newer Android models resulted in silent crashes because the OS requires dynamic authorizations for `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`, whereas older versions required fine location.
    *   *Solution*: Created a smart `PermissionHelper` class that requests both modern and legacy permission profiles dynamically, checking SDK versions gracefully to prevent crashing on launch.
2.  **Resource Leaks in BLE Streams**:
    *   *Issue*: Bluetooth scanning and characteristic notifications consume heavy processing power and radio bandwidth. Leaving subscriptions running during screen transitions quickly drained battery and crashed the BLE driver.
    *   *Solution*: Tied scanning states tightly to navigation lifecycles. Scanning is forcefully stopped the instant a device connection begins. Additionally, we wrapped the Details page inside a scoped `ChangeNotifierProvider` that automatically cancels characteristic subscriptions on widget disposal.
3.  **Physical Hardware Dependency for Testing**:
    *   *Issue*: Normal emulators cannot access BLE hardware. Testing GATT streams during standard emulator tasks was impossible without a constant physical setup.
    *   *Solution*: Implemented an in-app **Mock Simulator Mode** that swaps out `ReactiveBleService` for `MockBleService` at runtime. The simulator perfectly recreates RSSI fluctuations, connection delays, service trees, and standard byte packaging. This enables rapid UI/UX iterations and recording on standard developer machines.

---

## 🚀 Scaling to Production: Future Improvements

If scaling this application for a real-world enterprise healthcare deployment, we would implement:
1.  **Secure GATT Transactions**: Standard BLE streams are unencrypted. We would implement secure ECDH key exchanges over the characteristic, encrypting the vitals payload at the application layer prior to sending.
2.  **Persistent Background Telemetry Service**: Convert the BLE controller into an Android Foreground Service with persistent notifications, keeping the vitals stream alive even when the user locks their screen or switches apps.
3.  **Local SQLite Cache & Synchronization**: Implement an offline-first caching database (`sqflite` or `Hive`) to log historical vitals during communication drops, syncing the cached logs with a FHIR/REST medical cloud once internet connection resumes.
4.  **Anomaly Detection & Alerts**: Incorporate real-time outlier detection (such as heart rate exceeding 130 BPM or dropping below 50 BPM) and trigger high-priority system alerts and push notifications immediately to emergency contacts.
