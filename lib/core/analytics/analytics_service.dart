import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Statistiques anonymes : visiteurs uniques, écoutes, spectateurs de la TV.
///
/// Chaque appareil reçoit un identifiant aléatoire (aucune donnée personnelle).
/// Le serveur (fonction SQL `track`) ne compte qu'une fois par jour chaque
/// visiteur, chaque écoute d'un même titre et chaque spectateur de la TV.
/// Une erreur réseau n'affecte jamais l'appli.
class Analytics {
  Analytics._();

  static const _key = 'visitor_id';
  static String? _visitorId;

  static Future<String> _id() async {
    if (_visitorId != null) return _visitorId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_key);
    if (id == null) {
      id = _uuidV4();
      await prefs.setString(_key, id);
    }
    return _visitorId = id;
  }

  static String _uuidV4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => 'desktop',
      _ => 'autre',
    };
  }

  static Future<void> _track(String kind, {String? mediaId}) async {
    try {
      await Supabase.instance.client.rpc('track', params: {
        'p_kind': kind,
        'p_visitor': await _id(),
        'p_media': mediaId,
        'p_platform': _platform,
      });
    } catch (_) {
      // Statistique perdue : sans conséquence pour l'utilisateur.
    }
  }

  /// À l'ouverture de l'appli.
  static Future<void> visit() => _track('visit');

  /// Quand un titre commence (audio ou vidéo).
  static Future<void> play(String mediaId) => _track('play', mediaId: mediaId);

  /// Quand quelqu'un regarde la TV en direct.
  static Future<void> liveView() => _track('live');
}
