import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/import_service.dart';
import '../models/recipe.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import 'sessions_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImportService _importService = ImportService();
  final TextEditingController _jsonController = TextEditingController();

  void _showImportJsonDialog() {
    _jsonController.clear();
    showDialog(
      context: context,
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
              Text(
                'Import Recipes (JSON)',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Paste your JSON here:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: _jsonController,
                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '{"recipes": [...]}',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_jsonController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please paste JSON')),
                          );
                          return;
                        }

                        try {
                          await _importService
                              .importFromJsonText(_jsonController.text);
                          Navigator.pop(context);
                          Provider.of<AppState>(context, listen: false)
                              .loadAllRecipes();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recipes imported successfully!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Import failed: $e'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      },
                      child: Text('Import'),
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

  void _showImportFileDialog() async {
    try {
      final recipes = await _importService.importFromFile();
      Navigator.pop(context);
      Provider.of<AppState>(context, listen: false).loadAllRecipes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipes.length} recipes imported!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showAddRecipeDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final kcalController = TextEditingController();
    final proteinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkBgSecondary,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Recipe',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                SizedBox(height: AppConstants.defaultPadding),
                TextField(
                  controller: idController,
                  style: TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(labelText: 'Recipe ID'),
                ),
                SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(labelText: 'Dish Name'),
                ),
                SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: kcalController,
                  style: TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(labelText: 'Calories'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: proteinController,
                  style: TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(labelText: 'Protein (g)'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: AppConstants.defaultPadding),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final recipe = Recipe(
                            id: idController.text,
                            dishName: nameController.text,
                            prepTime: 0,
                            cookTime: 0,
                            totalTime: 0,
                            kcal: int.tryParse(kcalController.text) ?? 0,
                            proteinG:
                                double.tryParse(proteinController.text) ?? 0,
                            highlights: '',
                            ingredients: '',
                            instructions: '',
                            imageDescription: '',
                            imageFilename: '',
                          );
                          Provider.of<AppState>(context, listen: false)
                              .addRecipe(recipe);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recipe added!'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        child: Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) => ListView(
          children: [
            // Target count section
            Padding(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target Dishes',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: AppConstants.defaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: appState.targetDishCount.toDouble(),
                          min: AppConstants.minTargetCount.toDouble(),
                          max: AppConstants.maxTargetCount.toDouble(),
                          divisions: AppConstants.maxTargetCount -
                              AppConstants.minTargetCount,
                          label: '${appState.targetDishCount}',
                          onChanged: (value) {
                            appState.setTargetCount(value.toInt());
                          },
                        ),
                      ),
                      SizedBox(width: AppConstants.defaultPadding),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                          vertical: AppConstants.smallPadding,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkBgSecondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${appState.targetDishCount}',
                          style:
                              Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppTheme.pastelMint,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(color: AppTheme.textMuted, height: 32),

            // Data Management section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Text(
                'Data Management',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ),
            SizedBox(height: AppConstants.defaultPadding),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.upload),
                    label: Text('Import JSON (Paste)'),
                    onPressed: _showImportJsonDialog,
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  ElevatedButton.icon(
                    icon: Icon(Icons.file_open),
                    label: Text('Import JSON (File)'),
                    onPressed: _showImportFileDialog,
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  OutlinedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Recipe Manually'),
                    onPressed: _showAddRecipeDialog,
                  ),
                ],
              ),
            ),

            Divider(color: AppTheme.textMuted, height: 32),

            // Recipe database section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe Database',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.defaultPadding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Recipes',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${appState.allRecipes.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: AppTheme.pastelMint,
                                    ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.delete),
                            label: Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.error,
                            ),
                            onPressed: () {
                              // Show delete confirmation
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor:
                                      AppTheme.darkBgSecondary,
                                  title: Text('Delete All Recipes?'),
                                  content: Text(
                                      'This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        // Delete implementation
                                        Navigator.pop(context);
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.defaultPadding),

            // Sessions section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Past Sessions',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: AppConstants.defaultPadding),
                  OutlinedButton.icon(
                    icon: Icon(Icons.history),
                    label: Text(
                        'View History (${appState.pastSessions.length})'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionsHistoryScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppConstants.defaultPadding * 2),
          ],
        ),
      ),
    );
  }
}