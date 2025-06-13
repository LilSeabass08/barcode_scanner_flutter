import '../entities/age_group.dart';
import '../../data/models/product_model.dart'; // Referencing the data model

class NutritionAnalyzer {
  String analyze(Product? product, AgeGroup selectedAgeGroup) {
    if (product == null || product.nutriments == null) {
      return 'Product data not available for analysis.';
    }

    // Simplified analysis logic - expand this significantly
    // You'd have detailed nutritional guidelines per age group here
    final StringBuffer analysis = StringBuffer();
    analysis.writeln('Nutrition Analysis for ${selectedAgeGroup.label}:');
    analysis.writeln('Product: ${product.productName ?? 'N/A'}');

    final sugar = product.getNutrientValue('sugars_100g');
    final salt = product.getNutrientValue('salt_100g');
    final sodium = product.getNutrientValue('sodium_100g');
    final fiber = product.getNutrientValue('fiber_100g');
    // ... add more nutrients

    // Example simplified checks (replace with actual guidelines)
    if (sugar != null) {
      analysis.writeln('Sugars (per 100g): ${sugar}g');
      if (selectedAgeGroup == AgeGroup.sixToTwelveMonths && sugar > 5) {
        analysis.writeln('⚠️ High sugar content for 6-12 months.');
      } else if (sugar > 10) {
        analysis.writeln('⚠️ Generally high sugar content.');
      }
    } else {
      analysis.writeln('Sugars data not available.');
    }

    if (salt != null) {
      analysis.writeln('Salt (per 100g): ${salt}g');
      if (selectedAgeGroup == AgeGroup.sixToTwelveMonths && salt > 0.4) {
        analysis.writeln('⚠️ High salt content for 6-12 months.');
      }
    } else if (sodium != null) { // Fallback to sodium if salt is not available
      analysis.writeln('Sodium (per 100g): ${sodium}g (Salt equivalent: ${(sodium * 2.5).toStringAsFixed(2)}g)');
      if (selectedAgeGroup == AgeGroup.sixToTwelveMonths && (sodium * 2.5) > 0.4) {
        analysis.writeln('⚠️ High sodium/salt content for 6-12 months.');
      }
    }
    else {
      analysis.writeln('Salt/Sodium data not available.');
    }

    if (fiber != null) {
      analysis.writeln('Fiber (per 100g): ${fiber}g');
      if (fiber < 2 && (selectedAgeGroup == AgeGroup.oneToTwoYears || selectedAgeGroup == AgeGroup.twoToThreeYears)) {
        analysis.writeln('Consider foods with higher fiber content for this age group.');
      }
    } else {
      analysis.writeln('Fiber data not available.');
    }


    if (analysis.length == ('Nutrition Analysis for ${selectedAgeGroup.label}:\nProduct: ${product.productName ?? 'N/A'}\n').length) {
      analysis.writeln('No specific concerns noted based on available data, or data is insufficient for detailed analysis.');
    }


    return analysis.toString();
  }
}