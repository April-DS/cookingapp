import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/session.dart';
import 'database_service.dart';

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
    await loadAllRecipes();
    await loadPastSessions();
    _applyFilters();
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
    currentSession = null;
    
    _applyFilters(excludeIds: excludeIds);
    notifyListeners();
  }

  // Add recipe to current session (swipe right)
  void likeRecipe(Recipe recipe) {
    swipeHistory.add(recipe);
    currentSessionRecipes.add(recipe);
    filteredRecipes.removeWhere((r) => r.id == recipe.id);
    notifyListeners();
  }

  // Skip recipe (swipe left)
  void skipRecipe(Recipe recipe) {
    filteredRecipes.removeWhere((r) => r.id == recipe.id);
    notifyListeners();
  }

  // Undo last swipe
  void undoLastSwipe() {
    if (swipeHistory.isEmpty) return;
    
    final lastRecipe = swipeHistory.removeLast();
    currentSessionRecipes.removeWhere((r) => r.id == lastRecipe.id);
    
    // Re-add to filtered list
    filteredRecipes.add(lastRecipe);
    filteredRecipes.sort((a, b) => a.dishName.compareTo(b.dishName));
    
    notifyListeners();
  }

  // Apply filters
  void _applyFilters({Set<String>? excludeIds}) {
    filteredRecipes = allRecipes.where((recipe) {
      // Exclude recipes from previous session
      if (excludeIds != null && excludeIds.contains(recipe.id)) {
        return false;
      }

      // Exclude recipes already liked in current session
      if (currentSessionRecipes.any((r) => r.id == recipe.id)) {
        return false;
      }

      // Apply calorie filter
      if (filterByLight && !recipe.isLight) return false;

      // Apply time filters (can't use both fast and long together)
      if (filterByFast && !recipe.isFast) return false;
      if (filterByLong && !recipe.isLong) return false;

      return true;
    }).toList();

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
  Future<void> saveSession(String sessionName, Map<String, String> shoppingList) async {
    print('DEBUG AppState: saveSession called with ${shoppingList.length} items');
    
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
    );

    try {
      final id = await _dbService.insertSession(session);
      print('DEBUG AppState: Session saved with ID: $id');
      currentSession = session.copyWith(id: id);
      
      // Keep only last 4 sessions
      await _dbService.deleteOldSessions(maxSessions: 4);
      
      await loadPastSessions();
      notifyListeners();
    } catch (e) {
      print('DEBUG AppState: Error saving session: $e');
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Delete session
  Future<void> deleteSession(int sessionId) async {
    await _dbService.deleteSession(sessionId);
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
}