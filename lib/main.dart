import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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

// Enum to manage the selected age group
enum AgeGroup { sixToTwelve, thirteenToThirtySix }

class _MyHomePageState extends State<MyHomePage> {
  String _scanResult = 'N/A';
  Map<String, dynamic>? _productInfo;
  String _healthAnalysis = 'Scan a product to see the analysis.';
  bool _isLoading = false;
  AgeGroup _selectedAgeGroup = AgeGroup.sixToTwelve;

  Future<void> _scanBarcode() async {
    try {
      final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', // scanner line color
        'Cancel',  // cancel button text
        true,      // show flash icon
        ScanMode.BARCODE,
      );

      if (!mounted || barcode == '-1') {
        return; // User cancelled the scan
      }

      setState(() {
        _scanResult = barcode;
        _isLoading = true;
        _productInfo = null; // Clear previous product info
        _healthAnalysis = ''; // Clear previous analysis
      });

      await _fetchProductInfo(barcode);
    } catch (e) {
      setState(() {
        _scanResult = 'Error scanning barcode: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductInfo(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.net/api/v2/product/$barcode?fields=product_name,nutriments');
    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BabyFoodScanner/1.0 (sashi.ethington@gmail.com)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          setState(() {
            _productInfo = data['product'];
            _analyzeNutrition();
          });
        } else {
          setState(() {
            _productInfo = null;
            _healthAnalysis = 'Product not found in the database.';
          });
        }
      } else {
        setState(() {
          _productInfo = null;
          _healthAnalysis = 'Failed to fetch data from Open Food Facts API.';
        });
      }
    } catch (e) {
      setState(() {
        _productInfo = null;
        _healthAnalysis = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _analyzeNutrition() {
    if (_productInfo == null || _productInfo!['nutriments'] == null) {
      _healthAnalysis = 'No nutrition information available for this product.';
      return;
    }

    final nutriments = _productInfo!['nutriments'] as Map<String, dynamic>;
    List<String> analysisPoints = [];

    // --- Values from your document ---
    // Daily values. We will analyze the per-100g content to see if it's a significant source.
    double proteinDaily = _selectedAgeGroup == AgeGroup.sixToTwelve ? 11 : 13; // g
    double ironDaily = _selectedAgeGroup == AgeGroup.sixToTwelve ? 11 : 7; // mg
    double zincDaily = 3; // mg
    double potassiumDaily = _selectedAgeGroup == AgeGroup.sixToTwelve ? 860 : 2000; // mg

    // Get values from API (per 100g). Use 0 if null.
    // Note: Iron, Zinc, and Potassium from the API are in grams, so we convert to mg.
    double addedSugars = (nutriments['added-sugars_100g'] ?? 0).toDouble();
    double protein = (nutriments['proteins_100g'] ?? 0).toDouble();
    double iron = (nutriments['iron_100g'] ?? 0).toDouble() * 1000; // convert g to mg
    double zinc = (nutriments['zinc_100g'] ?? 0).toDouble() * 1000; // convert g to mg
    double potassium = (nutriments['potassium_100g'] ?? 0).toDouble() * 1000; // convert g to mg

    // **CRITICAL CHECK: Added Sugars** 
    if (addedSugars > 0) {
      analysisPoints.add('🔴 Contains added sugars (${addedSugars}g per 100g). It is best to avoid added sugars for babies and toddlers.');
    } else {
      analysisPoints.add('✅ Great! This product contains no added sugars.');
    }

    // --- Nutrient Analysis ---

    // Protein Analysis
    // Let's consider it a "good source" if a 100g serving has ~20% of daily value
    if (protein > (proteinDaily * 0.2)) {
      analysisPoints.add('Good source of Protein (${protein.toStringAsFixed(1)}g per 100g).');
    }

    // Iron Analysis 
    if (iron > (ironDaily * 0.2)) {
      analysisPoints.add('Good source of Iron (${iron.toStringAsFixed(1)}mg per 100g).');
    }

    // Zinc Analysis 
    if (zinc > (zincDaily * 0.2)) {
      analysisPoints.add('Good source of Zinc (${zinc.toStringAsFixed(1)}mg per 100g).');
    }
    
    // Potassium Analysis 
    if (potassium > (potassiumDaily * 0.1)) { // Potassium is in larger quantities, so lower threshold
        analysisPoints.add('Contains Potassium (${potassium.toStringAsFixed(0)}mg per 100g).');
    }


    if (analysisPoints.length <= 1 && addedSugars == 0) {
        analysisPoints.add('This product seems okay, but lacks significant amounts of key nutrients based on the data available.');
    }


    setState(() {
      _healthAnalysis = analysisPoints.join('\n\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Age Group Selector
              Text('Select Baby\'s Age Group:', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<AgeGroup>(
                segments: const <ButtonSegment<AgeGroup>>[
                  ButtonSegment<AgeGroup>(value: AgeGroup.sixToTwelve, label: Text('6-12m')),
                  ButtonSegment<AgeGroup>(value: AgeGroup.thirteenToThirtySix, label: Text('13-36m')),
                ],
                selected: <AgeGroup>{_selectedAgeGroup},
                onSelectionChanged: (Set<AgeGroup> newSelection) {
                  setState(() {
                    _selectedAgeGroup = newSelection.first;
                    // Re-analyze if a product is already loaded
                    if (_productInfo != null) {
                      _analyzeNutrition();
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              // Scan Result Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Scan Result (Barcode):', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_scanResult, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 10),
                      if (_productInfo != null) ...[
                        const Text('Product Name:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_productInfo!['product_name'] ?? 'N/A', style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Analysis Card
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Card(
                  elevation: 2,
                  color: Colors.lightBlue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Health Analysis for ${_selectedAgeGroup == AgeGroup.sixToTwelve ? "6-12 months" : "13-36 months"}:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          _healthAnalysis,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanBarcode,
        tooltip: 'Scan Barcode',
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan'),
      ),
    );
  }
}