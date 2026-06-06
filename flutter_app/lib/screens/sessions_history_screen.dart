import 'dart:convert';
import 'dart:io';
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
import 'recipe_detail_screen.dart';
import '../widgets/ingredient_list_item.dart';

class SessionsHistoryScreen extends StatefulWidget {
  const SessionsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SessionsHistoryScreen> createState() =>
      _SessionsHistoryScreenState();
}

class _SessionsHistoryScreenState extends State<SessionsHistoryScreen> {

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
      body: SafeArea(
        child: Consumer<AppState>(
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
              tooltip: 'Share JSON',
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
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  color: AppTheme.darkBg,
                  margin: EdgeInsets.only(bottom: AppConstants.smallPadding),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: recipe.imageFilename.isNotEmpty
                            ? Image.asset(
                                'assets/recipe_images/${recipe.imageFilename}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppTheme.pastelMint.withValues(alpha: 0.3),
                                  child: Icon(Icons.restaurant, color: AppTheme.pastelMint),
                                ),
                              )
                            : Container(
                                color: AppTheme.pastelMint.withValues(alpha: 0.3),
                                child: Icon(Icons.restaurant, color: AppTheme.pastelMint),
                              ),
                      ),
                    ),
                    title: Text(
                      recipe.dishName,
                      style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${StringExtensions.formatDuration(recipe.totalTime)} • ${recipe.kcal} kcal',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
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

  /// Build full exportable JSON for a session (includes full recipe data).
  Future<Map<String, dynamic>> _buildSessionExportJson(Session session, AppState appState) async {
    final recipes = await appState.getSessionRecipes(session);
    return {
      'app': 'pickish',
      'version': 1,
      'type': 'session',
      'session': {
        'session_name': session.sessionName,
        'date_created': session.dateCreated.toIso8601String(),
        'target_count': session.targetCount,
        'recipe_ids': session.recipeIds,
        'shopping_list': session.shoppingList,
        'ingredient_checked': session.ingredientChecked,
        'ingredient_quantities': session.ingredientQuantities,
      },
      'recipes': recipes.map((r) => r.toJson()).toList(),
    };
  }

  Future<void> _shareSession(Session session, AppState appState) async {
    final exportData = await _buildSessionExportJson(session, appState);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    // Write to a temp file and share as .json
    final dir = await Directory.systemTemp.createTemp('pickish_');
    final fileName = '${session.sessionName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.pickish.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Pickish Session: ${session.sessionName}',
      text: 'Pickish session "${session.sessionName}" — import this file into Pickish to get the same recipes and shopping list.',
    );
  }

  void _showShoppingList(
    BuildContext parentContext,
    Session initialSession,
    AppState appState,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        // Use a mutable local session so edits (delete, add, check) are reflected
        // without closing/reopening the dialog.
        var session = initialSession;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
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
                      child: session.shoppingList.isEmpty
                          ? Center(
                              child: Text('No items',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var key in session.shoppingList.keys.toList()..sort())
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: AppConstants.smallPadding / 2),
                                      child: IngredientListItem(
                                        ingredient: key,
                                        quantity: session.shoppingList[key] ?? '',
                                        checked: session.ingredientChecked[key] ?? false,
                                        onCheckChanged: (value) async {
                                          final updatedChecked = Map<String, bool>.from(session.ingredientChecked);
                                          updatedChecked[key] = value;
                                          final updatedSession = session.copyWith(
                                            ingredientChecked: updatedChecked,
                                          );
                                          await appState.updateSession(updatedSession);
                                          setDialogState(() => session = updatedSession);
                                        },
                                        onDelete: () async {
                                          final updatedShopping = Map<String, String>.from(session.shoppingList)..remove(key);
                                          final updatedChecked = Map<String, bool>.from(session.ingredientChecked)..remove(key);
                                          final updatedSession = session.copyWith(
                                            shoppingList: updatedShopping,
                                            ingredientChecked: updatedChecked,
                                          );
                                          await appState.updateSession(updatedSession);
                                          setDialogState(() => session = updatedSession);
                                        },
                                        onEdit: (newQuantity) async {
                                          final updatedSession = session.copyWith(
                                            shoppingList: {
                                              ...session.shoppingList,
                                              key: newQuantity,
                                            },
                                          );
                                          await appState.updateSession(updatedSession);
                                          setDialogState(() => session = updatedSession);
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
                              final result = await showDialog<String>(
                                context: context,
                                builder: (addContext) {
                                  final controller = TextEditingController();
                                  return Dialog(
                                    backgroundColor: AppTheme.darkBgSecondary,
                                    child: Padding(
                                      padding: EdgeInsets.all(AppConstants.defaultPadding),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Add Item',
                                            style: Theme.of(addContext).textTheme.displayMedium,
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
                                                  onPressed: () => Navigator.pop(addContext),
                                                  child: Text('Cancel'),
                                                ),
                                              ),
                                              SizedBox(width: AppConstants.smallPadding),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    final text = controller.text.trim();
                                                    if (text.isNotEmpty) {
                                                      Navigator.pop(addContext, text);
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
                                  );
                                },
                              );

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
                                await appState.updateSession(updatedSession);
                                setDialogState(() => session = updatedSession);
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
                              ScaffoldMessenger.of(parentContext).showSnackBar(
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
            );
          },
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