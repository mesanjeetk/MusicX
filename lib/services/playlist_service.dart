import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class PlaylistService {
  static const String _playlistsKey = 'user_playlists';
  static const String _favoritesKey = 'favorite_songs';
  static const String _recentlyPlayedKey = 'recently_played';
  static const String _playCountKey = 'play_count';

  // Playlists
  static Future<List<Playlist>> getAllPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getStringList(_playlistsKey) ?? [];
    
    return playlistsJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Playlist.fromMap(map);
    }).toList();
  }

  static Future<void> savePlaylist(Playlist playlist) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getAllPlaylists();
    
    final existingIndex = playlists.indexWhere((p) => p.id == playlist.id);
    if (existingIndex != -1) {
      playlists[existingIndex] = playlist;
    } else {
      playlists.add(playlist);
    }
    
    final playlistsJson = playlists.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_playlistsKey, playlistsJson);
  }

  static Future<void> deletePlaylist(String playlistId) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getAllPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    
    final playlistsJson = playlists.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList(_playlistsKey, playlistsJson);
  }

  // Favorites
  static Future<List<String>> getFavoriteSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  static Future<void> addToFavorites(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteSongIds();
    if (!favorites.contains(songId)) {
      favorites.add(songId);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  static Future<void> removeFromFavorites(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteSongIds();
    favorites.remove(songId);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  static Future<bool> isFavorite(String songId) async {
    final favorites = await getFavoriteSongIds();
    return favorites.contains(songId);
  }

  // Recently Played
  static Future<void> addToRecentlyPlayed(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final recentlyPlayed = prefs.getStringList(_recentlyPlayedKey) ?? [];
    
    // Remove if already exists
    recentlyPlayed.remove(songId);
    // Add to beginning
    recentlyPlayed.insert(0, songId);
    // Keep only last 50
    if (recentlyPlayed.length > 50) {
      recentlyPlayed.removeRange(50, recentlyPlayed.length);
    }
    
    await prefs.setStringList(_recentlyPlayedKey, recentlyPlayed);
  }

  static Future<List<String>> getRecentlyPlayedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentlyPlayedKey) ?? [];
  }

  // Play Count
  static Future<void> incrementPlayCount(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final playCountJson = prefs.getString(_playCountKey) ?? '{}';
    final playCount = Map<String, int>.from(jsonDecode(playCountJson));
    
    playCount[songId] = (playCount[songId] ?? 0) + 1;
    
    await prefs.setString(_playCountKey, jsonEncode(playCount));
  }

  static Future<int> getPlayCount(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final playCountJson = prefs.getString(_playCountKey) ?? '{}';
    final playCount = Map<String, int>.from(jsonDecode(playCountJson));
    
    return playCount[songId] ?? 0;
  }

  static Future<List<String>> getMostPlayedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final playCountJson = prefs.getString(_playCountKey) ?? '{}';
    final playCount = Map<String, int>.from(jsonDecode(playCountJson));
    
    final sortedEntries = playCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(50).map((e) => e.key).toList();
  }
}