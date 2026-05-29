import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConstants {
  // Standard GATT Service UUIDs
  static final Uuid heartRateServiceUuid = Uuid.parse('180D');
  static final Uuid batteryServiceUuid = Uuid.parse('180F');
  static final Uuid deviceInformationServiceUuid = Uuid.parse('180A');

  // Standard GATT Characteristic UUIDs
  static final Uuid heartRateMeasurementUuid = Uuid.parse('2A37');
  static final Uuid batteryLevelUuid = Uuid.parse('2A19');
  static final Uuid manufacturerNameUuid = Uuid.parse('2A29');

  // Descriptions for common Services
  static String getServiceLabel(String uuid) {
    final lowerUuid = uuid.toLowerCase();
    if (lowerUuid.contains('180d')) return 'Heart Rate Service';
    if (lowerUuid.contains('180f')) return 'Battery Service';
    if (lowerUuid.contains('180a')) return 'Device Info Service';
    if (lowerUuid.contains('1800')) return 'Generic Access Service';
    if (lowerUuid.contains('1801')) return 'Generic Attribute Service';
    return 'Custom Service';
  }

  // Descriptions for common Characteristics
  static String getCharacteristicLabel(String uuid) {
    final lowerUuid = uuid.toLowerCase();
    if (lowerUuid.contains('2a37')) return 'Heart Rate Measurement (Notify)';
    if (lowerUuid.contains('2a19')) return 'Battery Level (Read, Notify)';
    if (lowerUuid.contains('2a29')) return 'Manufacturer Name (Read)';
    if (lowerUuid.contains('2a00')) return 'Device Name (Read)';
    return 'Custom Characteristic';
  }
}
