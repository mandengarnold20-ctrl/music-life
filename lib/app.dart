import 'package:flutter/material.dart';

import 'core/router/app_routes.dart';
import 'core/router/app_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/splash_screen.dart';
import 'features/onboarding/presentation/welcome_screen.dart';

/// Racine de l'application : thème + routes.
class MusicLifeApp extends StatelessWidget {
  const MusicLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Life',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.welcome: (_) => const WelcomeScreen(),
        AppRoutes.shell: (_) => const AppShell(),
      },
    );
  }
}
