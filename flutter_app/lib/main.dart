import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/theme.dart';
import 'screens/swipe_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
      ],
      child: const CookingApp(),
    ),
  );
}

class CookingApp extends StatelessWidget {
  const CookingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cooking Swipe',
      theme: AppTheme.darkTheme(),
      home: const SwipeScreen(),
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}