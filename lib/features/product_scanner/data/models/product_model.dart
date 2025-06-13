// Basic model, expand as needed based on the API response
class Product {
  final String? productName;
  final Map<String, dynamic>? nutriments; // You might want to type this further

  Product({this.productName, this.nutriments});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productName: json['product_name_en'] as String? ?? json['product_name'] as String?,
      nutriments: json['nutriments'] as Map<String, dynamic>?,
    );
  }

  // Helper to safely get nutrient values
  double? getNutrientValue(String key) {
    if (nutriments == null) return null;
    final value = nutriments![key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}