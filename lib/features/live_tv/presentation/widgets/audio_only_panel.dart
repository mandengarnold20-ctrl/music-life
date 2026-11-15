import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/audio_player_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Remplace la vidéo quand le mode « audio uniquement » est actif.
class AudioOnlyPanel extends ConsumerWidget {
  const AudioOnlyPanel({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerStateProvider).valueOrNull;
    final playing = state?.playing ?? false;
    final audio = ref.read(audioPlayerServiceProvider);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.accentGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.graphic_eq_rounded, size: 44, color: Colors.white),
            const SizedBox(height: 8),
            const Text('Écoute audio du direct', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            const Text('Vous pouvez éteindre l\'écran', style: TextStyle(color: AppColors.mist, fontSize: 13)),
            const SizedBox(height: 10),
            IconButton.filled(
              tooltip: playing ? 'Pause' : 'Lecture',
              style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.deep),
              iconSize: 30,
              onPressed: playing ? audio.pause : audio.resume,
              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
