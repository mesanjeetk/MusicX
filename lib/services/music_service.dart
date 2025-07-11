import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class MusicService {
  static const List<String> _supportedExtensions = [
    '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.opus', '.wma'
  ];

  static Future<List<Song>> getAllSongs() async {
    final songs = <Song>[];
    
    // Get common music directories
    final directories = await _getMusicDirectories();
    
    for (final directory in directories) {
      if (await directory.exists()) {
        final files = await _getAudioFiles(directory);
        for (final file in files) {
          final song = await _createSongFromFile(file);
          if (song != null) {
            songs.add(song);
          }
        }
      }
    }
    
    // Sort songs alphabetically by title
    songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    
    return songs;
  }

  static Future<List<Directory>> _getMusicDirectories() async {
    final directories = <Directory>[];
    
    // Common Android music directories
    final commonPaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Music',
      '/sdcard/Download',
      '/sdcard/Downloads',
      '/storage/emulated/0/DCIM/Music',
      '/storage/emulated/0/Documents/Music',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Audio',
      '/storage/emulated/0/Telegram/Telegram Audio',
    ];
    
    // Add external storage directory if available
    try {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        commonPaths.add('${externalDir.path}/Music');
        commonPaths.add(externalDir.path);
      }
    } catch (e) {
      print('Error getting external storage: $e');
    }
    
    // Add directories that exist
    for (final path in commonPaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        directories.add(dir);
      }
    }
    
    return directories;
  }

  static Future<List<File>> _getAudioFiles(Directory directory) async {
    final files = <File>[];
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final extension = entity.path.toLowerCase().substring(
            entity.path.lastIndexOf('.'),
          );
          if (_supportedExtensions.contains(extension)) {
            files.add(entity);
          }
        }
      }
    } catch (e) {
      print('Error reading directory ${directory.path}: $e');
    }
    
    return files;
  }

  static Future<Song?> _createSongFromFile(File file) async {
    try {
      final fileName = _getFileNameWithoutExtension(file.path);
      final fileStat = await file.stat();
      
      // Extract basic info from filename and path
      final pathParts = file.path.split('/');
      String artist = 'Unknown Artist';
      String album = 'Unknown Album';
      String title = fileName;
      
      // Try to extract artist and title from filename patterns
      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts[1].trim();
        }
      }
      
      // Try to get album from parent directory
      if (pathParts.length >= 2) {
        final parentDir = pathParts[pathParts.length - 2];
        if (parentDir.toLowerCase() != 'music' && 
            parentDir.toLowerCase() != 'download' &&
            parentDir.toLowerCase() != 'downloads') {
          album = parentDir;
        }
      }
      
      // Estimate duration based on file size (rough approximation)
      final fileSizeKB = fileStat.size / 1024;
      final estimatedDuration = (fileSizeKB / 128).round(); // Assuming 128kbps average
      
      return Song(
        id: file.path.hashCode.toString(),
        title: title,
        artist: artist,
        album: album,
        path: file.path,
        albumArt: null, // We'll generate placeholder colors instead
        duration: estimatedDuration,
      );
    } catch (e) {
      print('Error creating song from ${file.path}: $e');
      return null;
    }
  }

  static String _getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final lastDot = fileName.lastIndexOf('.');
    return lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
  }

  // Generate a consistent color for each song based on title
  static int generateColorForSong(String title) {
    final hash = title.hashCode;
    final colors = [
      0xFF6366F1, // Indigo
      0xFF8B5CF6, // Purple
      0xFFEC4899, // Pink
      0xFFEF4444, // Red
      0xFFF59E0B, // Amber
      0xFF10B981, // Emerald
      0xFF06B6D4, // Cyan
      0xFF3B82F6, // Blue
      0xFF84CC16, // Lime
      0xFFF97316, // Orange
    ];
    return colors[hash.abs() % colors.length];
  }

  // Search songs by title, artist, or album
  static List<Song> searchSongs(List<Song> songs, String query) {
    if (query.isEmpty) return songs;
    
    final lowerQuery = query.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(lowerQuery) ||
             song.artist.toLowerCase().contains(lowerQuery) ||
             song.album.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Group songs by artist
  static Map<String, List<Song>> groupSongsByArtist(List<Song> songs) {
    final Map<String, List<Song>> grouped = {};
    for (final song in songs) {
      if (!grouped.containsKey(song.artist)) {
        grouped[song.artist] = [];
      }
      grouped[song.artist]!.add(song);
    }
    return grouped;
  }

  // Group songs by album
  static Map<String, List<Song>> groupSongsByAlbum(List<Song> songs) {
    final Map<String, List<Song>> grouped = {};
    for (final song in songs) {
      if (!grouped.containsKey(song.album)) {
        grouped[song.album] = [];
      }
      grouped[song.album]!.add(song);
    }
    return grouped;
  }

  // Get recently played songs (placeholder - would use shared preferences)
  static List<Song> getRecentlyPlayed(List<Song> allSongs) {
    // For now, return random songs as "recently played"
    final shuffled = List<Song>.from(allSongs);
    shuffled.shuffle(Random());
    return shuffled.take(10).toList();
  }

  // Get most played songs (placeholder)
  static List<Song> getMostPlayed(List<Song> allSongs) {
    // For now, return random songs as "most played"
    final shuffled = List<Song>.from(allSongs);
    shuffled.shuffle(Random());
    return shuffled.take(10).toList();
  }
}