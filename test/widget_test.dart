import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barcode_scanner/app.dart'; // Ensure this is the correct path to your app.dart

void main() {
  testWidgets('ProductScannerScreen has a title and a scan button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the AppBar title is present.
    expect(find.text('Baby Food Scanner'), findsOneWidget); // Assuming this is your title

    // Verify that the "Start Barcode Scan" button is present.
    expect(find.widgetWithText(ElevatedButton, 'Start Barcode Scan'), findsOneWidget);
  });
}