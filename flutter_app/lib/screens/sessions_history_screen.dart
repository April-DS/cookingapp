import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../models/recipe.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';
import '../widgets/flip_recipe_card.dart';

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
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
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
                    height: 280,
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

  void _showShoppingList(
    BuildContext context,
    Session session,
    AppState appState,
  ) {
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildShoppingListItems(session),
                  ),
                ),
              ),
              SizedBox(height: AppConstants.defaultPadding),
              ElevatedButton.icon(
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
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildShoppingListItems(Session session) {
    print('DEBUG: Shopping list has ${session.shoppingList.length} items');
    
    if (session.shoppingList.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
          child: Text(
            'No items saved',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ];
    }

    final sortedKeys = session.shoppingList.keys.toList()..sort();
    return [
      for (var key in sortedKeys)
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppConstants.smallPadding,
          ),
          child: Row(
            children: [
              Checkbox(
                value: false,
                onChanged: (_) {},
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (session.shoppingList[key]!.isNotEmpty)
                      Text(
                        session.shoppingList[key]!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  void _copyShoppingListToClipboard(Session session) {
    final list = session.recipeIds
        .map((id) => '☐ ${id.replaceAll('_', ' ')}')
        .join('\n');
    Clipboard.setData(ClipboardData(text: list));
  }
}