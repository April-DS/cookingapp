class Session {
  final int? id;
  final String sessionName;
  final DateTime dateCreated;
  final int targetCount;
  final List<String> recipeIds; // Recipe IDs selected in this session
  final Map<String, int> ingredientQuantities; // For shopping list aggregation
  final Map<String, bool> ingredientChecked; // Tick state for shopping items

  Session({
    this.id,
    required this.sessionName,
    required this.dateCreated,
    required this.targetCount,
    required this.recipeIds,
    this.ingredientQuantities = const {},
    this.ingredientChecked = const {},
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'session_name': sessionName,
    'date_created': dateCreated.toIso8601String(),
    'target_count': targetCount,
    'recipe_ids': recipeIds.join(','), // Store as comma-separated
    'ingredient_quantities': ingredientQuantities,
    'ingredient_checked': ingredientChecked,
  };

  // Create from JSON
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      sessionName: json['session_name'] ?? 'Unnamed Session',
      dateCreated: DateTime.parse(json['date_created']),
      targetCount: json['target_count'] ?? 5,
      recipeIds: (json['recipe_ids'] as String).split(','),
      ingredientQuantities: Map<String, int>.from(json['ingredient_quantities'] ?? {}),
      ingredientChecked: Map<String, bool>.from(json['ingredient_checked'] ?? {}),
    );
  }

  Session copyWith({
    int? id,
    String? sessionName,
    DateTime? dateCreated,
    int? targetCount,
    List<String>? recipeIds,
    Map<String, int>? ingredientQuantities,
    Map<String, bool>? ingredientChecked,
  }) {
    return Session(
      id: id ?? this.id,
      sessionName: sessionName ?? this.sessionName,
      dateCreated: dateCreated ?? this.dateCreated,
      targetCount: targetCount ?? this.targetCount,
      recipeIds: recipeIds ?? this.recipeIds,
      ingredientQuantities: ingredientQuantities ?? this.ingredientQuantities,
      ingredientChecked: ingredientChecked ?? this.ingredientChecked,
    );
  }
}
