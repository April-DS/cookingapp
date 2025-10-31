import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../widgets/ingredient_list_item.dart';

class ShoppingListDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Map<String, String> shoppingList;
  final Map<String, bool> checked;
  final Function(String) onAddItem;
  final Function(String) onDeleteItem;
  final Function(String, String) onEditItem;
  final Function(String, bool) onToggleChecked;

  const ShoppingListDialog({
    required this.title,
    this.subtitle,
    required this.shoppingList,
    required this.checked,
    required this.onAddItem,
    required this.onDeleteItem,
    required this.onEditItem,
    required this.onToggleChecked,
    Key? key,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context) {
    final sortedKeys = shoppingList.keys.toList()..sort();
    final list = sortedKeys.map((key) {
      final isChecked = checked[key] ?? false;
      final quantity = shoppingList[key] ?? '';
      final mark = isChecked ? '☑' : '☐';
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

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                style: Theme.of(dialogContext).textTheme.displayMedium,
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
                      onPressed: () {
                        nameController.dispose();
                        quantityController.dispose();
                        Navigator.pop(dialogContext);
                      },
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: AppConstants.smallPadding),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          // Store quantity in the key format: "name"
                          onAddItem(name);
                          // Update quantity separately
                          final quantity = quantityController.text.trim();
                          if (quantity.isNotEmpty) {
                            onEditItem(name, quantity);
                          }
                        }
                        nameController.dispose();
                        quantityController.dispose();
                        Navigator.pop(dialogContext);
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

  @override
  Widget build(BuildContext context) {
    final sortedKeys = shoppingList.keys.toList()..sort();

    return Dialog(
      backgroundColor: AppTheme.darkBgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 4),
                            Text(
                              subtitle!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: AppTheme.pastelMint),
                      onPressed: () => _copyToClipboard(context),
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.smallPadding),
                Text(
                  '${shoppingList.length} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.pastelMint,
                      ),
                ),
              ],
            ),
          ),

          Divider(color: AppTheme.textMuted, height: 1),

          // Shopping list items
          Flexible(
            child: shoppingList.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(AppConstants.defaultPadding * 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 48, color: AppTheme.textMuted),
                        SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'No items in list',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, index) {
                      final key = sortedKeys[index];
                      return IngredientListItem(
                        ingredient: key,
                        quantity: shoppingList[key] ?? '',
                        checked: checked[key] ?? false,
                        onCheckChanged: (value) {
                          onToggleChecked(key, value);
                        },
                        onDelete: () {
                          onDeleteItem(key);
                        },
                        onEdit: (newQuantity) {
                          onEditItem(key, newQuantity);
                        },
                      );
                    },
                  ),
          ),

          Divider(color: AppTheme.textMuted, height: 1),

          // Bottom actions
          Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Item'),
                    onPressed: () => _showAddItemDialog(context),
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done'),
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