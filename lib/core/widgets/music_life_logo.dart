import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Logo pinceau Music Life : « Music » sur une plaque blanche aux bords
/// déchirés + pastille « LIFE » en dégradé violet.
///
/// Dessiné en vectoriel : net à toutes les tailles, sans image à embarquer.
/// [cutoutColor] = couleur du fond derrière le logo (contour de la pastille).
class MusicLifeLogo extends StatelessWidget {
  const MusicLifeLogo({
    super.key,
    this.width = 240,
    this.cutoutColor = AppColors.night,
  });

  final double width;
  final Color cutoutColor;

  // Proportions de référence du dessin (identiques au canevas).
  static const _w = 640.0;
  static const _h = 262.0;
  static const _tilt = -2 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Music Life',
      image: true,
      child: SizedBox(
        width: width,
        height: width * _h / _w,
        child: FittedBox(
          child: SizedBox(
            width: _w,
            height: _h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 20,
                  top: 8,
                  child: Transform.rotate(
                    angle: _tilt,
                    child: SizedBox(
                      width: 600,
                      height: 212,
                      child: CustomPaint(
                        painter: const TornPlatePainter(color: Colors.white),
                        child: Center(
                          child: Text(
                            'Music',
                            style: GoogleFonts.permanentMarker(
                              fontSize: 148,
                              height: 1,
                              letterSpacing: 4,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 44,
                  bottom: 6,
                  child: Transform.rotate(
                    angle: _tilt,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(30, 4, 34, 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cutoutColor, width: 5),
                      ),
                      child: Text(
                        'LIFE',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 40,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plaque aux bords irréguliers (effet pinceau). Réutilisée par le
/// bandeau-titre. Le tracé est défini sur 600 × 212 et s'étire à la taille.
class TornPlatePainter extends CustomPainter {
  const TornPlatePainter({required this.color});

  final Color color;

  static const _refW = 600.0;
  static const _refH = 212.0;
  static const _points = <Offset>[
    Offset(8, 6), Offset(22.6, 6.5), Offset(37.3, 9.2), Offset(51.9, 6.1), Offset(66.6, 6.5), Offset(81.2, 7.1), Offset(95.9, 4.4), Offset(110.5, 6.8), Offset(125.2, 7.7), Offset(139.8, 9), Offset(154.5, 4.2), Offset(169.2, 5.7), Offset(183.8, 4.3), Offset(198.5, 9.5), Offset(213.1, 8.8), Offset(227.8, 4.3), Offset(242.4, 11), Offset(257, 11), Offset(271.7, 8.9), Offset(286.3, 8.7), Offset(301, 5.6), Offset(315.7, 4.7), Offset(330.3, 8.4), Offset(344.9, 5.2), Offset(359.6, 6.2), Offset(374.2, 6.7), Offset(388.9, 5.3), Offset(403.6, 8.4), Offset(418.2, 8.4), Offset(432.8, 11.3), Offset(447.5, 9.1), Offset(462.2, 10.1), Offset(476.8, 9.2), Offset(491.4, 10.4), Offset(506.1, 9.1), Offset(520.8, 7.9), Offset(535.4, 13.1), Offset(550.1, 13.2), Offset(564.7, 12.2), Offset(579.4, 11.4), Offset(594, 10), Offset(591, 24), Offset(591.3, 38), Offset(588.8, 52), Offset(595.5, 66), Offset(591.6, 80), Offset(595.8, 94), Offset(590.9, 108), Offset(596.3, 122), Offset(594.9, 136), Offset(586.1, 150), Offset(588, 164), Offset(594.7, 178), Offset(590, 192), Offset(590, 206), Offset(575.4, 205.2), Offset(560.7, 202.8), Offset(546, 206.6), Offset(531.4, 207.5), Offset(516.8, 203.9), Offset(502.1, 202.5), Offset(487.4, 204.1), Offset(472.8, 208.4), Offset(458.1, 206.9), Offset(443.5, 202.3), Offset(428.9, 203.1), Offset(414.2, 202), Offset(399.5, 201.6), Offset(384.9, 206.7), Offset(370.2, 202.2), Offset(355.6, 204.8), Offset(341, 203.9), Offset(326.3, 202), Offset(311.7, 205.7), Offset(297, 201.4), Offset(282.3, 204.9), Offset(267.7, 201.1), Offset(253.1, 203.1), Offset(238.4, 201.6), Offset(223.8, 201.9), Offset(209.1, 206.7), Offset(194.4, 205.4), Offset(179.8, 201.8), Offset(165.2, 205.8), Offset(150.5, 201), Offset(135.8, 202.2), Offset(121.2, 205.3), Offset(106.6, 203.7), Offset(91.9, 199.8), Offset(77.2, 205.9), Offset(62.6, 200.4), Offset(47.9, 200.6), Offset(33.3, 204.1), Offset(18.6, 200.9), Offset(4, 202), Offset(0.0, 188), Offset(0.5, 174), Offset(5.7, 160), Offset(2.6, 146), Offset(6.4, 132), Offset(4.4, 118), Offset(5.5, 104), Offset(10.9, 90), Offset(6.4, 76), Offset(7.6, 62), Offset(10.8, 48), Offset(4.3, 34), Offset(4.3, 20)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _refW;
    final sy = size.height / _refH;
    final path = Path()..moveTo(_points.first.dx * sx, _points.first.dy * sy);
    for (final p in _points.skip(1)) {
      path.lineTo(p.dx * sx, p.dy * sy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(TornPlatePainter old) => old.color != color;
}
