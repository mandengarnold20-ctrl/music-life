import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Lecteur audio unique de l'appli : direct en « audio seul » et pistes MP3.
///
/// Grâce à just_audio_background (basé sur audio_service), la lecture continue
/// écran éteint, avec titre + contrôles sur l'écran verrouillé.
class AudioPlayerService {
  AudioPlayerService() {
    _configureSession();
  }

  final AudioPlayer _player = AudioPlayer();

  /// Identifiant de ce qui est en cours ('live' ou id d'un média).
  String? currentId;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// Lance une URL audio (.m3u8 ou .mp3).
  Future<void> play({
    required String id,
    required String url,
    required String title,
    String artist = 'Music Life',
    String? artworkUrl,
    bool isLive = false,
  }) async {
    if (currentId == id && _player.playing) return;
    currentId = id;
    await _player.setAudioSource(
      AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: id,
          title: title,
          artist: isLive ? '$artist · EN DIRECT' : artist,
          artUri: artworkUrl == null ? null : Uri.parse(artworkUrl),
          extras: {'isLive': isLive},
        ),
      ),
    );
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();

  Future<void> stop() async {
    currentId = null;
    await _player.stop();
  }

  Future<void> dispose() => _player.dispose();
}

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

/// État du lecteur (lecture / pause / chargement) pour l'interface.
final audioPlayerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioPlayerServiceProvider).playerStateStream;
});
