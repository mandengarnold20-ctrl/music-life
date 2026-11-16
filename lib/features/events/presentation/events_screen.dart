import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chamfered_button.dart';
import '../../../core/widgets/responsive.dart';
import '../../artists/presentation/artist_screen.dart';
import '../../explore/domain/event_item.dart';
import '../../library/presentation/library_providers.dart';
import '../../library/presentation/track_list_screen.dart';
import '../../library/presentation/widgets/music_tiles.dart';

/// Filtre sélectionné (null = tous les événements).
final eventFilterProvider = StateProvider<EventType?>((ref) => null);

/// Onglet Événements : concerts, sorties d'album, sorties de clip, festivals.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  static const _filters = <EventType?>[null, EventType.concert, EventType.sortieAlbum, EventType.sortieClip, EventType.festival, EventType.liveTv];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(eventFilterProvider);
    final events = ref.watch(upcomingEventsProvider(filter));
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.lilac,
          onRefresh: () => ref.refresh(upcomingEventsProvider(filter).future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text('ÉVÉNEMENTS', style: AppTheme.condensed(size: 30).copyWith(letterSpacing: 2)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      for (final f in _filters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(f == null ? 'Tous' : f.label),
                            selected: filter == f,
                            selectedColor: AppColors.violet,
                            onSelected: (_) => ref.read(eventFilterProvider.notifier).state = f,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ...events.when<List<Widget>>(
                loading: () => [const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.lilac)))],
                error: (_, __) => [const SliverToBoxAdapter(child: _Empty('Chargement impossible. Vérifiez votre connexion.'))],
                data: (list) => list.isEmpty
                    ? [const SliverToBoxAdapter(child: _Empty('Aucun événement annoncé pour le moment.'))]
                    : [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 520,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              mainAxisExtent: Breakpoints.isWide(context) ? 330 : 300,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => EventCard(event: list[i], onTap: () => showEventDetails(context, ref, list[i])),
                              childCount: list.length,
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fiche détaillée d'un événement (utilisée aussi par l'accueil et la recherche).
void showEventDetails(BuildContext context, WidgetRef ref, EventItem e) {
  final repo = ref.read(libraryRepositoryProvider);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: Cover(url: e.bannerUrl, radius: 18, icon: Icons.event_rounded)),
          const SizedBox(height: 16),
          Text(e.type.label.toUpperCase(), style: AppTheme.condensed(size: 16, color: AppColors.lilacPale).copyWith(letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(e.title, style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _Info(Icons.schedule_rounded, DateFormat("EEEE d MMMM y 'à' HH'h'mm", 'fr_FR').format(e.startDate)),
          if (e.location != null || e.city != null) _Info(Icons.place_rounded, [e.location, e.city].whereType<String>().join(', ')),
          if (e.artistName != null && e.profileId != null)
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                openArtist(context, e.profileId!);
              },
              child: _Info(Icons.mic_rounded, e.artistName!, link: true),
            ),
          if (e.description != null) ...[
            const SizedBox(height: 12),
            Text(e.description!, style: const TextStyle(color: AppColors.mist, height: 1.6)),
          ],
          const SizedBox(height: 20),
          if (e.ticketUrl != null)
            ChamferedButton(
              label: 'Billetterie',
              icon: Icons.confirmation_number_rounded,
              onPressed: () => launchUrl(Uri.parse(e.ticketUrl!), mode: LaunchMode.externalApplication),
            ),
          if (e.albumId != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: AppColors.lilac), minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                final album = await repo.albumById(e.albumId!);
                if (album == null || !ctx.mounted) return;
                Navigator.pop(ctx);
                TrackListScreen.open(context,
                    title: album.title, subtitle: album.artistName, coverUrl: album.coverUrl, numbered: true, loader: () => repo.albumTracks(album.id));
              },
              icon: const Icon(Icons.album_rounded),
              label: const Text('Écouter l\'album'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text, {this.link = false});

  final IconData icon;
  final String text;
  final bool link;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.lilac),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(color: link ? AppColors.lilacPale : Colors.white, fontWeight: link ? FontWeight.w700 : FontWeight.w500)),
          ),
        ]),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(32), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mist)));
}
