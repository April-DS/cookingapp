import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../utils/extensions.dart';
import '../widgets/flip_recipe_card.dart';
import '../widgets/ingredient_list_item.dart';

class SessionsHistoryScreen extends StatefulWidget {
  const SessionsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SessionsHistoryScreen> createState() =>
      _SessionsHistoryScreenState();
}

class _SessionsHistoryScreenState extends State<SessionsHistoryScreen> {
  late Map<String, bool> cookedRecipes = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Past Sessions'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.pastSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: AppConstants.defaultPadding),
                  Text(
                    'No sessions yet',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Complete a swipe session to save it',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: appState.pastSessions.length,
            itemBuilder: (context, index) {
              final session = appState.pastSessions[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: AppConstants.defaultPadding,
                ),
                child: _buildSessionCard(context, appState, session),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    AppState appState,
    Session session,
  ) {
    final dateFormatter = DateFormat('MMM d, yyyy • HH:mm');
    final formattedDate =
        dateFormatter.format(session.dateCreated);

    return ExpansionTile(
      title: Text(session.sessionName),
      subtitle: Text(formattedDate),
      trailing: SizedBox(
        width: 136,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.share, color: AppTheme.pastelLavender),
              onPressed: () => _shareSession(session, appState),
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: Icon(Icons.shopping_cart, color: AppTheme.pastelMint),
              onPressed: () {
                _showShoppingList(context, session, appState);
              },
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
            IconButton(
              icon: Icon(Icons.delete, color: AppTheme.error),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.darkBgSecondary,
                    title: Text('Delete Session?'),
                    content: Text('Delete "${session.sessionName}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          appState.deleteSession(session.id ?? 0);
                          Navigator.pop(context);
                        },
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      children: [
        FutureBuilder<List<Recipe>>(
          future: appState.getSessionRecipes(session),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final recipes = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                final key = '${session.id}_${recipe.id}';
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: AppConstants.defaultPadding,
                  ),
          child: SizedBox(
            height: 380,
            child: FlipRecipeCard(
                      recipe: recipe,
                      isCooked: cookedRecipes[key] ?? false,
                      onCookedChanged: (value) {
                        setState(() {
                          cookedRecipes[key] = value;
                        });
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _shareSession(Session session, AppState appState) async {
    final recipes = await appState.getSessionRecipes(session);

    final buffer = StringBuffer();
    buffer.writeln('🍽 ${session.sessionName}');
    buffer.writeln('${DateFormat('MMM d, yyyy').format(session.dateCreated)}');
    buffer.writeln();

    buffer.writeln('📋 Recipes (${recipes.length}):');
    for (var recipe in recipes) {
      buffer.writeln('• ${recipe.dishName} — ${StringExtensions.formatDuration(recipe.totalTime)}, ${recipe.kcal} kcal');
    }

    if (session.shoppingList.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🛒 Shopping List:');
      final sortedKeys = session.shoppingList.keys.toList()..sort();
      for (var key in sortedKeys) {
        final quantity = session.shoppingList[key] ?? '';
        buffer.writeln('☐ $key${quantity.isNotEmpty ? ' ($quantity)' : ''}');
      }
    }

    buffer.writeln();
    buffer.writeln('Shared from Cooking Swipe');

    await Share.share(buffer.toString());
  }

  void _showShoppingList(
    BuildContext context,
    Session session,
    AppState appState,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        // Local mutable copy of checked state for the dialog
        final localChecked = Map<String, bool>.fromEntries(
          session.shoppingList.keys.map((k) => MapEntry(k, session.ingredientChecked[k] ?? false)),
        );

        return Dialog(
          backgroundColor: AppTheme.darkBgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppConstants.defaultPadding),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Shopping List',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  SizedBox(height: AppConstants.smallPadding),
                  Text(
                    session.sessionName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: AppConstants.defaultPadding),
                  Divider(color: AppTheme.textMuted, height: 1),
                  SizedBox(height: AppConstants.defaultPadding),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 360),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var key in session.shoppingList.keys.toList()..sort())
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: AppConstants.smallPadding / 2),
                              child: IngredientListItem(
                                ingredient: key,
                                quantity: session.shoppingList[key] ?? '',
                                checked: localChecked[key] ?? false,
                                onCheckChanged: (value) async {
                                  setState(() => localChecked[key] = value);
                                  // Persist change immediately
                                  final updatedSession = session.copyWith(
                                    ingredientChecked: {...session.ingredientChecked, ...localChecked},
                                  );
                                  await appState.updateSession(updatedSession);
                                },
                                onDelete: () async {
                                  // Remove item from shopping list
                                  final updatedSession = session.copyWith(
                                    shoppingList: Map.from(session.shoppingList)..remove(key),
                                    ingredientChecked: Map.from(session.ingredientChecked)..remove(key),
                                  );
                                  await appState.updateSession(updatedSession);
                                  Navigator.pop(context);
                                },
                                onEdit: (newQuantity) async {
                                  // Update quantity
                                  final updatedSession = session.copyWith(
                                    shoppingList: {
                                      ...session.shoppingList,
                                      key: newQuantity,
                                    },
                                  );
                                  await appState.updateSession(updatedSession);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: AppConstants.defaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Item'),
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
                                    padding: EdgeInsets.all(AppConstants.defaultPadding),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Add Item',
                                            style: Theme.of(dialogContext).textTheme.displayMedium,
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
                                                  onPressed: () {
                                                    final ctrl = controller;
                                                    Navigator.pop(dialogContext);
                                                    ctrl.dispose();
                                                  },
                                                  child: Text('Cancel'),
                                                ),
                                              ),
                                              SizedBox(width: AppConstants.smallPadding),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final text = controller.text;
                                                    final ctrl = controller;
                                                    if (text.isNotEmpty) {
                                                      Navigator.pop(dialogContext, text);
                                                    }
                                                    ctrl.dispose();
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
                              },
                            );

                            if (result != null && result.isNotEmpty) {
                              // Add new item
                              final updatedSession = session.copyWith(
                                shoppingList: {
                                  ...session.shoppingList,
                                  result: '', // Empty quantity by default
                                },
                              );
                              await appState.updateSession(updatedSession);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: AppConstants.smallPadding),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.copy),
                          label: Text('Copy List'),
                          onPressed: () {
                            _copyShoppingListToClipboard(session);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied to clipboard!'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
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
  }

  void _copyShoppingListToClipboard(Session session) {
    final sortedKeys = session.shoppingList.keys.toList()..sort();
    final list = sortedKeys.map((key) {
      final checked = session.ingredientChecked[key] ?? false;
      final quantity = session.shoppingList[key] ?? '';
      final mark = checked ? '☑' : '☐';
      return '$mark $key${quantity.isNotEmpty ? ' ($quantity)' : ''}';
    }).join('\n');
    
    Clipboard.setData(ClipboardData(text: list));
  }
}