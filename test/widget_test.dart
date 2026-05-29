import 'package:flutter_test/flutter_test.dart';
import 'package:orbytring/main.dart';

void main() {
  testWidgets('Smoke test: Renders onboarding permissions screen or main scanner', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify either the Permissions screen is displayed or the Scanner screen is displayed
    final permissionsScreenFinder = find.text('BLE Vitals Scanner');
    final scannerScreenFinder = find.text('BLE RADAR SCANNER');

    expect(
      permissionsScreenFinder.evaluate().isNotEmpty || scannerScreenFinder.evaluate().isNotEmpty,
      true,
      reason: 'Should render either PermissionsScreen or ScanScreen initially.',
    );
  });
}
