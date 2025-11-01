import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
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
    
    print('DEBUG: Loading ingredients for ${appState.currentSessionRecipes.length} recipes');
    
    // Aggregate ingredients from all selected recipes
    final allIngredientLists = <List<String>>[];
    for (var recipe in appState.currentSessionRecipes) {
      if (recipe.ingredients.isNotEmpty) {
        final parsed = recipe.ingredients.parseIngredients();
        print('DEBUG: Recipe ${recipe.dishName} has ingredients: $parsed');
        allIngredientLists.add(parsed);
      }
    }

    final aggregated = ListExtensions.aggregateIngredients(allIngredientLists);
    
    print('DEBUG: Aggregated ingredients: $aggregated');
    
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
    
    print('DEBUG: Saving session with ${_ingredients.length} items');
    print('DEBUG: Shopping list data: $_ingredients');
    print('DEBUG: Checked states: $_checked');
    
    try {
      await appState.saveSession(
        _sessionNameController.text.trim(),
        _ingredients,
        ingredientChecked: _checked,
      );

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
      print('DEBUG: Error saving session: $e');
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final sortedKeys = _ingredients.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
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

          // Recipe count
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
                Text(
                  '${_ingredients.length} Ingredients',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.pastelMint,
                      ),
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
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                    ),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      return IngredientListItem(
                        ingredient: key,
                        quantity: _ingredients[key] ?? '',
                        checked: _checked[key] ?? false,
                        onCheckChanged: (value) => _handleCheckChanged(key, value),
                        onDelete: () => _handleDelete(key),
                        onEdit: (newQuantity) => _handleEdit(key, newQuantity),
                      );
                    },
                  ),
          ),

          // Bottom actions
          Container(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppTheme.darkBgSecondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
    );
  }
}