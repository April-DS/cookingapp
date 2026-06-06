class IngredientCategories {
  static const Map<String, List<String>> _categoryKeywords = {
    'Produce': [
      'tomato', 'onion', 'garlic', 'pepper', 'lettuce', 'spinach',
      'carrot', 'potato', 'sweet potato', 'broccoli', 'cauliflower',
      'zucchini', 'eggplant', 'capsicum', 'mushroom', 'cucumber',
      'avocado', 'lemon', 'lime', 'ginger', 'celery', 'kale',
      'basil', 'cilantro', 'parsley', 'mint', 'rosemary', 'thyme',
      'oregano', 'dill', 'chili', 'jalapeno', 'shallot', 'leek',
      'corn', 'peas', 'bean sprout', 'cabbage', 'pumpkin', 'squash',
      'beetroot', 'radish', 'asparagus', 'artichoke', 'fennel',
      'spring onion', 'scallion', 'chive', 'rocket', 'arugula',
      'pineapple', 'mango', 'banana', 'apple', 'berry',
    ],
    'Meat & Seafood': [
      'chicken', 'beef', 'pork', 'lamb', 'turkey', 'bacon',
      'sausage', 'mince', 'steak', 'salmon', 'tuna', 'fish',
      'shrimp', 'prawn', 'cod', 'barramundi', 'anchov',
      'sardine', 'crab', 'lobster', 'mussel', 'calamari', 'squid',
    ],
    'Dairy & Eggs': [
      'milk', 'cream', 'cheese', 'butter', 'yogurt', 'yoghurt',
      'egg', 'feta', 'mozzarella', 'parmesan', 'ricotta',
      'sour cream', 'creme fraiche', 'mascarpone',
    ],
    'Grains & Pasta': [
      'rice', 'pasta', 'noodle', 'bread', 'flour', 'oat',
      'quinoa', 'couscous', 'buckwheat', 'tortilla', 'pita',
      'spaghetti', 'penne', 'fettuccine', 'macaroni',
      'breadcrumb', 'panko', 'wrap',
    ],
    'Canned & Jarred': [
      'canned', 'tinned', 'can of', 'jar of', 'passata',
      'tomato paste', 'tomato sauce', 'coconut milk', 'coconut cream',
      'chickpea', 'lentil', 'kidney bean', 'black bean', 'white bean',
      'baked bean', 'corn kernel', 'olive',
    ],
    'Oils & Condiments': [
      'oil', 'vinegar', 'soy sauce', 'worcestershire', 'hot sauce',
      'mustard', 'ketchup', 'mayonnaise', 'honey', 'maple syrup',
      'sriracha', 'tahini', 'pesto', 'salsa', 'miso',
      'fish sauce', 'oyster sauce', 'hoisin',
    ],
    'Spices & Seasoning': [
      'salt', 'pepper', 'cumin', 'paprika', 'turmeric', 'cinnamon',
      'nutmeg', 'coriander', 'curry', 'chili powder', 'cayenne',
      'bay leaf', 'saffron', 'cardamom', 'clove', 'star anise',
      'smoked paprika', 'dried', 'ground', 'seasoning', 'spice',
    ],
    'Nuts & Seeds': [
      'almond', 'walnut', 'cashew', 'peanut', 'pistachio',
      'pine nut', 'pecan', 'hazelnut', 'sesame', 'sunflower',
      'pumpkin seed', 'chia', 'flax', 'hemp',
    ],
  };

  static String categorize(String ingredient) {
    final lower = ingredient.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'Other';
  }

  static Map<String, List<String>> groupByCategory(List<String> ingredients) {
    final grouped = <String, List<String>>{};
    for (final ingredient in ingredients) {
      final category = categorize(ingredient);
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(ingredient);
    }
    // Sort categories in a fixed order
    final orderedCategories = [
      'Produce',
      'Meat & Seafood',
      'Dairy & Eggs',
      'Grains & Pasta',
      'Canned & Jarred',
      'Oils & Condiments',
      'Spices & Seasoning',
      'Nuts & Seeds',
      'Other',
    ];
    final result = <String, List<String>>{};
    for (final cat in orderedCategories) {
      if (grouped.containsKey(cat)) {
        result[cat] = grouped[cat]!..sort();
      }
    }
    return result;
  }
}
