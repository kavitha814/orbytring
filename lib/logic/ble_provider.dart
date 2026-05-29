import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../data/ble/ble_service.dart';
import '../data/ble/mock_ble_service.dart';
import '../data/ble/reactive_ble_service.dart';
import '../data/models/ble_device_model.dart';
import '../core/utils/permission_helper.dart';

class BleProvider extends ChangeNotifier {
  BleService _bleService;
  bool _isMockMode = true; // Default to simulator mode for flawless emulator testing
  bool _permissionsGranted = false;
  
  List<BleDeviceModel> _scanResults = [];
  bool _isScanning = false;
  
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  String? _connectedDeviceId;
  String? _connectingDeviceId;
  
  StreamSubscription<List<BleDeviceModel>>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionStateSubscription;

  BleProvider() : _bleService = MockBleService() {
    _init();
  }

  // Getters
  BleService get bleService => _bleService;
  bool get isMockMode => _isMockMode;
  bool get permissionsGranted => _permissionsGranted;
  List<BleDeviceModel> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  DeviceConnectionState get connectionState => _connectionState;
  String? get connectedDeviceId => _connectedDeviceId;
  String? get connectingDeviceId => _connectingDeviceId;

  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  bool get isConnecting => _connectionState == DeviceConnectionState.connecting;

  Future<void> _init() async {
    _permissionsGranted = await PermissionHelper.arePermissionsGranted();
    notifyListeners();
    
    // Automatically start scanning if permissions are granted and we're in mock mode
    if (_permissionsGranted && _isMockMode) {
      startScan();
    }
  }

  /// Request permissions and update status
  Future<bool> checkAndRequestPermissions() async {
    final granted = await PermissionHelper.requestBlePermissions();
    _permissionsGranted = granted;
    notifyListeners();
    return granted;
  }

  /// Toggle between physical BLE and in-app BLE simulation
  void toggleMockMode(bool enabled) {
    if (_isMockMode == enabled) return;
    
    // Stop scanning and disconnect from current items before switching
    stopScan();
    if (isConnected || isConnecting) {
      disconnectDevice();
    }
    
    _isMockMode = enabled;
    
    // Clean up old service
    if (_bleService is MockBleService) {
      (_bleService as MockBleService).dispose();
    } else if (_bleService is ReactiveBleService) {
      (_bleService as ReactiveBleService).dispose();
    }
    
    // Instantiate new service
    _bleService = enabled ? MockBleService() : ReactiveBleService();
    _scanResults.clear();
    
    notifyListeners();

    // Automatically resume scan if permissions allow
    if (_permissionsGranted) {
      startScan();
    }
  }

  /// Start scan for nearby devices
  void startScan() {
    if (_isScanning) return;
    _scanResults.clear();
    
    _isScanning = true;
    notifyListeners();

    // Stop existing scan subscription if any
    _scanSubscription?.cancel();

    _bleService.startScan();
    _scanSubscription = _bleService.scanResults.listen(
      (results) {
        _scanResults = results;
        notifyListeners();
      },
      onError: (error) {
        _isScanning = false;
        notifyListeners();
      },
    );
  }

  /// Stop scan
  void stopScan() {
    if (!_isScanning) return;
    _bleService.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to selected device
  Future<void> connectToDevice(BleDeviceModel device) async {
    // Stop scanning before connecting to save radio bandwidth (highly recommended in BLE)
    stopScan();
    
    _connectingDeviceId = device.id;
    _connectionState = DeviceConnectionState.connecting;
    notifyListeners();

    // Listen to connection updates
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = _bleService.connectionState.listen(
      (update) {
        if (update.deviceId == device.id) {
          _connectionState = update.connectionState;
          if (_connectionState == DeviceConnectionState.connected) {
            _connectedDeviceId = device.id;
            _connectingDeviceId = null;
          } else if (_connectionState == DeviceConnectionState.disconnected) {
            _connectedDeviceId = null;
            _connectingDeviceId = null;
          }
          notifyListeners();
        }
      },
      onError: (error) {
        _connectionState = DeviceConnectionState.disconnected;
        _connectedDeviceId = null;
        _connectingDeviceId = null;
        notifyListeners();
      },
    );

    try {
      await _bleService.connect(device.id);
    } catch (e) {
      _connectionState = DeviceConnectionState.disconnected;
      _connectingDeviceId = null;
      notifyListeners();
    }
  }

  /// Disconnect current device
  Future<void> disconnectDevice() async {
    await _bleService.disconnect();
    _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    _connectionState = DeviceConnectionState.disconnected;
    _connectedDeviceId = null;
    _connectingDeviceId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    if (_bleService is MockBleService) {
      (_bleService as MockBleService).dispose();
    } else if (_bleService is ReactiveBleService) {
      (_bleService as ReactiveBleService).dispose();
    }
    super.dispose();
  }
}
