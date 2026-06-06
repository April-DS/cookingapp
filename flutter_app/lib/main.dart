import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'services/app_state.dart';
import 'theme/theme.dart';
import 'screens/swipe_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/browse_recipes_screen.dart';
import 'screens/sessions_history_screen.dart';
import 'screens/onboarding_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
      ],
      child: PickishApp(showOnboarding: !onboardingComplete),
    ),
  );
}

class PickishApp extends StatefulWidget {
  final bool showOnboarding;
  const PickishApp({Key? key, required this.showOnboarding}) : super(key: key);

  @override
  State<PickishApp> createState() => _PickishAppState();
}

class _PickishAppState extends State<PickishApp> {
  late bool _showOnboarding;
  StreamSubscription<List<SharedMediaFile>>? _intentSub;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _setupIncomingFileHandling();
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  /// Listen for .pickish.json files shared to / opened with the app and import them.
  void _setupIncomingFileHandling() {
    // While the app is already running.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedFiles,
      onError: (_) {},
    );

    // When the app is launched fresh by opening/sharing a file.
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      _handleSharedFiles(files);
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    // Defer so the navigator/provider tree is ready on cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      for (final f in files) {
        if (f.path.isEmpty) continue;
        try {
          final contents = await File(f.path).readAsString();
          final json = jsonDecode(contents) as Map<String, dynamic>;
          if (!mounted) return;
          final appState = Provider.of<AppState>(context, listen: false);
          final name = await appState.importSharedSession(json);

          messengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Imported session: $name'),
              backgroundColor: AppTheme.success,
            ),
          );
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const SessionsHistoryScreen()),
          );
        } catch (_) {
          messengerKey.currentState?.showSnackBar(
            const SnackBar(
              content: Text('Could not import that file — not a Pickish session'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return; // only handle the first valid file
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      title: 'Pickish',
      theme: AppTheme.darkTheme(),
      home: _showOnboarding
          ? OnboardingScreen(
              onComplete: () => setState(() => _showOnboarding = false),
            )
          : const SwipeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
        '/statistics': (context) => const StatisticsScreen(),
        '/browse': (context) => const BrowseRecipesScreen(),
        '/history': (context) => const SessionsHistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
