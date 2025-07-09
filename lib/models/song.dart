class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final String? albumArt;
  final int duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    this.albumArt,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'albumArt': albumArt,
      'duration': duration,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'] ?? 'Unknown Album',
      path: map['path'] ?? '',
      albumArt: map['albumArt'],
      duration: map['duration'] ?? 0,
    );
  }
}