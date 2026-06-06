import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/app_state.dart';
import 'theme/theme.dart';
import 'screens/swipe_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/browse_recipes_screen.dart';
import 'screens/onboarding_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
