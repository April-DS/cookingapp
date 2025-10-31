import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../widgets/ingredient_list_item.dart';
import 'sessions_history_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late Map<String, String> _ingredients;
  late Map<String, bool> _checkedItems;
  late TextEditingController _sessionNameController;

  @override
  void initState() {
    super.initState();
    _sessionNameController = TextEditingController();
    _aggregateIngredients();
    _checkedItems = {};
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  void _aggregateIngredients() {
    final appState = Provider.of<AppState>(context, listen: false);
    final ingredientLists = appState.currentSessionRecipes
        .map((r) => r.ingredients.parseIngredients())
        .toList();

    _ingredients = {};
    
    // Aggregate all ingredients
    for (final list in ingredientLists) {
      for (final ingredient in list) {
        if (_ingredients.containsKey(ingredient)) {
          // Already exists, just keep it
          _ingredients[ingredient] = _ingredients[ingredient]!;
        } else {
          _ingredients[ingredient] = ingredient;
        }
      }
    }
    
    // Sort alphabetically
    final sorted = Map.fromEntries(
      _ingredients.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    _ingredients = sorted;
    
    print('DEBUG: Aggregated ${_ingredients.length} ingredients');
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkBgSecondary,
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
                controller: controller,
                style: TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: 'e.g., 2 cups flour',
                ),
                autofocus: true,
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
                        if (controller.text.isNotEmpty) {
                          setState(() {
                            _ingredients[controller.text] = '';
                            _checkedItems[controller.text] = false;
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
    controller.dispose();
  }

  void _showSaveSessionDialog() {
    _sessionNameController.clear();
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
                'Save Session',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: _sessionNameController,
                style: TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: 'Leave empty for auto-generated name',
                  labelText: 'Session Name (Optional)',
                ),
                autofocus: true,
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
                        print('DEBUG: Saving with ${_ingredients.length} ingredients');
                        Provider.of<AppState>(context, listen: false)
                            .saveSession(_sessionNameController.text, _ingredients);
                        Navigator.pop(context);
                        // Go back to sessions history
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SessionsHistoryScreen(),
                          ),
                        );
                      },
                      child: Text('Save'),
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
    final clipboard = _ingredients.entries
        .map((e) {
          final checked = _checkedItems[e.key] ?? false;
          final mark = checked ? '☑' : '☐';
          return '$mark ${e.key}${e.value.isNotEmpty ? ' ${e.value}' : ''}';
        })
        .join('\n');

    Clipboard.setData(ClipboardData(text: clipboard));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: AppTheme.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Info header
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Container(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: AppTheme.darkBgSecondary,
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonCornerRadius),
              ),
              child: Consumer<AppState>(
                builder: (context, appState, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appState.currentSessionRecipes.length} Recipes Selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.pastelMint,
                          ),
                    ),
                    SizedBox(height: AppConstants.smallPadding),
                    Text(
                      '${_ingredients.length} Items to Buy',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ingredient list
          Expanded(
            child: _ingredients.isEmpty
                ? Center(
                    child: Text(
                      'No ingredients',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    padding:
                        EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                        ),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final sortedKeys = _ingredients.keys.toList()..sort();
                      final key = sortedKeys[index];
                      final value = _ingredients[key]!;

                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.smallPadding / 2,
                        ),
                        child: IngredientListItem(
                          ingredient: key,
                          quantity: value,
                          checked: _checkedItems[key] ?? false,
                          onCheckChanged: (value) {
                            setState(() {
                              _checkedItems[key] = value;
                            });
                          },
                          onDelete: () {
                            setState(() {
                              _ingredients.remove(key);
                              _checkedItems.remove(key);
                            });
                          },
                          onEdit: (newQuantity) {
                            setState(() {
                              _ingredients[key] = newQuantity;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Add item button
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: AppConstants.smallPadding,
            ),
            child: OutlinedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Add Item'),
              onPressed: _showAddItemDialog,
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.copy),
                    label: Text('Copy'),
                    onPressed: _copyToClipboard,
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Save'),
                    onPressed: _showSaveSessionDialog,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}