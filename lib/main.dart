import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

/// Point d'entrée de Music Life.
///
/// Lancer avec :
/// flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///             --dart-define=SUPABASE_ANON_KEY=eyJ...
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Env.assertConfigured();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Lecture audio en arrière-plan + contrôles sur l'écran verrouillé
  // (applis Android / iOS ; la version web utilise le lecteur du navigateur).
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.musiclife.app.audio',
      androidNotificationChannelName: 'Music Life — lecture audio',
      androidNotificationOngoing: true,
    );
  }

  // Dates en français (« dimanche 22 novembre »).
  await initializeDateFormatting('fr_FR');

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(const ProviderScope(child: MusicLifeApp()));
}
