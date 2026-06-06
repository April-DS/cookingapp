import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../widgets/recipe_card.dart';
import '../widgets/filter_modal.dart';
import 'recipe_detail_screen.dart';
import 'shopping_list_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({Key? key}) : super(key: key);

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.startNewSession();
    });
  }

  void _handleSwipeRight(AppState appState) {
    if (_currentIndex < appState.filteredRecipes.length) {
      appState.likeRecipe(appState.filteredRecipes[_currentIndex]);

      if (appState.sessionComplete) {
        _showSessionCompleteDialog(appState);
      } else {
        setState(() {
          // likeRecipe removes the recipe from filteredRecipes, so the list
          // shrinks and _currentIndex now points to the next recipe already.
          // Clamp to stay in bounds (min 0 to avoid negative index).
          if (_currentIndex >= appState.filteredRecipes.length) {
            _currentIndex = appState.filteredRecipes.isEmpty
                ? 0
                : appState.filteredRecipes.length - 1;
          }
        });
      }
    }
  }

  void _handleSwipeLeft(AppState appState) {
    if (_currentIndex < appState.filteredRecipes.length) {
      appState.skipRecipe(appState.filteredRecipes[_currentIndex]);
      setState(() {
        // skipRecipe removes the recipe from filteredRecipes, so the list
        // shrinks and _currentIndex now points to the next recipe already.
        // Clamp to stay in bounds (min 0 to avoid negative index).
        if (_currentIndex >= appState.filteredRecipes.length) {
          _currentIndex = appState.filteredRecipes.isEmpty
              ? 0
              : appState.filteredRecipes.length - 1;
        }
      });
    }
  }

  void _handleUndo(AppState appState) {
    if (appState.swipeHistory.isEmpty) return;

    appState.undoLastSwipe();
    // undoLastSwipe() inserts the restored recipe at index 0 of filteredRecipes,
    // so always jump to index 0 to show the restored card.
    setState(() => _currentIndex = 0);
  }

  void _showSessionCompleteDialog(AppState appState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 48, color: AppTheme.success),
              SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Perfect!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppConstants.smallPadding),
              Text(
                'You\'ve selected ${appState.targetDishCount} delicious recipes',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.defaultPadding * 1.5),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShoppingListScreen(),
                    ),
                  );
                },
                child: Text('View Shopping List'),
              ),
              SizedBox(height: AppConstants.smallPadding),
              OutlinedButton.icon(
                icon: Icon(Icons.edit, size: 18),
                label: Text('Edit Selection'),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditSelectionSheet(appState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSelectionSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final recipes = List<Recipe>.from(appState.currentSessionRecipes);
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Recipes (${recipes.length}/${appState.targetDishCount})',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Done'),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.smallPadding),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return Card(
                            color: AppTheme.darkBg,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Image.asset(
                                    'assets/recipe_images/${recipe.imageFilename}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: AppTheme.pastelMint,
                                      child: Icon(Icons.restaurant, color: AppTheme.darkBg),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                recipe.dishName,
                                style: TextStyle(color: AppTheme.textLight),
                              ),
                              subtitle: Text(
                                '${recipe.kcal} kcal • ${StringExtensions.formatDuration(recipe.totalTime)}',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.remove_circle, color: AppTheme.error),
                                onPressed: () {
                                  appState.removeFromSession(recipe);
                                  setSheetState(() {});
                                  setState(() {
                                    _currentIndex = 0;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterModal(AppState appState) {
    showDialog(
      context: context,
      builder: (context) => FilterModal(
        initialLight: appState.filterByLight,
        initialFast: appState.filterByFast,
        initialLong: appState.filterByLong,
        allRecipes: appState.allRecipes,
        onApply: (light, fast, long) {
          appState.setLightFilter(light);
          appState.setFastFilter(fast);
          appState.setLongFilter(long);
          setState(() => _currentIndex = 0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pickish'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/browse'),
            tooltip: 'Browse Recipes',
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, '/statistics').then((_) {
              // Reload recipes to get updated stats
              Provider.of<AppState>(context, listen: false).loadAllRecipes();
            }),
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.filteredRecipes.isEmpty) {
            return _buildEmptyState(context, appState);
          }

          // Clamp index safely (avoid side-effect assignment during build by
          // using a local variable; schedule a post-frame correction if needed).
          var safeIndex = _currentIndex;
          if (safeIndex >= appState.filteredRecipes.length) {
            safeIndex = appState.filteredRecipes.length - 1;
          }
          if (safeIndex < 0) safeIndex = 0;
          if (safeIndex != _currentIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _currentIndex = safeIndex);
            });
          }

          final currentRecipe = appState.filteredRecipes[safeIndex];

          return SafeArea(
            top: false,
            child: Column(
              children: [
                // Progress counter - tap to preview/edit chosen recipes
                GestureDetector(
                  onTap: appState.likedCount > 0
                      ? () => _showEditSelectionSheet(appState)
                      : null,
                  child: Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      children: [
                        Text(
                          'Your Selection',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        SizedBox(height: AppConstants.smallPadding),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding,
                            vertical: AppConstants.smallPadding,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBgSecondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${appState.likedCount} / ${appState.targetDishCount}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: AppTheme.pastelMint,
                                    ),
                              ),
                              if (appState.likedCount > 0) ...[
                                SizedBox(width: 8),
                                Icon(
                                  Icons.visibility,
                                  size: 18,
                                  color: AppTheme.pastelMint,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Swipe progress indicator
                Text(
                  'Card ${safeIndex + 1} of ${appState.filteredRecipes.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: AppConstants.smallPadding),

                // Recipe card
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    child: RecipeCard(
                      recipe: currentRecipe,
                      currentIndex: safeIndex,
                      totalCards: appState.filteredRecipes.length,
                      onSwipeRight: () => _handleSwipeRight(appState),
                      onSwipeLeft: () => _handleSwipeLeft(appState),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RecipeDetailScreen(recipe: currentRecipe),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: AppConstants.smallPadding),

                // Action buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  child: Row(
                    children: [
                      // Filter button
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.filter_list, size: 18),
                            label: Text('Filter'),
                            onPressed: () => _showFilterModal(appState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasActiveFilters(appState)
                                  ? AppTheme.pastelPeach
                                  : AppTheme.pastelMint,
                              foregroundColor: AppTheme.darkBg,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // Undo button
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.undo, size: 18),
                            label: Text('Undo'),
                            onPressed: appState.swipeHistory.isEmpty
                                ? null
                                : () => _handleUndo(appState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appState.swipeHistory.isEmpty
                                  ? AppTheme.textMuted.withValues(alpha: 0.5)
                                  : AppTheme.pastelBlush,
                              foregroundColor: AppTheme.darkBg,
                              disabledForegroundColor: AppTheme.textMuted,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),

                      // Skip button
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.close, size: 18),
                            label: Text('Skip'),
                            onPressed: () => _handleSwipeLeft(appState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.pastelLavender,
                              foregroundColor: AppTheme.darkBg,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    // Determine why there are no recipes to show
    final hasNoRecipesAtAll = appState.allRecipes.isEmpty;
    final hasActiveFilters = _hasActiveFilters(appState);
    final hasSwipedAll = !hasNoRecipesAtAll &&
        appState.swipeHistory.isNotEmpty &&
        appState.filteredRecipes.isEmpty;

    final IconData icon;
    final String title;
    final String subtitle;

    if (hasNoRecipesAtAll) {
      icon = Icons.restaurant_menu;
      title = 'No recipes yet';
      subtitle = 'Import recipes from settings to get started';
    } else if (hasSwipedAll && !hasActiveFilters) {
      icon = Icons.done_all;
      title = 'You\'ve seen all recipes!';
      subtitle =
          'Start a new session to reshuffle, or import more recipes from settings';
    } else if (hasActiveFilters) {
      icon = Icons.filter_alt_off;
      title = 'No matches';
      subtitle =
          'No recipes match your current filters. Try clearing them to see more';
    } else {
      icon = Icons.no_meals;
      title = 'No recipes available';
      subtitle = 'Try adjusting filters or import more recipes';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppTheme.textMuted),
            SizedBox(height: AppConstants.defaultPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.defaultPadding * 1.5),
            if (hasActiveFilters)
              ElevatedButton.icon(
                icon: Icon(Icons.filter_alt_off, size: 18),
                onPressed: () {
                  appState.clearFilters();
                  setState(() => _currentIndex = 0);
                },
                label: Text('Clear Filters'),
              ),
            if (hasSwipedAll && !hasActiveFilters)
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, size: 18),
                onPressed: () {
                  appState.startNewSession();
                  setState(() => _currentIndex = 0);
                },
                label: Text('Start Fresh'),
              ),
            SizedBox(height: AppConstants.defaultPadding),
            OutlinedButton.icon(
              icon: Icon(Icons.settings, size: 18),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              label: Text('Import Recipes'),
            ),
            if (appState.likedCount > 0) ...[
              SizedBox(height: AppConstants.defaultPadding),
              OutlinedButton.icon(
                icon: Icon(Icons.check_circle, size: 18),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShoppingListScreen(),
                    ),
                  );
                },
                label: Text(
                    'Continue with ${appState.likedCount} recipe${appState.likedCount == 1 ? '' : 's'}'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters(AppState appState) {
    return appState.filterByLight ||
        appState.filterByFast ||
        appState.filterByLong;
  }
}