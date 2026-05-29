import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Check and request all required Bluetooth and Location permissions
  static Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid) {
      // iOS manages permissions via Info.plist, permission_handler handles this implicitly
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }

    // Android-specific permissions logic
    // Detect if we are on Android 12 (API 31) or above
    // Since we cannot read build version easily without device_info, we request both sets safely.
    // permission_handler gracefully ignores permissions not applicable to the SDK version.
    
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    final statuses = await permissions.request();

    // Check if the critical ones are granted
    final isScanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final isConnectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final isLocationGranted = statuses[Permission.location]?.isGranted ?? false;

    // On older Android (<=11), bluetoothScan and bluetoothConnect might return denied/ignored,
    // but location and legacy bluetooth permissions are mandatory.
    // On newer Android (>=12), scan and connect are mandatory.
    // To be robust, we allow success if either (scan + connect) are granted, OR if location is granted on older devices.
    
    // We check overall status:
    final bluetoothStatus = await Permission.bluetooth.status;
    
    return (isScanGranted && isConnectGranted) || isLocationGranted || bluetoothStatus.isGranted;
  }

  /// Check if permissions are already granted
  static Future<bool> arePermissionsGranted() async {
    if (!Platform.isAndroid) {
      return await Permission.bluetooth.isGranted;
    }

    final isScanGranted = await Permission.bluetoothScan.isGranted;
    final isConnectGranted = await Permission.bluetoothConnect.isGranted;
    final isLocationGranted = await Permission.location.isGranted;
    final isLegacyBleGranted = await Permission.bluetooth.isGranted;

    return (isScanGranted && isConnectGranted) || isLocationGranted || isLegacyBleGranted;
  }
}
