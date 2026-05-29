import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/ble_provider.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isRequesting = false;

  Future<void> _handlePermissionRequest(BleProvider bleProvider) async {
    setState(() {
      _isRequesting = true;
    });

    final success = await bleProvider.checkAndRequestPermissions();
    
    if (mounted) {
      setState(() {
        _isRequesting = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth & Location permissions are required to scan for BLE devices.'),
            backgroundColor: AppTheme.accentRoseGold,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bleProvider = Provider.of<BleProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Beautiful glowing Bluetooth icon with Orbyt Gold
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppTheme.accentAuricGold.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentAuricGold.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentAuricGold.withOpacity(0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bluetooth_searching,
                  color: AppTheme.accentAuricGold,
                  size: 50,
                ),
              ),
              const SizedBox(height: 36),
              // App Title & Tagline
              const Text(
                'BLE Vitals Scanner',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppTheme.textStellarBlack,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'High-Fidelity GATT Vitals Explorer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentAuricGold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              // Explanatory Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildRequirementRow(
                        context,
                        Icons.bluetooth,
                        'Bluetooth Permissions',
                        'Required to search, negotiate GATT Handshakes, and stream notifications from BLE peripherals.',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(color: AppTheme.borderSteelSilver),
                      ),
                      _buildRequirementRow(
                        context,
                        Icons.location_on,
                        'Location Permissions',
                        'Required by Android operating systems (11 and below) to accurately scan for nearby Bluetooth radio hardware.',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Onboarding button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isRequesting
                    ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.accentAuricGold),
                      )
                    : ElevatedButton(
                        onPressed: () => _handlePermissionRequest(bleProvider),
                        child: const Text('Grant BLE Access'),
                      ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This application strictly accesses BLE features.\nNo personal data is collected or transmitted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textGunmetal,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accentAuricGold, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textStellarBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textGunmetal,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
