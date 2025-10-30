import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';

class IngredientListItem extends StatefulWidget {
  final String ingredient;
  final String quantity;
  final bool checked;
  final Function(bool) onCheckChanged;
  final VoidCallback onDelete;
  final Function(String) onEdit;

  const IngredientListItem({
    required this.ingredient,
    required this.quantity,
    required this.checked,
    required this.onCheckChanged,
    required this.onDelete,
    required this.onEdit,
    Key? key,
  }) : super(key: key);

  @override
  State<IngredientListItem> createState() => _IngredientListItemState();
}

class _IngredientListItemState extends State<IngredientListItem> {
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.quantity);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
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
                'Edit Quantity',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppConstants.defaultPadding),
              TextField(
                controller: _editController,
                style: TextStyle(color: AppTheme.textLight),
                decoration: InputDecoration(
                  labelText: widget.ingredient,
                  hintText: 'e.g., 2 cups, 500ml',
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
                        widget.onEdit(_editController.text);
                        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${widget.ingredient}-${widget.quantity}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppConstants.defaultPadding),
        color: AppTheme.error.withOpacity(0.8),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonCornerRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: widget.checked,
                onChanged: (value) => widget.onCheckChanged(value ?? false),
              ),
              SizedBox(width: AppConstants.smallPadding),

              // Ingredient and quantity
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ingredient,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            decoration: widget.checked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: widget.checked
                                ? AppTheme.textMuted
                                : AppTheme.textLight,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.quantity,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.pastelPeach,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),

              // Edit button
              IconButton(
                icon: Icon(Icons.edit, size: 18),
                onPressed: _showEditDialog,
                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}