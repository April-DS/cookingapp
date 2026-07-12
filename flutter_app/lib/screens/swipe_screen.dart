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

  // Pending portion choice for the card currently shown (before it's swiped).
  // Tied to a recipe id so a new card falls back to that recipe's default servings.
  String? _portionRecipeId;
  int? _portionValue;

  int _currentPortions(Recipe recipe) =>
      (_portionRecipeId == recipe.id && _portionValue != null)
          ? _portionValue!
          : recipe.servings;

  void _changePortions(Recipe recipe, int delta) {
    final next = (_currentPortions(recipe) + delta).clamp(1, 99);
    setState(() {
      _portionRecipeId = recipe.id;
      _portionValue = next;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.startNewSession();
    });
  }

  // Resolve the index of the card currently shown. The build() method clamps
  // a stale/out-of-bounds _currentIndex into a `safeIndex` for display, so the
  // swipe handlers must act on that SAME clamped index — otherwise a swipe can
  // like/skip the wrong recipe (or be silently ignored) when the two diverge.
  int _visibleIndex(AppState appState) {
    if (appState.filteredRecipes.isEmpty) return -1;
    var index = _currentIndex;
    if (index >= appState.filteredRecipes.length) {
      index = appState.filteredRecipes.length - 1;
    }
    if (index < 0) index = 0;
    return index;
  }

  void _handleSwipeRight(AppState appState) {
    final index = _visibleIndex(appState);
    if (index >= 0) {
      _currentIndex = index;
      final recipe = appState.filteredRecipes[index];
      appState.likeRecipe(recipe, portions: _currentPortions(recipe));

      if (appState.phaseComplete) {
        if (!appState.inDessertPhase) {
          // Mains done — offer a dessert round before the shopping list.
          _showMainsCompleteDialog(appState);
        } else {
          _showSessionCompleteDialog(appState);
        }
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
    final index = _visibleIndex(appState);
    if (index >= 0) {
      _currentIndex = index;
      appState.skipRecipe(appState.filteredRecipes[index]);
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

  /// Shown when the main-dish target is reached: offer a dessert round.
  void _showMainsCompleteDialog(AppState appState) {
    _showDessertCountDialog(
      appState,
      title: 'Main dishes done!',
      message:
          'You\'ve picked ${appState.mainsPickedCount} main dishes. Add some desserts?',
      skipLabel: 'No desserts',
      onSkip: () => _showSessionCompleteDialog(appState),
    );
  }

  /// Shown from the 🍰 app bar icon: dessert round on top of current picks,
  /// or a desserts-only session when nothing is picked yet.
  void _showDessertDialog(AppState appState) {
    if (appState.inDessertPhase) return; // already picking desserts
    _showDessertCountDialog(
      appState,
      title: 'Desserts',
      message: appState.likedCount > 0
          ? 'Add desserts to your current selection. How many?'
          : 'Start a desserts-only session. How many?',
      skipLabel: 'Cancel',
      onSkip: null,
    );
  }

  void _showDessertCountDialog(
    AppState appState, {
    required String title,
    required String message,
    required String skipLabel,
    VoidCallback? onSkip,
  }) {
    int count = appState.targetDessertCount;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          backgroundColor: AppTheme.darkBgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cake, size: 44, color: AppTheme.pastelPeach),
                SizedBox(height: AppConstants.defaultPadding),
                Text(title, style: Theme.of(dialogContext).textTheme.displayMedium),
                SizedBox(height: AppConstants.smallPadding),
                Text(
                  message,
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppConstants.defaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: AppTheme.pastelBlush, size: 32),
                      onPressed: count > 1
                          ? () => setDialogState(() => count--)
                          : null,
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: Theme.of(dialogContext)
                            .textTheme
                            .displayMedium
                            ?.copyWith(color: AppTheme.pastelMint),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline,
                          color: AppTheme.pastelMint, size: 32),
                      onPressed: count < 10
                          ? () => setDialogState(() => count++)
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.defaultPadding),
                ElevatedButton.icon(
                  icon: Icon(Icons.cake, size: 18),
                  label: Text('Pick $count dessert${count == 1 ? '' : 's'}'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    appState.startDessertPhase(count);
                    setState(() => _currentIndex = 0);
                  },
                ),
                SizedBox(height: AppConstants.smallPadding),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    onSkip?.call();
                  },
                  child: Text(skipLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                'You\'ve selected ${appState.likedCount} delicious recipe${appState.likedCount == 1 ? '' : 's'}',
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
                          'Your Recipes (${recipes.length}/${appState.totalTargetCount})',
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
        allRecipes: appState.allRecipes
            .where((r) => r.isDessert == appState.inDessertPhase)
            .toList(),
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
          Consumer<AppState>(
            builder: (context, appState, _) => IconButton(
              icon: Icon(
                Icons.cake,
                color: appState.inDessertPhase ? AppTheme.pastelPeach : null,
              ),
              onPressed: () => _showDessertDialog(appState),
              tooltip: 'Desserts',
            ),
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/browse'),
            tooltip: 'Browse Recipes',
          ),
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: () => Navigator.pushNamed(context, '/statistics').then((_) {
              // Reload recipes to get updated stats
              if (!mounted) return;
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
                          appState.inDessertPhase
                              ? 'Desserts'
                              : 'Your Selection',
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
                              if (appState.inDessertPhase) ...[
                                Icon(Icons.cake,
                                    size: 18, color: AppTheme.pastelPeach),
                                SizedBox(width: 6),
                              ],
                              Text(
                                appState.inDessertPhase
                                    ? '${appState.dessertsPickedCount} / ${appState.targetDessertCount}'
                                    : '${appState.mainsPickedCount} / ${appState.targetDishCount}',
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

                // Portion selector (adjust before swiping right to add)
                _buildPortionSelector(currentRecipe),
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

  Widget _buildPortionSelector(Recipe recipe) {
    final portions = _currentPortions(recipe);
    final isCustom = portions != recipe.servings;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.smallPadding, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.darkBgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 18, color: AppTheme.pastelMint),
          SizedBox(width: 6),
          Text('Portions', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
          SizedBox(width: AppConstants.smallPadding),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: AppTheme.pastelBlush),
            iconSize: 26,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: portions > 1 ? () => _changePortions(recipe, -1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$portions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.pastelMint,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.pastelMint),
            iconSize: 26,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () => _changePortions(recipe, 1),
          ),
          if (isCustom)
            Text('(default ${recipe.servings})',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
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