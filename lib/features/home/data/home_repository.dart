import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../library/domain/vod_item.dart';
import '../domain/daily_verse.dart';
import '../domain/home_banner.dart';

/// Données de l'écran d'Accueil.
class HomeRepository {
  HomeRepository(this._db);

  final SupabaseClient _db;

  /// Bannières actives (la RLS filtre déjà les dates de début / fin).
  Future<List<HomeBanner>> banners() async {
    final rows = await _db.from('home_banners').select().order('sort_order').limit(6);
    return rows.map(HomeBanner.fromMap).toList();
  }

  /// « Vidéos à la une » triées par priorité.
  Future<List<VodItem>> featured({int limit = 12}) async {
    final rows = await _db
        .from('media_items')
        .select(VodItem.selectColumns)
        .eq('is_featured', true)
        .not('video_url', 'is', null)
        .order('featured_priority', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(VodItem.fromMap).toList();
  }

  /// Derniers contenus d'une catégorie.
  Future<List<VodItem>> latest(MediaCategory category, {int limit = 12}) async {
    final rows = await _db
        .from('media_items')
        .select(VodItem.selectColumns)
        .eq('category', category.name)
        .order('created_at', ascending: false)
        .limit(limit);
    return rows.map(VodItem.fromMap).toList();
  }

  Future<VodItem?> mediaById(String id) async {
    final row = await _db.from('media_items').select(VodItem.selectColumns).eq('id', id).maybeSingle();
    return row == null ? null : VodItem.fromMap(row);
  }

  /// Verset du jour ; à défaut, le plus récent déjà publié.
  Future<DailyVerse?> verseOfTheDay() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final row = await _db
        .from('daily_verses')
        .select()
        .lte('display_date', today)
        .order('display_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : DailyVerse.fromMap(row);
  }

  /// Lien de don (ouvert dans le navigateur — règles App Store).
  Future<String?> donationUrl() async {
    final row = await _db.from('app_settings').select('donation_url').eq('id', 1).maybeSingle();
    final url = row?['donation_url'] as String?;
    return (url == null || url.isEmpty) ? null : url;
  }
}
