import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../models/session.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'recipe_detail_screen.dart';
import 'shopping_list_screen.dart';

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
      bottomNavigationBar: Consumer<AppState>(
        builder: (context, appState, _) {
          final count = appState.currentSessionRecipes.length;
          if (count == 0) return const SizedBox.shrink();
          return SafeArea(
            child: Container(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: AppTheme.darkBgSecondary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$count recipe${count == 1 ? '' : 's'} selected',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.pastelMint,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Review & Save'),
                    onPressed: () => _reviewAndSave(context, appState),
                  ),
                ],
              ),
            ),
          );
        },
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

  Future<void> _reviewAndSave(BuildContext context, AppState appState) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.darkBgSecondary,
        title: const Text('Save selection'),
        content: const Text(
          'Add these recipes to a new session, or merge them into an existing saved session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'existing'),
            child: const Text('Existing session'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, 'new'),
            child: const Text('New session'),
          ),
        ],
      ),
    );

    if (choice == 'new') {
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
      );
    } else if (choice == 'existing') {
      if (!context.mounted) return;
      await _addToExistingSession(context, appState);
    }
  }

  Future<void> _addToExistingSession(
      BuildContext context, AppState appState) async {
    if (appState.pastSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved sessions yet — create a new one first')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Session>(
      context: context,
      backgroundColor: AppTheme.darkBgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Text('Add to which session?',
                    style: Theme.of(sheetContext).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: appState.pastSessions
                      .map((s) => ListTile(
                            leading: Icon(Icons.folder, color: AppTheme.pastelMint),
                            title: Text(s.sessionName,
                                style: TextStyle(color: AppTheme.textLight)),
                            subtitle: Text('${s.recipeIds.length} recipes',
                                style: TextStyle(color: AppTheme.textMuted)),
                            onTap: () => Navigator.pop(sheetContext, s),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: AppConstants.smallPadding),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    final addedCount = appState.currentSessionRecipes.length;
    await appState.mergeCurrentIntoSession(selected);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $addedCount recipe${addedCount == 1 ? '' : 's'} to "${selected.sessionName}"'),
        backgroundColor: AppTheme.success,
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
