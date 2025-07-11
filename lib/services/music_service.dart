import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../models/song.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();
  
  List<Song> _songs = [];
  List<Song> get songs => _songs;
  
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidVersion = await _getAndroidVersion();
      
      if (androidVersion >= 33) {
        // Android 13+ (API 33+)
        final permissions = await [
          Permission.audio,
          Permission.notification,
        ].request();
        
        return permissions.values.every((status) => status.isGranted);
      } else if (androidVersion >= 30) {
        // Android 11-12 (API 30-32)
        final permissions = await [
          Permission.storage,
          Permission.manageExternalStorage,
        ].request();
        
        return permissions.values.every((status) => status.isGranted);
      } else {
        // Android 10 and below
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }
  
  Future<int> _getAndroidVersion() async {
    // This is a simplified version - in real app, you'd use device_info_plus
    return 33; // Assume latest for this example
  }
  
  Future<List<Song>> loadMusicFromDevice() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Storage permission not granted');
    }
    
    _songs = await _scanForMusicFiles();
    return _songs;
  }
  
  Future<List<Song>> _scanForMusicFiles() async {
    final List<Song> songs = [];
    
    // Common music directories
    final musicDirs = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/DCIM',
      '/sdcard/Music',
      '/sdcard/Download',
    ];
    
    for (final dirPath in musicDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        await _scanDirectory(dir, songs);
      }
    }
    
    return songs;
  }
  
  Future<void> _scanDirectory(Directory dir, List<Song> songs) async {
    try {
      final entities = await dir.list(recursive: true).toList();
      
      for (final entity in entities) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (_isAudioFile(extension)) {
            final song = await _createSongFromFile(entity);
            if (song != null) {
              songs.add(song);
            }
          }
        }
      }
    } catch (e) {
      print('Error scanning directory ${dir.path}: $e');
    }
  }
  
  bool _isAudioFile(String extension) {
    const audioExtensions = [
      'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', 'wma', '3gp', 'mp4'
    ];
    return audioExtensions.contains(extension);
  }
  
  Future<Song?> _createSongFromFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final nameWithoutExtension = fileName.split('.').first;
      
      // Simple parsing - in real app, you'd use metadata extraction
      final parts = nameWithoutExtension.split(' - ');
      final title = parts.length > 1 ? parts[1] : nameWithoutExtension;
      final artist = parts.isNotEmpty ? parts[0] : 'Unknown Artist';
      
      return Song(
        id: file.path.hashCode.toString(),
        title: title,
        artist: artist,
        path: file.path,
        duration: null, // Would be extracted from metadata
      );
    } catch (e) {
      print('Error creating song from file ${file.path}: $e');
      return null;
    }
  }
  
  List<Song> searchSongs(String query) {
    if (query.isEmpty) return _songs;
    
    return _songs.where((song) {
      return song.title.toLowerCase().contains(query.toLowerCase()) ||
             song.artist.toLowerCase().contains(query.toLowerCase()) ||
             (song.album?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }
  
  List<Song> getSongsByArtist(String artist) {
    return _songs.where((song) => song.artist == artist).toList();
  }
  
  List<String> getAllArtists() {
    return _songs.map((song) => song.artist).toSet().toList()..sort();
  }
  
  List<String> getAllAlbums() {
    return _songs
        .where((song) => song.album != null)
        .map((song) => song.album!)
        .toSet()
        .toList()
      ..sort();
  }
}