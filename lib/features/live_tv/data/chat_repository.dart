import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/chat_message.dart';

/// Chat du direct (temps réel). Les règles RLS du serveur garantissent :
/// écriture réservée aux connectés non bannis, pendant un direct avec chat
/// ouvert, nom d'auteur imposé par le serveur.
class ChatRepository {
  ChatRepository(this._db);

  final SupabaseClient _db;

  /// 100 derniers messages, du plus récent au plus ancien.
  Stream<List<ChatMessage>> watch(String liveStreamId) => _db
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('live_stream_id', liveStreamId)
      .order('created_at', ascending: false)
      .limit(100)
      .map((rows) => rows.map(ChatMessage.fromMap).where((m) => !m.isHidden).toList());

  Future<void> send(String liveStreamId, String body) =>
      _db.from('chat_messages').insert({'live_stream_id': liveStreamId, 'body': body.trim()});

  /// Modération : la suppression est diffusée en temps réel à tous les
  /// spectateurs (le message disparaît de leur écran).
  Future<void> remove(int messageId) => _db.from('chat_messages').delete().eq('id', messageId);
}
