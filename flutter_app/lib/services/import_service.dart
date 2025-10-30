import 'dart:convert';
import '../models/recipe.dart';
import 'database_service.dart';

class ImportService {
  final DatabaseService _dbService = DatabaseService();

  // Import recipes from JSON text
  Future<List<Recipe>> importFromJsonText(String jsonText) async {
    try {
      print('DEBUG: Starting import...');
      final decoded = jsonDecode(jsonText);
      print('DEBUG: JSON decoded successfully');
      final recipes = _parseRecipes(decoded);
      print('DEBUG: Parsed ${recipes.length} recipes');
      
      // Save to database
      for (var recipe in recipes) {
        await _dbService.insertRecipe(recipe);
        print('DEBUG: Saved recipe: ${recipe.dishName}');
      }
      
      print('DEBUG: Import complete - ${recipes.length} recipes saved');
      return recipes;
    } catch (e) {
      print('DEBUG: Import error: $e');
      throw Exception('Failed to parse JSON: $e');
    }
  }

  // Parse recipes from decoded JSON
  List<Recipe> _parseRecipes(dynamic decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON structure');
    }

    final recipesList = decoded['recipes'];
    if (recipesList is! List) {
      throw Exception('recipes field must be an array');
    }

    return [
      for (var r in recipesList)
        Recipe.fromJson(r as Map<String, dynamic>)
    ];
  }

  // Export recipes to JSON (for backup)
  Future<String> exportRecipesToJson(List<Recipe> recipes) async {
    final json = {
      'recipes': [for (var r in recipes) r.toJson()]
    };
    return jsonEncode(json);
  }
}