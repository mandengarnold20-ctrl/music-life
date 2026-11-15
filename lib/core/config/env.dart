/// Configuration injectée à la compilation (jamais de clé dans le code source).
///
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class Env {
  Env._();

  // Valeurs par défaut = projet Supabase « music-life ».
  // La clé « publishable » est faite pour être dans l'appli (sécurité assurée par la RLS).
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jlkorgraxfdktbtxlbow.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_gB_su3gMv60YvIHCqPLQAA_biaaaCn3',
  );

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Configuration Supabase manquante. Lancez l\'appli avec '
        '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
      );
    }
  }
}
