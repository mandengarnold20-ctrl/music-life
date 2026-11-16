/// Album d'un artiste (table `albums`).
class Album {
  const Album({required this.id, required this.title, this.coverUrl, this.releaseDate, this.description, this.profileId, this.artistName});

  final String id;
  final String title;
  final String? coverUrl;
  final DateTime? releaseDate;
  final String? description;
  final String? profileId;
  final String? artistName;

  static const selectColumns = 'id,title,cover_url,release_date,description,profile_id,profiles(name)';

  factory Album.fromMap(Map<String, dynamic> m) => Album(
        id: m['id'] as String,
        title: m['title'] as String,
        coverUrl: m['cover_url'] as String?,
        releaseDate: m['release_date'] == null ? null : DateTime.parse(m['release_date'] as String),
        description: m['description'] as String?,
        profileId: m['profile_id'] as String?,
        artistName: (m['profiles'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

/// Playlist composée par l'admin (table `playlists`).
class Playlist {
  const Playlist({required this.id, required this.title, this.description, this.coverUrl});

  final String id;
  final String title;
  final String? description;
  final String? coverUrl;

  factory Playlist.fromMap(Map<String, dynamic> m) => Playlist(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        coverUrl: m['cover_url'] as String?,
      );
}

/// Artiste, chantre ou groupe (table `profiles`).
class Artist {
  const Artist({required this.id, required this.name, required this.role, this.photoUrl, this.bio, this.socialLinks = const {}});

  final String id;
  final String name;
  final String role;
  final String? photoUrl;
  final String? bio;
  final Map<String, dynamic> socialLinks;

  String get roleLabel => switch (role) {
        'chantre' => 'Chantre',
        'groupe' => 'Groupe',
        'musicien' => 'Musicien',
        'pasteur' => 'Pasteur',
        _ => 'Artiste',
      };

  factory Artist.fromMap(Map<String, dynamic> m) => Artist(
        id: m['id'] as String,
        name: m['name'] as String,
        role: m['role'] as String? ?? 'artiste',
        photoUrl: m['photo_url'] as String?,
        bio: m['bio'] as String?,
        socialLinks: (m['social_links'] as Map<String, dynamic>?) ?? const {},
      );
}
