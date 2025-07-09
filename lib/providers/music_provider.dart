import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';
import '../services/audio_handler.dart';
import '../services/music_service.dart';
import '../services/permission_service.dart';

class MusicProvider extends ChangeNotifier {
  final MusicAudioHandler _audioHandler;
  
  List<Song> _songs = [];
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLoading = false;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Getters
  List<Song> get songs => _songs;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isLoading => _isLoading;
  bool get isShuffleEnabled => _isShuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;

  MusicProvider(this._audioHandler) {
    _init();
  }

  void _init() {
    // Listen to streams
    _audioHandler.currentSong.listen((song) {
      _currentSong = song;
      notifyListeners();
    });

    _audioHandler.playerState.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioHandler.position.listen((position) {
      _position = position;
      notifyListeners();
    });

    _audioHandler.duration.listen((duration) {
      _duration = duration ?? Duration.zero;
      notifyListeners();
    });

    loadSongs();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if we have storage permission before loading songs
      final hasStoragePermission = await PermissionService.hasAllEssentialPermissions();
      if (!hasStoragePermission) {
        print('Storage permission not granted, cannot load songs');
        return;
      }
      
      _songs = await MusicService.getAllSongs();
      await _audioHandler.setSongs(_songs);
    } catch (e) {
      print('Error loading songs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playPause() async {
    if (_isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> playSong(Song song) async {
    final index = _songs.indexWhere((s) => s.id == song.id);
    if (index != -1) {
      await _audioHandler.playFromIndex(index);
    }
  }

  Future<void> nextSong() async {
    await _audioHandler.skipToNext();
  }

  Future<void> previousSong() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
    // Implement shuffle logic here
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
    // Implement repeat logic here
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

enum RepeatMode { off, all, one }