import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({required this.recipe, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ingredients = recipe.ingredients.parseIngredients();
    final instructions = recipe.instructions.parseInstructions();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing app bar with recipe image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.darkBgSecondary,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroImage(),
                  // Gradient overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          AppTheme.darkBg.withOpacity(0.8),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Title at bottom of image
                  Positioned(
                    left: AppConstants.defaultPadding,
                    right: AppConstants.defaultPadding,
                    bottom: AppConstants.defaultPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.dishName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            if (recipe.isLight) ...[
                              _buildChip('Light', AppTheme.pastelMint),
                              SizedBox(width: 6),
                            ],
                            if (recipe.isFast) ...[
                              _buildChip('Fast', AppTheme.pastelYellow),
                              SizedBox(width: 6),
                            ],
                            if (recipe.isLong) ...[
                              _buildChip('Long Cook', AppTheme.pastelPeach),
                              SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Body content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats row
                  _buildStatsRow(context),
                  SizedBox(height: AppConstants.defaultPadding * 1.5),

                  // Highlights
                  if (recipe.highlights.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Highlights'),
                    SizedBox(height: AppConstants.smallPadding),
                    Text(
                      recipe.highlights,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.pastelYellow,
                          ),
                    ),
                    SizedBox(height: AppConstants.defaultPadding * 1.5),
                  ],

                  // Ingredients
                  _buildSectionTitle(context, 'Ingredients'),
                  SizedBox(height: AppConstants.smallPadding),
                  ...ingredients.map(
                    (ingredient) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('  \u2022  ',
                              style: TextStyle(
                                  color: AppTheme.pastelMint, fontSize: 14)),
                          Expanded(
                            child: Text(
                              ingredient,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textLight,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppConstants.defaultPadding * 1.5),

                  // Instructions
                  if (instructions.isNotEmpty) ...[
                    _buildSectionTitle(context, 'Instructions'),
                    SizedBox(height: AppConstants.smallPadding),
                    ...instructions.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.pastelMint.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    color: AppTheme.pastelMint,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  entry.value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.textLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding for safe area
                  SizedBox(height: AppConstants.defaultPadding * 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final imagePath = 'assets/recipe_images/${recipe.imageFilename}';
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.pastelMint, AppTheme.pastelPeach],
            ),
          ),
          child: Center(
            child: Icon(Icons.restaurant, size: 64, color: AppTheme.darkBg),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.darkBg,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.darkBgSecondary,
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(context, Icons.timer_outlined,
              StringExtensions.formatDuration(recipe.prepTime), 'Prep'),
          _buildDivider(),
          _buildStat(context, Icons.local_fire_department_outlined,
              StringExtensions.formatDuration(recipe.cookTime), 'Cook'),
          _buildDivider(),
          _buildStat(context, Icons.access_time,
              StringExtensions.formatDuration(recipe.totalTime), 'Total'),
          _buildDivider(),
          _buildStat(context, Icons.bolt, '${recipe.kcal}', 'kcal'),
          _buildDivider(),
          _buildStat(context, Icons.fitness_center,
              '${recipe.proteinG.toStringAsFixed(1)}g', 'Protein'),
        ],
      ),
    );
  }

  Widget _buildStat(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.pastelMint, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppTheme.textMuted.withOpacity(0.3),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.pastelMint,
          ),
    );
  }
}
