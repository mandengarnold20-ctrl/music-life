import 'package:supabase_flutter/supabase_flutter.dart';

import '../../explore/domain/event_item.dart';
import '../domain/live_stream.dart';

/// Accès au flux TV. `watch()` utilise Supabase Realtime : dès que l'admin
/// passe is_live à true/false, l'appli bascule toute seule.
class LiveStreamRepository {
  LiveStreamRepository(this._db);

  final SupabaseClient _db;

  Stream<LiveStream?> watch() => _db
      .from('live_stream')
      .stream(primaryKey: ['id'])
      .limit(1)
      .map((rows) => rows.isEmpty ? null : LiveStream.fromMap(rows.first));

  /// Grille des prochains programmes diffusés sur la TV.
  Future<List<EventItem>> upcomingTvPrograms({int limit = 6}) async {
    final rows = await _db
        .from('events')
        .select()
        .eq('is_live_tv', true)
        .gte('start_date', DateTime.now().toUtc().toIso8601String())
        .order('start_date')
        .limit(limit);
    return rows.map(EventItem.fromMap).toList();
  }
}
