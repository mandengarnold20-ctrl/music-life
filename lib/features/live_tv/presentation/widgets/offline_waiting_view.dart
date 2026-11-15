import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/music_life_logo.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../explore/domain/event_item.dart';
import '../../domain/live_stream.dart';
import '../live_tv_providers.dart';
import 'countdown.dart';

/// Écran d'attente élégant quand aucun direct n'est en cours :
/// bannière, compte à rebours, infos du prochain programme et grille TV.
class OfflineWaitingView extends ConsumerWidget {
  const OfflineWaitingView({super.key, required this.stream, this.onRetry});

  final LiveStream? stream;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(upcomingTvProgramsProvider);
    final nextAt = stream?.nextProgramAt;
    final showCountdown = nextAt != null && nextAt.isAfter(DateTime.now());

    return RefreshIndicator(
      color: AppColors.lilac,
      onRefresh: () async {
        ref.invalidate(upcomingTvProgramsProvider);
        onRetry?.call();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Bannière d'attente
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (stream?.offlineBannerUrl != null)
                  CachedNetworkImage(imageUrl: stream!.offlineBannerUrl!, fit: BoxFit.cover)
                else
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xF214001F)],
                    ),
                  ),
                ),
                const Positioned(top: 16, right: 16, child: MusicLifeLogo(width: 110, cutoutColor: Color(0xFF2A0045))),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PROCHAIN DIRECT', style: AppTheme.condensed(size: 18, color: AppColors.lilacPale).copyWith(letterSpacing: 3)),
                      const SizedBox(height: 6),
                      Text(
                        stream?.nextProgramInfo ?? 'Le direct reprend bientôt',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (showCountdown) ...[
            Countdown(target: nextAt!),
            const SizedBox(height: 8),
            Center(
              child: Text(
                DateFormat("EEEE d MMMM 'à' HH'h'mm", 'fr_FR').format(nextAt!),
                style: const TextStyle(color: AppColors.mist),
              ),
            ),
          ] else if (stream == null && onRetry != null)
            Center(
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Vérifier à nouveau'),
              ),
            ),
          const SectionHeader(title: 'Grille des programmes'),
          programs.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppColors.lilac)),
            ),
            error: (_, __) => const _Empty('Grille indisponible pour le moment.'),
            data: (list) => list.isEmpty
                ? const _Empty('Aucun programme annoncé pour l\'instant.')
                : Column(children: [for (final p in list) _ProgramTile(p)]),
          ),
        ],
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile(this.event);

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('d', 'fr_FR').format(event.startDate);
    final month = DateFormat('MMM', 'fr_FR').format(event.startDate).toUpperCase().replaceAll('.', '');
    final hour = DateFormat("EEEE · HH'h'mm", 'fr_FR').format(event.startDate);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(gradient: AppColors.accentGradient, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(day, style: AppTheme.condensed(size: 26)),
                Text(month, style: const TextStyle(fontSize: 11, letterSpacing: 1, color: AppColors.mist)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [hour, if (event.city != null) event.city!].join(' · '),
                  style: const TextStyle(color: AppColors.mist, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(message, style: const TextStyle(color: AppColors.mist)),
      );
}
