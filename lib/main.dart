import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'logic/ble_provider.dart';
import 'presentation/screens/permissions_screen.dart';
import 'presentation/screens/scan_screen.dart';

void main() {
  // Ensure Flutter engine bindings are initialized prior to loading platform channels (Bluetooth)
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BleProvider>(
          create: (_) => BleProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Vitals Scanner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppHome(),
    );
  }
}

class AppHome extends StatelessWidget {
  const AppHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Monitor permissions in real-time. Redirect to onboarding if unauthorized.
    final bleProvider = Provider.of<BleProvider>(context);

    if (bleProvider.permissionsGranted) {
      return const ScanScreen();
    } else {
      return const PermissionsScreen();
    }
  }
}
