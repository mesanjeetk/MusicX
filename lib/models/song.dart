class Song {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String path;
  final Duration? duration;
  final String? albumArt;
  
  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.path,
    this.duration,
    this.albumArt,
  });
  
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown Title',
      artist: map['artist'] ?? 'Unknown Artist',
      album: map['album'],
      path: map['path'] ?? '',
      duration: map['duration'] != null 
        ? Duration(milliseconds: map['duration'])
        : null,
      albumArt: map['albumArt'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration?.inMilliseconds,
      'albumArt': albumArt,
    };
  }
}