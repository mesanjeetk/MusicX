import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';

class MusicProvider extends ChangeNotifier {
  final MusicService _musicService = MusicService();
  
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  
  List<Song> get songs => _filteredSongs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  
  Future<void> loadMusic() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _songs = await _musicService.loadMusicFromDevice();
      _filteredSongs = _songs;
    } catch (e) {
      print('Error loading music: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void searchSongs(String query) {
    _searchQuery = query;
    _filteredSongs = _musicService.searchSongs(query);
    notifyListeners();
  }
  
  void clearSearch() {
    _searchQuery = '';
    _filteredSongs = _songs;
    notifyListeners();
  }
  
  List<String> get allArtists => _musicService.getAllArtists();
  List<String> get allAlbums => _musicService.getAllAlbums();
  
  List<Song> getSongsByArtist(String artist) {
    return _musicService.getSongsByArtist(artist);
  }
}