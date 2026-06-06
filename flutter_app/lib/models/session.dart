import 'dart:convert';

class Session {
  final int? id;
  final String sessionName;
  final DateTime dateCreated;
  final int targetCount;
  final List<String> recipeIds;
  final Map<String, String> ingredientQuantities;
  final Map<String, bool> ingredientChecked;
  final Map<String, bool> recipesCooked;
  final Map<String, String> shoppingList;

  Session({
    this.id,
    required this.sessionName,
    required this.dateCreated,
    required this.targetCount,
    required this.recipeIds,
    this.ingredientQuantities = const {},
    this.ingredientChecked = const {},
    this.recipesCooked = const {},
    this.shoppingList = const {},
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'session_name': sessionName,
    'date_created': dateCreated.toIso8601String(),
    'target_count': targetCount,
    'recipe_ids': recipeIds.join(','),
    'ingredient_quantities': ingredientQuantities,
    'ingredient_checked': ingredientChecked,
    'recipes_cooked': recipesCooked,
    'shopping_list': shoppingList,
  };

  /// Parse recipe_ids from either a comma-separated string (DB) or a List (JSON import).
  static List<String> _parseRecipeIds(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((e) => e.toString()).where((id) => id.isNotEmpty).toList();
    }
    if (data is String) {
      return data.split(',').where((id) => id.isNotEmpty).toList();
    }
    return [];
  }

  // Create from JSON
  factory Session.fromJson(Map<String, dynamic> json) {
    // Helper function to parse map fields
    Map<String, String> parseStringMap(dynamic data) {
      if (data == null) return {};
      if (data is Map<String, String>) return data;
      if (data is String && data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    Map<String, bool> parseBoolMap(dynamic data) {
      if (data == null) return {};
      if (data is Map<String, bool>) return data;
      if (data is String && data.isNotEmpty) {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          return decoded.map((k, v) => MapEntry(k.toString(), v == true));
        } catch (e) {
          return {};
        }
      }
      return {};
    }

    return Session(
      id: json['id'],
      sessionName: json['session_name'] ?? 'Unnamed Session',
      dateCreated: DateTime.tryParse(json['date_created'] ?? '') ?? DateTime.now(),
      targetCount: json['target_count'] ?? 5,
      recipeIds: _parseRecipeIds(json['recipe_ids']),
      ingredientQuantities: parseStringMap(json['ingredient_quantities']),
      ingredientChecked: parseBoolMap(json['ingredient_checked']),
      recipesCooked: parseBoolMap(json['recipes_cooked']),
      shoppingList: parseStringMap(json['shopping_list']),
    );
  }

  Session copyWith({
    int? id,
    String? sessionName,
    DateTime? dateCreated,
    int? targetCount,
    List<String>? recipeIds,
    Map<String, String>? ingredientQuantities,
    Map<String, bool>? ingredientChecked,
    Map<String, bool>? recipesCooked,
    Map<String, String>? shoppingList,
  }) {
    return Session(
      id: id ?? this.id,
      sessionName: sessionName ?? this.sessionName,
      dateCreated: dateCreated ?? this.dateCreated,
      targetCount: targetCount ?? this.targetCount,
      recipeIds: recipeIds ?? this.recipeIds,
      ingredientQuantities: ingredientQuantities ?? this.ingredientQuantities,
      ingredientChecked: ingredientChecked ?? this.ingredientChecked,
      recipesCooked: recipesCooked ?? this.recipesCooked,
      shoppingList: shoppingList ?? this.shoppingList,
    );
  }
}