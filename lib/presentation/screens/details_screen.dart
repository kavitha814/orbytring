import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ble_constants.dart';
import '../../logic/ble_provider.dart';
import '../../logic/vitals_provider.dart';
import '../widgets/vitals_chart.dart';

class DetailsScreen extends StatelessWidget {
  final String deviceId;
  final String deviceName;

  const DetailsScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    final bleProvider = Provider.of<BleProvider>(context, listen: false);

    // Provide VitalsProvider scoped only to this screen's lifetime
    return ChangeNotifierProvider<VitalsProvider>(
      create: (_) => VitalsProvider(
        bleService: bleProvider.bleService,
        deviceId: deviceId,
      ),
      child: Consumer<VitalsProvider>(
        builder: (context, vitalsProvider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(deviceName.toUpperCase()),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleExit(context, bleProvider),
              ),
              actions: [
                // Display Battery level badge in app bar if active
                if (vitalsProvider.batteryLevel != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          _getBatteryIcon(vitalsProvider.batteryLevel!),
                          color: AppTheme.accentAuricGold,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vitalsProvider.batteryLevel}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentAuricGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.link_off, color: AppTheme.accentRoseGold),
                  tooltip: 'Disconnect',
                  onPressed: () => _handleExit(context, bleProvider),
                ),
              ],
            ),
            body: bleProvider.connectionState == DeviceConnectionState.disconnected
                ? _buildDisconnectedState(context)
                : SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Connection Status Banner Card
                          _buildConnectionCard(context, bleProvider.connectionState),
                          
                          const SizedBox(height: 16),
                          
                          // 2. Vitals Stream Telemetry Section
                          _buildVitalsCard(context, vitalsProvider),
                          
                          const SizedBox(height: 18),
                          
                          // 3. GATT Services Explorer Section
                          Text(
                            'GATT SERVICE DISCOVERY',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppTheme.textStellarBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          if (vitalsProvider.isDiscovering)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(color: AppTheme.accentAuricGold),
                                      SizedBox(height: 14),
                                      Text('Querying Device GATT Services...', style: TextStyle(color: AppTheme.textStellarBlack)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (vitalsProvider.discoveryError != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'GATT Error: ${vitalsProvider.discoveryError}',
                                  style: const TextStyle(color: AppTheme.accentRoseGold),
                                ),
                              ),
                            )
                          else
                            _buildGattTree(context, vitalsProvider.discoveredServices),
                          
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  void _handleExit(BuildContext context, BleProvider bleProvider) {
    // Gracefully trigger disconnection and pop back to scan
    bleProvider.disconnectDevice();
    Navigator.of(context).pop();
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 20) return Icons.battery_3_bar;
    return Icons.battery_alert;
  }

  Widget _buildDisconnectedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 54, color: AppTheme.accentRoseGold),
            const SizedBox(height: 16),
            const Text(
              'DEVICE LINK SEVERED',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentRoseGold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The peripheral disconnected unexpectedly or lost radio coverage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGunmetal),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return to Radar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, DeviceConnectionState state) {
    Color statusColor;
    String label;
    IconData icon;
    
    switch (state) {
      case DeviceConnectionState.connected:
        statusColor = AppTheme.accentAuricGold;
        label = 'TELEMETRY CHANNEL LINKED';
        icon = Icons.bolt;
        break;
      case DeviceConnectionState.connecting:
        statusColor = AppTheme.accentRoseGold;
        label = 'SYNCHRONIZING HANDSHAKE...';
        icon = Icons.sync;
        break;
      default:
        statusColor = AppTheme.accentRoseGold;
        label = 'DISCONNECTED';
        icon = Icons.power_off;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hardware ID: $deviceId',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textGunmetal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsCard(BuildContext context, VitalsProvider vitalsProvider) {
    final hasHrService = vitalsProvider.discoveredServices.any(
      (s) => s.serviceId == BleConstants.heartRateServiceUuid,
    );

    if (!hasHrService && !vitalsProvider.isDiscovering) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Icon(Icons.warning, color: AppTheme.textGunmetal),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No standard Heart Rate Service (0x180D) was announced by this peripheral.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textStellarBlack),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_heart, color: AppTheme.accentRoseGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'VITAL TELEMETRY STREAM',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textStellarBlack),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => vitalsProvider.toggleHeartRateSubscription(),
                  icon: Icon(
                    vitalsProvider.isSubscribedToHeartRate ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(
                    vitalsProvider.isSubscribedToHeartRate ? 'Unsubscribe' : 'Subscribe',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: vitalsProvider.isSubscribedToHeartRate 
                        ? AppTheme.accentRoseGold 
                        : AppTheme.accentAuricGold,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.borderSteelSilver, height: 20),
            
            if (!vitalsProvider.isSubscribedToHeartRate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.wifi_tethering, size: 36, color: AppTheme.textGunmetal.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Click Subscribe to establish standard GATT characteristic notifications.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.textGunmetal, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Live BPM and pulsing graphic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Pulse icon
                  PulsingHeart(
                    bpm: vitalsProvider.currentHeartRate ?? 72,
                    isActive: vitalsProvider.currentHeartRate != null,
                  ),
                  
                  // Readout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            vitalsProvider.currentHeartRate?.toString() ?? '--',
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textStellarBlack,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'BPM',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentRoseGold,
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Heart Rate (GATT 0x2A37)',
                        style: TextStyle(fontSize: 11, color: AppTheme.textGunmetal),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Scrolling ECG-style Waveform
              VitalsChart(history: vitalsProvider.heartRateHistory),
              
              const SizedBox(height: 12),
              
              // Raw byte data display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.borderSteelSilver.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSteelSilver),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RAW RX BYTES:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textGunmetal),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vitalsProvider.rawBytes.isEmpty 
                            ? 'AWAITING PACKETS...' 
                            : '[${vitalsProvider.rawBytes.map((b) => '0x${b.toRadixString(16).padLeft(2, '0').toUpperCase()}').join(', ')}]',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppTheme.accentAuricGold,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGattTree(BuildContext context, List<DiscoveredService> services) {
    if (services.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No GATT services found.', style: TextStyle(color: AppTheme.textStellarBlack)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        final serviceLabel = BleConstants.getServiceLabel(service.serviceId.toString());

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Icon(
                serviceLabel.contains('Heart Rate') ? Icons.monitor_heart : Icons.widgets,
                color: serviceLabel.contains('Heart Rate') ? AppTheme.accentRoseGold : AppTheme.accentAuricGold,
              ),
              title: Text(
                serviceLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textStellarBlack),
              ),
              subtitle: Text(
                'UUID: ${service.serviceId.toString().toUpperCase()}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.textGunmetal),
              ),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: AppTheme.borderSteelSilver),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: service.characteristicIds.map((charId) {
                      final charLabel = BleConstants.getCharacteristicLabel(charId.toString());
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right, size: 16, color: AppTheme.accentAuricGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    charLabel,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textStellarBlack),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'UUID: ${charId.toString().toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace', 
                                      fontSize: 10.5, 
                                      color: AppTheme.textGunmetal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Stateful Widget to handle custom dynamic pulsing speeds for the Heart graphic
class PulsingHeart extends StatefulWidget {
  final int bpm;
  final bool isActive;

  const PulsingHeart({
    super.key,
    required this.bpm,
    required this.isActive,
  });

  @override
  State<PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<PulsingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _calculateDuration(widget.bpm),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingHeart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      _controller.duration = _calculateDuration(widget.bpm);
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.stop();
    }
  }

  Duration _calculateDuration(int bpm) {
    // Speed: 60,000 / BPM = millisecond duration per complete beat (we halve it because reverse is active)
    final rate = (60000 / bpm) / 2;
    return Duration(milliseconds: rate.round().clamp(150, 1000));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppTheme.accentRoseGold.withOpacity(0.08),
          shape: BoxShape.circle,
          boxShadow: [
            if (widget.isActive)
              BoxShadow(
                color: AppTheme.accentRoseGold.withOpacity(0.12),
                blurRadius: 15,
                spreadRadius: 1,
              ),
          ],
        ),
        child: const Icon(
          Icons.favorite,
          color: AppTheme.accentRoseGold,
          size: 40,
        ),
      ),
    );
  }
}
