import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/tab_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_background.dart';
import '../../../core/widgets/live_badge.dart';
import '../../../core/widgets/music_life_logo.dart';
import '../../library/domain/vod_item.dart';
import '../../library/presentation/vod_player_screen.dart';
import '../../live_tv/presentation/live_tv_providers.dart';
import '../domain/home_banner.dart';
import 'home_providers.dart';
import 'widgets/hero_banner_carousel.dart';
import 'widgets/media_carousel.dart';
import 'widgets/verse_card.dart';

/// Onglet 1 — Accueil.
/// Bannière admin, badge EN DIRECT automatique, carrousels, verset du jour,
/// bouton de soutien (lien externe, conforme App Store).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _goLive(WidgetRef ref) => ref.read(currentTabProvider.notifier).state = AppTab.live;

  Future<void> _openBanner(BuildContext context, WidgetRef ref, HomeBanner b) async {
    switch (b.target) {
      case BannerTarget.live:
        _goLive(ref);
      case BannerTarget.media:
        if (b.targetId == null) return;
        final item = await ref.read(homeRepositoryProvider).mediaById(b.targetId!);
        if (item != null && context.mounted) openVod(context, item);
      case BannerTarget.event:
        ref.read(currentTabProvider.notifier).state = AppTab.explore;
      case BannerTarget.url:
        if (b.targetUrl != null) await _launchExternal(context, b.targetUrl!);
      case BannerTarget.none:
        break;
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(homeBannersProvider)
      ..invalidate(featuredVideosProvider)
      ..invalidate(latestByCategoryProvider)
      ..invalidate(verseOfTheDayProvider)
      ..invalidate(donationUrlProvider);
    await ref.read(homeBannersProvider.future).catchError((_) => <HomeBanner>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLive = ref.watch(liveStreamProvider).valueOrNull?.canPlay ?? false;
    final liveTitle = ref.watch(liveStreamProvider).valueOrNull?.title;
    final banners = ref.watch(homeBannersProvider);
    final verse = ref.watch(verseOfTheDayProvider).valueOrNull;
    final donationUrl = ref.watch(donationUrlProvider).valueOrNull;
    void seeAll() => ref.read(currentTabProvider.notifier).state = AppTab.library;

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
                if (isLive) Padding(padding: const EdgeInsets.only(right: 16), child: LiveBadge(onTap: () => _goLive(ref))),
              ],
            ),

            // Bandeau « en direct maintenant »
            if (isLive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Material(
                    color: AppColors.live.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _goLive(ref),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.live_tv_rounded, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                liveTitle ?? 'Culte en direct',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const Text('Regarder', style: TextStyle(color: AppColors.lilacPale, fontWeight: FontWeight.w700)),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.lilacPale),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Bannière principale
            SliverToBoxAdapter(
              child: banners.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: HeroBannerCarousel(banners: list, onOpen: (b) => _openBanner(context, ref, b)),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AspectRatio(aspectRatio: 4 / 3.4, child: _BannerSkeleton()),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),

            SliverToBoxAdapter(
              child: MediaCarousel(title: 'Vidéos à la une', items: ref.watch(featuredVideosProvider), onSeeAll: seeAll),
            ),
            SliverToBoxAdapter(
              child: MediaCarousel(
                title: 'Nouveautés Louange',
                items: ref.watch(latestByCategoryProvider(MediaCategory.louange)),
                onSeeAll: seeAll,
              ),
            ),
            if (verse != null) SliverToBoxAdapter(child: VerseCard(verse: verse)),
            SliverToBoxAdapter(
              child: MediaCarousel(
                title: 'Derniers Cultes',
                items: ref.watch(latestByCategoryProvider(MediaCategory.culte)),
                onSeeAll: seeAll,
              ),
            ),
            SliverToBoxAdapter(
              child: MediaCarousel(
                title: 'Magazines & Actualités',
                items: ref.watch(latestByCategoryProvider(MediaCategory.magazine)),
                onSeeAll: seeAll,
              ),
            ),
            if (donationUrl != null) SliverToBoxAdapter(child: _SupportCard(url: donationUrl)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

/// « Soutenir l'œuvre » : ouvre le lien de don dans le navigateur
/// (aucun paiement intégré — conforme aux règles Apple).
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
                Text('Soutenir l\'œuvre', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) =>
      DecoratedBox(decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)));
}
