import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../downloads/data/downloads_controller.dart';
import '../../../explore/domain/event_item.dart';
import '../../domain/collections.dart';
import '../../domain/vod_item.dart';
import '../vod_player_screen.dart';

/// Image réseau avec repli en dégradé violet.
class Cover extends StatelessWidget {
  const Cover({super.key, this.url, this.radius = 12, this.icon = Icons.music_note_rounded});

  final String? url;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.accentGradient),
      child: Center(child: Icon(icon, color: Colors.white70)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: AppColors.surface),
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}

/// Ligne de titre : pochette, titre, artiste, durée, état du téléchargement.
class TrackTile extends ConsumerWidget {
  const TrackTile({super.key, required this.item, this.leadingNumber, this.offline});

  final VodItem item;
  final int? leadingNumber;
  final DownloadedTrack? offline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloaded = ref.watch(downloadsProvider.select(
      (s) => s.find(item.id, video: false) != null || s.find(item.id, video: true) != null,
    ));
    return ListTile(
      onTap: () => openVod(context, item, offline: offline),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Cover(url: item.thumbnailUrl, radius: 10),
            if (item.hasVideo)
              const Positioned(
                right: 4,
                bottom: 4,
                child: Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
      title: Text(
        leadingNumber == null ? item.title : '$leadingNumber. ${item.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [item.artistName ?? item.category.label, if (item.durationLabel != null) item.durationLabel!].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.mist, fontSize: 13),
      ),
      trailing: downloaded || offline != null
          ? const Tooltip(
              message: 'Disponible hors connexion',
              child: Icon(Icons.download_done_rounded, color: AppColors.lilac),
            )
          : const Icon(Icons.more_horiz_rounded, color: AppColors.mist),
    );
  }
}

/// Carte carrée (album, playlist, artiste).
class SquareCard extends StatelessWidget {
  const SquareCard({super.key, required this.title, this.subtitle, this.imageUrl, required this.onTap, this.width = 160, this.round = false, this.icon = Icons.album_rounded});

  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final double width;
  final bool round;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: round ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 1, child: Cover(url: imageUrl, radius: round ? width : 16, icon: icon)),
              const SizedBox(height: 8),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.mist, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte album prête à l'emploi.
SquareCard albumCard(BuildContext context, Album a, VoidCallback onTap, {double width = 160}) => SquareCard(
      title: a.title,
      subtitle: [a.artistName, if (a.releaseDate != null) a.releaseDate!.year.toString()].whereType<String>().join(' · '),
      imageUrl: a.coverUrl,
      onTap: onTap,
      width: width,
    );

/// Carte playlist prête à l'emploi.
SquareCard playlistCard(BuildContext context, Playlist p, VoidCallback onTap, {double width = 160}) => SquareCard(
      title: p.title,
      subtitle: p.description,
      imageUrl: p.coverUrl,
      onTap: onTap,
      width: width,
      icon: Icons.queue_music_rounded,
    );

/// Carte d'événement : date, type, titre, artiste, lieu.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onTap, this.width});

  final EventItem event;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('d', 'fr_FR').format(event.startDate);
    final month = DateFormat('MMM', 'fr_FR').format(event.startDate).toUpperCase().replaceAll('.', '');
    final when = DateFormat("EEEE · HH'h'mm", 'fr_FR').format(event.startDate);
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Cover(url: event.bannerUrl, radius: 0, icon: Icons.event_rounded),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xCC14001F), borderRadius: BorderRadius.circular(999)),
                        child: Text(event.type.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        Text(day, style: AppTheme.condensed(size: 24)),
                        Text(month, style: const TextStyle(fontSize: 11, color: AppColors.mist)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            [if (event.artistName != null) event.artistName!, when, if (event.city != null) event.city!].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.mist, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
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
