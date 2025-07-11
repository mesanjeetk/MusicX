import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _key = 'cached_songs';

  static Future<List<FileSystemEntity>> loadCachedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];

    return jsonList
        .map((p) => File(p))
        .where((file) => file.existsSync())
        .toList();
  }

  static Future<void> saveSongs(List<FileSystemEntity> files) async {
    final prefs = await SharedPreferences.getInstance();
    final paths = files.map((f) => f.path).toSet().toList(); // ensure uniqueness
    await prefs.setStringList(_key, paths);
  }

  static Future<void> removeDeletedSongsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    final validPaths = jsonList.where((p) => File(p).existsSync()).toList();
    await prefs.setStringList(_key, validPaths);
  }

}
