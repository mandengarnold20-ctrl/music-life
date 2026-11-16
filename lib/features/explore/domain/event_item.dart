/// Types d'événements musicaux.
enum EventType {
  concert('Concert'),
  sortieAlbum('Sortie d\'album'),
  sortieClip('Sortie de clip'),
  festival('Festival'),
  liveTv('Direct TV'),
  autre('Événement');

  const EventType(this.label);
  final String label;

  String get dbValue => switch (this) {
        EventType.sortieAlbum => 'sortie_album',
        EventType.sortieClip => 'sortie_clip',
        EventType.liveTv => 'live_tv',
        _ => name,
      };

  static EventType fromDb(String? v) =>
      EventType.values.firstWhere((t) => t.dbValue == v, orElse: () => EventType.autre);
}

/// Événement musical (table `events`).
class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.startDate,
    this.type = EventType.concert,
    this.description,
    this.bannerUrl,
    this.endDate,
    this.location,
    this.city,
    this.isLiveTv = false,
    this.ticketUrl,
    this.profileId,
    this.artistName,
    this.albumId,
  });

  final String id;
  final String title;
  final EventType type;
  final String? description;
  final String? bannerUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? city;
  final bool isLiveTv;
  final String? ticketUrl;
  final String? profileId;
  final String? artistName;
  final String? albumId;

  static const selectColumns = '*, profiles(name)';

  factory EventItem.fromMap(Map<String, dynamic> m) => EventItem(
        id: m['id'] as String,
        title: m['title'] as String,
        type: EventType.fromDb(m['event_type'] as String?),
        description: m['description'] as String?,
        bannerUrl: m['banner_url'] as String?,
        startDate: DateTime.parse(m['start_date'] as String).toLocal(),
        endDate: m['end_date'] == null ? null : DateTime.parse(m['end_date'] as String).toLocal(),
        location: m['location'] as String?,
        city: m['city'] as String?,
        isLiveTv: m['is_live_tv'] as bool? ?? false,
        ticketUrl: m['ticket_url'] as String?,
        profileId: m['profile_id'] as String?,
        artistName: (m['profiles'] as Map<String, dynamic>?)?['name'] as String?,
        albumId: m['album_id'] as String?,
      );
}
