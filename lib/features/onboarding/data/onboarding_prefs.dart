import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise si l'écran de bienvenue a déjà été vu.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const _key = 'onboarding_seen';

  static Future<bool> isSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  static Future<void> markSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}
