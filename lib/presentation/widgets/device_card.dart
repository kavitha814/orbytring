import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ble_constants.dart';
import '../../data/models/ble_device_model.dart';
import '../../logic/ble_provider.dart';

class DeviceCard extends StatelessWidget {
  final BleDeviceModel device;

  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final bleProvider = Provider.of<BleProvider>(context);
    
    final isConnectingThis = bleProvider.isConnecting && bleProvider.connectingDeviceId == device.id;
    final isConnectedThis = bleProvider.isConnected && bleProvider.connectedDeviceId == device.id;

    // Get color representing RSSI signal strength
    Color rssiColor;
    if (device.rssi >= -60) {
      rssiColor = AppTheme.accentAuricGold;
    } else if (device.rssi >= -80) {
      rssiColor = AppTheme.accentRoseGold;
    } else {
      rssiColor = AppTheme.textGunmetal;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon indicating type / signal strength
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: rssiColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bluetooth,
                    color: rssiColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Device Names and Identifiers
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppTheme.textGunmetal,
                        ),
                      ),
                    ],
                  ),
                ),
                // RSSI numerical value badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${device.rssi} dBm',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rssiColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSignalIndicator(device.rssi, rssiColor),
                  ],
                ),
              ],
            ),
            
            // Build capsule tags representing services advertised
            if (device.serviceUuids.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: device.serviceUuids.map((uuid) {
                  final label = BleConstants.getServiceLabel(uuid.toString());
                  final isHeartRate = label.contains('Heart Rate');
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHeartRate 
                          ? AppTheme.accentRoseGold.withOpacity(0.1)
                          : AppTheme.accentAuricGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isHeartRate 
                            ? AppTheme.accentRoseGold.withOpacity(0.25)
                            : AppTheme.accentAuricGold.withOpacity(0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isHeartRate) ...[
                          const Icon(Icons.favorite, size: 10, color: AppTheme.accentRoseGold),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHeartRate ? AppTheme.accentRoseGold : AppTheme.accentAuricGold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Connection Action Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: isConnectingThis
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: AppTheme.accentAuricGold),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentAuricGold),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Connecting Vitals...',
                            style: TextStyle(color: AppTheme.accentAuricGold, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: bleProvider.isConnecting
                          ? null // Disable clicking others during an active handshake
                          : () => bleProvider.connectToDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnectedThis ? AppTheme.accentRoseGold : AppTheme.accentAuricGold,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isConnectedThis ? 'Connected' : 'Connect Device',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Draw discrete signal strength bars
  Widget _buildSignalIndicator(int rssi, Color color) {
    int activeBars = 1;
    if (rssi >= -60) {
      activeBars = 4;
    } else if (rssi >= -70) {
      activeBars = 3;
    } else if (rssi >= -85) {
      activeBars = 2;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < activeBars;
        return Container(
          width: 3.5,
          height: 6.0 + (index * 3.0),
          margin: const EdgeInsets.symmetric(horizontal: 1.0),
          decoration: BoxDecoration(
            color: isActive ? color : AppTheme.borderSteelSilver,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
