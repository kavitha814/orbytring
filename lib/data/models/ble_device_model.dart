import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleDeviceModel {
  final String id;
  final String name;
  final int rssi;
  final List<Uuid> serviceUuids;
  final Map<Uuid, List<int>> serviceData;
  final bool isConnectable;

  BleDeviceModel({
    required this.id,
    required this.name,
    required this.rssi,
    required this.serviceUuids,
    this.serviceData = const {},
    this.isConnectable = true,
  });

  // Factory constructor to map from flutter_reactive_ble's DiscoveredDevice
  factory BleDeviceModel.fromDiscoveredDevice(DiscoveredDevice device) {
    return BleDeviceModel(
      id: device.id,
      name: device.name.isEmpty ? 'Unknown Device' : device.name,
      rssi: device.rssi,
      serviceUuids: device.serviceUuids,
      serviceData: device.serviceData,
      isConnectable: device.connectable == Connectable.available || 
                     device.connectable == Connectable.unknown,
    );
  }

  BleDeviceModel copyWith({
    String? id,
    String? name,
    int? rssi,
    List<Uuid>? serviceUuids,
    Map<Uuid, List<int>>? serviceData,
    bool? isConnectable,
  }) {
    return BleDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      serviceUuids: serviceUuids ?? this.serviceUuids,
      serviceData: serviceData ?? this.serviceData,
      isConnectable: isConnectable ?? this.isConnectable,
    );
  }
}
