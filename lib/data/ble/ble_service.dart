import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/ble_device_model.dart';

abstract class BleService {
  /// Stream of all active scan results
  Stream<List<BleDeviceModel>> get scanResults;

  /// Stream of the current connection state updates
  Stream<ConnectionStateUpdate> get connectionState;

  /// Whether the service is currently scanning
  bool get isScanning;

  /// Start scanning for nearby BLE devices
  void startScan();

  /// Stop scanning
  void stopScan();

  /// Connect to a device by its ID
  Future<void> connect(String deviceId);

  /// Disconnect from the current device
  Future<void> disconnect();

  /// Discover all available GATT services on the connected device
  Future<List<DiscoveredService>> discoverServices(String deviceId);

  /// Subscribe to a characteristic to receive real-time streams of notifications
  Stream<List<int>> subscribeToCharacteristic(
    String deviceId,
    Uuid serviceUuid,
    Uuid characteristicUuid,
  );
}
