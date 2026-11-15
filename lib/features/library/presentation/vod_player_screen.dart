import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/audio_player_service.dart';
import '../../../core/media/hls_video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/vod_item.dart';

/// Ouvre un contenu de la médiathèque.
void openVod(BuildContext context, VodItem item) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => VodPlayerScreen(item: item)));
}

/// Lecture d'une vidéo ou d'un audio (VOD).
/// Le téléchargement hors-ligne sera ajouté avec l'onglet Médiathèque.
class VodPlayerScreen extends ConsumerStatefulWidget {
  const VodPlayerScreen({super.key, required this.item});

  final VodItem item;

  @override
  ConsumerState<VodPlayerScreen> createState() => _VodPlayerScreenState();
}

class _VodPlayerScreenState extends ConsumerState<VodPlayerScreen> {
  late bool _audioOnly = !widget.item.hasVideo;

  @override
  void initState() {
    super.initState();
    if (_audioOnly) WidgetsBinding.instance.addPostFrameCallback((_) => _playAudio());
  }

  Future<void> _playAudio() {
    final item = widget.item;
    return ref.read(audioPlayerServiceProvider).play(
          id: item.id,
          url: item.audioUrl!,
          title: item.title,
          artist: item.artistName ?? 'Music Life',
          artworkUrl: item.thumbnailUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final playing = ref.watch(audioPlayerStateProvider).valueOrNull?.playing ?? false;
    final audio = ref.read(audioPlayerServiceProvider);
    final isThisAudio = audio.currentId == item.id;

    return Scaffold(
      appBar: AppBar(title: Text(item.category.label)),
      extendBodyBehindAppBar: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: ListView(
          children: [
            if (!_audioOnly && item.hasVideo)
              HlsVideoPlayer(url: item.videoUrl!)
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.thumbnailUrl != null)
                      CachedNetworkImage(imageUrl: item.thumbnailUrl!, fit: BoxFit.cover)
                    else
                      const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.accentGradient)),
                    const ColoredBox(color: Color(0x88000000)),
                    Center(
                      child: IconButton.filled(
                        iconSize: 40,
                        tooltip: playing && isThisAudio ? 'Pause' : 'Lecture',
                        style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.deep),
                        onPressed: () {
                          if (!isThisAudio) {
                            _playAudio();
                          } else {
                            playing ? audio.pause() : audio.resume();
                          }
                        },
                        icon: Icon(playing && isThisAudio ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    [if (item.artistName != null) item.artistName!, if (item.durationLabel != null) item.durationLabel!].join(' · '),
                    style: const TextStyle(color: AppColors.lilacPale, fontWeight: FontWeight.w600),
                  ),
                  if (item.hasVideo && item.hasAudio) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.lilac),
                        shape: const StadiumBorder(),
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: () {
                        setState(() => _audioOnly = !_audioOnly);
                        if (_audioOnly) {
                          _playAudio();
                        } else if (isThisAudio) {
                          audio.stop();
                        }
                      },
                      icon: Icon(_audioOnly ? Icons.ondemand_video_rounded : Icons.headphones_rounded),
                      label: Text(_audioOnly ? 'Revenir à la vidéo' : 'Écouter en audio seul'),
                    ),
                  ],
                  if (item.description != null) ...[
                    const SizedBox(height: 16),
                    Text(item.description!, style: const TextStyle(color: AppColors.mist, height: 1.55)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
