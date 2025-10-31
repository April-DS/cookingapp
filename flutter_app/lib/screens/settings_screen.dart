import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/import_service.dart';
import '../models/recipe.dart';
import '../models/session.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
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
                        Navigator.pop(context);
                        _showSnackBar('Imported recipes');
                      } catch (e) {
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
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final kcalController = TextEditingController();
    final proteinController = TextEditingController();

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
              Text('Add Recipe',
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID'),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: kcalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'kcal'),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: proteinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'protein (g)'),
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
                      final recipe = Recipe(
                        id: idController.text.trim(),
                        dishName: nameController.text.trim(),
                        prepTime: 0,
                        cookTime: 0,
                        totalTime: 0,
                        kcal: int.tryParse(kcalController.text) ?? 0,
                        proteinG: double.tryParse(proteinController.text) ?? 0,
                        highlights: '',
                        ingredients: '',
                        instructions: '',
                        imageDescription: '',
                        imageFilename: '',
                      );
                      try {
                        await Provider.of<AppState>(context, listen: false)
                            .addRecipe(recipe);
                        Navigator.pop(context);
                        _showSnackBar('Recipe added');
                      } catch (e) {
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
    );
  }

  void _showLastSessionShoppingList(BuildContext context, Session session) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
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
            child: StatefulBuilder(
              builder: (context, setState) {
                final shopping = Map<String, String>.from(session.shoppingList);
                final checked = Map<String, bool>.from(session.ingredientChecked);

                return Column(
                  children: [
                    // Header
                    Text('Last Shopping List',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppConstants.smallPadding),

                    // List
                    Expanded(
                      child: shopping.isEmpty
                          ? Center(
                              child: Text('No items saved',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            )
                          : ListView(
                              children: [
                                for (var key in shopping.keys.toList()..sort())
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppConstants.smallPadding / 2),
                                    child: IngredientListItem(
                                      ingredient: key,
                                      quantity: shopping[key] ?? '',
                                      checked: checked[key] ?? false,
                                      onCheckChanged: (value) async {
                                        checked[key] = value;
                                        final updatedSession = session.copyWith(
                                          ingredientChecked: Map.from(checked),
                                        );
                                        await Provider.of<AppState>(context,
                                                listen: false)
                                            .updateSession(updatedSession);
                                        setState(() {});
                                      },
                                      onDelete: () async {
                                        final updatedShopping =
                                            Map<String, String>.from(shopping)
                                              ..remove(key);
                                        final updatedChecked =
                                            Map<String, bool>.from(checked)
                                              ..remove(key);
                                        final updatedSession = session.copyWith(
                                          shoppingList: updatedShopping,
                                          ingredientChecked: updatedChecked,
                                        );
                                        await Provider.of<AppState>(context,
                                                listen: false)
                                            .updateSession(updatedSession);
                                        setState(() {});
                                      },
                                      onEdit: (newQuantity) async {
                                        final updatedSession = session.copyWith(
                                          shoppingList: {
                                            ...shopping,
                                            key: newQuantity,
                                          },
                                        );
                                        await Provider.of<AppState>(context,
                                                listen: false)
                                            .updateSession(updatedSession);
                                        setState(() {});
                                      },
                                    ),
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
                              late final TextEditingController controller;
                              final result = await showDialog<String>(
                                context: context,
                                barrierDismissible: false,
                                builder: (dialogContext) {
                                  controller = TextEditingController();
                                  return Dialog(
                                    backgroundColor: AppTheme.darkBgSecondary,
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          AppConstants.defaultPadding),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Add Item',
                                            style: Theme.of(dialogContext)
                                                .textTheme
                                                .displayMedium,
                                          ),
                                          const SizedBox(
                                              height:
                                                  AppConstants.defaultPadding),
                                          TextField(
                                            controller: controller,
                                            style: const TextStyle(
                                                color: AppTheme.textLight),
                                            decoration: const InputDecoration(
                                              hintText: 'e.g., 2 cups flour',
                                            ),
                                            autofocus: true,
                                          ),
                                          const SizedBox(
                                              height:
                                                  AppConstants.defaultPadding),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    final ctrl = controller;
                                                    Navigator.pop(dialogContext);
                                                    ctrl.dispose();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppConstants
                                                      .smallPadding),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final text = controller.text;
                                                    final ctrl = controller;
                                                    if (text.isNotEmpty) {
                                                      Navigator.pop(
                                                          dialogContext, text);
                                                    }
                                                    ctrl.dispose();
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

                              if (result != null && result.isNotEmpty) {
                                final updatedSession = session.copyWith(
                                  shoppingList: {
                                    ...shopping,
                                    result: '', // Empty quantity by default
                                  },
                                  ingredientChecked: {
                                    ...checked,
                                    result: false, // Unchecked by default
                                  },
                                );
                                await Provider.of<AppState>(context,
                                        listen: false)
                                    .updateSession(updatedSession);
                                setState(() {});
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
                              final list = shopping.entries.map((e) {
                                final mark = checked[e.key] ?? false ? '☑' : '☐';
                                return '$mark ${e.key}${e.value.isNotEmpty ? ' (${e.value})' : ''}';
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppState>(
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

            // 3) Data Management
            Text('Data Management', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import JSON'),
                  onPressed: _showImportJsonDialog,
                ),
                const SizedBox(width: AppConstants.smallPadding),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recipe Manually'),
                  onPressed: _showAddRecipeDialog,
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
                      onPressed: () {},
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
