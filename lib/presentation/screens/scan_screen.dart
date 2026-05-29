import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/ble_provider.dart';
import '../widgets/pulse_radar.dart';
import '../widgets/device_card.dart';
import 'details_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isDetailsOpen = false;

  @override
  void initState() {
    super.initState();
    // Add reactive listener to handle auto-navigation on connection success
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = Provider.of<BleProvider>(context, listen: false);
      bleProvider.addListener(_connectionListener);
    });
  }

  void _connectionListener() {
    if (!mounted) return;
    final bleProvider = Provider.of<BleProvider>(context, listen: false);
    
    if (bleProvider.connectionState == DeviceConnectionState.connected && 
        bleProvider.connectedDeviceId != null &&
        !_isDetailsOpen) {
      
      setState(() {
        _isDetailsOpen = true;
      });
      
      // Stop scanning to preserve power
      bleProvider.stopScan();

      // Navigate to Details Screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DetailsScreen(
            deviceId: bleProvider.connectedDeviceId!,
            deviceName: bleProvider.scanResults.any((d) => d.id == bleProvider.connectedDeviceId)
                ? bleProvider.scanResults.firstWhere((d) => d.id == bleProvider.connectedDeviceId).name
                : 'Orbytring Device',
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _isDetailsOpen = false;
          });
          // Automatically resume scanning when returning from Details Screen
          final provider = Provider.of<BleProvider>(context, listen: false);
          if (provider.permissionsGranted) {
            provider.startScan();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Safely remove listener to avoid memory leaks
    final bleProvider = Provider.of<BleProvider>(context, listen: false);
    bleProvider.removeListener(_connectionListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = Provider.of<BleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE RADAR SCANNER'),
        actions: [
          IconButton(
            icon: Icon(
              bleProvider.isScanning ? Icons.stop : Icons.play_arrow,
              color: bleProvider.isScanning ? AppTheme.accentRoseGold : AppTheme.accentAuricGold,
            ),
            tooltip: bleProvider.isScanning ? 'Stop Scan' : 'Start Scan',
            onPressed: () {
              if (bleProvider.isScanning) {
                bleProvider.stopScan();
              } else {
                bleProvider.startScan();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Dual Mode Toggle Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderSteelSilver, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            bleProvider.isMockMode ? Icons.bolt : Icons.bluetooth_connected,
                            color: bleProvider.isMockMode ? AppTheme.accentRoseGold : AppTheme.accentAuricGold,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Simulator Mode Active',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textStellarBlack),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bleProvider.isMockMode
                            ? 'Streaming virtual vital devices for emulators.'
                            : 'Scanning real physical BLE peripherals.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textGunmetal),
                      ),
                    ],
                  ),
                ),
                // Premium Toggle Switch
                Switch.adaptive(
                  value: bleProvider.isMockMode,
                  activeColor: AppTheme.accentAuricGold,
                  activeTrackColor: AppTheme.accentAuricGold.withOpacity(0.3),
                  onChanged: (val) => bleProvider.toggleMockMode(val),
                ),
              ],
            ),
          ),

          // 2. Animated Pulse Radar Display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                PulseRadar(isScanning: bleProvider.isScanning),
                const SizedBox(height: 10),
                Text(
                  bleProvider.isScanning
                      ? 'SCANNING FOR BLE PERIPHERALS...'
                      : 'SCANNER INACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: bleProvider.isScanning ? AppTheme.accentAuricGold : AppTheme.textGunmetal,
                  ),
                ),
              ],
            ),
          ),

          // 3. Real-time Discovered Devices Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DISCOVERED DEVICES',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: AppTheme.textStellarBlack,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.borderSteelSilver.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${bleProvider.scanResults.length} FOUND',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAuricGold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Scrollable Scan Results list
          Expanded(
            child: bleProvider.scanResults.isEmpty
                ? _buildEmptyState(bleProvider)
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: bleProvider.scanResults.length,
                    itemBuilder: (context, index) {
                      final device = bleProvider.scanResults[index];
                      return DeviceCard(device: device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BleProvider bleProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              bleProvider.isScanning ? Icons.radar : Icons.bluetooth_disabled,
              size: 44,
              color: AppTheme.textGunmetal.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              bleProvider.isScanning
                  ? 'Searching for Bluetooth low energy signals. Keep your vitals monitor nearby.'
                  : 'Radar is powered down. Click the play button at the top to start scanning.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textGunmetal,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
