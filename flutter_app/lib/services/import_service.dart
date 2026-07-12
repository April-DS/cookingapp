import 'dart:convert';
import '../models/recipe.dart';
import 'database_service.dart';

class ImportService {
  final DatabaseService _dbService = DatabaseService();

  // Import recipes from JSON text (replaces existing — used for manual imports)
  Future<List<Recipe>> importFromJsonText(String jsonText) async {
    try {
      final decoded = jsonDecode(jsonText);
      final recipes = _parseRecipes(decoded);

      // Save to database
      for (var recipe in recipes) {
        await _dbService.insertRecipe(recipe);
      }

      return recipes;
    } catch (e) {
      throw Exception('Failed to parse JSON: $e');
    }
  }

  // Import bundled recipes — only inserts NEW recipes, preserves existing stats
  Future<List<Recipe>> importBundledRecipes(String jsonText) async {
    try {
      final decoded = jsonDecode(jsonText);
      final recipes = _parseRecipes(decoded);

      for (var recipe in recipes) {
        await _dbService.insertRecipeIfNew(recipe);
        // Keep curated servings/category in sync for already-installed
        // recipes without touching their pick/skip stats.
        await _dbService.updateRecipeMeta(recipe.id, recipe.servings, recipe.category);
      }

      return recipes;
    } catch (e) {
      throw Exception('Failed to parse bundled JSON: $e');
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