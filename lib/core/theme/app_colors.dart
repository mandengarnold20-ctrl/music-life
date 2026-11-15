import 'package:flutter/material.dart';

/// Palette Music Life (identique au canevas de design).
class AppColors {
  AppColors._();

  static const night = Color(0xFF14001F);      // fond principal
  static const plum = Color(0xFF2A0045);
  static const deep = Color(0xFF3A0066);
  static const indigo = Color(0xFF4B0082);
  static const violet = Color(0xFF7A12C4);
  static const vivid = Color(0xFFA100F2);
  static const lilac = Color(0xFFC774FF);
  static const lilacPale = Color(0xFFD9A6FF);
  static const mist = Color(0xFFE9D2FF);       // texte secondaire sur fond sombre
  static const live = Color(0xFFE5002B);       // badge EN DIRECT
  static const ink = Color(0xFF111014);
  static const surface = Color(0xFF1E0032);    // cartes
  static const surfaceHigh = Color(0xFF2B0A45);

  /// Fond de l'appli (comme l'illustration de référence).
  static const backgroundGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [plum, night, deep],
    stops: [0, 0.45, 1],
  );

  /// Dégradé de la pastille « LIFE » et des barres d'accent.
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, indigo, Color(0xFF22003A)],
    stops: [0, 0.5, 1],
  );
}
