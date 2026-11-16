import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_background.dart';
import '../../../core/widgets/music_life_logo.dart';
import '../data/onboarding_prefs.dart';

/// Écran de lancement : logo pinceau sur fond violet animé,
/// puis redirection vers Bienvenue (1re ouverture) ou l'appli.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // Durée minimale d'affichage du logo, en parallèle de la lecture des préférences.
    final results = await Future.wait([
      OnboardingPrefs.isSeen(),
      Future<void>.delayed(const Duration(milliseconds: 2400)),
    ]);
    if (!mounted) return;
    final seen = results.first as bool;
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    Navigator.of(context).pushReplacementNamed(seen || signedIn ? AppRoutes.shell : AppRoutes.welcome);
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Halo lilas derrière le logo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [AppColors.lilac.withValues(alpha: 0.4), AppColors.lilac.withValues(alpha: 0)],
                        ),
                      ),
                      child: const MusicLifeLogo(width: 300, cutoutColor: Color(0xFF1E0032)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'LOUANGE · ADORATION · CONCERTS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.mist,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 48,
                child: AnimatedBuilder(
                  animation: _dots,
                  builder: (context, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = 2 * math.pi * (_dots.value - i * 0.17);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase))),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
