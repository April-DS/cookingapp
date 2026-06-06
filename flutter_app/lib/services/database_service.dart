import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';
import '../models/session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'cooking_app.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN ingredient_quantities TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN ingredient_checked TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN recipes_cooked TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN shopping_list TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN pick_count INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN skip_count INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN servings INTEGER DEFAULT 2');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sessions ADD COLUMN recipe_portions TEXT');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Recipes table
    await db.execute('''
      CREATE TABLE recipes(
        id TEXT PRIMARY KEY,
        dish_name TEXT NOT NULL,
        prep_time INTEGER,
        cook_time INTEGER,
        total_time INTEGER,
        kcal INTEGER,
        protein_g REAL,
        highlights TEXT,
        ingredients TEXT,
        instructions TEXT,
        image_description TEXT,
        image_filename TEXT,
        servings INTEGER DEFAULT 2,
        pick_count INTEGER DEFAULT 0,
        skip_count INTEGER DEFAULT 0
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_name TEXT NOT NULL,
        date_created TEXT NOT NULL,
        target_count INTEGER,
        recipe_ids TEXT NOT NULL,
        ingredient_quantities TEXT,
        ingredient_checked TEXT,
        recipes_cooked TEXT,
        shopping_list TEXT,
        recipe_portions TEXT
      )
    ''');
  }

  // ========== RECIPE METHODS ==========

  Future<void> insertRecipe(Recipe recipe) async {
    final db = await database;
    await db.insert(
      'recipes',
      {
        'id': recipe.id,
        'dish_name': recipe.dishName,
        'prep_time': recipe.prepTime,
        'cook_time': recipe.cookTime,
        'total_time': recipe.totalTime,
        'kcal': recipe.kcal,
        'protein_g': recipe.proteinG,
        'highlights': recipe.highlights,
        'ingredients': recipe.ingredients,
        'instructions': recipe.instructions,
        'image_description': recipe.imageDescription,
        'image_filename': recipe.imageFilename,
        'servings': recipe.servings,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert a recipe only if it doesn't already exist (preserves pick/skip counts).
  Future<void> insertRecipeIfNew(Recipe recipe) async {
    final db = await database;
    await db.insert(
      'recipes',
      {
        'id': recipe.id,
        'dish_name': recipe.dishName,
        'prep_time': recipe.prepTime,
        'cook_time': recipe.cookTime,
        'total_time': recipe.totalTime,
        'kcal': recipe.kcal,
        'protein_g': recipe.proteinG,
        'highlights': recipe.highlights,
        'ingredients': recipe.ingredients,
        'instructions': recipe.instructions,
        'image_description': recipe.imageDescription,
        'image_filename': recipe.imageFilename,
        'servings': recipe.servings,
        'pick_count': 0,
        'skip_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final maps = await db.query('recipes');
    return [
      for (var m in maps)
        Recipe.fromJson({
          'id': m['id'] ?? '',
          'dish_name': m['dish_name'] ?? '',
          'cooking_time': {
            'prep_time': m['prep_time'] ?? 0,
            'cook_time': m['cook_time'] ?? 0,
            'total_time': m['total_time'] ?? 0,
          },
          'nutrition': {
            'kcal': m['kcal'] ?? 0,
            'protein_g': m['protein_g'] ?? 0,
            'highlights': m['highlights'] ?? '',
          },
          'ingredients': m['ingredients'] ?? '',
          'instructions': m['instructions'] ?? '',
          'image_description': m['image_description'] ?? '',
          'image_filename': m['image_filename'] ?? '',
          'servings': m['servings'] ?? 2,
          'pick_count': m['pick_count'] ?? 0,
          'skip_count': m['skip_count'] ?? 0,
        })
    ];
  }

  Future<Recipe?> getRecipeById(String id) async {
    final db = await database;
    final maps = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    return Recipe.fromJson({
      'id': m['id'] ?? '',
      'dish_name': m['dish_name'] ?? '',
      'cooking_time': {
        'prep_time': m['prep_time'] ?? 0,
        'cook_time': m['cook_time'] ?? 0,
        'total_time': m['total_time'] ?? 0,
      },
      'nutrition': {
        'kcal': m['kcal'] ?? 0,
        'protein_g': m['protein_g'] ?? 0,
        'highlights': m['highlights'] ?? '',
      },
      'ingredients': m['ingredients'] ?? '',
      'instructions': m['instructions'] ?? '',
      'image_description': m['image_description'] ?? '',
      'image_filename': m['image_filename'] ?? '',
      'servings': m['servings'] ?? 2,
      'pick_count': m['pick_count'] ?? 0,
      'skip_count': m['skip_count'] ?? 0,
    });
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final db = await database;
    await db.update(
      'recipes',
      {
        'dish_name': recipe.dishName,
        'prep_time': recipe.prepTime,
        'cook_time': recipe.cookTime,
        'total_time': recipe.totalTime,
        'kcal': recipe.kcal,
        'protein_g': recipe.proteinG,
        'highlights': recipe.highlights,
        'ingredients': recipe.ingredients,
        'instructions': recipe.instructions,
        'image_description': recipe.imageDescription,
        'image_filename': recipe.imageFilename,
        'servings': recipe.servings,
        'pick_count': recipe.pickCount,
        'skip_count': recipe.skipCount,
      },
      where: 'id = ?',
      whereArgs: [recipe.id],
    );
  }

  Future<void> deleteRecipe(String id) async {
    final db = await database;
    await db.delete(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update only the curated servings for a recipe (preserves pick/skip stats).
  Future<void> updateRecipeServings(String recipeId, int servings) async {
    final db = await database;
    await db.update(
      'recipes',
      {'servings': servings},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<void> incrementPickCount(String recipeId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE recipes SET pick_count = COALESCE(pick_count, 0) + 1 WHERE id = ?',
      [recipeId],
    );
  }

  Future<void> incrementSkipCount(String recipeId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE recipes SET skip_count = COALESCE(skip_count, 0) + 1 WHERE id = ?',
      [recipeId],
    );
  }

  Future<void> decrementPickCount(String recipeId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE recipes SET pick_count = MAX(COALESCE(pick_count, 0) - 1, 0) WHERE id = ?',
      [recipeId],
    );
  }

  Future<void> decrementSkipCount(String recipeId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE recipes SET skip_count = MAX(COALESCE(skip_count, 0) - 1, 0) WHERE id = ?',
      [recipeId],
    );
  }

  // ========== SESSION METHODS ==========

  Future<int> insertSession(Session session) async {
    final db = await database;
    
    final result = await db.insert(
      'sessions',
      {
        'session_name': session.sessionName,
        'date_created': session.dateCreated.toIso8601String(),
        'target_count': session.targetCount,
        'recipe_ids': session.recipeIds.join(','),
        'ingredient_quantities': jsonEncode(session.ingredientQuantities),
        'ingredient_checked': jsonEncode(session.ingredientChecked),
        'recipes_cooked': jsonEncode(session.recipesCooked),
        'shopping_list': jsonEncode(session.shoppingList),
        'recipe_portions': jsonEncode(session.recipePortions),
      },
    );

    return result;
  }

  Future<void> updateSession(Session session) async {
    final db = await database;
    
    await db.update(
      'sessions',
      {
        'session_name': session.sessionName,
        'date_created': session.dateCreated.toIso8601String(),
        'target_count': session.targetCount,
        'recipe_ids': session.recipeIds.join(','),
        'ingredient_quantities': jsonEncode(session.ingredientQuantities),
        'ingredient_checked': jsonEncode(session.ingredientChecked),
        'recipes_cooked': jsonEncode(session.recipesCooked),
        'shopping_list': jsonEncode(session.shoppingList),
        'recipe_portions': jsonEncode(session.recipePortions),
      },
      where: 'id = ?',
      whereArgs: [session.id],
    );

  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date_created DESC');

    final sessions = <Session>[];
    for (var m in maps) {
      try {
        sessions.add(_sessionFromRow(m));
      } catch (e) {
      }
    }

    return sessions;
  }

  /// Build a Session from a DB row with null-safe parsing of every field.
  Session _sessionFromRow(Map<String, dynamic> m) {
    final rawIds = m['recipe_ids'];
    final recipeIds = (rawIds is String)
        ? rawIds.split(',').where((id) => id.isNotEmpty).toList()
        : <String>[];
    return Session(
      id: m['id'] as int?,
      sessionName: m['session_name'] as String? ?? 'Unnamed Session',
      dateCreated: DateTime.tryParse(m['date_created']?.toString() ?? '') ?? DateTime.now(),
      targetCount: m['target_count'] as int? ?? 5,
      recipeIds: recipeIds,
      ingredientQuantities: _parseJsonMap<String, String>(m['ingredient_quantities']),
      ingredientChecked: _parseJsonMap<String, bool>(m['ingredient_checked']),
      recipesCooked: _parseJsonMap<String, bool>(m['recipes_cooked']),
      shoppingList: _parseJsonMap<String, String>(m['shopping_list']),
      recipePortions: _parseJsonMap<String, int>(m['recipe_portions']),
    );
  }

  Map<K, V> _parseJsonMap<K, V>(dynamic jsonData) {
    if (jsonData == null) return {};
    try {
      if (jsonData is String) {
        final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k as K, v as V));
      }
      if (jsonData is Map) {
        return jsonData.map((k, v) => MapEntry(k as K, v as V));
      }
    } catch (e) {
    }
    return {};
  }

  Future<Session?> getSessionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return _sessionFromRow(maps.first);
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete old sessions, keeping only the most recent maxSessions
  Future<void> deleteOldSessions({int maxSessions = 4}) async {
    final db = await database;
    
    // Get all sessions ordered by date
    final sessions = await db.query(
      'sessions',
      orderBy: 'date_created DESC',
    );

    // Delete sessions beyond maxSessions
    if (sessions.length > maxSessions) {
      for (var i = maxSessions; i < sessions.length; i++) {
        await db.delete(
          'sessions',
          where: 'id = ?',
          whereArgs: [sessions[i]['id']],
        );
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}