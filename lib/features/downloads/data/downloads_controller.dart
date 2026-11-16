import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/domain/vod_item.dart';

/// Un titre téléchargé pour l'écoute hors connexion.
class DownloadedTrack {
  const DownloadedTrack({required this.item, required this.path, required this.isVideo, required this.bytes});

  final VodItem item;
  final String path; // dossier privé de l'appli (inaccessible aux autres applis)
  final bool isVideo;
  final int bytes;

  String get key => '${item.id}_${isVideo ? 'v' : 'a'}';

  Map<String, dynamic> toJson() => {'item': item.toMap(), 'path': path, 'isVideo': isVideo, 'bytes': bytes};

  factory DownloadedTrack.fromJson(Map<String, dynamic> j) => DownloadedTrack(
        item: VodItem.fromMap(j['item'] as Map<String, dynamic>),
        path: j['path'] as String,
        isVideo: j['isVideo'] as bool,
        bytes: (j['bytes'] as num).toInt(),
      );
}

class DownloadsState {
  const DownloadsState({this.items = const [], this.progress = const {}});

  final List<DownloadedTrack> items;
  final Map<String, double> progress; // clé → 0..1 pendant le téléchargement

  DownloadedTrack? find(String mediaId, {required bool video}) {
    for (final t in items) {
      if (t.item.id == mediaId && t.isVideo == video) return t;
    }
    return null;
  }

  DownloadsState copyWith({List<DownloadedTrack>? items, Map<String, double>? progress}) =>
      DownloadsState(items: items ?? this.items, progress: progress ?? this.progress);
}

/// Gère les téléchargements hors connexion (applis Android / iOS uniquement).
class DownloadsController extends StateNotifier<DownloadsState> {
  DownloadsController() : super(const DownloadsState()) {
    _load();
  }

  static const _prefsKey = 'downloads_v1';
  static bool get supported => !kIsWeb;

  Future<void> _load() async {
    if (!supported) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => DownloadedTrack.fromJson(e as Map<String, dynamic>))
        .where((t) => File(t.path).existsSync())
        .toList();
    state = state.copyWith(items: list);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.items.map((t) => t.toJson()).toList()));
  }

  /// Télécharge l'audio (par défaut) ou la vidéo d'un titre.
  /// Lève une [Exception] avec un message lisible en cas d'échec.
  Future<void> download(VodItem item, {bool video = false}) async {
    if (!supported) throw Exception('Le téléchargement est disponible dans l\'appli Android / iPhone.');
    if (!item.isDownloadable) throw Exception('Ce titre n\'est pas disponible hors connexion.');
    final url = video ? item.videoUrl : item.audioUrl;
    if (url == null || url.isEmpty) throw Exception('Aucun fichier à télécharger.');
    if (Uri.parse(url).path.endsWith('.m3u8')) {
      throw Exception('Ce titre est en streaming uniquement (pas de fichier MP4/MP3).');
    }

    final key = '${item.id}_${video ? 'v' : 'a'}';
    if (state.progress.containsKey(key) || state.find(item.id, video: video) != null) return;

    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/downloads');
    await dir.create(recursive: true);
    final ext = video ? 'mp4' : (Uri.parse(url).path.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''));
    final file = File('${dir.path}/$key.${ext.isEmpty ? 'mp3' : ext}');

    state = state.copyWith(progress: {...state.progress, key: 0});
    final client = http.Client();
    try {
      final response = await client.send(http.Request('GET', Uri.parse(url)));
      if (response.statusCode != 200) throw Exception('Téléchargement refusé (${response.statusCode}).');
      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) state = state.copyWith(progress: {...state.progress, key: received / total});
      }
      await sink.close();
      final track = DownloadedTrack(item: item, path: file.path, isVideo: video, bytes: received);
      state = DownloadsState(
        items: [track, ...state.items],
        progress: Map.of(state.progress)..remove(key),
      );
      await _save();
    } catch (e) {
      if (await file.exists()) await file.delete();
      state = state.copyWith(progress: Map.of(state.progress)..remove(key));
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> remove(DownloadedTrack track) async {
    final f = File(track.path);
    if (await f.exists()) await f.delete();
    state = state.copyWith(items: state.items.where((t) => t.key != track.key).toList());
    await _save();
  }
}

final downloadsProvider = StateNotifierProvider<DownloadsController, DownloadsState>((ref) => DownloadsController());
