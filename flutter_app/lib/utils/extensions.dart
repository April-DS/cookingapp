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
        final name = parsed['name'] as String;
        
        if (aggregated.containsKey(name)) {
          final existing = aggregated[name] as Map<String, dynamic>;
          final existingQuantity = existing['quantity'] ?? 0.0;
          final existingUnit = existing['unit'] ?? '';
          final newQuantity = parsed['quantity'] ?? 0.0;
          final newUnit = parsed['unit'] ?? '';
          
          // Only combine if units match
          if (existingUnit == newUnit) {
            aggregated[name] = {
              'quantity': (existingQuantity as double) + (newQuantity as double),
              'unit': existingUnit,
            };
          } else {
            // If units don't match, keep as separate entries
            final uniqueKey = '$name (${parsed['unit']})';
            if (!aggregated.containsKey(uniqueKey)) {
              aggregated[uniqueKey] = {
                'quantity': newQuantity,
                'unit': newUnit,
              };
            }
          }
        } else {
          aggregated[name] = {
            'quantity': parsed['quantity'],
            'unit': parsed['unit'],
          };
        }
      }
    }

    // Convert to final string format
    return aggregated.map((name, data) {
      if (data is Map<String, dynamic>) {
        final quantity = data['quantity'];
        final unit = data['unit'] as String;
        
        if (quantity != null && quantity > 0) {
          final q = quantity as double;
          final quantityStr = q.toStringAsFixed(q % 1 == 0 ? 0 : 1);
          return MapEntry(name, '$quantityStr${unit.isNotEmpty ? ' $unit' : ''}');
        }
      }
      return MapEntry(name, '');
    });
  }

  /// Parse a single ingredient line into quantity, unit, and name
  static Map<String, dynamic> _parseIngredientWithQuantity(String ingredient) {
    // Simple parsing - look for numbers at the beginning
    final pattern = RegExp(r'^(\d+(?:\.\d+)?)\s*([a-zA-Z]*)\s+(.+)');
    final match = pattern.firstMatch(ingredient);

    if (match != null) {
      return {
        'quantity': double.tryParse(match.group(1)!) ?? 0.0,
        'unit': match.group(2)?.trim() ?? '',
        'name': match.group(3)?.trim() ?? ingredient.trim(),
      };
    }

    // If no quantity found, return the whole string as name
    return {
      'quantity': 0.0,
      'unit': '',
      'name': ingredient.trim(),
    };
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