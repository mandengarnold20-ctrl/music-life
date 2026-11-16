import 'package:flutter/material.dart';

/// Points de rupture : téléphone, tablette, ordinateur / TV.
class Breakpoints {
  Breakpoints._();

  /// Tablette en paysage, ordinateur, TV : menu latéral au lieu de la barre du bas.
  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 840;

  /// Nombre de colonnes conseillé pour une grille de cartes.
  static double gridCardWidth(BuildContext context) => isWide(context) ? 280 : 200;
}

/// Centre le contenu et limite sa largeur sur les grands écrans.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.maxWidth = 1200});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
