import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import 'recipe_detail_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

enum SortMode { mostPicked, mostSkipped, pickRate, totalSwipes }

class _StatisticsScreenState extends State<StatisticsScreen> {
  SortMode _sortMode = SortMode.mostPicked;

  List<Recipe> _sortRecipes(List<Recipe> recipes) {
    final sorted = List<Recipe>.from(recipes);
    switch (_sortMode) {
      case SortMode.mostPicked:
        sorted.sort((a, b) => b.pickCount.compareTo(a.pickCount));
      case SortMode.mostSkipped:
        sorted.sort((a, b) => b.skipCount.compareTo(a.skipCount));
      case SortMode.pickRate:
        sorted.sort((a, b) => b.pickRate.compareTo(a.pickRate));
      case SortMode.totalSwipes:
        sorted.sort((a, b) => b.totalSwipes.compareTo(a.totalSwipes));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.allRecipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: AppConstants.defaultPadding),
                  Text('No data yet',
                      style: Theme.of(context).textTheme.displayMedium),
                  SizedBox(height: AppConstants.smallPadding),
                  Text('Start swiping to see statistics',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            );
          }

          final recipes = appState.allRecipes;
          final totalPicks = recipes.fold<int>(0, (sum, r) => sum + r.pickCount);
          final totalSkips = recipes.fold<int>(0, (sum, r) => sum + r.skipCount);
          final totalSwipes = totalPicks + totalSkips;
          final sorted = _sortRecipes(recipes);
          final recipesWithData = sorted.where((r) => r.totalSwipes > 0).toList();

          return Column(
            children: [
              // Summary cards
              Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  children: [
                    _buildStatCard(context, 'Total Swipes', '$totalSwipes',
                        AppTheme.pastelLavender),
                    SizedBox(width: AppConstants.smallPadding),
                    _buildStatCard(context, 'Picked', '$totalPicks',
                        AppTheme.pastelMint),
                    SizedBox(width: AppConstants.smallPadding),
                    _buildStatCard(context, 'Skipped', '$totalSkips',
                        AppTheme.pastelBlush),
                  ],
                ),
              ),

              // Sort selector
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Most Picked', SortMode.mostPicked),
                      SizedBox(width: 6),
                      _buildSortChip('Most Skipped', SortMode.mostSkipped),
                      SizedBox(width: 6),
                      _buildSortChip('Pick Rate', SortMode.pickRate),
                      SizedBox(width: 6),
                      _buildSortChip('Most Swiped', SortMode.totalSwipes),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppConstants.smallPadding),

              // Recipe list
              Expanded(
                child: recipesWithData.isEmpty
                    ? Center(
                        child: Text('No swipe data yet',
                            style: Theme.of(context).textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(
                            horizontal: AppConstants.defaultPadding),
                        itemCount: recipesWithData.length,
                        itemBuilder: (context, index) {
                          final recipe = recipesWithData[index];
                          return _buildRecipeStatRow(context, recipe, index + 1);
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

  Widget _buildStatCard(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: AppTheme.darkBgSecondary,
          borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .displayMedium
                    ?.copyWith(color: color)),
            SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortMode mode) {
    final selected = _sortMode == mode;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _sortMode = mode),
      selectedColor: AppTheme.pastelMint,
      backgroundColor: AppTheme.darkBgSecondary,
      labelStyle: TextStyle(
        color: selected ? AppTheme.darkBg : AppTheme.textLight,
      ),
      padding: EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildRecipeStatRow(BuildContext context, Recipe recipe, int rank) {
    final pickPct = recipe.totalSwipes > 0
        ? (recipe.pickRate * 100).toStringAsFixed(0)
        : '0';

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(recipe: recipe)),
        ),
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: recipe.imageFilename.isNotEmpty
                      ? Image.asset(
                          'assets/recipe_images/${recipe.imageFilename}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.pastelMint,
                            child: Icon(Icons.restaurant,
                                color: AppTheme.darkBg, size: 20),
                          ),
                        )
                      : Container(
                          color: AppTheme.pastelMint,
                          child: Icon(Icons.restaurant,
                              color: AppTheme.darkBg, size: 20),
                        ),
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),
              // Name + time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.dishName,
                        style: TextStyle(
                            color: AppTheme.textLight, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      '${StringExtensions.formatDuration(recipe.totalTime)} • ${recipe.kcal} kcal',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniStat(
                      '${recipe.pickCount}', Icons.favorite, AppTheme.pastelMint),
                  SizedBox(width: 8),
                  _buildMiniStat(
                      '${recipe.skipCount}', Icons.close, AppTheme.pastelBlush),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPickRateColor(recipe.pickRate),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pickPct%',
                      style: TextStyle(
                          color: AppTheme.darkBg,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Color _getPickRateColor(double rate) {
    if (rate >= 0.7) return AppTheme.pastelMint;
    if (rate >= 0.4) return AppTheme.pastelYellow;
    return AppTheme.pastelBlush;
  }
}
