import 'dart:io';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

class MusicService {
  static const List<String> _supportedExtensions = [
    '.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg'
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
    
    return songs;
  }

  static Future<List<Directory>> _getMusicDirectories() async {
    final directories = <Directory>[];
    
    // External storage directories
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      directories.add(Directory('${externalDir.path}/Music'));
      directories.add(Directory('/storage/emulated/0/Music'));
      directories.add(Directory('/storage/emulated/0/Download'));
      directories.add(Directory('/sdcard/Music'));
      directories.add(Directory('/sdcard/Download'));
    }
    
    return directories;
  }

  static Future<List<File>> _getAudioFiles(Directory directory) async {
    final files = <File>[];
    
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final extension = entity.path.toLowerCase().substring(entity.path.lastIndexOf('.'));
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
      final metadata = await MetadataRetriever.fromFile(file);
      
      return Song(
        id: file.path.hashCode.toString(),
        title: metadata.trackName ?? _getFileNameWithoutExtension(file.path),
        artist: metadata.trackArtistNames?.join(', ') ?? 'Unknown Artist',
        album: metadata.albumName ?? 'Unknown Album',
        path: file.path,
        albumArt: metadata.albumArt != null ? 
          'data:image/jpeg;base64,${metadata.albumArt}' : null,
        duration: metadata.trackDuration?.inSeconds ?? 0,
      );
    } catch (e) {
      print('Error reading metadata for ${file.path}: $e');
      return Song(
        id: file.path.hashCode.toString(),
        title: _getFileNameWithoutExtension(file.path),
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        path: file.path,
        albumArt: null,
        duration: 0,
      );
    }
  }

  static String _getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final lastDot = fileName.lastIndexOf('.');
    return lastDot != -1 ? fileName.substring(0, lastDot) : fileName;
  }
}