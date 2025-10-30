class Recipe {
  final String id;
  final String dishName;
  final int prepTime;
  final int cookTime;
  final int totalTime;
  final int kcal;
  final double proteinG;
  final String highlights;
  final String ingredients;
  final String instructions;
  final String imageDescription;
  final String imageFilename;

  Recipe({
    required this.id,
    required this.dishName,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.kcal,
    required this.proteinG,
    required this.highlights,
    required this.ingredients,
    required this.instructions,
    required this.imageDescription,
    required this.imageFilename,
  });

  // Convert from JSON
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final cookingTime = json['cooking_time'] as Map<String, dynamic>? ?? {};
    final nutrition = json['nutrition'] as Map<String, dynamic>? ?? {};

    return Recipe(
      id: json['id'] ?? '',
      dishName: json['dish_name'] ?? '',
      prepTime: (cookingTime['prep_time'] as int?) ?? 0,
      cookTime: (cookingTime['cook_time'] as int?) ?? 0,
      totalTime: (cookingTime['total_time'] as int?) ?? 0,
      kcal: (nutrition['kcal'] as int?) ?? 0,
      proteinG: (nutrition['protein_g'] as num?)?.toDouble() ?? 0.0,
      highlights: nutrition['highlights'] as String? ?? '',
      ingredients: json['ingredients'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      imageDescription: json['image_description'] as String? ?? '',
      imageFilename: json['image_filename'] as String? ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'dish_name': dishName,
    'cooking_time': {
      'prep_time': prepTime,
      'cook_time': cookTime,
      'total_time': totalTime,
    },
    'nutrition': {
      'kcal': kcal,
      'protein_g': proteinG,
      'highlights': highlights,
    },
    'ingredients': ingredients,
    'instructions': instructions,
    'image_description': imageDescription,
    'image_filename': imageFilename,
  };

  // Check if "light" (<=500 kcal)
  bool get isLight => kcal <= 500;

  // Check if "fast" (<=25 min)
  bool get isFast => totalTime <= 25;

  // Check if "long" (>=60 min)
  bool get isLong => totalTime >= 60;
}