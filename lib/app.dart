import 'package:flutter/material.dart';
import 'features/product_scanner/presentation/screens/product_scanner_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Food Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Keep for older widget compatibility if needed
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Consider defining text themes, button themes, etc., here for app-wide consistency
      ),
      home: const ProductScannerScreen(title: 'Baby Food Scanner'),
    );
  }
}