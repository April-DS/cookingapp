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
      version: 1,
      onCreate: _onCreate,
    );
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
        image_filename TEXT
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
        ingredient_checked TEXT
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
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    return Recipe.fromJson(maps.first);
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final db = await database;
    await db.update(
      'recipes',
      recipe.toJson(),
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

  // ========== SESSION METHODS ==========

  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert(
      'sessions',
      {
        'session_name': session.sessionName,
        'date_created': session.dateCreated.toIso8601String(),
        'target_count': session.targetCount,
        'recipe_ids': session.recipeIds.join(','),
      },
    );
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final maps = await db.query('sessions', orderBy: 'date_created DESC');
    return [for (var m in maps) Session.fromJson(m)];
  }

  Future<Session?> getSessionById(int id) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Session.fromJson(maps.first);
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}