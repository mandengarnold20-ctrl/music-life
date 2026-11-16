import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../explore/domain/event_item.dart';
import '../data/library_repository.dart';
import '../domain/collections.dart';
import '../domain/vod_item.dart';

final libraryRepositoryProvider = Provider((ref) => LibraryRepository(ref.watch(supabaseClientProvider)));

/// Titres par catégorie (null = toutes).
final tracksByCategoryProvider = FutureProvider.family<List<VodItem>, MediaCategory?>(
  (ref, category) => ref.watch(libraryRepositoryProvider).latest(category: category),
);

final featuredTracksProvider = FutureProvider<List<VodItem>>((ref) => ref.watch(libraryRepositoryProvider).featured());
final popularTracksProvider = FutureProvider<List<VodItem>>((ref) => ref.watch(libraryRepositoryProvider).popular());
final albumsProvider = FutureProvider<List<Album>>((ref) => ref.watch(libraryRepositoryProvider).albums());
final playlistsProvider = FutureProvider<List<Playlist>>((ref) => ref.watch(libraryRepositoryProvider).playlists());

/// Événements à venir (null = tous les types).
final upcomingEventsProvider = FutureProvider.family<List<EventItem>, EventType?>(
  (ref, type) => ref.watch(libraryRepositoryProvider).upcomingEvents(type: type),
);
