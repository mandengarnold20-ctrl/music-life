import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive.dart';
import '../../artists/presentation/artist_screen.dart';
import '../../events/presentation/events_screen.dart';
import '../../library/data/library_repository.dart';
import '../../library/presentation/library_providers.dart';
import '../../library/presentation/track_list_screen.dart';
import '../../library/presentation/vod_player_screen.dart';
import '../../library/presentation/widgets/music_tiles.dart';

/// Onglet Recherche : une seule barre pour les titres, artistes, albums,
/// playlists et événements (tolère les fautes de frappe).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _input = TextEditingController();
  Timer? _debounce;
  String _query = '';
  Future<List<SearchHit>>? _results;

  static const _sections = <String, String>{
    'video': 'Clips',
    'audio': 'Titres audio',
    'profile': 'Artistes',
    'album': 'Albums',
    'playlist': 'Playlists',
    'event': 'Événements',
  };

  @override
  void dispose() {
    _debounce?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final q = value.trim();
      setState(() {
        _query = q;
        _results = q.length < 2 ? null : ref.read(libraryRepositoryProvider).search(q);
      });
    });
  }

  Future<void> _open(SearchHit hit) async {
    final repo = ref.read(libraryRepositoryProvider);
    switch (hit.kind) {
      case 'video':
      case 'audio':
        final item = await repo.mediaById(hit.id);
        if (item != null && mounted) openVod(context, item);
      case 'profile':
        openArtist(context, hit.id);
      case 'album':
        TrackListScreen.open(context, title: hit.title, subtitle: hit.subtitle, coverUrl: hit.imageUrl, numbered: true, loader: () => repo.albumTracks(hit.id));
      case 'playlist':
        TrackListScreen.open(context, title: hit.title, subtitle: hit.subtitle, coverUrl: hit.imageUrl, loader: () => repo.playlistTracks(hit.id));
      case 'event':
        final e = await repo.eventById(hit.id);
        if (e != null && mounted) showEventDetails(context, ref, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        bottom: false,
        child: MaxWidth(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text('RECHERCHE', style: AppTheme.condensed(size: 30).copyWith(letterSpacing: 2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _input,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Titre, artiste, album, concert…',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mist),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Effacer',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _input.clear();
                              _onChanged('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _results == null
                    ? const _Hint()
                    : FutureBuilder<List<SearchHit>>(
                        future: _results,
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.lilac));
                          }
                          if (snap.hasError) {
                            return const Center(child: Text('Recherche impossible. Vérifiez votre connexion.', style: TextStyle(color: AppColors.mist)));
                          }
                          final hits = snap.data ?? const [];
                          if (hits.isEmpty) {
                            return Center(child: Text('Aucun résultat pour « $_query ».', style: const TextStyle(color: AppColors.mist)));
                          }
                          return ListView(
                            padding: const EdgeInsets.only(bottom: 32),
                            children: [
                              for (final entry in _sections.entries)
                                if (hits.any((h) => h.kind == entry.key)) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                                    child: Text(entry.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.lilacPale)),
                                  ),
                                  for (final h in hits.where((h) => h.kind == entry.key))
                                    ListTile(
                                      onTap: () => _open(h),
                                      leading: SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: Cover(
                                          url: h.imageUrl,
                                          radius: h.kind == 'profile' ? 52 : 10,
                                          icon: switch (h.kind) {
                                            'profile' => Icons.person_rounded,
                                            'album' => Icons.album_rounded,
                                            'playlist' => Icons.queue_music_rounded,
                                            'event' => Icons.event_rounded,
                                            'video' => Icons.ondemand_video_rounded,
                                            _ => Icons.music_note_rounded,
                                          },
                                        ),
                                      ),
                                      title: Text(h.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      subtitle: h.subtitle == null || h.subtitle!.isEmpty
                                          ? null
                                          : Text(h.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mist)),
                                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
                                    ),
                                ],
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.library_music_rounded, size: 56, color: AppColors.lilac),
            SizedBox(height: 12),
            Text(
              'Cherchez un chant, un artiste, un album ou un concert.\nMême avec une faute de frappe, on le trouve !',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mist, height: 1.6),
            ),
          ],
        ),
      );
}
