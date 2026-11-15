import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/audio_player_service.dart';
import '../../../core/media/hls_video_player.dart';
import '../../../core/router/tab_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/live_badge.dart';
import '../domain/live_stream.dart';
import 'live_tv_providers.dart';
import 'widgets/audio_only_panel.dart';
import 'widgets/live_chat.dart';
import 'widgets/offline_waiting_view.dart';

/// Onglet 2 — TV Live.
///
/// Bascule automatiquement (Supabase Realtime) entre :
///  • is_live = true  → lecteur HLS + mode audio + chat modéré
///  • is_live = false → écran d'attente (compte à rebours + grille)
class LiveTvScreen extends ConsumerWidget {
  const LiveTvScreen({super.key});

  static const _audioId = 'live';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fin du direct : on coupe aussi l'audio en arrière-plan.
    ref.listen<AsyncValue<LiveStream?>>(liveStreamProvider, (prev, next) {
      final wasLive = prev?.valueOrNull?.canPlay ?? false;
      final isLive = next.valueOrNull?.canPlay ?? false;
      if (wasLive && !isLive) {
        final audio = ref.read(audioPlayerServiceProvider);
        if (audio.currentId == _audioId) audio.stop();
        ref.read(liveAudioModeProvider.notifier).state = false;
      }
    });

    final live = ref.watch(liveStreamProvider);

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        bottom: false,
        child: live.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.lilac)),
          error: (_, __) => OfflineWaitingView(
            stream: null,
            onRetry: () => ref.invalidate(liveStreamProvider),
          ),
          data: (stream) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: stream != null && stream.canPlay
                ? _LiveView(key: const ValueKey('on-air'), stream: stream)
                : OfflineWaitingView(key: const ValueKey('off-air'), stream: stream),
          ),
        ),
      ),
    );
  }
}

class _LiveView extends ConsumerWidget {
  const _LiveView({super.key, required this.stream});

  final LiveStream stream;

  Future<void> _toggleAudio(WidgetRef ref, bool enable) async {
    final audio = ref.read(audioPlayerServiceProvider);
    ref.read(liveAudioModeProvider.notifier).state = enable;
    if (enable) {
      await audio.play(
        id: LiveTvScreen._audioId,
        url: stream.audioUrl!,
        title: stream.title,
        artworkUrl: stream.offlineBannerUrl,
        isLive: true,
      );
    } else if (audio.currentId == LiveTvScreen._audioId) {
      await audio.stop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioMode = ref.watch(liveAudioModeProvider);
    // La vidéo n'est montée que si l'onglet est visible (économise batterie et données).
    final tabVisible = ref.watch(currentTabProvider) == AppTab.live;

    final Widget player;
    if (audioMode) {
      player = AudioOnlyPanel(title: stream.title);
    } else if (tabVisible) {
      player = HlsVideoPlayer(url: stream.hlsUrl!, isLive: true);
    } else {
      player = const AspectRatio(aspectRatio: 16 / 9, child: ColoredBox(color: Colors.black));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        player,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              const LiveBadge(compact: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: audioMode,
            onChanged: (v) => _toggleAudio(ref, v),
            activeTrackColor: AppColors.violet,
            secondary: const Icon(Icons.headphones_rounded, color: AppColors.lilacPale),
            title: const Text('Audio uniquement', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Économie de données · écoute écran éteint',
                style: TextStyle(color: AppColors.mist, fontSize: 13)),
          ),
        ),
        const Divider(height: 1, color: Colors.white12),
        Expanded(
          child: stream.chatEnabled
              ? LiveChat(liveStreamId: stream.id)
              : const Center(
                  child: Text('Le chat est fermé pour ce direct.', style: TextStyle(color: AppColors.mist)),
                ),
        ),
      ],
    );
  }
}
