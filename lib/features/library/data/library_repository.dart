import 'package:supabase_flutter/supabase_flutter.dart';

import '../../explore/domain/event_item.dart';
import '../domain/collections.dart';
import '../domain/vod_item.dart';

/// Accès au catalogue musical : titres, albums, playlists, artistes, événements.
class LibraryRepository {
  LibraryRepository(this._db);

  final SupabaseClient _db;

  List<VodItem> _items(List<Map<String, dynamic>> rows) => rows.map(VodItem.fromMap).toList();

  Future<List<VodItem>> latest({MediaCategory? category, int limit = 40}) async {
    var q = _db.from('media_items').select(VodItem.selectColumns);
    if (category != null) q = q.eq('category', category.name);
    return _items(await q.order('created_at', ascending: false).limit(limit));
  }

  Future<List<VodItem>> featured({int limit = 12}) async => _items(await _db
      .from('media_items')
      .select(VodItem.selectColumns)
      .eq('is_featured', true)
      .order('featured_priority', ascending: false)
      .order('created_at', ascending: false)
      .limit(limit));

  Future<List<VodItem>> popular({int limit = 12}) async => _items(await _db
      .from('media_items')
      .select(VodItem.selectColumns)
      .gt('play_count', 0)
      .order('play_count', ascending: false)
      .limit(limit));

  Future<VodItem?> mediaById(String id) async {
    final row = await _db.from('media_items').select(VodItem.selectColumns).eq('id', id).maybeSingle();
    return row == null ? null : VodItem.fromMap(row);
  }

  Future<List<Album>> albums({int limit = 40}) async {
    final rows = await _db.from('albums').select(Album.selectColumns).order('release_date', ascending: false).limit(limit);
    return rows.map(Album.fromMap).toList();
  }

  Future<Album?> albumById(String id) async {
    final row = await _db.from('albums').select(Album.selectColumns).eq('id', id).maybeSingle();
    return row == null ? null : Album.fromMap(row);
  }

  Future<List<VodItem>> albumTracks(String albumId) async => _items(await _db
      .from('media_items')
      .select(VodItem.selectColumns)
      .eq('album_id', albumId)
      .order('track_number')
      .order('created_at'));

  Future<List<Playlist>> playlists({bool featuredOnly = false}) async {
    var q = _db.from('playlists').select();
    if (featuredOnly) q = q.eq('is_featured', true);
    final rows = await q.order('sort_order').order('created_at', ascending: false);
    return rows.map(Playlist.fromMap).toList();
  }

  Future<Playlist?> playlistById(String id) async {
    final row = await _db.from('playlists').select().eq('id', id).maybeSingle();
    return row == null ? null : Playlist.fromMap(row);
  }

  Future<List<VodItem>> playlistTracks(String playlistId) async {
    final rows = await _db
        .from('playlist_items')
        .select('position, media_items(${VodItem.selectColumns})')
        .eq('playlist_id', playlistId)
        .order('position');
    return rows
        .map((r) => r['media_items'])
        .whereType<Map<String, dynamic>>()
        .map(VodItem.fromMap)
        .toList();
  }

  Future<Artist?> artistById(String id) async {
    final row = await _db.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : Artist.fromMap(row);
  }

  Future<List<VodItem>> artistTracks(String profileId) async => _items(await _db
      .from('media_items')
      .select(VodItem.selectColumns)
      .eq('profile_id', profileId)
      .order('play_count', ascending: false)
      .order('created_at', ascending: false));

  Future<List<Album>> artistAlbums(String profileId) async {
    final rows = await _db.from('albums').select(Album.selectColumns).eq('profile_id', profileId).order('release_date', ascending: false);
    return rows.map(Album.fromMap).toList();
  }

  /// Événements à venir (et ceux d'aujourd'hui), du plus proche au plus lointain.
  Future<List<EventItem>> upcomingEvents({EventType? type, int limit = 50}) async {
    final since = DateTime.now().subtract(const Duration(hours: 12)).toUtc().toIso8601String();
    var q = _db.from('events').select(EventItem.selectColumns).gte('start_date', since);
    if (type != null) q = q.eq('event_type', type.dbValue);
    final rows = await q.order('start_date').limit(limit);
    return rows.map(EventItem.fromMap).toList();
  }

  Future<EventItem?> eventById(String id) async {
    final row = await _db.from('events').select(EventItem.selectColumns).eq('id', id).maybeSingle();
    return row == null ? null : EventItem.fromMap(row);
  }

  /// Recherche globale (fonction SQL `search_all`).
  Future<List<SearchHit>> search(String q) async {
    final rows = await _db.rpc('search_all', params: {'q': q, 'max_per_type': 15}) as List<dynamic>;
    return rows.map((r) => SearchHit.fromMap(r as Map<String, dynamic>)).toList();
  }
}

/// Un résultat de recherche.
class SearchHit {
  const SearchHit({required this.kind, required this.id, required this.title, this.subtitle, this.imageUrl});

  final String kind; // video | audio | profile | album | playlist | event
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;

  factory SearchHit.fromMap(Map<String, dynamic> m) => SearchHit(
        kind: m['kind'] as String,
        id: m['id'] as String,
        title: m['title'] as String,
        subtitle: m['subtitle'] as String?,
        imageUrl: m['image_url'] as String?,
      );
}
