import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive.dart';
import '../../downloads/data/downloads_controller.dart';
import '../domain/vod_item.dart';
import 'library_providers.dart';
import 'track_list_screen.dart';
import 'widgets/music_tiles.dart';

/// Onglet Bibliothèque : catégories, albums, playlists, téléchargements.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  static const _categories = MediaCategory.values;

  @override
  Widget build(BuildContext context) {
    final tabs = <String>['Tout', ..._categories.map((c) => c.label), 'Albums', 'Playlists', 'Hors connexion'];
    return DefaultTabController(
      length: tabs.length,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text('BIBLIOTHÈQUE', style: AppTheme.condensed(size: 30).copyWith(letterSpacing: 2)),
              ),
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.lilac,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.mist,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                dividerColor: Colors.white12,
                tabs: [for (final t in tabs) Tab(text: t)],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const _TrackList(category: null),
                    for (final c in _categories) _TrackList(category: c),
                    const _AlbumsGrid(),
                    const _PlaylistsGrid(),
                    const _DownloadsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackList extends ConsumerWidget {
  const _TrackList({required this.category});

  final MediaCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksByCategoryProvider(category));
    return RefreshIndicator(
      color: AppColors.lilac,
      onRefresh: () => ref.refresh(tracksByCategoryProvider(category).future),
      child: tracks.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lilac)),
        error: (_, __) => const _Message('Chargement impossible. Vérifiez votre connexion.'),
        data: (list) => list.isEmpty
            ? const _Message('Aucun titre dans cette catégorie pour le moment.')
            : MaxWidth(
                maxWidth: 900,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (context, i) => TrackTile(item: list[i]),
                ),
              ),
      ),
    );
  }
}

class _AlbumsGrid extends ConsumerWidget {
  const _AlbumsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(libraryRepositoryProvider);
    return ref.watch(albumsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lilac)),
          error: (_, __) => const _Message('Chargement impossible.'),
          data: (albums) => albums.isEmpty
              ? const _Message('Aucun album pour le moment.')
              : _Grid(
                  count: albums.length,
                  builder: (context, i, w) => albumCard(context, albums[i], () => TrackListScreen.open(
                        context,
                        title: albums[i].title,
                        subtitle: albums[i].artistName,
                        coverUrl: albums[i].coverUrl,
                        numbered: true,
                        loader: () => repo.albumTracks(albums[i].id),
                      ), width: w),
                ),
        );
  }
}

class _PlaylistsGrid extends ConsumerWidget {
  const _PlaylistsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(libraryRepositoryProvider);
    return ref.watch(playlistsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lilac)),
          error: (_, __) => const _Message('Chargement impossible.'),
          data: (lists) => lists.isEmpty
              ? const _Message('Aucune playlist pour le moment.')
              : _Grid(
                  count: lists.length,
                  builder: (context, i, w) => playlistCard(context, lists[i], () => TrackListScreen.open(
                        context,
                        title: lists[i].title,
                        subtitle: lists[i].description,
                        coverUrl: lists[i].coverUrl,
                        loader: () => repo.playlistTracks(lists[i].id),
                      ), width: w),
                ),
        );
  }
}

class _DownloadsList extends ConsumerWidget {
  const _DownloadsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DownloadsController.supported) {
      return const _Message(
        'L\'écoute hors connexion est disponible dans l\'appli Android et iPhone.\n'
        'Ouvrez un titre puis touchez « Télécharger ».',
      );
    }
    final state = ref.watch(downloadsProvider);
    if (state.items.isEmpty) {
      return const _Message('Aucun téléchargement.\nOuvrez un titre puis touchez « Télécharger » pour l\'écouter sans internet.');
    }
    final totalMb = state.items.fold<int>(0, (s, t) => s + t.bytes) / (1024 * 1024);
    return MaxWidth(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('${state.items.length} titre(s) · ${totalMb.toStringAsFixed(1)} Mo sur ce téléphone',
                style: const TextStyle(color: AppColors.mist)),
          ),
          for (final t in state.items)
            Dismissible(
              key: ValueKey(t.key),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: AppColors.live,
                child: const Icon(Icons.delete_rounded),
              ),
              confirmDismiss: (_) async => await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Supprimer ce téléchargement ?'),
                  content: Text('« ${t.item.title} » ne sera plus disponible hors connexion.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
                  ],
                ),
              ) ?? false,
              onDismissed: (_) => ref.read(downloadsProvider.notifier).remove(t),
              child: TrackTile(item: t.item, offline: t),
            ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Glissez un titre vers la gauche pour le supprimer.', style: TextStyle(color: AppColors.mist, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Grille de cartes qui s'adapte à la largeur (téléphone → TV).
class _Grid extends StatelessWidget {
  const _Grid({required this.count, required this.builder});

  final int count;
  final Widget Function(BuildContext, int, double) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cardW = Breakpoints.gridCardWidth(context);
      final cols = (c.maxWidth / (cardW + 16)).floor().clamp(2, 8);
      final w = (c.maxWidth - 40 - 16 * (cols - 1)) / cols;
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: w + 56,
        ),
        itemCount: count,
        itemBuilder: (context, i) => builder(context, i, w),
      );
    });
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mist, height: 1.6)),
          ),
        ],
      );
}
