import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chamfered_button.dart';
import '../../domain/home_banner.dart';

/// Bannière principale (Hero Banner) défilant automatiquement toutes les 6 s.
class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({super.key, required this.banners, required this.onOpen});

  final List<HomeBanner> banners;
  final ValueChanged<HomeBanner> onOpen;

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final _page = PageController(viewportFraction: 0.9);
  int _index = 0;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _auto = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!_page.hasClients) return;
        final next = (_index + 1) % widget.banners.length;
        _page.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3.4,
          child: PageView.builder(
            controller: _page,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BannerCard(banner: widget.banners[i], onOpen: widget.onOpen),
            ),
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.lilac : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onOpen});

  final HomeBanner banner;
  final ValueChanged<HomeBanner> onOpen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
            errorWidget: (_, __, ___) => const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x6614001F), Color(0xF014001F)],
                stops: [0.3, 0.6, 1],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.15),
                ),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(banner.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mist)),
                ],
                if (banner.target != BannerTarget.none) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 170,
                    child: ChamferedButton(
                      height: 46,
                      label: banner.ctaLabel ?? 'Découvrir',
                      icon: banner.target == BannerTarget.live ? Icons.live_tv_rounded : Icons.play_arrow_rounded,
                      onPressed: () => onOpen(banner),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
