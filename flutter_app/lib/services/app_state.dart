import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/recipe.dart';
import '../models/session.dart';
import '../utils/extensions.dart';
import 'database_service.dart';
import 'import_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  // State variables
  List<Recipe> allRecipes = [];
  List<Recipe> filteredRecipes = [];
  List<Recipe> currentSessionRecipes = [];
  Session? currentSession;
  List<Session> pastSessions = [];

  // Settings
  int targetDishCount = 5;
  bool filterByLight = false;
  bool filterByFast = false;
  bool filterByLong = false;

  // Undo history
  List<Recipe> swipeHistory = [];
  List<bool> swipeWasLike = []; // Track if swipe was like (true) or skip (false)

  // Getters
  int get likedCount => currentSessionRecipes.length;
  bool get sessionComplete => likedCount >= targetDishCount;

  AppState() {
    _initialize();
  }

  // Initialize app
  Future<void> _initialize() async {
    // Load bundled recipes (only inserts new ones, preserves existing stats)
    await _loadBundledRecipes();
    await loadAllRecipes();
    await loadPastSessions();
    _applyFilters();
  }

  Future<void> _loadBundledRecipes() async {
    try {
      final jsonText = await rootBundle.loadString('assets/dishes_json.json');
      // Use importBundledRecipes to only insert NEW recipes — preserves pick/skip stats
      await ImportService().importBundledRecipes(jsonText);
    } catch (e) {
      debugPrint('Failed to load bundled recipes: $e');
    }
  }

  // Load all recipes from database
  Future<void> loadAllRecipes() async {
    allRecipes = await _dbService.getAllRecipes();
    _applyFilters();
    notifyListeners();
  }

  // Load past sessions
  Future<void> loadPastSessions() async {
    pastSessions = await _dbService.getAllSessions();
    notifyListeners();
  }

  // Start new session
  void startNewSession() {
    // Get recipes from previous session to exclude
    final excludeIds = currentSessionRecipes.map((r) => r.id).toSet();
    
    // Filter out recipes from previous session
    currentSessionRecipes = [];
    swipeHistory = [];
    swipeWasLike = [];
    currentSession = null;
    
    _applyFilters(excludeIds: excludeIds);
    notifyListeners();
  }

  // Add recipe to current session (swipe right)
  void likeRecipe(Recipe recipe) {
    swipeHistory.add(recipe);
    swipeWasLike.add(true);
    currentSessionRecipes.add(recipe);
    filteredRecipes.removeWhere((r) => r.id == recipe.id);
    _dbService.incrementPickCount(recipe.id);
    notifyListeners();
  }

  // Skip recipe (swipe left)
  void skipRecipe(Recipe recipe) {
    swipeHistory.add(recipe);
    swipeWasLike.add(false);
    filteredRecipes.removeWhere((r) => r.id == recipe.id);
    _dbService.incrementSkipCount(recipe.id);
    notifyListeners();
  }

  // Returns true if the undone swipe was a 'like', false if it was a 'skip' or nothing
  bool undoLastSwipe() {
    if (swipeHistory.isEmpty || swipeWasLike.isEmpty) return false;

    final wasLike = swipeWasLike.removeLast();
    final lastRecipe = swipeHistory.removeLast();

    if (wasLike) {
      // Remove from liked recipes and reverse the pick count
      currentSessionRecipes.removeWhere((r) => r.id == lastRecipe.id);
      _dbService.decrementPickCount(lastRecipe.id);
    } else {
      // Reverse the skip count
      _dbService.decrementSkipCount(lastRecipe.id);
    }

    // Re-add to filtered list if not already present. Insert at front so it appears next.
    if (!filteredRecipes.any((r) => r.id == lastRecipe.id)) {
      filteredRecipes.insert(0, lastRecipe);
    }

    notifyListeners();
    return wasLike;
  }

  // Add a recipe to the current session directly (from browse screen)
  bool addToSession(Recipe recipe) {
    if (sessionComplete) return false;
    if (currentSessionRecipes.any((r) => r.id == recipe.id)) return false;
    currentSessionRecipes.add(recipe);
    filteredRecipes.removeWhere((r) => r.id == recipe.id);
    _dbService.incrementPickCount(recipe.id);
    notifyListeners();
    return true;
  }

  // Remove a recipe from the current session (for editing selections)
  void removeFromSession(Recipe recipe) {
    final wasInSession = currentSessionRecipes.any((r) => r.id == recipe.id);
    currentSessionRecipes.removeWhere((r) => r.id == recipe.id);

    if (wasInSession) {
      // Reverse the pick count that was added when the recipe was liked/added.
      _dbService.decrementPickCount(recipe.id);

      // Drop any matching 'like' entry from the undo history so a later undo
      // doesn't try to remove/decrement this recipe a second time.
      final historyIndex = swipeHistory.lastIndexWhere((r) => r.id == recipe.id);
      if (historyIndex != -1 && swipeWasLike[historyIndex]) {
        swipeHistory.removeAt(historyIndex);
        swipeWasLike.removeAt(historyIndex);
      }
    }

    // Add back to filtered list so it can be swiped again
    if (!filteredRecipes.any((r) => r.id == recipe.id)) {
      filteredRecipes.insert(0, recipe);
    }
    notifyListeners();
  }

  // Apply filters and randomize order
  void _applyFilters({Set<String>? excludeIds}) {
    // Build set of all swiped recipe IDs (both liked and skipped) to exclude
    final swipedIds = swipeHistory.map((r) => r.id).toSet();

    filteredRecipes = allRecipes.where((recipe) {
      // Exclude recipes from previous session
      if (excludeIds != null && excludeIds.contains(recipe.id)) {
        return false;
      }

      // Exclude recipes already liked in current session
      if (currentSessionRecipes.any((r) => r.id == recipe.id)) {
        return false;
      }

      // Exclude recipes already swiped (liked or skipped) in current session
      if (swipedIds.contains(recipe.id)) {
        return false;
      }

      // Apply calorie filter
      if (filterByLight && !recipe.isLight) return false;

      // Apply time filters (can't use both fast and long together)
      if (filterByFast && !recipe.isFast) return false;
      if (filterByLong && !recipe.isLong) return false;

      return true;
    }).toList();

    // Randomize the order
    filteredRecipes.shuffle();

    notifyListeners();
  }

  // Set calorie filter
  void setLightFilter(bool value) {
    filterByLight = value;
    _applyFilters();
  }

  // Set time filter - Fast
  void setFastFilter(bool value) {
    filterByFast = value;
    if (value) filterByLong = false; // Can't be both
    _applyFilters();
  }

  // Set time filter - Long
  void setLongFilter(bool value) {
    filterByLong = value;
    if (value) filterByFast = false; // Can't be both
    _applyFilters();
  }

  // Clear filters
  void clearFilters() {
    filterByLight = false;
    filterByFast = false;
    filterByLong = false;
    _applyFilters();
  }

  // Set target dish count (don't clear history)
  void setTargetCount(int count) {
    targetDishCount = count;
    notifyListeners();
  }

  // Save current session with shopping list
Future<void> saveSession(String sessionName, Map<String, String> shoppingList, {Map<String, bool>? ingredientChecked, Map<String, String>? ingredientQuantities}) async {
  // Auto-generate name if empty
  final finalName = sessionName.isEmpty
      ? _formatDateTime(DateTime.now())
      : sessionName;

  final session = Session(
    sessionName: finalName,
    dateCreated: DateTime.now(),
    targetCount: targetDishCount,
    recipeIds: currentSessionRecipes.map((r) => r.id).toList(),
    shoppingList: shoppingList,
    ingredientChecked: ingredientChecked ?? {},
    ingredientQuantities: ingredientQuantities ?? {},
  );

  try {
    final id = await _dbService.insertSession(session);
    currentSession = session.copyWith(id: id);
    
    // Keep only last 4 sessions
    await _dbService.deleteOldSessions(maxSessions: 4);
    
    await loadPastSessions();

    // After saving a session, reset to a new session
    startNewSession();

    notifyListeners();
  } catch (e) {
    rethrow;
  }
}

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Merge the current session's recipes into an existing saved session.
  // Adds any new recipe ids and folds their ingredients into the shopping list
  // (preserving the existing list's items and manual edits), then persists.
  Future<void> mergeCurrentIntoSession(Session target) async {
    final mergedIds = List<String>.from(target.recipeIds);
    final mergedShopping = Map<String, String>.from(target.shoppingList);

    for (final recipe in currentSessionRecipes) {
      if (!mergedIds.contains(recipe.id)) {
        mergedIds.add(recipe.id);
      }
      for (final ingredient in recipe.ingredients.parseIngredients()) {
        // Match the existing shopping-list key format (full ingredient line).
        mergedShopping.putIfAbsent(ingredient, () => '');
      }
    }

    final updated = target.copyWith(
      recipeIds: mergedIds,
      shoppingList: mergedShopping,
    );
    await _dbService.updateSession(updated);
    await loadPastSessions();

    // Clear the in-progress selection now that it's been folded in.
    currentSessionRecipes = [];
    swipeHistory = [];
    swipeWasLike = [];
    _applyFilters();
    notifyListeners();
  }

  // Delete session
  Future<void> deleteSession(int sessionId) async {
    await _dbService.deleteSession(sessionId);
    await loadPastSessions();
    notifyListeners();
  }

  // Update an existing session (e.g., toggle shopping list checked state)
  Future<void> updateSession(Session session) async {
    await _dbService.updateSession(session);
    await loadPastSessions();
    notifyListeners();
  }

  // Get recipes for a session
  Future<List<Recipe>> getSessionRecipes(Session session) async {
    final recipes = <Recipe>[];
    for (var id in session.recipeIds) {
      final recipe = await _dbService.getRecipeById(id);
      if (recipe != null) recipes.add(recipe);
    }
    return recipes;
  }

  // Add recipe to database
  Future<void> addRecipe(Recipe recipe) async {
    await _dbService.insertRecipe(recipe);
    await loadAllRecipes();
  }

  // Delete recipe from database
  Future<void> deleteRecipe(String recipeId) async {
    await _dbService.deleteRecipe(recipeId);
    await loadAllRecipes();
  }

  // Import a shared Pickish session from JSON
  Future<String> importSharedSession(Map<String, dynamic> json) async {
    if (json['app'] != 'pickish' || json['type'] != 'session') {
      throw Exception('Not a valid Pickish session file');
    }

    final sessionData = json['session'] as Map<String, dynamic>;
    final recipesData = json['recipes'] as List<dynamic>? ?? [];

    // Import the recipes (use insertRecipeIfNew to avoid overwriting stats)
    for (var r in recipesData) {
      final recipe = Recipe.fromJson(r as Map<String, dynamic>);
      await _dbService.insertRecipeIfNew(recipe);
    }

    // Parse shopping list and checked maps
    final shoppingList = (sessionData['shopping_list'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {};
    final ingredientChecked = (sessionData['ingredient_checked'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v == true)) ?? {};
    final ingredientQuantities = (sessionData['ingredient_quantities'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {};

    // Create the session
    final session = Session(
      sessionName: sessionData['session_name'] ?? 'Imported Session',
      dateCreated: DateTime.tryParse(sessionData['date_created'] ?? '') ?? DateTime.now(),
      targetCount: sessionData['target_count'] ?? 5,
      recipeIds: List<String>.from(sessionData['recipe_ids'] ?? []),
      shoppingList: shoppingList,
      ingredientChecked: ingredientChecked,
      ingredientQuantities: ingredientQuantities,
    );

    await _dbService.insertSession(session);
    await loadAllRecipes();
    await loadPastSessions();
    notifyListeners();

    return session.sessionName;
  }
}