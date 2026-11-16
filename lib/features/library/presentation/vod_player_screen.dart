import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/media/audio_player_service.dart';
import '../../../core/media/hls_video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive.dart';
import '../../artists/presentation/artist_screen.dart';
import '../../downloads/data/downloads_controller.dart';
import '../domain/vod_item.dart';
import 'widgets/music_tiles.dart';

/// Ouvre un titre. [offline] = version téléchargée à lire sans connexion.
void openVod(BuildContext context, VodItem item, {DownloadedTrack? offline}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => VodPlayerScreen(item: item, offline: offline)));
}

/// Lecture d'un clip ou d'un titre audio, téléchargement hors connexion, paroles.
class VodPlayerScreen extends ConsumerStatefulWidget {
  const VodPlayerScreen({super.key, required this.item, this.offline});

  final VodItem item;
  final DownloadedTrack? offline;

  @override
  ConsumerState<VodPlayerScreen> createState() => _VodPlayerScreenState();
}

class _VodPlayerScreenState extends ConsumerState<VodPlayerScreen> {
  late bool _audioOnly = widget.offline != null ? !widget.offline!.isVideo : !widget.item.hasVideo;

  VodItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    if (_audioOnly) WidgetsBinding.instance.addPostFrameCallback((_) => _playAudio());
  }

  /// Fichier local si le titre est téléchargé, sinon streaming.
  DownloadedTrack? _local({required bool video}) =>
      widget.offline?.isVideo == video ? widget.offline : ref.read(downloadsProvider).find(item.id, video: video);

  Future<void> _playAudio() async {
    final local = _local(video: false);
    final url = local?.path ?? item.audioUrl;
    if (url == null) return;
    Analytics.play(item.id);
    await ref.read(audioPlayerServiceProvider).play(
          id: item.id,
          url: url,
          isFile: local != null,
          title: item.title,
          artist: item.artistName ?? 'Music Life',
          artworkUrl: item.thumbnailUrl,
        );
  }

  Future<void> _download({required bool video}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(downloadsProvider.notifier).download(item, video: video);
      messenger.showSnackBar(SnackBar(content: Text('« ${item.title} » est disponible hors connexion.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final playing = ref.watch(audioPlayerStateProvider).valueOrNull?.playing ?? false;
    final audio = ref.read(audioPlayerServiceProvider);
    final isThisAudio = audio.currentId == item.id;
    final downloads = ref.watch(downloadsProvider);
    final localVideo = _local(video: true);
    final videoSource = localVideo?.path ?? item.videoUrl;
    final wide = Breakpoints.isWide(context);

    final player = !_audioOnly && videoSource != null
        ? HlsVideoPlayer(
            url: videoSource,
            isFile: localVideo != null,
            onStarted: () => Analytics.play(item.id),
          )
        : AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Cover(url: item.thumbnailUrl, radius: 0),
                const ColoredBox(color: Color(0x88000000)),
                Center(
                  child: IconButton.filled(
                    iconSize: 44,
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
          );

    final details = Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          if (item.artistName != null && item.profileId != null)
            InkWell(
              onTap: () => openArtist(context, item.profileId!),
              child: Text(item.artistName!, style: const TextStyle(color: AppColors.lilacPale, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          const SizedBox(height: 4),
          Text(
            [item.category.label, if (item.durationLabel != null) item.durationLabel!, if (item.playCount > 0) '${item.playCount} écoutes'].join(' · '),
            style: const TextStyle(color: AppColors.mist),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (item.hasVideo && item.hasAudio)
                _Pill(
                  icon: _audioOnly ? Icons.ondemand_video_rounded : Icons.headphones_rounded,
                  label: _audioOnly ? 'Voir le clip' : 'Écouter en audio seul',
                  onTap: () {
                    setState(() => _audioOnly = !_audioOnly);
                    if (_audioOnly) {
                      _playAudio();
                    } else if (isThisAudio) {
                      audio.stop();
                    }
                  },
                ),
              if (DownloadsController.supported && item.isDownloadable && item.hasAudio)
                _DownloadPill(
                  label: 'Télécharger l\'audio',
                  done: downloads.find(item.id, video: false) != null,
                  progress: downloads.progress['${item.id}_a'],
                  onTap: () => _download(video: false),
                ),
              if (DownloadsController.supported && item.isDownloadable && item.hasVideo)
                _DownloadPill(
                  label: 'Télécharger le clip',
                  done: downloads.find(item.id, video: true) != null,
                  progress: downloads.progress['${item.id}_v'],
                  onTap: () => _download(video: true),
                ),
            ],
          ),
          if (!DownloadsController.supported && item.isDownloadable)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Écoute hors connexion : disponible dans l\'appli Android et iPhone.', style: TextStyle(color: AppColors.mist, fontSize: 13)),
            ),
          if (item.description != null) ...[
            const SizedBox(height: 18),
            Text(item.description!, style: const TextStyle(color: AppColors.mist, height: 1.55)),
          ],
          if (item.lyrics != null && item.lyrics!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Paroles', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(item.lyrics!, style: const TextStyle(height: 1.7, fontSize: 16)),
          ],
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(item.category.label)),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: wide
            ? MaxWidth(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: player)),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: details),
                    ],
                  ),
                ),
              )
            : ListView(children: [player, details]),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.lilac),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 46),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      );
}

class _DownloadPill extends StatelessWidget {
  const _DownloadPill({required this.label, required this.done, required this.progress, required this.onTap});

  final String label;
  final bool done;
  final double? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (done) return const _Pill(icon: Icons.download_done_rounded, label: 'Disponible hors connexion', onTap: null);
    if (progress != null) {
      return _Pill(icon: Icons.downloading_rounded, label: 'Téléchargement… ${(progress! * 100).round()} %', onTap: null);
    }
    return _Pill(icon: Icons.download_rounded, label: label, onTap: onTap);
  }
}
