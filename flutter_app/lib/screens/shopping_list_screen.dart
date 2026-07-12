import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../utils/ingredient_categories.dart';
import '../widgets/ingredient_list_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _sessionNameController = TextEditingController();
  final Map<String, String> _ingredients = {};
  final Map<String, bool> _checked = {};
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIngredients();
    });
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  void _loadIngredients() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Aggregate ingredients from all selected recipes, scaled to chosen portions.
    final allIngredientLists = <List<String>>[];
    for (var recipe in appState.currentSessionRecipes) {
      if (recipe.ingredients.isNotEmpty) {
        final factor = recipe.servings > 0
            ? appState.portionsFor(recipe) / recipe.servings
            : 1.0;
        final parsed = recipe.ingredients
            .parseIngredients()
            .map((line) => line.scaleFirstQuantity(factor))
            .toList();
        allIngredientLists.add(parsed);
      }
    }

    final aggregated = ListExtensions.aggregateIngredients(allIngredientLists);

    setState(() {
      _ingredients.clear();
      _ingredients.addAll(aggregated);
      // Initialize all items as unchecked
      for (var key in _ingredients.keys) {
        _checked[key] = false;
      }
    });
  }

  void _addNewItem() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

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
                'Add Item',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: nameController,
                style: TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g., Tomatoes',
                ),
                autofocus: true,
              ),
              SizedBox(height: AppConstants.smallPadding),
              TextField(
                controller: quantityController,
                style: TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  labelText: 'Quantity (optional)',
                  hintText: 'e.g., 2 kg, 500ml',
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
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          setState(() {
                            _ingredients[name] = quantityController.text.trim();
                            _checked[name] = false;
                          });
                          Navigator.pop(context);
                        }
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
    ).then((_) {
      // Dispose the dialog's controllers when it closes to avoid leaks.
      nameController.dispose();
      quantityController.dispose();
    });
  }

  /// Build full exportable JSON for the current session (before saving).
  Map<String, dynamic> _buildSessionExportJson(AppState appState) {
    final sessionName = _sessionNameController.text.trim().isEmpty
        ? 'Pickish Session'
        : _sessionNameController.text.trim();
    return {
      'app': 'pickish',
      'version': 1,
      'type': 'session',
      'session': {
        'session_name': sessionName,
        'date_created': DateTime.now().toIso8601String(),
        'target_count': appState.totalTargetCount,
        'recipe_ids': appState.currentSessionRecipes.map((r) => r.id).toList(),
        'shopping_list': _ingredients,
        'ingredient_checked': _checked,
        'ingredient_quantities': <String, String>{},
      },
      'recipes': appState.currentSessionRecipes.map((r) => r.toJson()).toList(),
    };
  }

  Future<void> _shareCurrentSession(AppState appState) async {
    final exportData = _buildSessionExportJson(appState);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final sessionName = _sessionNameController.text.trim().isEmpty
        ? 'pickish_session'
        : _sessionNameController.text.trim().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

    final dir = await Directory.systemTemp.createTemp('pickish_');
    final file = File('${dir.path}/$sessionName.pickish.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Pickish Session: ${_sessionNameController.text.trim().isEmpty ? "My Session" : _sessionNameController.text.trim()}',
      text: 'Import this file into Pickish to get the same recipes and shopping list.',
    );
  }

  void _copyToClipboard() {
    final sortedKeys = _ingredients.keys.toList()..sort();
    final list = sortedKeys.map((key) {
      final checked = _checked[key] ?? false;
      final quantity = _ingredients[key] ?? '';
      final mark = checked ? '☑' : '☐';
      return '$mark $key${quantity.isNotEmpty ? ' ($quantity)' : ''}';
    }).join('\n');
    
    Clipboard.setData(ClipboardData(text: list));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shopping list copied to clipboard'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveSession() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      await appState.saveSession(
        _sessionNameController.text.trim(),
        _ingredients,
        ingredientChecked: _checked,
      );

      _saved = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session saved successfully!'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to swipe screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving session: $e'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleCheckChanged(String key, bool value) {
    setState(() {
      _checked[key] = value;
    });
  }

  void _handleDelete(String key) {
    setState(() {
      _ingredients.remove(key);
      _checked.remove(key);
    });
  }

  void _handleEdit(String key, String newQuantity) {
    setState(() {
      _ingredients[key] = newQuantity;
    });
  }

  void _showEditRecipesSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                          'Recipes (${recipes.length}/${appState.totalTargetCount})',
                          style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            if (recipes.length < appState.totalTargetCount) {
                              // Go back to swiping to fill remaining slots
                              Navigator.pop(context);
                            } else {
                              // Reload ingredients with current recipes
                              _loadIngredients();
                            }
                          },
                          child: Text('Done'),
                        ),
                      ],
                    ),
                    SizedBox(height: AppConstants.smallPadding),
                    if (recipes.length < appState.totalTargetCount)
                      Padding(
                        padding: EdgeInsets.only(bottom: AppConstants.smallPadding),
                        child: Text(
                          'Remove recipes and tap Done to go back and choose new ones',
                          style: TextStyle(color: AppTheme.pastelPeach, fontSize: 12),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(sheetContext).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: recipes.length,
                        itemBuilder: (ctx, index) {
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
                                  setState(() {});
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

  Future<bool> _confirmDiscard() async {
    if (_saved || _ingredients.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkBgSecondary,
        title: Text('Discard session?'),
        content: Text(
          'You haven\'t saved this session yet. Your recipes and shopping list will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final grouped = IngredientCategories.groupByCategory(_ingredients.keys.toList());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareCurrentSession(appState),
            tooltip: 'Share',
          ),
          IconButton(
            icon: Icon(Icons.copy),
            onPressed: _copyToClipboard,
            tooltip: 'Copy to clipboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Session name input
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session Name (optional)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: AppConstants.smallPadding),
                TextField(
                  controller: _sessionNameController,
                  style: TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(
                    hintText: 'Auto-generates if empty',
                    suffixIcon: Icon(Icons.edit, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.textMuted, height: 1),

          // Recipe count with edit button
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${appState.currentSessionRecipes.length} Recipes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Row(
                  children: [
                    Text(
                      '${_ingredients.length} Items',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.pastelMint,
                          ),
                    ),
                    SizedBox(width: AppConstants.smallPadding),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.edit, size: 14),
                        label: Text('Edit', style: TextStyle(fontSize: 12)),
                        onPressed: () => _showEditRecipesSheet(appState),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Shopping list
          Expanded(
            child: _ingredients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: AppTheme.textMuted),
                        SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'No ingredients found',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Try adding recipes with ingredients first',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    children: [
                      for (final entry in grouped.entries) ...[
                        Padding(
                          padding: EdgeInsets.only(top: AppConstants.defaultPadding, bottom: 4),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: AppTheme.pastelPeach,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final key in entry.value)
                          IngredientListItem(
                            ingredient: key,
                            quantity: _ingredients[key] ?? '',
                            checked: _checked[key] ?? false,
                            onCheckChanged: (value) => _handleCheckChanged(key, value),
                            onDelete: () => _handleDelete(key),
                            onEdit: (newQuantity) => _handleEdit(key, newQuantity),
                          ),
                      ],
                    ],
                  ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppTheme.darkBgSecondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.2),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text('Add Item'),
                        onPressed: _addNewItem,
                      ),
                    ),
                    SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save),
                        label: Text('Save Session'),
                        onPressed: _saveSession,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}