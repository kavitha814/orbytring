# Project Presentation: BLE Vitals Scanner
**Orbytring Theme Edition**

A presentation-deck format summarizing the technical design, UX flow, and implementation details for the Flutter Intern Assignment.

---

## 🛝 Slide 1: Cover Slide
### BLE Vitals Scanner (Orbytring Brand Edition)
> **Bridging High-Fidelity Medical Scanning with Elegant Brand Identity**

*   **Presenter:** Kavitha R
*   **Email:** [kavitharamesh1408@gmail.com](mailto:kavitharamesh1408@gmail.com)
*   **Position Applied:** Flutter Intern
*   **Company:** Orbytring / Sensio
*   **Deliverable:** Complete Flutter Application & Standalone BLE Peripheral Simulator

---

## 🛝 Slide 2: The Challenge & Objective
### The Project Goal
*   **Objective**: Build a responsive Flutter application that discovers nearby BLE devices, connects to a selected device, and displays its live telemetry stream.
*   **Technical Constraint**: Utilize only `flutter_reactive_ble` for native Bluetooth core operations.
*   **Design Goal**: Move away from generic templates to implement a brand-aligned, premium **Light Theme (White Mode)** modeled directly after the official [orbytring.com](https://www.orbytring.com) colors.

---

## 🛝 Slide 3: The Seamless User Journey
### End-to-End User Experience Flow

```
[ 1. Permission Gate ] ➔ [ 2. Radar Scan ] ➔ [ 3. Handshake Link ] ➔ [ 4. Service Tree Explorer ] ➔ [ 5. Live ECG Stream ]
```

1.  **Onboarding Gate**: Graceful runtime permissions check (Bluetooth & Location) that respects Android and iOS SDK versions.
2.  **Visual Scanning**: A high-performance canvas radar sweeps to identify active BLE devices, organizing lists by RSSI signal strength.
3.  **Connection Handshake**: Taps on a target device trigger structured state-machine updates with user-friendly load states.
4.  **Service Tree Explorer**: Displays all discovered GATT services and characteristics, converting hex codes into readable clinical descriptors.
5.  **Live ECG Stream**: Renders real-time telemetry plotting, displaying a scrolling Bezier ECG waveform, pulsing heart icon, and live BPM data.

---

## 🛝 Slide 4: Brand-Aligned Color System
### Styled with Orbyt Smart Ring Design Tokens

We designed a curated palette directly matching Orbytring's product lines:

*   **Canvas Base Background**: `#F8FAFC` (Soft Metallic White)
*   **Surface Cards**: `#FFFFFF` (Pure White cards with sleek silver borders)
*   **Auric Accent Gold**: `#C5A059` (Branded Champagne Gold for sweep radars, primary buttons, and status toggles)
*   **Vitals Rose Gold**: `#D49A8F` (Warm Rose Gold for scrolling ECG vector lines, pulsar node points, and subscribed statuses)
*   **Primary Text**: `#0F172A` (Stellar Black for sharp, high-contrast headers)
*   **Secondary Text**: `#64748B` (Slate Grey for GATT hex IDs and hardware metadata)

---

## 🛝 Slide 5: Architecture & Decoupled Design
### Robust Software Engineering Blueprint

To ensure the application is scalable, testable, and robust, we decoupled the interface widgets from the native hardware drivers:

*   **Abstract Interface Layer**: `BleService` establishes the structural contract.
*   **Physical Driver (`ReactiveBleService`)**: Directly manages native Android/iOS Bluetooth controllers using `flutter_reactive_ble`.
*   **Virtual Driver (`MockBleService`)**: Emulates full scanning cycles, connection states, and realistic heart rate/battery notification packets locally.
*   **Consumer Providers**: `BleProvider` manages connection sequences and simulator states, while `VitalsProvider` parses raw characteristic notifications.

---

## 🛝 Slide 6: Dual Testing Architecture
### Absolute Verification on Any Platform

We created a dual testing layout that allows instant validation:

1.  **In-App Software Simulator**:
    *   Toggled instantly with a card switch at the top of the scan list.
    *   Enables verification of scrolling charts, dynamic service trees, and pulsing heart states directly inside headless android emulators without requiring a physical transceiver.
2.  **External Python Peripheral Simulator (`ble_simulator.py`)**:
    *   A standalone script built using the Python `bless` and `bleak` libraries.
    *   Registers a standard Heart Rate service (`0x180D`) and characteristic (`0x2A37`).
    *   Broadcasts mock telemetry packets periodically to provide realistic signals for physical testing.

---

## 🛝 Slide 7: Technical Detail: Binary Packet Parsing
### Under the Hood of Live GATT Subscriptions

Standard heart rate vitals coordinates are parsed directly from raw bytes matching GATT specifications (`0x2A37`):

```dart
// Byte 0: Flags block
// Byte 1: Heart Rate Value (uint8 representation)
if (packet.length >= 2) {
  final flags = packet[0];
  final int heartRateValue;
  
  if ((flags & 0x01) == 0) {
    // 8-bit format value
    heartRateValue = packet[1];
  } else {
    // 16-bit format value (little-endian representation)
    heartRateValue = packet[1] | (packet[2] << 8);
  }
  
  _updateHeartRate(heartRateValue);
}
```

*   **Scrolling Vector Graph**: The `VitalsChart` maintains a scrolling history list, drawing custom Bezier curves on a grid canvas using standard HTML/Flutter paint strokes.

---

## 🛝 Slide 8: Implementation Checkpoints
### Compilation, Verification & Delivery

*   **Static Code Analysis**: Executed `flutter analyze` with **0 errors, 0 warnings, and 0 lint issues** after configuring strict analysis options.
*   **Integration Smoke Test**: Updated unit tests to verify the initial state routing checks.
*   **Submission Package**:
    *   **APK Location:** `d:\projects\orbytring\build\app\outputs\flutter-apk\app-release.apk`
    *   **APK Size:** 44.2MB (Tree-shaken, optimized for release)

---

## 🛝 Slide 9: Summary & Thank You
### Submitted by Kavitha R

*   **Email:** [kavitharamesh1408@gmail.com](mailto:kavitharamesh1408@gmail.com)
*   **Applied Position:** Flutter Intern
*   **Role Goal:** To bring production-level code, clean architecture, and rigorous brand standards to the Orbytring engineering team.

---
*(End of Presentation)*
