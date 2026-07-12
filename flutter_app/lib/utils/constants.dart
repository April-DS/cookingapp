// ============ lib/utils/constants.dart ============

class AppConstants {
  // App info
  static const String appName = 'Pickish';
  static const String appVersion = '1.3.0';

  // Database
  static const String dbName = 'cooking_app.db';
  static const String recipesTable = 'recipes';
  static const String sessionsTable = 'sessions';

  // Image assets
  static const String recipeImagesPath = 'assets/recipe_images/';

  // Default settings
  static const int defaultTargetCount = 5;
  static const int minTargetCount = 1;
  static const int maxTargetCount = 20;

  // Filter thresholds
  static const int lightCalorieThreshold = 500;
  static const int fastCookTimeThreshold = 30;
  static const int longCookTimeThreshold = 60;

  // UI constants
  static const double cardCornerRadius = 12.0;
  static const double buttonCornerRadius = 8.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
}