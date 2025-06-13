import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import '../../data/datasources/open_food_facts_api_service.dart';
import '../../data/models/product_model.dart';
import '../../domain/entities/age_group.dart';
import '../../domain/usecases/analyze_nutrition.dart';

class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({super.key, required this.title});
  final String title;

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  String? _scanResult;
  Product? _productInfo;
  String _healthAnalysis = '';
  bool _isLoading = false;
  AgeGroup _selectedAgeGroup = AgeGroup.sixToTwelveMonths;

  // Instantiate services - in a larger app, use dependency injection (Provider, Riverpod, GetIt)
  final OpenFoodFactsApiService _apiService = OpenFoodFactsApiService();
  final NutritionAnalyzer _nutritionAnalyzer = NutritionAnalyzer();

  Future<void> _scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      if (!mounted) return;

      if (barcodeScanRes == '-1') {
        // User cancelled the scan
        setState(() {
          _scanResult = 'Scan cancelled.';
          _productInfo = null;
          _healthAnalysis = '';
        });
      } else {
        setState(() {
          _scanResult = barcodeScanRes;
          _isLoading = true;
          _productInfo = null; // Clear previous product info
          _healthAnalysis = ''; // Clear previous analysis
        });
        await _fetchProductInfo(barcodeScanRes);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanResult = 'Failed to get platform version or scan error: $e';
        _healthAnalysis = 'Error during scan.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductInfo(String barcode) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final product = await _apiService.fetchProductInfo(barcode);
      if (!mounted) return;

      setState(() {
        _productInfo = product;
        if (product != null) {
          _healthAnalysis = _nutritionAnalyzer.analyze(product, _selectedAgeGroup);
        } else {
          _healthAnalysis = 'Product information not found or could not be retrieved.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _healthAnalysis = 'Error fetching product details: $e';
        _productInfo = null;
      });
      print('Error in _fetchProductInfo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onAgeGroupSelected(AgeGroup? newAgeGroup) {
    if (newAgeGroup != null) {
      setState(() {
        _selectedAgeGroup = newAgeGroup;
        // Re-analyze if product info is already available
        if (_productInfo != null) {
          _healthAnalysis = _nutritionAnalyzer.analyze(_productInfo, _selectedAgeGroup);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Start Barcode Scan'),
                  onPressed: _scanBarcode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                if (_scanResult != null)
                  Text(
                    'Scan Result: $_scanResult',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 20),
                Text(
                  'Select Baby\'s Age Group:',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                SegmentedButton<AgeGroup>(
                  segments: AgeGroup.values
                      .map((ageGroup) => ButtonSegment<AgeGroup>(
                    value: ageGroup,
                    label: Text(ageGroup.label),
                    icon: const Icon(Icons.child_care_outlined),
                  ))
                      .toList(),
                  selected: {_selectedAgeGroup},
                  onSelectionChanged: (Set<AgeGroup> newSelection) {
                    _onAgeGroupSelected(newSelection.first);
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    // You might need to adjust this depending on the number of segments
                    // to prevent overflow or make it scrollable if many segments.
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_productInfo != null || _healthAnalysis.isNotEmpty)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productInfo?.productName ?? 'Product Details:',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _healthAnalysis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_scanResult != null && _scanResult != 'Scan cancelled.') // Show if scan happened but no data yet or error
                    Text(
                      _healthAnalysis.isNotEmpty ? _healthAnalysis : 'Awaiting product information or analysis...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}