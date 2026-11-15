import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../explore/domain/event_item.dart';
import '../data/chat_repository.dart';
import '../data/live_stream_repository.dart';
import '../domain/chat_message.dart';
import '../domain/live_stream.dart';

final liveStreamRepositoryProvider =
    Provider((ref) => LiveStreamRepository(ref.watch(supabaseClientProvider)));

final chatRepositoryProvider = Provider((ref) => ChatRepository(ref.watch(supabaseClientProvider)));

/// État du direct en temps réel (utilisé par l'accueil, la barre d'onglets et la TV).
final liveStreamProvider = StreamProvider<LiveStream?>(
  (ref) => ref.watch(liveStreamRepositoryProvider).watch(),
);

final upcomingTvProgramsProvider = FutureProvider<List<EventItem>>(
  (ref) => ref.watch(liveStreamRepositoryProvider).upcomingTvPrograms(),
);

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>(
  (ref, liveStreamId) => ref.watch(chatRepositoryProvider).watch(liveStreamId),
);

/// Mode « audio uniquement / économie de données » du direct.
final liveAudioModeProvider = StateProvider<bool>((ref) => false);
