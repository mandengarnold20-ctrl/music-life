import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../library/domain/vod_item.dart';
import '../../../library/presentation/vod_player_screen.dart';

/// Carrousel horizontal de contenus avec titre de section.
/// Masqué automatiquement s'il n'y a rien à afficher.
class MediaCarousel extends StatelessWidget {
  const MediaCarousel({super.key, required this.title, required this.items, this.onSeeAll});

  final String title;
  final AsyncValue<List<VodItem>> items;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return items.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [SectionHeader(title: title), const _SkeletonRow()],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => list.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: title, onSeeAll: onSeeAll),
                SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => MediaCard(item: list[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

class MediaCard extends StatelessWidget {
  const MediaCard({super.key, required this.item, this.width = 240});

  final VodItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}${item.artistName != null ? ', ${item.artistName}' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openVod(context, item),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.thumbnailUrl != null)
                        CachedNetworkImage(
                          imageUrl: item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(color: AppColors.surface),
                          errorWidget: (_, __, ___) => const DecoratedBox(
                            decoration: BoxDecoration(gradient: AppColors.accentGradient),
                          ),
                        )
                      else
                        const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
                      Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(color: Color(0xCCFFFFFF), shape: BoxShape.circle),
                          child: Icon(
                            item.hasVideo ? Icons.play_arrow_rounded : Icons.headphones_rounded,
                            color: AppColors.deep,
                          ),
                        ),
                      ),
                      if (item.durationLabel != null)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(6)),
                            child: Text(item.durationLabel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (item.artistName != null)
                Text(item.artistName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mist, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 196,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: 240,
          height: 135,
          alignment: Alignment.topCenter,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
