import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:openfoodfacts/openfoodfacts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Food Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Baby Food Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _scanResult = 'N/A';
  Map<String, dynamic>? _productInfo;
  String _healthAnalysis = '';
  bool _isLoading = false;

  Future<void> _scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancel',
        true,
        ScanMode.BARCODE,
      );

      if (!mounted || barcode == '-1') {
        return;
      }

      setState(() {
        _scanResult = barcode;
        _isLoading = true;
      });

      await _fetchProductInfo(barcode);
    } catch (e) {
      setState(() {
        _scanResult = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductInfo(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.net/api/v0/product/$barcode.json');
    try {
      // Per Open Food Facts API guidelines, add a custom User-Agent header.
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BabyFoodScanner/1.0 (sashi.ethington@gmail.com)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          setState(() {
            _productInfo = data['product'];
            _analyzeNutrition();
          });
        } else {
          setState(() {
            _productInfo = null;
            _healthAnalysis = 'Product not found.';
          });
        }
      } else {
        setState(() {
          _productInfo = null;
          _healthAnalysis = 'Failed to fetch data.';
        });
      }
    } catch (e) {
      setState(() {
        _productInfo = null;
        _healthAnalysis = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _analyzeNutrition() {
    if (_productInfo == null || _productInfo!['nutriments'] == null) {
      _healthAnalysis = 'No nutrition information available.';
      return;
    }

    final nutriments = _productInfo!['nutriments'];
    final sugars = nutriments['sugars_100g'] ?? 0;
    final sodium = nutriments['sodium_100g'] ?? 0;

    // Simple analysis based on sugar and sodium content for babies
    // These thresholds are examples and should be based on pediatric guidelines
    if (sugars > 10) {
      _healthAnalysis = 'High in sugar. Not recommended for daily intake.';
    } else if (sodium > 0.2) {
      _healthAnalysis = 'High in sodium. Not recommended for daily intake.';
    } else {
      _healthAnalysis = 'This product appears to be a healthy choice.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Scan Result:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_scanResult),
                    const SizedBox(height: 20),
                    if (_productInfo != null) ...[
                      const Text('Product Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_productInfo!['product_name'] ?? 'N/A'),
                      const SizedBox(height: 10),
                      const Text('Nutrition Facts (per 100g):', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Sugars: ${_productInfo!['nutriments']['sugars_100g'] ?? 'N/A'}g'),
                      Text('Sodium: ${_productInfo!['nutriments']['sodium_100g'] ?? 'N/A'}g'),
                      const SizedBox(height: 20),
                    ],
                    const Text('Health Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(_healthAnalysis, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        tooltip: 'Scan Barcode',
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}