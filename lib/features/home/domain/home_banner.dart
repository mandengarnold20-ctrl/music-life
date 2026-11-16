/// Destination d'une bannière d'accueil.
enum BannerTarget { none, live, media, event, url, album, playlist, profile }

/// Bannière principale pilotée par l'admin (table `home_banners`).
class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.target,
    this.subtitle,
    this.ctaLabel,
    this.targetId,
    this.targetUrl,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? ctaLabel;
  final BannerTarget target;
  final String? targetId;
  final String? targetUrl;

  factory HomeBanner.fromMap(Map<String, dynamic> m) => HomeBanner(
        id: m['id'] as String,
        title: m['title'] as String,
        subtitle: m['subtitle'] as String?,
        imageUrl: m['image_url'] as String,
        ctaLabel: m['cta_label'] as String?,
        target: BannerTarget.values.firstWhere(
          (t) => t.name == m['target_type'],
          orElse: () => BannerTarget.none,
        ),
        targetId: m['target_id'] as String?,
        targetUrl: m['target_url'] as String?,
      );
}
