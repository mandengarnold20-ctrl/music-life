import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Bouton au coin haut-droit coupé (style « Book Now » de l'illustration).
class ChamferedButton extends StatelessWidget {
  const ChamferedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background = Colors.white,
    this.foreground = AppColors.deep,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ClipPath(
        clipper: const _ChamferClipper(cut: 22, radius: 12),
        child: Material(
          color: background,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, color: foreground, size: 20), const SizedBox(width: 8)],
                  Text(
                    label,
                    style: TextStyle(color: foreground, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChamferClipper extends CustomClipper<Path> {
  const _ChamferClipper({required this.cut, required this.radius});

  final double cut;
  final double radius;

  @override
  Path getClip(Size s) {
    return Path()
      ..moveTo(radius, 0)
      ..lineTo(s.width - cut, 0)
      ..lineTo(s.width, cut)
      ..lineTo(s.width, s.height - radius)
      ..quadraticBezierTo(s.width, s.height, s.width - radius, s.height)
      ..lineTo(radius, s.height)
      ..quadraticBezierTo(0, s.height, 0, s.height - radius)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..close();
  }

  @override
  bool shouldReclip(_ChamferClipper old) => old.cut != cut || old.radius != radius;
}
