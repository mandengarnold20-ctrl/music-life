/// État de la chaîne TV (table `live_stream`, une seule ligne).
class LiveStream {
  const LiveStream({
    required this.id,
    required this.title,
    required this.isLive,
    required this.chatEnabled,
    this.hlsUrl,
    this.audioHlsUrl,
    this.nextProgramInfo,
    this.nextProgramAt,
    this.offlineBannerUrl,
  });

  final String id;
  final String title;
  final bool isLive;
  final bool chatEnabled;
  final String? hlsUrl;
  final String? audioHlsUrl;
  final String? nextProgramInfo;
  final DateTime? nextProgramAt;
  final String? offlineBannerUrl;

  /// Vrai seulement si le direct est actif ET qu'un flux est renseigné.
  bool get canPlay => isLive && (hlsUrl?.isNotEmpty ?? false);

  /// Flux pour le mode « audio uniquement » : rendu audio seul s'il existe
  /// (vraie économie de données), sinon le flux principal.
  String? get audioUrl => (audioHlsUrl?.isNotEmpty ?? false) ? audioHlsUrl : hlsUrl;

  factory LiveStream.fromMap(Map<String, dynamic> m) => LiveStream(
        id: m['id'] as String,
        title: m['title'] as String,
        isLive: m['is_live'] as bool? ?? false,
        chatEnabled: m['chat_enabled'] as bool? ?? false,
        hlsUrl: m['hls_url'] as String?,
        audioHlsUrl: m['audio_hls_url'] as String?,
        nextProgramInfo: m['next_program_info'] as String?,
        nextProgramAt: m['next_program_at'] == null ? null : DateTime.parse(m['next_program_at'] as String).toLocal(),
        offlineBannerUrl: m['offline_banner_url'] as String?,
      );
}
