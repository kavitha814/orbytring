import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../core/constants/ble_constants.dart';
import '../data/ble/ble_service.dart';
import '../data/models/vital_record.dart';

class VitalsProvider extends ChangeNotifier {
  final BleService _bleService;
  final String _deviceId;

  List<DiscoveredService> _discoveredServices = [];
  bool _isDiscovering = false;
  String? _discoveryError;

  // Active subscriptions
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<List<int>>? _batterySubscription;

  // Raw and parsed states
  int? _currentHeartRate;
  int? _batteryLevel;
  List<int> _rawBytes = [];
  final List<VitalRecord> _heartRateHistory = [];
  
  bool _isSubscribedToHeartRate = false;

  VitalsProvider({
    required BleService bleService,
    required String deviceId,
  })  : _bleService = bleService,
        _deviceId = deviceId {
    _discoverServices();
  }

  // Getters
  List<DiscoveredService> get discoveredServices => _discoveredServices;
  bool get isDiscovering => _isDiscovering;
  String? get discoveryError => _discoveryError;
  int? get currentHeartRate => _currentHeartRate;
  int? get batteryLevel => _batteryLevel;
  List<int> get rawBytes => _rawBytes;
  List<VitalRecord> get heartRateHistory => _heartRateHistory;
  bool get isSubscribedToHeartRate => _isSubscribedToHeartRate;

  /// Trigger service discovery
  Future<void> _discoverServices() async {
    _isDiscovering = true;
    _discoveryError = null;
    notifyListeners();

    try {
      final services = await _bleService.discoverServices(_deviceId);
      _discoveredServices = services;
      
      // Auto-subscribe to Battery if available
      _checkAndSubscribeBattery();
    } catch (e) {
      _discoveryError = e.toString();
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Subscribe to standard battery characteristic if present in services list
  void _checkAndSubscribeBattery() {
    try {
      final hasBatteryService = _discoveredServices.any(
        (s) => s.serviceId == BleConstants.batteryServiceUuid,
      );
      
      if (hasBatteryService) {
        _batterySubscription?.cancel();
        _batterySubscription = _bleService
            .subscribeToCharacteristic(
          _deviceId,
          BleConstants.batteryServiceUuid,
          BleConstants.batteryLevelUuid,
        )
            .listen(
          (data) {
            if (data.isNotEmpty) {
              _batteryLevel = data[0];
              notifyListeners();
            }
          },
          onError: (_) {},
        );
      }
    } catch (_) {}
  }

  /// Subscribe to Heart Rate notifications
  void toggleHeartRateSubscription() {
    if (_isSubscribedToHeartRate) {
      _heartRateSubscription?.cancel();
      _heartRateSubscription = null;
      _isSubscribedToHeartRate = false;
      _currentHeartRate = null;
      _rawBytes.clear();
      notifyListeners();
      return;
    }

    _isSubscribedToHeartRate = true;
    notifyListeners();

    _heartRateSubscription?.cancel();
    _heartRateSubscription = _bleService
        .subscribeToCharacteristic(
      _deviceId,
      BleConstants.heartRateServiceUuid,
      BleConstants.heartRateMeasurementUuid,
    )
        .listen(
      (data) {
        _rawBytes = data;
        _parseHeartRatePacket(data);
      },
      onError: (error) {
        _isSubscribedToHeartRate = false;
        _currentHeartRate = null;
        notifyListeners();
      },
    );
  }

  /// Parse binary BLE heart rate measurement packet (GATT Spec: 2A37)
  void _parseHeartRatePacket(List<int> data) {
    if (data.length < 2) return;

    final flags = data[0];
    final is16BitValue = (flags & 0x01) != 0;
    
    int parsedHeartRate = 0;
    if (is16BitValue) {
      if (data.length >= 3) {
        // Little endian uint16
        parsedHeartRate = data[1] + (data[2] << 8);
      }
    } else {
      parsedHeartRate = data[1];
    }

    if (parsedHeartRate > 0) {
      _currentHeartRate = parsedHeartRate;
      
      // Save to rolling historical record list (keep maximum 35 points for a beautiful clean chart)
      _heartRateHistory.add(VitalRecord(
        timestamp: DateTime.now(),
        value: parsedHeartRate.toDouble(),
      ));
      
      if (_heartRateHistory.length > 35) {
        _heartRateHistory.removeAt(0);
      }
      
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _batterySubscription?.cancel();
    super.dispose();
  }
}
