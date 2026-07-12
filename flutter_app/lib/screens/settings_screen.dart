import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/app_state.dart';
import '../services/import_service.dart';
import '../models/recipe.dart';
import '../models/session.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import 'recipe_detail_screen.dart';
import 'sessions_history_screen.dart';
import '../widgets/ingredient_list_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ImportService _importService = ImportService();
  final TextEditingController _jsonController = TextEditingController();

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  void _showImportJsonDialog() {
    _jsonController.clear();
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Import Recipes (JSON)', 
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppConstants.smallPadding),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Paste JSON below'),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppConstants.smallPadding),
                  ElevatedButton(
                    onPressed: () async {
                      final text = _jsonController.text.trim();
                      if (text.isEmpty) return;
                      try {
                        await _importService.importFromJsonText(text);
                        // Refresh the recipe list so the new recipes appear.
                        if (!mounted) return;
                        await Provider.of<AppState>(context, listen: false)
                            .loadAllRecipes();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _showSnackBar('Imported recipes');
                      } catch (e) {
                        if (!mounted) return;
                        _showSnackBar('Import failed: ${e.toString()}',
                            isError: true);
                      }
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRecipeDialog() {
    final nameController = TextEditingController();
    final prepTimeController = TextEditingController();
    final cookTimeController = TextEditingController();
    final kcalController = TextEditingController();
    final proteinController = TextEditingController();
    final highlightsController = TextEditingController();
    final ingredientsController = TextEditingController();
    final instructionsController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add Recipe',
                  style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppConstants.smallPadding),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Dish Name *'),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: prepTimeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Prep (min)'),
                            ),
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Expanded(
                            child: TextField(
                              controller: cookTimeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Cook (min)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: kcalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'kcal'),
                            ),
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Expanded(
                            child: TextField(
                              controller: proteinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Protein (g)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      TextField(
                        controller: highlightsController,
                        decoration: const InputDecoration(
                          labelText: 'Highlights',
                          hintText: 'e.g., High protein, Gluten-free',
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      TextField(
                        controller: ingredientsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Ingredients *',
                          hintText: 'One per line',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      TextField(
                        controller: instructionsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Instructions',
                          hintText: 'Step by step',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          _showSnackBar('Dish name is required', isError: true);
                          return;
                        }
                        final prepTime = int.tryParse(prepTimeController.text) ?? 0;
                        final cookTime = int.tryParse(cookTimeController.text) ?? 0;
                        final recipe = Recipe(
                          id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                          dishName: name,
                          prepTime: prepTime,
                          cookTime: cookTime,
                          totalTime: prepTime + cookTime,
                          kcal: int.tryParse(kcalController.text) ?? 0,
                          proteinG: double.tryParse(proteinController.text) ?? 0,
                          highlights: highlightsController.text.trim(),
                          ingredients: ingredientsController.text.trim(),
                          instructions: instructionsController.text.trim(),
                          imageDescription: '',
                          imageFilename: '',
                        );
                        try {
                          await Provider.of<AppState>(context, listen: false)
                              .addRecipe(recipe);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _showSnackBar('Recipe added');
                        } catch (e) {
                          if (!mounted) return;
                          _showSnackBar('Add failed: ${e.toString()}',
                              isError: true);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Dispose the dialog's controllers when it closes to avoid leaks.
      nameController.dispose();
      prepTimeController.dispose();
      cookTimeController.dispose();
      kcalController.dispose();
      proteinController.dispose();
      highlightsController.dispose();
      ingredientsController.dispose();
      instructionsController.dispose();
    });
  }

  void _showLastSessionShoppingList(BuildContext parentContext, Session initialSession) {
    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) {
        // Use StatefulBuilder so we can update session in-place without pop/re-show
        var session = initialSession;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppTheme.darkBgSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Text('Last Shopping List',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppConstants.smallPadding),

                      // List
                      Expanded(
                        child: session.shoppingList.isEmpty
                            ? Center(
                                child: Text('No items saved',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              )
                            : ListView(
                                children: [
                                  for (var key in session.shoppingList.keys.toList()..sort())
                                    IngredientListItem(
                                      ingredient: key,
                                      quantity: session.shoppingList[key] ?? '',
                                      checked: session.ingredientChecked[key] ?? false,
                                      onCheckChanged: (value) async {
                                        final updatedChecked = Map<String, bool>.from(session.ingredientChecked);
                                        updatedChecked[key] = value;
                                        final updatedSession = session.copyWith(
                                          ingredientChecked: updatedChecked,
                                        );
                                        await Provider.of<AppState>(context, listen: false)
                                            .updateSession(updatedSession);
                                        setDialogState(() => session = updatedSession);
                                      },
                                      onDelete: () async {
                                        final updatedShopping = Map<String, String>.from(session.shoppingList)..remove(key);
                                        final updatedChecked = Map<String, bool>.from(session.ingredientChecked)..remove(key);
                                        final updatedSession = session.copyWith(
                                          shoppingList: updatedShopping,
                                          ingredientChecked: updatedChecked,
                                        );
                                        await Provider.of<AppState>(context, listen: false)
                                            .updateSession(updatedSession);
                                        setDialogState(() => session = updatedSession);
                                      },
                                      onEdit: (newQuantity) async {
                                        final updatedSession = session.copyWith(
                                          shoppingList: {
                                            ...session.shoppingList,
                                            key: newQuantity,
                                          },
                                        );
                                        await Provider.of<AppState>(context, listen: false)
                                            .updateSession(updatedSession);
                                        setDialogState(() => session = updatedSession);
                                      },
                                    ),
                                ],
                              ),
                      ),

                      // Actions
                      const SizedBox(height: AppConstants.defaultPadding),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Item'),
                              onPressed: () async {
                                final controller = TextEditingController();
                                final String? result;
                                try {
                                  result = await showDialog<String>(
                                  context: context,
                                  builder: (addContext) {
                                    return Dialog(
                                      backgroundColor: AppTheme.darkBgSecondary,
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppConstants.defaultPadding),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Add Item',
                                              style: Theme.of(addContext).textTheme.displayMedium,
                                            ),
                                            const SizedBox(height: AppConstants.defaultPadding),
                                            TextField(
                                              controller: controller,
                                              style: const TextStyle(color: AppTheme.textLight),
                                              decoration: const InputDecoration(
                                                hintText: 'e.g., 2 cups flour',
                                              ),
                                              autofocus: true,
                                            ),
                                            const SizedBox(height: AppConstants.defaultPadding),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () => Navigator.pop(addContext),
                                                    child: const Text('Cancel'),
                                                  ),
                                                ),
                                                const SizedBox(width: AppConstants.smallPadding),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      final text = controller.text.trim();
                                                      if (text.isNotEmpty) {
                                                        Navigator.pop(addContext, text);
                                                      }
                                                    },
                                                    child: const Text('Add'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                                } finally {
                                  controller.dispose();
                                }

                                if (result != null && result.isNotEmpty) {
                                  final updatedSession = session.copyWith(
                                    shoppingList: {
                                      ...session.shoppingList,
                                      result: '',
                                    },
                                    ingredientChecked: {
                                      ...session.ingredientChecked,
                                      result: false,
                                    },
                                  );
                                  if (!context.mounted) return;
                                  await Provider.of<AppState>(context, listen: false)
                                      .updateSession(updatedSession);
                                  setDialogState(() => session = updatedSession);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                              onPressed: () {
                                final sortedKeys = session.shoppingList.keys.toList()..sort();
                                final list = sortedKeys.map((key) {
                                  final mark = session.ingredientChecked[key] ?? false ? '☑' : '☐';
                                  return '$mark ${key}${session.shoppingList[key]!.isNotEmpty ? ' (${session.shoppingList[key]})' : ''}';
                                }).join('\n');
                                Clipboard.setData(ClipboardData(text: list));
                                Navigator.pop(context);
                                _showSnackBar('Copied to clipboard');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _importSessionFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null) return;

      final contents = await File(file.path!).readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;

      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);

      // One picker handles both shared sessions and full backups.
      if (json['type'] == 'backup') {
        final summary = await appState.importBackup(json);
        if (!mounted) return;
        _showSnackBar('Backup restored: $summary');
      } else {
        final sessionName = await appState.importSharedSession(json);
        if (!mounted) return;
        _showSnackBar('Imported session: $sessionName');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Import failed: ${e.toString()}', isError: true);
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final backup = await appState.buildBackupJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final dir = await Directory.systemTemp.createTemp('pickish_');
      final file = File('${dir.path}/pickish_backup_$stamp.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Pickish backup $stamp',
        text:
            'Full Pickish backup (recipes, statistics, sessions). Restore via Settings → Import / Restore.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Backup failed: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Consumer<AppState>(
        builder: (context, appState, _) => ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // 1) Target Dishes
            Text('Target Dishes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.smallPadding),
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
                    onChanged: (v) => appState.setTargetCount(v.toInt()),
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkBgSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${appState.targetDishCount}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.pastelMint),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding * 2),

            // 2) Past Sessions
            Text('Past Sessions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: Text('View History (${appState.pastSessions.length})'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SessionsHistoryScreen()),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                if (appState.pastSessions.isNotEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Last List'),
                    onPressed: () => _showLastSessionShoppingList(context, appState.pastSessions.first),
                  ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding * 2),

            // 2b) Quick Access
            Text('Quick Access', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Browse'),
                    onPressed: () => Navigator.pushNamed(context, '/browse'),
                  ),
                ),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Statistics'),
                    onPressed: () => Navigator.pushNamed(context, '/statistics'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding * 2),

            // 3) Data Management
            Text('Data Management', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.smallPadding),
            Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Recipes'),
                  onPressed: _showImportJsonDialog,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recipe'),
                  onPressed: _showAddRecipeDialog,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text('Import / Restore'),
                  onPressed: () => _importSessionFromFile(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.backup),
                  label: const Text('Backup All'),
                  onPressed: () => _exportBackup(context),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.defaultPadding * 2),

            // 4) Recipe Database
            Text('Recipe Database', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.smallPadding),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Recipes',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          '${appState.allRecipes.length}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.pastelMint),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Random'),
                      onPressed: appState.allRecipes.isEmpty
                          ? null
                          : () {
                              final random = Random();
                              final recipe = appState.allRecipes[
                                  random.nextInt(appState.allRecipes.length)];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RecipeDetailScreen(recipe: recipe),
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.defaultPadding * 2),
            Center(
              child: Text(
                'Pickish v${AppConstants.appVersion}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
          ],
        ),
      ),
      ),
    );
  }
}