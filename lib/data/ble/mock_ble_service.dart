import 'dart:async';
import 'dart:math';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/ble_device_model.dart';
import 'ble_service.dart';

class MockBleService implements BleService {
  final _scanResultsController = StreamController<List<BleDeviceModel>>.broadcast();
  final _connectionStateController = StreamController<ConnectionStateUpdate>.broadcast();

  bool _isScanning = false;
  Timer? _scanTimer;
  Timer? _vitalsTimer;
  StreamController<List<int>>? _charSubscriptionController;

  final List<BleDeviceModel> _mockDevices = [
    BleDeviceModel(
      id: 'DE:AD:BE:EF:01:23',
      name: 'Orbytring Vitals Sim',
      rssi: -58,
      serviceUuids: [Uuid.parse('180D'), Uuid.parse('180F')],
    ),
    BleDeviceModel(
      id: 'AA:BB:CC:DD:EE:01',
      name: 'Pulse Oximeter 50D',
      rssi: -72,
      serviceUuids: [Uuid.parse('180D')],
    ),
    BleDeviceModel(
      id: '12:34:56:78:9A:BC',
      name: 'Fitbit Charge 6',
      rssi: -64,
      serviceUuids: [Uuid.parse('180D'), Uuid.parse('180A')],
    ),
    BleDeviceModel(
      id: '98:76:54:32:10:FE',
      name: 'Smart Blood Pressure',
      rssi: -85,
      serviceUuids: [Uuid.parse('180A')],
    ),
  ];

  String? _connectedDeviceId;

  @override
  Stream<List<BleDeviceModel>> get scanResults => _scanResultsController.stream;

  @override
  Stream<ConnectionStateUpdate> get connectionState => _connectionStateController.stream;

  @override
  bool get isScanning => _isScanning;

  @override
  void startScan() {
    if (_isScanning) return;
    _isScanning = true;

    // Send initial list
    _scanResultsController.add(List.from(_mockDevices));

    // Simulate occasional RSSI fluctuations and new devices
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final random = Random();
      final updatedDevices = _mockDevices.map((device) {
        // Fluctuating RSSI +/- 5
        final newRssi = device.rssi + random.nextInt(11) - 5;
        return device.copyWith(rssi: newRssi.clamp(-100, -30));
      }).toList();
      _scanResultsController.add(updatedDevices);
    });
  }

  @override
  void stopScan() {
    _scanTimer?.cancel();
    _isScanning = false;
  }

  @override
  Future<void> connect(String deviceId) async {
    _connectedDeviceId = deviceId;

    // Emit Connecting state
    _connectionStateController.add(ConnectionStateUpdate(
      deviceId: deviceId,
      connectionState: DeviceConnectionState.connecting,
      failure: null,
    ));

    // Wait 1.5 seconds to simulate connection handshake
    await Future.delayed(const Duration(milliseconds: 1500));

    if (_connectedDeviceId == deviceId) {
      _connectionStateController.add(ConnectionStateUpdate(
        deviceId: deviceId,
        connectionState: DeviceConnectionState.connected,
        failure: null,
      ));
    }
  }

  @override
  Future<void> disconnect() async {
    final devId = _connectedDeviceId;
    if (devId == null) return;

    _connectionStateController.add(ConnectionStateUpdate(
      deviceId: devId,
      connectionState: DeviceConnectionState.disconnecting,
      failure: null,
    ));

    await Future.delayed(const Duration(milliseconds: 500));

    _vitalsTimer?.cancel();
    _charSubscriptionController?.close();
    _charSubscriptionController = null;
    _connectedDeviceId = null;

    _connectionStateController.add(ConnectionStateUpdate(
      deviceId: devId,
      connectionState: DeviceConnectionState.disconnected,
      failure: null,
    ));
  }

  @override
  Future<List<DiscoveredService>> discoverServices(String deviceId) async {
    // Return standard simulated service tree based on mock device UUIDs
    final device = _mockDevices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => _mockDevices.first,
    );

    final List<DiscoveredService> services = [];

    // Generic Access
    services.add(DiscoveredService(
      serviceId: Uuid.parse('1800'),
      serviceInstanceId: '1800',
      characteristicIds: [Uuid.parse('2A00')],
      characteristics: const [],
    ));

    // Device Information if in serviceUuids
    if (device.serviceUuids.contains(Uuid.parse('180A'))) {
      services.add(DiscoveredService(
        serviceId: Uuid.parse('180A'),
        serviceInstanceId: '180A',
        characteristicIds: [Uuid.parse('2A29')],
        characteristics: const [],
      ));
    }

    // Battery Service if in serviceUuids
    if (device.serviceUuids.contains(Uuid.parse('180F'))) {
      services.add(DiscoveredService(
        serviceId: Uuid.parse('180F'),
        serviceInstanceId: '180F',
        characteristicIds: [Uuid.parse('2A19')],
        characteristics: const [],
      ));
    }

    // Heart Rate Service if in serviceUuids
    if (device.serviceUuids.contains(Uuid.parse('180D'))) {
      services.add(DiscoveredService(
        serviceId: Uuid.parse('180D'),
        serviceInstanceId: '180D',
        characteristicIds: [Uuid.parse('2A37')],
        characteristics: const [],
      ));
    }

    return services;
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    String deviceId,
    Uuid serviceUuid,
    Uuid characteristicUuid,
  ) {
    _vitalsTimer?.cancel();
    _charSubscriptionController?.close();

    final controller = StreamController<List<int>>.broadcast();
    _charSubscriptionController = controller;

    final random = Random();
    double currentHeartRate = 72.0;

    // Simulate sending data packets periodically
    _vitalsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      if (characteristicUuid == Uuid.parse('2A37')) {
        // Heart Rate Measurement simulation:
        // Byte 0: Flags (0x06 means 8-bit value, sensor contact detected)
        // Byte 1: HR Value (Uint8)
        // Add random wander (+/- 2 bpm)
        currentHeartRate += (random.nextDouble() * 4.0) - 2.0;
        currentHeartRate = currentHeartRate.clamp(60.0, 120.0);

        final packet = [
          0x06, // Flags
          currentHeartRate.round(), // Value
        ];
        controller.add(packet);
      } else if (characteristicUuid == Uuid.parse('2A19')) {
        // Battery level: decrease by 1 periodically
        final batteryLevel = (98 - (timer.tick ~/ 10)).clamp(0, 100);
        controller.add([batteryLevel]);
      } else {
        // Custom echo/default
        controller.add([0x00, 0x01, 0x02]);
      }
    });

    return controller.stream;
  }

  void dispose() {
    _scanResultsController.close();
    _connectionStateController.close();
    _scanTimer?.cancel();
    _vitalsTimer?.cancel();
    _charSubscriptionController?.close();
  }
}
