import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fond violet en dégradé avec des halos lumineux qui se baladent
/// lentement + trame de points qui s'efface (comme l'illustration).
///
/// Respecte le réglage « Réduire les animations » du téléphone.
class GlowBackground extends StatefulWidget {
  const GlowBackground({super.key, required this.child, this.showDots = true});

  final Widget child;
  final bool showDots;

  @override
  State<GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<GlowBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.backgroundGradient)),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(painter: _GlowPainter(_controller.value)),
          ),
        ),
        if (widget.showDots)
          IgnorePointer(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.1,
                colors: [Colors.white, Colors.transparent],
              ).createShader(rect),
              child: const CustomPaint(painter: _DotsPainter(), size: Size.infinite),
            ),
          ),
        widget.child,
      ],
    );
  }
}

/// Dessine 3 halos dont les trajectoires bouclent parfaitement (t ∈ [0,1]).
class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t);

  final double t;

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)]).createShader(
        Rect.fromCircle(center: center, radius: radius),
      );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final a = 2 * math.pi * t;
    final w = size.width;
    final h = size.height;

    // Halo violet vif — haut gauche, descend en diagonale.
    _blob(
      canvas,
      Offset(w * 0.1 + math.sin(a) * w * 0.35, h * 0.12 + (1 - math.cos(a)) * h * 0.18),
      w * 0.6,
      AppColors.vivid.withValues(alpha: 0.55),
    );
    // Halo violet — bas droite, remonte.
    _blob(
      canvas,
      Offset(w * 0.95 - math.sin(a + 1) * w * 0.3, h * 0.88 - (1 - math.cos(a)) * h * 0.2),
      w * 0.7,
      AppColors.violet.withValues(alpha: 0.6),
    );
    // Petite lueur lilas — au centre, fait un 8.
    _blob(
      canvas,
      Offset(w * 0.45 + math.sin(2 * a) * w * 0.25, h * 0.55 + math.sin(a) * h * 0.12),
      w * 0.35,
      AppColors.lilacPale.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.lilac.withValues(alpha: 0.2);
    const step = 14.0;
    for (var y = 2.0; y < size.height; y += step) {
      for (var x = 2.0; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}
