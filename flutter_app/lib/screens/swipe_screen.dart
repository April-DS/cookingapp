import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../widgets/recipe_card.dart';
import '../widgets/filter_modal.dart';
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
      }
    }
  }

  void _handleSwipeLeft(AppState appState) {
    if (_currentIndex < appState.filteredRecipes.length) {
      appState.skipRecipe(appState.filteredRecipes[_currentIndex]);
    }
  }

  void _handleUndo(AppState appState) {
    if (appState.swipeHistory.isEmpty) return;
    
    final wasLike = appState.swipeWasLike.isNotEmpty 
        ? appState.swipeWasLike.last 
        : false;
    
    appState.undoLastSwipe();
    
    if (wasLike) {
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);
      }
    }
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
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal(AppState appState) {
    showDialog(
      context: context,
      builder: (context) => FilterModal(
        initialLight: appState.filterByLight,
        initialFast: appState.filterByFast,
        initialLong: appState.filterByLong,
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
        title: Text('Cooking Swipe'),
        actions: [
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

          if (_currentIndex >= appState.filteredRecipes.length) {
            _currentIndex = appState.filteredRecipes.length - 1;
          }

          final currentRecipe = appState.filteredRecipes[_currentIndex];

          return Column(
            children: [
              // Progress counter
              Padding(
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
                      child: Text(
                        '${appState.likedCount} / ${appState.targetDishCount}',
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium
                            ?.copyWith(
                              color: AppTheme.pastelMint,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppConstants.defaultPadding),

              // Recipe card
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                  ),
                  child: RecipeCard(
                    recipe: currentRecipe,
                    currentIndex: _currentIndex,
                    totalCards: appState.filteredRecipes.length,
                    onSwipeRight: () => _handleSwipeRight(appState),
                    onSwipeLeft: () => _handleSwipeLeft(appState),
                  ),
                ),
              ),
              SizedBox(height: AppConstants.defaultPadding),

              // Action buttons
              Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    SizedBox(height: AppConstants.smallPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Filter button (primary)
                        ElevatedButton.icon(
                          icon: Icon(Icons.filter_list),
                          label: Text('Filter'),
                          onPressed: () => _showFilterModal(appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasActiveFilters(appState)
                                ? AppTheme.pastelPeach
                                : AppTheme.pastelMint,
                            foregroundColor: AppTheme.darkBg,
                          ),
                        ),

                        // Undo button
                        ElevatedButton.icon(
                          icon: Icon(Icons.undo),
                          label: Text('Undo'),
                          onPressed: appState.swipeHistory.isEmpty
                              ? null
                              : () => _handleUndo(appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appState.swipeHistory.isEmpty
                                ? AppTheme.textMuted.withOpacity(0.5)
                                : AppTheme.pastelBlush,
                            foregroundColor: AppTheme.darkBg,
                            disabledForegroundColor: AppTheme.textMuted,
                          ),
                        ),

                        // Skip button
                        ElevatedButton.icon(
                          icon: Icon(Icons.close),
                          label: Text('Skip'),
                          onPressed: () => _handleSwipeLeft(appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.pastelLavender,
                            foregroundColor: AppTheme.darkBg,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_meals, size: 64, color: AppTheme.textMuted),
            SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No recipes available',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            SizedBox(height: AppConstants.smallPadding),
            Text(
              'Try adjusting filters or import more recipes',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.defaultPadding * 1.5),
            ElevatedButton(
              onPressed: () {
                appState.clearFilters();
                setState(() => _currentIndex = 0);
              },
              child: Text('Clear Filters'),
            ),
            SizedBox(height: AppConstants.defaultPadding),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              child: Text('Import Recipes'),
            ),
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