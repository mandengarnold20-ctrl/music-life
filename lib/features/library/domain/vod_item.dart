/// Catégories musicales (enum SQL `media_category`).
enum MediaCategory {
  louange('Louange'),
  adoration('Adoration'),
  concert('Concerts'),
  clip('Clips'),
  instrumental('Instrumental');

  const MediaCategory(this.label);
  final String label;

  /// Les anciennes valeurs (culte, predication, magazine) sont rangées en Louange.
  static MediaCategory fromDb(String v) =>
      MediaCategory.values.firstWhere((c) => c.name == v, orElse: () => MediaCategory.louange);
}

/// Titre musical : clip vidéo et/ou piste audio (table `media_items`).
class VodItem {
  const VodItem({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.description,
    this.videoUrl,
    this.audioUrl,
    this.thumbnailUrl,
    this.duration,
    this.isFeatured = false,
    this.isDownloadable = true,
    this.playCount = 0,
    this.profileId,
    this.artistName,
    this.albumId,
    this.lyrics,
  });

  final String id;
  final String title;
  final String? description;
  final MediaCategory category;
  final String? videoUrl;
  final String? audioUrl;
  final String? thumbnailUrl;
  final Duration? duration;
  final bool isFeatured;
  final bool isDownloadable;
  final int playCount;
  final String? profileId;
  final String? artistName; // jointure profiles(name)
  final String? albumId;
  final String? lyrics;
  final DateTime createdAt;

  bool get hasVideo => videoUrl?.isNotEmpty ?? false;
  bool get hasAudio => audioUrl?.isNotEmpty ?? false;

  /// « 1:02:15 » ou « 4:32 »
  String? get durationLabel {
    final d = duration;
    if (d == null) return null;
    final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  }

  /// Colonnes à sélectionner (avec le nom de l'artiste lié).
  static const selectColumns =
      'id,title,description,category,video_url,audio_url,thumbnail_url,duration,is_featured,'
      'is_downloadable,play_count,profile_id,album_id,lyrics,created_at,profiles(name)';

  factory VodItem.fromMap(Map<String, dynamic> m) => VodItem(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        category: MediaCategory.fromDb(m['category'] as String),
        videoUrl: m['video_url'] as String?,
        audioUrl: m['audio_url'] as String?,
        thumbnailUrl: m['thumbnail_url'] as String?,
        duration: m['duration'] == null ? null : Duration(seconds: (m['duration'] as num).toInt()),
        isFeatured: m['is_featured'] as bool? ?? false,
        isDownloadable: m['is_downloadable'] as bool? ?? true,
        playCount: (m['play_count'] as num?)?.toInt() ?? 0,
        profileId: m['profile_id'] as String?,
        artistName: (m['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        albumId: m['album_id'] as String?,
        lyrics: m['lyrics'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );

  /// Sens inverse de [fromMap] (sauvegarde des téléchargements hors connexion).
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'video_url': videoUrl,
        'audio_url': audioUrl,
        'thumbnail_url': thumbnailUrl,
        'duration': duration?.inSeconds,
        'is_featured': isFeatured,
        'is_downloadable': isDownloadable,
        'play_count': playCount,
        'profile_id': profileId,
        'album_id': albumId,
        'lyrics': lyrics,
        'created_at': createdAt.toUtc().toIso8601String(),
        'profiles': artistName == null ? null : {'name': artistName},
      };
}
