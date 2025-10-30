import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/app_state.dart';
import '../theme/theme.dart';
import '../utils/constants.dart';

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
                child:
                    _buildSessionCard(context, appState, session),
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

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardCornerRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session name and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.sessionName,
                        style: Theme.of(context)
                            .textTheme
                            .displayMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppConstants.smallPadding),
                      Text(
                        formattedDate,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: AppConstants.defaultPadding),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.pastelMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${session.recipeIds.length} recipes',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              color: AppTheme.darkBg,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppConstants.defaultPadding),

            // Recipes preview
            FutureBuilder<List<String>>(
              future: Future.value(session.recipeIds),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SizedBox(height: 40);
                }

                final recipes = snapshot.data!;
                return Wrap(
                  spacing: AppConstants.smallPadding,
                  runSpacing: AppConstants.smallPadding,
                  children: recipes
                      .take(3)
                      .map((id) =>
                          _buildRecipeChip(id))
                      .toList(),
                );
              },
            ),
            if (session.recipeIds.length > 3)
              Padding(
                padding: EdgeInsets.only(
                  top: AppConstants.smallPadding,
                ),
                child: Text(
                  '+${session.recipeIds.length - 3} more',
                  style:
                      Theme.of(context).textTheme.bodySmall,
                ),
              ),
            SizedBox(height: AppConstants.defaultPadding),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.visibility),
                    label: Text('View'),
                    onPressed: () =>
                        _showSessionDetails(
                          context,
                          appState,
                          session,
                        ),
                  ),
                ),
                SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.delete),
                    label: Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.darkBgSecondary,
                          title: Text('Delete Session?'),
                          content: Text(
                            'Delete "${session.sessionName}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                appState
                                    .deleteSession(session.id ?? 0);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text('Session deleted'),
                                    backgroundColor:
                                        AppTheme.success,
                                  ),
                                );
                              },
                              child: Text('Delete'),
                            ),
                          ],
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
  }

  Widget _buildRecipeChip(String recipeId) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.darkBgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.pastelLavender),
      ),
      child: Text(
        recipeId.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: AppTheme.pastelLavender,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showSessionDetails(
    BuildContext context,
    AppState appState,
    Session session,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.darkBgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppConstants.cardCornerRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.sessionName,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: AppConstants.defaultPadding),
              Divider(color: AppTheme.textMuted, height: 1),
              SizedBox(height: AppConstants.defaultPadding),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: session.recipeIds.length,
                  itemBuilder: (context, index) {
                    final recipeId =
                        session.recipeIds[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical:
                            AppConstants.smallPadding / 2,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 16,
                              color:
                                  AppTheme.success),
                          SizedBox(
                              width:
                                  AppConstants
                                      .smallPadding),
                          Expanded(
                            child: Text(
                              recipeId
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppConstants.defaultPadding),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}