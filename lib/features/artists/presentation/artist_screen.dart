import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../library/domain/collections.dart';
import '../../library/domain/vod_item.dart';
import '../../library/presentation/library_providers.dart';
import '../../library/presentation/track_list_screen.dart';
import '../../library/presentation/widgets/music_tiles.dart';

void openArtist(BuildContext context, String profileId) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArtistScreen(profileId: profileId)));
}

/// Fiche artiste : photo, biographie, réseaux, titres populaires, albums.
class ArtistScreen extends ConsumerWidget {
  const ArtistScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(libraryRepositoryProvider);
    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<(Artist?, List<VodItem>, List<Album>)>(
          future: (() async => (
                await repo.artistById(profileId),
                await repo.artistTracks(profileId),
                await repo.artistAlbums(profileId),
              ))(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return snap.hasError
                  ? const Center(child: Text('Chargement impossible.', style: TextStyle(color: AppColors.mist)))
                  : const Center(child: CircularProgressIndicator(color: AppColors.lilac));
            }
            final (artist, tracks, albums) = snap.data!;
            if (artist == null) return const Center(child: Text('Artiste introuvable.'));
            return MaxWidth(
              maxWidth: 1000,
              child: ListView(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kToolbarHeight, bottom: 32),
                children: [
                  const SizedBox(height: 8),
                  Center(child: SizedBox(width: 150, height: 150, child: Cover(url: artist.photoUrl, radius: 150, icon: Icons.person_rounded))),
                  const SizedBox(height: 14),
                  Center(child: Text(artist.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                  Center(child: Text(artist.roleLabel, style: const TextStyle(color: AppColors.lilacPale, fontWeight: FontWeight.w600))),
                  if (artist.socialLinks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          for (final e in artist.socialLinks.entries)
                            if (e.value is String && (e.value as String).startsWith('http'))
                              ActionChip(
                                label: Text(e.key[0].toUpperCase() + e.key.substring(1)),
                                avatar: const Icon(Icons.open_in_new_rounded, size: 16),
                                onPressed: () => launchUrl(Uri.parse(e.value as String), mode: LaunchMode.externalApplication),
                              ),
                        ],
                      ),
                    ),
                  if (artist.bio != null && artist.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(artist.bio!, style: const TextStyle(color: AppColors.mist, height: 1.6)),
                    ),
                  if (albums.isNotEmpty) ...[
                    const SectionHeader(title: 'Albums'),
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: albums.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (context, i) => albumCard(context, albums[i], () => TrackListScreen.open(
                              context,
                              title: albums[i].title,
                              subtitle: artist.name,
                              coverUrl: albums[i].coverUrl,
                              numbered: true,
                              loader: () => repo.albumTracks(albums[i].id),
                            )),
                      ),
                    ),
                  ],
                  SectionHeader(title: 'Titres (${tracks.length})'),
                  if (tracks.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Aucun titre pour le moment.', style: TextStyle(color: AppColors.mist)))
                  else
                    for (final t in tracks) TrackTile(item: t),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
