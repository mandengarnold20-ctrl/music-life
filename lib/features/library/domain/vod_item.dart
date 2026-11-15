/// Catégories de la médiathèque (enum SQL `media_category`).
enum MediaCategory {
  culte('Cultes'),
  louange('Louange & Adoration'),
  predication('Prédications'),
  magazine('Infos & Magazines');

  const MediaCategory(this.label);
  final String label;

  static MediaCategory fromDb(String v) =>
      MediaCategory.values.firstWhere((c) => c.name == v, orElse: () => MediaCategory.louange);
}

/// Vidéo ou audio du catalogue (table `media_items`).
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
    this.profileId,
    this.artistName,
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
  final String? profileId;
  final String? artistName; // jointure profiles(name)
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
      'id,title,description,category,video_url,audio_url,thumbnail_url,duration,is_featured,profile_id,created_at,profiles(name)';

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
        profileId: m['profile_id'] as String?,
        artistName: (m['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}
