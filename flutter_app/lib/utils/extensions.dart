// ============ lib/utils/extensions.dart ============

extension StringExtensions on String {
  /// Parse ingredient string into list of ingredients
  /// Format: "1. Item 1kg\n2. Item 2\n3. Item 3"
  List<String> parseIngredients() {
    return split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .toList();
  }

  /// Parse instructions string into list of steps
  /// Format: "1. Step one\n2. Step two\n3. Step three"
  List<String> parseInstructions() {
    return split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
        .toList();
  }

  /// Format duration in minutes to readable format
  /// 45 -> "45 min"
  /// 120 -> "2h"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${mins}m';
      }
    }
  }
}

extension ListExtensions on List<String> {
  /// Aggregate ingredients across multiple ingredient lists
  /// Returns a map of ingredient -> total quantity
  static Map<String, String> aggregateIngredients(
    List<List<String>> ingredientLists,
  ) {
    final Map<String, dynamic> aggregated = {};

    for (final list in ingredientLists) {
      for (final ingredient in list) {
        final parsed = _parseIngredientWithQuantity(ingredient);
        
        if (aggregated.containsKey(parsed['name'])) {
          // Try to sum quantities
          final existing = aggregated[parsed['name']];
          if (existing is Map && parsed['quantity'] != null) {
            existing['total'] = (existing['total'] ?? 0) + parsed['quantity'];
          }
        } else {
          aggregated[parsed['name']] = parsed;
        }
      }
    }

    return aggregated.map(
      (name, data) {
        String display;
        if (data is Map && data['total'] != null) {
          display = '${data['total']} ${data['unit'] ?? ''}';
        } else {
          display = data.toString();
        }
        return MapEntry(name, display.trim());
      },
    );
  }

  /// Parse a single ingredient line into quantity, unit, and name
  /// Examples:
  /// "Tomatoes 1 kg" -> {quantity: 1, unit: "kg", name: "Tomatoes"}
  /// "Olive oil" -> {name: "Olive oil"}
  static Map<String, dynamic> _parseIngredientWithQuantity(String ingredient) {
    final pattern = RegExp(r'^(.+?)\s+(\d+(?:[.,]\d+)?)\s*([a-z%]*)', 
      caseSensitive: false);
    final match = pattern.firstMatch(ingredient);

    if (match != null) {
      return {
        'name': match.group(1)!.trim(),
        'quantity': double.tryParse(match.group(2)!.replaceAll(',', '.')) ?? 0,
        'unit': match.group(3)?.trim() ?? '',
        'total': double.tryParse(match.group(2)!.replaceAll(',', '.')) ?? 0,
      };
    }

    return {'name': ingredient.trim()};
  }
}

extension IntExtensions on int {
  /// Format calories to readable format
  /// 400 -> "400 kcal"
  String toCalorieString() => '$this kcal';

  /// Format protein to readable format
  /// 25 -> "25g protein"
  String toProteinString() => '${this}g protein';
}

extension DoubleExtensions on double {
  /// Format protein to readable format
  /// 25.5 -> "25.5g protein"
  String toProteinString() => '${toStringAsFixed(1)}g protein';
}