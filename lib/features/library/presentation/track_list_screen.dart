import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive.dart';
import '../domain/vod_item.dart';
import 'vod_player_screen.dart';
import 'widgets/music_tiles.dart';

/// Écran générique : liste de titres (album, playlist, catégorie).
class TrackListScreen extends StatelessWidget {
  const TrackListScreen({
    super.key,
    required this.title,
    required this.loader,
    this.subtitle,
    this.coverUrl,
    this.numbered = false,
  });

  final String title;
  final String? subtitle;
  final String? coverUrl;
  final Future<List<VodItem>> Function() loader;
  final bool numbered;

  static void open(BuildContext context, {required String title, required Future<List<VodItem>> Function() loader, String? subtitle, String? coverUrl, bool numbered = false}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TrackListScreen(title: title, subtitle: subtitle, coverUrl: coverUrl, loader: loader, numbered: numbered),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      extendBodyBehindAppBar: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: FutureBuilder<List<VodItem>>(
          future: loader(),
          builder: (context, snap) {
            final tracks = snap.data ?? const <VodItem>[];
            return MaxWidth(
              maxWidth: 900,
              child: ListView(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + kToolbarHeight, bottom: 32),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(width: 120, height: 120, child: Cover(url: coverUrl, radius: 18, icon: Icons.queue_music_rounded)),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                              if (subtitle != null) ...[
                                const SizedBox(height: 6),
                                Text(subtitle!, style: const TextStyle(color: AppColors.mist)),
                              ],
                              const SizedBox(height: 12),
                              if (tracks.isNotEmpty)
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.deep),
                                  onPressed: () => openVod(context, tracks.first),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text('Écouter (${tracks.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.lilac)))
                  else if (snap.hasError)
                    const Padding(padding: EdgeInsets.all(24), child: Text('Chargement impossible. Vérifiez votre connexion.', style: TextStyle(color: AppColors.mist)))
                  else if (tracks.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Text('Aucun titre pour le moment.', style: TextStyle(color: AppColors.mist)))
                  else
                    for (var i = 0; i < tracks.length; i++) TrackTile(item: tracks[i], leadingNumber: numbered ? i + 1 : null),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
