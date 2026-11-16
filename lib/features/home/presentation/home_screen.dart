import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/tab_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_background.dart';
import '../../../core/widgets/live_badge.dart';
import '../../../core/widgets/music_life_logo.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_header.dart';
import '../../artists/presentation/artist_screen.dart';
import '../../events/presentation/events_screen.dart';
import '../../library/domain/vod_item.dart';
import '../../library/presentation/library_providers.dart';
import '../../library/presentation/track_list_screen.dart';
import '../../library/presentation/vod_player_screen.dart';
import '../../library/presentation/widgets/music_tiles.dart';
import '../../live_tv/presentation/live_tv_providers.dart';
import '../domain/home_banner.dart';
import 'home_providers.dart';
import 'widgets/hero_banner_carousel.dart';
import 'widgets/media_carousel.dart';
import 'widgets/verse_card.dart';

/// Onglet 1 — Accueil : bannière, chaîne en direct, clips à la une,
/// nouveautés, louange, adoration, concerts, top écoutes, playlists, événements.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _goTo(WidgetRef ref, AppTab tab) => ref.read(currentTabProvider.notifier).state = tab;

  Future<void> _openBanner(BuildContext context, WidgetRef ref, HomeBanner b) async {
    final repo = ref.read(libraryRepositoryProvider);
    final id = b.targetId;
    switch (b.target) {
      case BannerTarget.live:
        _goTo(ref, AppTab.live);
      case BannerTarget.media:
        if (id == null) return;
        final item = await repo.mediaById(id);
        if (item != null && context.mounted) openVod(context, item);
      case BannerTarget.album:
        if (id == null) return;
        final a = await repo.albumById(id);
        if (a != null && context.mounted) {
          TrackListScreen.open(context, title: a.title, subtitle: a.artistName, coverUrl: a.coverUrl, numbered: true, loader: () => repo.albumTracks(a.id));
        }
      case BannerTarget.playlist:
        if (id == null) return;
        final p = await repo.playlistById(id);
        if (p != null && context.mounted) {
          TrackListScreen.open(context, title: p.title, subtitle: p.description, coverUrl: p.coverUrl, loader: () => repo.playlistTracks(p.id));
        }
      case BannerTarget.profile:
        if (id != null) openArtist(context, id);
      case BannerTarget.event:
        if (id == null) {
          _goTo(ref, AppTab.events);
          return;
        }
        final e = await repo.eventById(id);
        if (e != null && context.mounted) showEventDetails(context, ref, e);
      case BannerTarget.url:
        if (b.targetUrl != null) await _launchExternal(context, b.targetUrl!);
      case BannerTarget.none:
        break;
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(homeBannersProvider)
      ..invalidate(featuredTracksProvider)
      ..invalidate(popularTracksProvider)
      ..invalidate(tracksByCategoryProvider)
      ..invalidate(playlistsProvider)
      ..invalidate(upcomingEventsProvider)
      ..invalidate(verseOfTheDayProvider)
      ..invalidate(donationUrlProvider);
    await ref.read(homeBannersProvider.future).catchError((_) => <HomeBanner>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamProvider).valueOrNull;
    final isLive = live?.canPlay ?? false;
    final banners = ref.watch(homeBannersProvider);
    final verse = ref.watch(verseOfTheDayProvider).valueOrNull;
    final donationUrl = ref.watch(donationUrlProvider).valueOrNull;
    final playlists = ref.watch(playlistsProvider).valueOrNull ?? const [];
    final events = ref.watch(upcomingEventsProvider(null)).valueOrNull ?? const [];
    final repo = ref.read(libraryRepositoryProvider);
    void seeAll() => _goTo(ref, AppTab.library);
    final wide = Breakpoints.isWide(context);

    Widget carousel(String title, AsyncValue<List<VodItem>> items) =>
        MediaCarousel(title: title, items: items, onSeeAll: seeAll);

    return GlowBackground(
      showDots: false,
      child: RefreshIndicator(
        color: AppColors.lilac,
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: const Color(0xE614001F),
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 68,
              title: const MusicLifeLogo(width: 118, cutoutColor: Color(0xFF14001F)),
              actions: [
                if (isLive) Padding(padding: const EdgeInsets.only(right: 16), child: LiveBadge(onTap: () => _goTo(ref, AppTab.live))),
              ],
            ),
            SliverToBoxAdapter(
              child: MaxWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: Material(
                          color: AppColors.live.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _goTo(ref, AppTab.live),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                const Icon(Icons.live_tv_rounded, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(live?.title ?? 'Music Life TV en direct',
                                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                const Text('Regarder', style: TextStyle(color: AppColors.lilacPale, fontWeight: FontWeight.w700)),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.lilacPale),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    banners.maybeWhen(
                      data: (list) => list.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: HeroBannerCarousel(banners: list, onOpen: (b) => _openBanner(context, ref, b), wide: wide),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                    carousel('Clips à la une', ref.watch(featuredTracksProvider)),
                    carousel('Nouveautés', ref.watch(tracksByCategoryProvider(null))),
                    carousel('Louange', ref.watch(tracksByCategoryProvider(MediaCategory.louange))),
                    carousel('Adoration', ref.watch(tracksByCategoryProvider(MediaCategory.adoration))),
                    if (verse != null) VerseCard(verse: verse),
                    carousel('Concerts', ref.watch(tracksByCategoryProvider(MediaCategory.concert))),
                    carousel('Les plus écoutés', ref.watch(popularTracksProvider)),
                    if (playlists.isNotEmpty) ...[
                      SectionHeader(title: 'Playlists', onSeeAll: seeAll),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: playlists.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, i) => playlistCard(context, playlists[i], () => TrackListScreen.open(
                                context,
                                title: playlists[i].title,
                                subtitle: playlists[i].description,
                                coverUrl: playlists[i].coverUrl,
                                loader: () => repo.playlistTracks(playlists[i].id),
                              )),
                        ),
                      ),
                    ],
                    if (events.isNotEmpty) ...[
                      SectionHeader(title: 'Prochains événements', onSeeAll: () => _goTo(ref, AppTab.events)),
                      SizedBox(
                        height: 300,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: events.length.clamp(0, 8),
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (context, i) =>
                              EventCard(event: events[i], width: 300, onTap: () => showEventDetails(context, ref, events[i])),
                        ),
                      ),
                    ],
                    if (donationUrl != null) _SupportCard(url: donationUrl),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ouvre un lien dans le navigateur externe.
Future<void> _launchExternal(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le lien.')));
  }
}

/// « Soutenir Music Life » : lien de don ouvert dans le navigateur (règles App Store).
class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lilac.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_rounded, color: AppColors.lilac, size: 32),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Soutenir Music Life', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 2),
                Text('Votre don s\'ouvre dans le navigateur.', style: TextStyle(color: AppColors.mist, fontSize: 13)),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.deep),
            onPressed: () => _launchExternal(context, url),
            child: const Text('Donner', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
