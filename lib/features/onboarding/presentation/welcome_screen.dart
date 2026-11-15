import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chamfered_button.dart';
import '../../../core/widgets/glow_background.dart';
import '../../../core/widgets/music_life_logo.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../data/onboarding_prefs.dart';

/// Écran de bienvenue (1re ouverture).
/// Accroche : « Louange, cultes et communauté, là où vous êtes. »
/// avec le mot « êtes » souligné d'un trait qui se dessine.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _enter(BuildContext context) async {
    await OnboardingPrefs.markSeen();
    if (context.mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) {
    final headline = Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontSize: 38,
          letterSpacing: -0.5,
          color: Colors.white,
        );

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          // Défile sur les petits écrans, occupe toute la hauteur sur les grands.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MusicLifeLogo(width: 190, cutoutColor: Color(0xFF22003A)),
                const Spacer(),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(
                    style: headline,
                    children: [
                      const TextSpan(text: 'Louange, cultes\net communauté,\nlà où vous '),
                      WidgetSpan(
                        // « bottom » (et non « baseline ») : compatible avec IntrinsicHeight.
                        alignment: PlaceholderAlignment.bottom,
                        child: _UnderlinedWord('êtes', style: headline?.copyWith(color: AppColors.lilacPale)),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Suivez les cultes en direct, écoutez la louange même hors connexion '
                  'et trouvez une église près de chez vous.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.mist, height: 1.55),
                ),
                const Spacer(),
                ChamferedButton(label: 'Commencer', onPressed: () => _enter(context)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () async {
                      final signedIn = await showSignInSheet(context);
                      if (signedIn && context.mounted) _enter(context);
                    },
                    child: const Text(
                      "J'ai déjà un compte",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mot en couleur souligné d'un trait courbe qui se dessine à l'ouverture.
class _UnderlinedWord extends StatefulWidget {
  const _UnderlinedWord(this.word, {this.style});

  final String word;
  final TextStyle? style;

  @override
  State<_UnderlinedWord> createState() => _UnderlinedWordState();
}

class _UnderlinedWordState extends State<_UnderlinedWord> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _draw.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) _draw.value = 1;
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(widget.word, style: widget.style),
        Positioned(
          left: -4,
          right: -4,
          bottom: -8,
          height: 16,
          child: AnimatedBuilder(
            animation: _draw,
            builder: (context, _) => CustomPaint(
              painter: _SwooshPainter(
                progress: Curves.easeOut.transform(_draw.value),
                color: widget.style?.color ?? AppColors.lilacPale,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwooshPainter extends CustomPainter {
  _SwooshPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // Tracé de référence 120 × 20, mis à l'échelle.
    final sx = size.width / 120;
    final sy = size.height / 20;
    final full = Path()
      ..moveTo(4 * sx, 14 * sy)
      ..cubicTo(30 * sx, 4 * sy, 80 * sx, 2 * sy, 116 * sx, 10 * sy);
    final metric = full.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SwooshPainter old) => old.progress != progress || old.color != color;
}
