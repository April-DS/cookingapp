import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'recipe_detail_screen.dart';

class BrowseRecipesScreen extends StatefulWidget {
  const BrowseRecipesScreen({Key? key}) : super(key: key);

  @override
  State<BrowseRecipesScreen> createState() => _BrowseRecipesScreenState();
}

class _BrowseRecipesScreenState extends State<BrowseRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Recipe> _filterRecipes(List<Recipe> recipes) {
    if (_query.isEmpty) return recipes;
    final q = _query.toLowerCase();
    return recipes.where((r) {
      return r.dishName.toLowerCase().contains(q) ||
          r.highlights.toLowerCase().contains(q) ||
          r.ingredients.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Recipes'),
      ),
      body: SafeArea(
        child: Consumer<AppState>(
        builder: (context, appState, _) {
          final filtered = _filterRecipes(appState.allRecipes);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ingredient, or tag...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),

              // Results count
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filtered.length} recipe${filtered.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              SizedBox(height: AppConstants.smallPadding),

              // Recipe grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: AppTheme.textMuted),
                            SizedBox(height: AppConstants.defaultPadding),
                            Text('No recipes found',
                                style:
                                    Theme.of(context).textTheme.displayMedium),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(AppConstants.defaultPadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: AppConstants.smallPadding,
                          mainAxisSpacing: AppConstants.smallPadding,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeGridItem(context, filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }

  Widget _buildRecipeGridItem(BuildContext context, Recipe recipe) {
    final appState = Provider.of<AppState>(context);
    final alreadyInSession = appState.currentSessionRecipes.any((r) => r.id == recipe.id);
    final sessionFull = appState.sessionComplete;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipe: recipe)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  recipe.imageFilename.isNotEmpty
                      ? Image.asset(
                          'assets/recipe_images/${recipe.imageFilename}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.pastelMint.withValues(alpha: 0.3),
                            child: Icon(Icons.restaurant,
                                color: AppTheme.pastelMint, size: 40),
                          ),
                        )
                      : Container(
                          color: AppTheme.pastelMint.withValues(alpha: 0.3),
                          child: Icon(Icons.restaurant,
                              color: AppTheme.pastelMint, size: 40),
                        ),
                  // Add to session button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        if (alreadyInSession) {
                          appState.removeFromSession(recipe);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${recipe.dishName}"'),
                              backgroundColor: AppTheme.error,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } else if (!sessionFull) {
                          appState.addToSession(recipe);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "${recipe.dishName}" (${appState.likedCount}/${appState.targetDishCount})'),
                              backgroundColor: AppTheme.success,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: alreadyInSession
                              ? AppTheme.pastelMint
                              : sessionFull
                                  ? Colors.grey
                                  : Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          alreadyInSession ? Icons.check : Icons.add,
                          color: alreadyInSession ? AppTheme.darkBg : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(AppConstants.smallPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.dishName,
                      style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 12, color: AppTheme.textMuted),
                        SizedBox(width: 3),
                        Text(
                          StringExtensions.formatDuration(recipe.totalTime),
                          style:
                              TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.local_fire_department,
                            size: 12, color: AppTheme.textMuted),
                        SizedBox(width: 3),
                        Text(
                          '${recipe.kcal}',
                          style:
                              TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
