import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglets de la barre du bas.
enum AppTab { home, live, library, explore, search }

/// Onglet affiché — modifiable depuis n'importe quel écran
/// (ex : le badge EN DIRECT de l'accueil ouvre la TV Live).
final currentTabProvider = StateProvider<AppTab>((ref) => AppTab.home);
