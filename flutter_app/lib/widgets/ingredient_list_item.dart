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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showEditDialog() async {
    final controller = TextEditingController(text: widget.quantity);
    
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppTheme.darkBgSecondary,
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Quantity',
                  style: Theme.of(dialogContext).textTheme.displayMedium,
                ),
                SizedBox(height: AppConstants.defaultPadding),
                TextField(
                  controller: controller,
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
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: AppConstants.smallPadding),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final text = controller.text;
                          Navigator.pop(dialogContext);
                          widget.onEdit(text);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
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
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonCornerRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: AppConstants.smallPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: widget.checked,
                  onChanged: (value) => widget.onCheckChanged(value ?? false),
                ),
              ),
              SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                              fontSize: 16,
                              height: 1.3,
                            ),
                      ),
                      if (widget.quantity.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.quantity,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.pastelPeach,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _showEditDialog,
                    tooltip: 'Edit quantity',
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppTheme.error),
                    onPressed: widget.onDelete,
                    tooltip: 'Remove item',
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}