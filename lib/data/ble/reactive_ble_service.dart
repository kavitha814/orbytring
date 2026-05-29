import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/ble_device_model.dart';
import 'ble_service.dart';

class ReactiveBleService implements BleService {
  final _ble = FlutterReactiveBle();
  
  // StreamControllers to publish clean unified events
  final _scanResultsController = StreamController<List<BleDeviceModel>>.broadcast();
  final _connectionStateController = StreamController<ConnectionStateUpdate>.broadcast();

  bool _isScanning = false;
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  
  // Keep track of discovered devices to avoid duplicates during scanning
  final Map<String, BleDeviceModel> _discoveredDevicesMap = {};

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
    _discoveredDevicesMap.clear();

    _scanSubscription = _ble.scanForDevices(
      withServices: [], // Scan for all services
      scanMode: ScanMode.lowLatency,
    ).listen(
      (device) {
        final model = BleDeviceModel.fromDiscoveredDevice(device);
        _discoveredDevicesMap[device.id] = model;
        
        // Sort discovered devices by RSSI strength descending
        final sortedList = _discoveredDevicesMap.values.toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));
          
        _scanResultsController.add(sortedList);
      },
      onError: (Object error) {
        _isScanning = false;
        _scanResultsController.addError(error);
      },
    );
  }

  @override
  void stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
  }

  @override
  Future<void> connect(String deviceId) async {
    // Cancel any ongoing connections first
    await _connectionSubscription?.cancel();

    _connectionSubscription = _ble
        .connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen(
      (update) {
        _connectionStateController.add(update);
      },
      onError: (Object error) {
        _connectionStateController.add(ConnectionStateUpdate(
          deviceId: deviceId,
          connectionState: DeviceConnectionState.disconnected,
          failure: const GenericFailure(
            code: ConnectionError.unknown,
            message: 'Connection failed',
          ),
        ));
      },
    );
  }

  @override
  Future<void> disconnect() async {
    if (_connectionSubscription != null) {
      await _connectionSubscription!.cancel();
      _connectionSubscription = null;
    }
  }

  @override
  Future<List<DiscoveredService>> discoverServices(String deviceId) async {
    try {
      await _ble.discoverAllServices(deviceId);
      final services = await _ble.getDiscoveredServices(deviceId);
      return services.map((s) {
        return DiscoveredService(
          serviceId: s.id,
          serviceInstanceId: s.id.toString(),
          characteristicIds: s.characteristics.map((c) => c.id).toList(),
          characteristics: const [],
        );
      }).toList();
    } catch (e) {
      // Re-throw to be handled by the VitalsProvider
      rethrow;
    }
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(
    String deviceId,
    Uuid serviceUuid,
    Uuid characteristicUuid,
  ) {
    final characteristic = QualifiedCharacteristic(
      characteristicId: characteristicUuid,
      serviceId: serviceUuid,
      deviceId: deviceId,
    );

    return _ble.subscribeToCharacteristic(characteristic);
  }

  void dispose() {
    stopScan();
    _connectionSubscription?.cancel();
    _scanResultsController.close();
    _connectionStateController.close();
  }
}
