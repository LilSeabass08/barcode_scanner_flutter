import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class OpenFoodFactsApiService {
  static const String _baseUrl = 'https://world.openfoodfacts.net/api/v0/product/';

  Future<Product?> fetchProductInfo(String barcode) async {
    final response = await http.get(Uri.parse('$_baseUrl$barcode.json'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 1 && jsonResponse['product'] != null) {
        return Product.fromJson(jsonResponse['product'] as Map<String, dynamic>);
      } else {
        // Product not found or error in response structure
        print('Product not found or invalid data for barcode: $barcode');
        return null;
      }
    } else {
      // Handle HTTP error
      print('Failed to load product info: ${response.statusCode}');
      throw Exception('Failed to load product info: ${response.statusCode}');
    }
  }
}