/// Événement de l'agenda (table `events`).
class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.startDate,
    this.description,
    this.bannerUrl,
    this.endDate,
    this.location,
    this.city,
    this.isLiveTv = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? bannerUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? city;
  final bool isLiveTv;

  factory EventItem.fromMap(Map<String, dynamic> m) => EventItem(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        bannerUrl: m['banner_url'] as String?,
        startDate: DateTime.parse(m['start_date'] as String).toLocal(),
        endDate: m['end_date'] == null ? null : DateTime.parse(m['end_date'] as String).toLocal(),
        location: m['location'] as String?,
        city: m['city'] as String?,
        isLiveTv: m['is_live_tv'] as bool? ?? false,
      );
}
